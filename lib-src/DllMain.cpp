// -*-c++-*-
// Time-stamp: <2003-10-23 13:49:38 dhruva>
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
#define CRAMP_LOG_BUFFER_LIMIT 10000
#endif

long g_l_profile=0;
long g_l_stoplogging=0;
long g_l_calldepthlimit=10;

std::queue<std::string> g_LogQueue;
std::hash_map<unsigned int,SIZE_T> g_hFuncCalls;

CRITICAL_SECTION g_cs_log;
CRITICAL_SECTION g_cs_prof;

// File static
static char logpath[256]=".";

void DumpLogsTH(void);
void CALLBACK FlushLogCB(void *,BOOLEAN);

BOOL OnProcessStart(void);
BOOL OnProcessEnd(void);

//-----------------------------------------------------------------------------
// CRAMP_DumpFunctionInfo
//-----------------------------------------------------------------------------
extern "C" __declspec(dllexport)
  void CRAMP_DumpFunctionInfo(void){
  FILE *fFuncInfo=0;
  char filename[256];
  sprintf(filename,"%s/cramp_funcinfo#%d.log",
          logpath,
          GetCurrentProcessId());

  fFuncInfo=fopen(filename,"wc");
  if(!fFuncInfo)
    return;

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

    // Block the modification of hash
    EnterCriticalSection(&g_cs_prof);

    std::queue<std::string> q_funcinfo;
    std::hash_map<unsigned int,SIZE_T>::iterator iter=g_hFuncCalls.begin();
    for(;iter!=g_hFuncCalls.end();iter++){
      unsigned int addr=(*iter).first;
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
        continue;

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
      sprintf(msg,"%08X|%s|%s|%ld",
              addr,modShortNameBuf,undName,(*iter).second);
      q_funcinfo.push(msg);
    }

    // Unlock the hash
    LeaveCriticalSection(&g_cs_prof);

    while(!q_funcinfo.empty()){
      fprintf(fFuncInfo,"%s\n",q_funcinfo.front().c_str());
      q_funcinfo.pop();
    }

  }while(0);

  if(h_proc){
    SymCleanup(h_proc);
    CloseHandle(h_proc);
    h_proc=0;
  }

  fclose(fFuncInfo);
  fFuncInfo=0;
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
// OnProcessStart
//-----------------------------------------------------------------------------
BOOL
OnProcessStart(void){
  BOOL valid=FALSE;
  char filename[256];
  CallMonitor::TICKS frequency=0;

  if(getenv("CRAMP_LOGPATH"))
    sprintf(logpath,"%s",getenv("CRAMP_LOGPATH"));

  do{
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
    HANDLE h_th=0;
    h_th=chBEGINTHREADEX(NULL,0,DumpLogsTH,0,0,NULL);
    if(!h_th){
      DeleteCriticalSection(&g_cs_log);
      DeleteCriticalSection(&g_cs_prof);
      break;
    }
    // This is not a critical thread
    SetThreadPriority(h_th,THREAD_PRIORITY_BELOW_NORMAL);
    CloseHandle(h_th);

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
  CRAMP_DumpFunctionInfo();
  DeleteCriticalSection(&g_cs_log);
  DeleteCriticalSection(&g_cs_prof);
  return(TRUE);
}

//-----------------------------------------------------------------------------
// FlushLogCB
//-----------------------------------------------------------------------------
void CALLBACK
FlushLogCB(void *flog,BOOLEAN itcb){
  if(!flog)
    return;
  fflush((FILE *)flog);
  return;
}

//-----------------------------------------------------------------------------
// DumpLogsTH
//-----------------------------------------------------------------------------
void
DumpLogsTH(void){
  long dest=0;
  FILE *fLogFile=0;
  char filename[256];
  sprintf(filename,"%s/cramp_profile#%d.log",
          logpath,
          GetCurrentProcessId());
  fLogFile=fopen(filename,"wc");
  if(!fLogFile)
    return;

  HANDLE h_time=0;
  if(!CreateTimerQueueTimer(&h_time,NULL,FlushLogCB,fLogFile,
                            500,500,
                            WT_EXECUTEINIOTHREAD))
    h_time=0;

  while(1){
    InterlockedCompareExchange(&dest,1,g_l_stoplogging);
    if(!dest)
      break;
    while(!g_LogQueue.empty()){
      EnterCriticalSection(&g_cs_log);
      fprintf(fLogFile,"%s\n",g_LogQueue.front().c_str());
      g_LogQueue.pop();
      LeaveCriticalSection(&g_cs_log);
    }
  }

  if(h_time)
    DeleteTimerQueueTimer(NULL,h_time,NULL);
  h_time=0;

  fflush(fLogFile);
  fclose(fLogFile);
  fLogFile=0;

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
      break;
  }
  return(TRUE);
}
