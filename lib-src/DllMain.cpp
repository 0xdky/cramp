// -*-c++-*-
// Time-stamp: <2003-11-01 09:38:58 dhruva>
//-----------------------------------------------------------------------------
// File : DllMain.cpp
// Desc : DllMain implementation for profiler and support code
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __DLLMAIN_SRC

#include "cramp.h"
#include "CallMonLOG.h"

#include <imagehlp.h>
#include <queue>
#include <string>
#include <hash_map>

#ifndef CRAMP_LOG_BUFFER_LIMIT
#define CRAMP_LOG_BUFFER_LIMIT 100000
#endif

FILE *g_fLogFile=0;
FILE *g_fFuncInfo=0;

unsigned int g_pid=0;
long g_l_profile=0;
long g_l_stoplogging=0;
long g_l_calldepthlimit=10;

std::queue<std::string> g_LogQueue;
std::hash_map<unsigned int,FuncInfo> g_hFuncCalls;

CRITICAL_SECTION g_cs_log;
CRITICAL_SECTION g_cs_prof;

// File static
static char logpath[256]=".";
static HANDLE h_logthread=0;

void DumpLogsTH(void);
void CALLBACK FlushLogCB(void *,BOOLEAN);

BOOL OnProcessStart(void);
BOOL OnProcessEnd(void);
void FlushLogQueue(void);
BOOL WriteFuncInfo(unsigned int,unsigned long);

//-----------------------------------------------------------------------------
// CRAMP_FlushProfileLogs
//-----------------------------------------------------------------------------
extern "C" __declspec(dllexport)
  void CRAMP_FlushProfileLogs(void){
  // Usually this iscalled to collect all logs
  // Hence, flush all logs before getting logs

  if(g_fLogFile)
    fflush(g_fLogFile);

  // Block the modification of hash
  EnterCriticalSection(&g_cs_prof);

  FILE *f_stat=0;
  char filename[MAX_PATH];
  sprintf(filename,"%s/cramp_stat#%d.log",logpath,g_pid);
  f_stat=fopen(filename,"w+");
  DEBUGCHK(f_stat);

  std::hash_map<unsigned int,FuncInfo>::iterator iter=g_hFuncCalls.begin();
  for(;iter!=g_hFuncCalls.end();iter++){
    if(f_stat)
      fprintf(f_stat,"%08X|%d|%I64d|%I64d\n",
              (*iter).first,
              (*iter).second._calls,
              (*iter).second._totalticks,
              (*iter).second._maxticks);

    // Ensure, you do not revisit between calls
    if(!(*iter).second._pending)
      continue;
    (*iter).second._pending=FALSE;

    if(!g_fFuncInfo)
      WriteFuncInfo((*iter).first,(*iter).second._calls);
  }
  if(f_stat){
    fflush(f_stat);
    fclose(f_stat);
  }

  // Unlock the hash
  LeaveCriticalSection(&g_cs_prof);

  if(g_fFuncInfo)
    fflush(g_fFuncInfo);

  return;
}

//-----------------------------------------------------------------------------
// CRAMP_EnableProfile
//  Thread safe
//-----------------------------------------------------------------------------
extern "C" __declspec(dllexport)
  void __declspec(naked) CRAMP_EnableProfile(void){
  __asm
  {
    PUSH EBP
      MOV  EBP , ESP
      PUSH EAX
      MOV  EAX , ESP
      SUB  ESP , __LOCAL_SIZE
      PUSHAD
      }

  InterlockedExchange(&g_l_profile,1);

  __asm
  {
    POPAD
      ADD ESP , __LOCAL_SIZE
      POP EAX
      MOV ESP , EBP
      POP EBP
      RET
      }
}

//-----------------------------------------------------------------------------
// CRAMP_DisableProfile
//  Thread safe
//-----------------------------------------------------------------------------
extern "C" __declspec(dllexport)
  void __declspec(naked) CRAMP_DisableProfile(void){
  __asm
  {
    PUSH EBP
      MOV  EBP , ESP
      PUSH EAX
      MOV  EAX , ESP
      SUB  ESP , __LOCAL_SIZE
      PUSHAD
      }

  InterlockedExchange(&g_l_profile,0);

  __asm
  {
    POPAD
      ADD ESP , __LOCAL_SIZE
      POP EAX
      MOV ESP , EBP
      POP EBP
      RET
      }
}

//-----------------------------------------------------------------------------
// CRAMP_SetCallDepthLimit
//  Thread safe
//-----------------------------------------------------------------------------
extern "C" __declspec(dllexport)
  void __declspec(naked) CRAMP_SetCallDepthLimit(long iCallDepth){
  __asm
  {
    PUSH EBP
      MOV  EBP , ESP
      PUSH EAX
      MOV  EAX , ESP
      SUB  ESP , __LOCAL_SIZE
      PUSHAD
      }

  InterlockedExchange(&g_l_calldepthlimit,iCallDepth);

  __asm
  {
    POPAD
      ADD ESP , __LOCAL_SIZE
      POP EAX
      MOV ESP , EBP
      POP EBP
      RET
      }
}

//-----------------------------------------------------------------------------
// WriteFuncInfo
//-----------------------------------------------------------------------------
BOOL
WriteFuncInfo(unsigned int addr,unsigned long calls){
  if(!g_fFuncInfo)
    return(FALSE);

  BOOL ret=FALSE;
  HANDLE h_proc=0;
  do{
    h_proc=GetCurrentProcess();
    if(!h_proc)
      break;

    SymInitialize(h_proc,NULL,FALSE);

    char msg[MAX_PATH*4];
    TCHAR moduleName[MAX_PATH];
    TCHAR modShortNameBuf[MAX_PATH];
    MEMORY_BASIC_INFORMATION mbi;
    BYTE symbolBuffer[sizeof(IMAGEHLP_SYMBOL)+1024];
    PIMAGEHLP_SYMBOL pSymbol=(PIMAGEHLP_SYMBOL)&symbolBuffer[0];

    VirtualQuery((void *)addr,&mbi,sizeof(mbi));
    GetModuleFileName((HMODULE)mbi.AllocationBase,
                      moduleName,MAX_PATH);
    _splitpath(moduleName,NULL,NULL,modShortNameBuf,NULL);

    // Following not per docs, but per example...
    memset(pSymbol,0,sizeof(PIMAGEHLP_SYMBOL));
    pSymbol->SizeOfStruct=sizeof(symbolBuffer);
    pSymbol->MaxNameLength=1023;
    pSymbol->Address=0;
    pSymbol->Flags=0;
    pSymbol->Size=0;

    DWORD symDisplacement=0;
    if(!SymLoadModule(h_proc,
                      NULL,
                      moduleName,
                      NULL,
                      (DWORD)mbi.AllocationBase,
                      0))
      break;

    SymSetOptions(SymGetOptions()&~SYMOPT_UNDNAME);
    char undName[1024];
    if(!SymGetSymFromAddr(h_proc,addr,&symDisplacement,pSymbol)){
      // Couldn't retrieve symbol (no debug info?)
      strcpy(undName,"<unknown symbol>");
    }
    else
    {
      // Unmangle name, throwing away decorations
      // that don't affect uniqueness:
      if(0==UnDecorateSymbolName(pSymbol->Name, undName,
                                 sizeof(undName),
                                 UNDNAME_NO_MS_KEYWORDS        |
                                 UNDNAME_NO_ACCESS_SPECIFIERS  |
                                 UNDNAME_NO_FUNCTION_RETURNS   |
                                 UNDNAME_NO_ALLOCATION_MODEL   |
                                 UNDNAME_NO_ALLOCATION_LANGUAGE|
                                 UNDNAME_NO_MEMBER_TYPE))
        strcpy(undName,pSymbol->Name);
    }
    SymUnloadModule(h_proc,(DWORD)mbi.AllocationBase);
    fprintf(g_fFuncInfo,"%08X|%s|%s|%ld\n",
            addr,modShortNameBuf,undName,calls);
    ret=TRUE;
  }while(0);

  if(h_proc){
    SymCleanup(h_proc);
    CloseHandle(h_proc);
    h_proc=0;
  }
  if(ret=FALSE)
    fprintf(g_fFuncInfo,"%08X|<unknown module>|<unknown symbol>|%ld\n",
            addr,calls);

  return(ret);
}

//-----------------------------------------------------------------------------
// FlushLogQueue
//-----------------------------------------------------------------------------
inline void
FlushLogQueue(void){
  if(!g_fLogFile)
    return;
  EnterCriticalSection(&g_cs_log);
  while(!g_LogQueue.empty()){
    fprintf(g_fLogFile,"%s\n",g_LogQueue.front().c_str());
    g_LogQueue.pop();
  }
  LeaveCriticalSection(&g_cs_log);
  fflush(g_fLogFile);
  return;
}

//-----------------------------------------------------------------------------
// OnProcessStart
//-----------------------------------------------------------------------------
BOOL
OnProcessStart(void){
  BOOL valid=FALSE;
  char filename[256];
  CallMonitor::TICKS frequency=0;

  g_pid=GetCurrentProcessId();

  if(getenv("CRAMP_LOGPATH"))
    sprintf(logpath,"%s",getenv("CRAMP_LOGPATH"));

  do{
    sprintf(filename,"%s/cramp_profile#%d.log",
            logpath,
            g_pid);

    // If only STAT is required
    if(!getenv("CRAMP_PROFILE_STAT")){
      g_fLogFile=fopen(filename,"wc");
      if(!g_fLogFile)
        break;
    }

    sprintf(filename,"%s/cramp_funcinfo#%d.log",
            logpath,
            g_pid);
    g_fFuncInfo=fopen(filename,"wc");
    if(!g_fFuncInfo)
      break;

    CallMonitor::queryTickFreq(&frequency);
    if(getenv("CRAMP_PROFILE"))
      InterlockedExchange(&g_l_profile,1);
    else
      InterlockedExchange(&g_l_profile,0);

    char *cdeep=getenv("CRAMP_PROFILE_CALLDEPTH");
    if(cdeep)
      InterlockedExchange(&g_l_calldepthlimit,atol(cdeep));

    // Initialize critical sections
    if(!InitializeCriticalSectionAndSpinCount(&g_cs_prof,4000L))
      break;
    if(!InitializeCriticalSectionAndSpinCount(&g_cs_log,4000L)){
      DeleteCriticalSection(&g_cs_prof);
      break;
    }

    // Start logging thread
    InterlockedExchange(&g_l_stoplogging,0);

#if BUFFERED_OUTPUT
    h_logthread=chBEGINTHREADEX(NULL,0,DumpLogsTH,0,0,NULL);
    if(!h_logthread){
      DeleteCriticalSection(&g_cs_log);
      DeleteCriticalSection(&g_cs_prof);
      break;
    }
    // This is not a critical thread, when logs are 0
    SetThreadPriority(h_logthread,THREAD_PRIORITY_LOWEST);
#endif

    // Set this if all succeeds
    valid=TRUE;
  }while(0);

  return(valid);
}

//-----------------------------------------------------------------------------
// OnProcessEnd
//-----------------------------------------------------------------------------
BOOL
OnProcessEnd(void){
  InterlockedExchange(&g_l_stoplogging,1);
  CRAMP_FlushProfileLogs();

  if(g_fLogFile)
    fclose(g_fLogFile);
  if(g_fFuncInfo)
    fclose(g_fFuncInfo);

  g_fLogFile=0;
  g_fFuncInfo=0;

  DeleteCriticalSection(&g_cs_log);
  DeleteCriticalSection(&g_cs_prof);
  return(TRUE);
}

//-----------------------------------------------------------------------------
// FlushLogCB
//-----------------------------------------------------------------------------
void CALLBACK
FlushLogCB(void *iLogThread,BOOLEAN itcb){
  if(!g_fLogFile)
    return;
  fflush(g_fLogFile);
  if(!iLogThread)
    return;

  // Dynamic modification of thread priority
  // depending on log queue size
  HANDLE h_logth=iLogThread;
  if(g_LogQueue.size()>(2*CRAMP_LOG_BUFFER_LIMIT))
    SetThreadPriority(h_logth,THREAD_PRIORITY_ABOVE_NORMAL);
  else if(g_LogQueue.size()<CRAMP_LOG_BUFFER_LIMIT)
    SetThreadPriority(h_logth,THREAD_PRIORITY_BELOW_NORMAL);

  return;
}

//-----------------------------------------------------------------------------
// DumpLogsTH
//-----------------------------------------------------------------------------
void
DumpLogsTH(void){
  if(!g_fLogFile)
    return;

  long dest=0;
  HANDLE h_time=0;
  HANDLE h_cth=GetCurrentThread();
  if(!CreateTimerQueueTimer(&h_time,NULL,FlushLogCB,h_cth,
                            500,1000,
                            WT_EXECUTEINIOTHREAD))
    h_time=0;

  while(1){
    dest=0;
    InterlockedCompareExchange(&dest,1,g_l_stoplogging);
    while(!g_LogQueue.empty()){
      EnterCriticalSection(&g_cs_log);
      fprintf(g_fLogFile,"%s\n",g_LogQueue.front().c_str());
      g_LogQueue.pop();
      // Panic case...
      while(g_LogQueue.size()>(3*CRAMP_LOG_BUFFER_LIMIT)){
        fprintf(g_fLogFile,"%s\n",g_LogQueue.front().c_str());
        g_LogQueue.pop();
      }
      LeaveCriticalSection(&g_cs_log);
    }
    if(!dest)
      break;
  }

  if(h_time)
    DeleteTimerQueueTimer(NULL,h_time,NULL);
  h_time=0;

  fflush(g_fLogFile);
  return;
}

//-----------------------------------------------------------------------------
// DllMain
//-----------------------------------------------------------------------------
BOOL WINAPI DllMain(HINSTANCE hinstDLL,
                    DWORD fdwReason,
                    LPVOID lpvReserved){
  static BOOL valid=FALSE;

  switch (fdwReason)
  {
    case DLL_PROCESS_ATTACH:
      valid=OnProcessStart();
    case DLL_THREAD_ATTACH:
      if(valid)
        CallMonitor::threadAttach(new CallMonLOG());
      break;
    case DLL_PROCESS_DETACH:
      if(valid)
        OnProcessEnd();
    case DLL_THREAD_DETACH:
      if(valid)
        CallMonitor::threadDetach();
      if(g_fLogFile)
        fflush(g_fLogFile);
      if(g_fFuncInfo)
        fflush(g_fFuncInfo);
      break;
  }
  return(TRUE);
}
