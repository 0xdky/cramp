// -*-c++-*-
// Time-stamp: <2003-10-21 15:32:27 dhruva>
//-----------------------------------------------------------------------------
// File: CallMon.cpp
// Desc: CallMon hook implementation (CallMon.cpp)
//       Copyright (c) 1998 John Panzer.  Permission is granted to
//       use, copy, modify, distribute, and sell this source code as
//       long as this copyright notice appears in all source files.
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-30-2003  Mod                                                          dky
// 10-01-2003  Mod  Profile only if CRAMP_PROFILE env var is set            dky
//-----------------------------------------------------------------------------
#define __CALLMON_SRC

#include "cramp.h"
#include <imagehlp.h>
#include <stdio.h>
#include <stdlib.h>
#include "CallMon.h"
#include "CallMonLOG.h"
#include "ProfileLimit.h"

using namespace std;

typedef CallMonitor::ADDR ADDR;

// Processor-specific offset from
// _penter return address to start of
// caller.
static const unsigned OFFSET_CALL_BYTES=5;

// To toggle profiling
extern long g_l_profile;
extern CRITICAL_SECTION g_cs_prof;
extern DB *g_pdb_funcinfo;

// To minimize calls to system methods
typedef struct{
  SIZE_T _calls;
  BOOLEAN _profile;
  char _modname[256];
  char _funcname[512];
}FuncInfo;

// Start of MSVC-specific code

// _pexit is called upon return from
// an instrumented function.
static void _pexit()
{
  CallMonitor::TICKS endTime;
  CallMonitor::queryTicks(&endTime);
  ADDR framePtr,parentFramePtr;

  // Retrieve parent stack frame to pass
  // to exitProcedure
  __asm mov DWORD PTR [framePtr], ebp
    parentFramePtr = ((ADDR *)framePtr)[0];

  CallMonitor *pth=0;
  pth=CallMonitor::threadPtr();
  if(!pth)
    return;
  pth->exitProcedure(parentFramePtr,
                     &((ADDR*)framePtr)[3],endTime);
}

// An entry point to which all instrumented
// function returns are redirected.
static void __declspec(naked) _pexitThunk()
{
  // Push placeholder return address
  __asm push 0
    // Protect original return value
    __asm push eax
    _pexit();
  // Restore original return value
  __asm pop eax
    // Return using new address set by _pexit
    __asm ret
    }

// Causes problems with (at least) msdev 6.0 sp 5,
// because it clobbers registers
#if 0
// _penter is called on entry to each client function
extern "C" __declspec(dllexport)
  void _penter()
{
  CallMonitor::TICKS entryTime;
  CallMonitor::queryTicks(&entryTime); // Track entry time

  ADDR framePtr;
  __asm mov DWORD PTR [framePtr], ebp

    CallMonitor::threadObj().enterProcedure(
      (ADDR)((unsigned *)framePtr)[0],
      (ADDR)((unsigned *)framePtr)[1]-OFFSET_CALL_BYTES,
      (ADDR*)&((unsigned *)framePtr)[2],
      entryTime);
}
#else
// Patch due to Derek Young:
// _penter is called on entry to each client function
extern "C" __declspec(dllexport) __declspec(naked)
  void _penter()
{
  // The function prolog.
  __asm
  {
    PUSH EBP                    // Set up the standard stack frame.
      MOV  EBP , ESP

      PUSH EAX                    // Save off EAX as I need to use it
      // before saving all registers.
      MOV  EAX , ESP              // Get the current stack value into
      //  EAX.

      SUB  ESP , __LOCAL_SIZE     // Save off the space needed by the
      // local variables.

      PUSHAD                      // Save off all general register
      // values.
      }

  // Instrumented code
  do{
    long dest=0;
    InterlockedCompareExchange(&dest,1,g_l_profile);
    if(dest)
      break;

    CallMonitor::TICKS entryTime;
    CallMonitor::queryTicks(&entryTime); // Track entry time

    ADDR framePtr;
    __asm mov DWORD PTR [framePtr], ebp
      ;                         // Just for indentation

    CallMonitor *pth=0;
    pth=CallMonitor::threadPtr();
    if(!pth)
      break;
    pth->enterProcedure((ADDR)((unsigned *)framePtr)[0],
                        (ADDR)((unsigned *)framePtr)[1]-OFFSET_CALL_BYTES,
                        (ADDR*)&((unsigned *)framePtr)[2],
                        entryTime);
  }while(0);

  // prolog
  __asm
  {
    POPAD                       // Restore all general purpose
      // values.

      ADD ESP , __LOCAL_SIZE      // Remove space needed for locals.

      POP EAX                     // Restore EAX

      MOV ESP , EBP               // Restore the standard stack frame.
      POP EBP
      RET                         // Return to caller.
      }
}
#endif


#ifdef PENTIUM
void CallMonitor::queryTickFreq(TICKS *t)
{
  static TICKS ticksPerSec=0;
  if (!ticksPerSec)
  {
    static const int NUM_LOOPS=100;
    LARGE_INTEGER freq;
    QueryPerformanceFrequency(&freq);

    TICKS qpf1,qpf2,qc1,qc2;
    QueryPerformanceCounter((LARGE_INTEGER*)&qpf1);
    RDTSC(((LARGE_INTEGER&)qc1).LowPart,((LARGE_INTEGER&)qc1).HighPart);
    for(int i=0;i<NUM_LOOPS;i++)
      Sleep(1);
    QueryPerformanceCounter((LARGE_INTEGER*)&qpf2);
    RDTSC(((LARGE_INTEGER&)qc2).LowPart,((LARGE_INTEGER&)qc2).HighPart);
    __int64 qpcTicks = qpf2-qpf1;
    __int64 qcTicks = qc2-qc1;
    long double ratio = ((long double)qcTicks)/((long double)qpcTicks);
    ticksPerSec = ratio * (long double)freq.QuadPart;
  }
  *t = ticksPerSec;
}
#endif
// End of MSVC-specific code

// Figure 2:  CallMonitor class implementation (CallMon.cpp)
// Copyright (c) 1998 John Panzer.  Permission is granted to
// use, copy, modify, distribute, and sell this source code as
// long as this copyright notice appears in all source files.

// Utility functions
void indent(int level)
{
  for(int i=0;i<level;i++) putchar('\t');
}

//
// class CallMonitor
//
DWORD CallMonitor::tlsSlot=0xFFFFFFFF;

CallMonitor::CallMonitor(){
  queryTicks(&threadStartTime);
}

CallMonitor::~CallMonitor(){
}

void CallMonitor::threadAttach(CallMonitor *newObj){
  if (tlsSlot==0xFFFFFFFF) tlsSlot = TlsAlloc();
  TlsSetValue(tlsSlot,newObj);
}

void CallMonitor::threadDetach(){
  delete &threadObj();
}

CallMonitor &CallMonitor::threadObj(){
  CallMonitor *self = (CallMonitor *)
    TlsGetValue(tlsSlot);
  return *self;
}

CallMonitor *CallMonitor::threadPtr(){
  CallMonitor *self=(CallMonitor *)TlsGetValue(tlsSlot);
  return(self);
}

// Performs standard entry processing
void CallMonitor::enterProcedure(ADDR parentFramePtr,
                                 ADDR funcAddr,
                                 ADDR *retAddrPtr,
                                 const TICKS &entryTime){

  BOOLEAN ret=FALSE;
  callInfoStack.push_back(CallInfo());
  CallInfo &ci=callInfoStack.back();
  ci.funcAddr=funcAddr;
  EnterCriticalSection(&g_cs_prof);
  ret=getFuncInfo(ci.funcAddr,ci.modl,ci.func);
  LeaveCriticalSection(&g_cs_prof);
  if(!ret){
    callInfoStack.pop_back();
    return;
  }

  ci.startTime=0;
  ci.parentFrame=parentFramePtr;
  ci.origRetAddr=*retAddrPtr;
  ci.entryTime=entryTime;
  logEntry(ci);
  callInfoStack.push_back(ci);

  *retAddrPtr=(ADDR)_pexitThunk; // Redirect eventual return to local thunk
  queryTicks(&ci.startTime);    // Track approx. start time
  return;
}

// Performs standard exit processing
void CallMonitor::exitProcedure(ADDR parentFramePtr,
                                ADDR *retAddrPtr,
                                const TICKS &endTime){
  // Pops shadow stack until finding a call record
  // that matches the current stack layout.
  bool inSync=false;
  while(1){
    // Retrieve original call record
    CallInfo &ci=callInfoStack.back();
    ci.endTime=endTime;
    *retAddrPtr=ci.origRetAddr;
    if(ci.parentFrame==parentFramePtr){
      logExit(ci,true);         // Record normal exit
      callInfoStack.pop_back();
      return;
    }
    logExit(ci,false);          // Record exceptional exit
    callInfoStack.pop_back();
  }
}

// Default entry logging procedure
void CallMonitor::logEntry(CallInfo &ci){
  indent(callInfoStack.size()-1);
  string module,name;
  getFuncInfo(ci.funcAddr,module,name);
  printf("%s!%s (%08X)\n",module.c_str(),
         name.c_str(),ci.funcAddr);
}

// Default exit logging procedure
void CallMonitor::logExit(CallInfo &ci,bool normalRet){
  indent(callInfoStack.size()-1);
  if (!normalRet) printf("exception ");
  TICKS ticksPerSecond;
  queryTickFreq(&ticksPerSecond);
  printf("exit %08X, elapsed time=%I64d ms (%I64d ticks)\n",ci.funcAddr,
         (ci.endTime-ci.startTime)/(ticksPerSecond/1000),
         (ci.endTime-ci.startTime));
}

void DumpLastError(){
  LPVOID lpMsgBuf;
  FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |
                FORMAT_MESSAGE_FROM_SYSTEM |
                FORMAT_MESSAGE_IGNORE_INSERTS,
                NULL,
                GetLastError(),
                MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
                (LPTSTR) &lpMsgBuf,    0,    NULL );
  OutputDebugString((LPCTSTR)lpMsgBuf);
  LocalFree( lpMsgBuf );
}

BOOLEAN
CallMonitor::getFuncInfo(ADDR addr,
                         string &module,
                         string &funcName){
  DBT key,data;
  memset(&key,0,sizeof(key));
  memset(&data,0,sizeof(data));
  key.size=sizeof(ADDR);
  key.data=&addr;
  data.flags=DB_DBT_MALLOC;

  // Get from BDB HASH
  do{
    if(!g_pdb_funcinfo)
      break;
    if(!g_pdb_funcinfo->get(g_pdb_funcinfo,NULL,&key,&data,0)){
      FuncInfo *pfi=(FuncInfo *)data.data;
      // Method filtered
      if(!pfi->_profile){
        return(FALSE);
      }
      pfi->_calls++;
      module=pfi->_modname;
      funcName=pfi->_funcname;
      data.size=sizeof(*pfi);
      data.data=pfi;
      DEBUGCHK(!g_pdb_funcinfo->put(g_pdb_funcinfo,NULL,&key,&data,0));
      return(TRUE);
    }
  }while(0);

  SymInitialize(GetCurrentProcess(),NULL,FALSE);
  TCHAR moduleName[MAX_PATH];
  TCHAR modShortNameBuf[MAX_PATH];
  MEMORY_BASIC_INFORMATION mbi;

  VirtualQuery((void*)addr,&mbi,sizeof(mbi));
  GetModuleFileName((HMODULE)mbi.AllocationBase,
                    moduleName, MAX_PATH );

  _splitpath(moduleName,NULL,NULL,modShortNameBuf,NULL);

  BYTE symbolBuffer[ sizeof(IMAGEHLP_SYMBOL) + 1024 ];
  PIMAGEHLP_SYMBOL pSymbol =
    (PIMAGEHLP_SYMBOL)&symbolBuffer[0];
  // Following not per docs, but per example...
  pSymbol->SizeOfStruct = sizeof(symbolBuffer);
  pSymbol->MaxNameLength = 1023;
  pSymbol->Address = 0;
  pSymbol->Flags = 0;
  pSymbol->Size =0;

  DWORD symDisplacement = 0;
  HANDLE h_proc=0;
  h_proc=GetCurrentProcess();
  if (!SymLoadModule(h_proc,
                     NULL,
                     moduleName,
                     NULL,
                     (DWORD)mbi.AllocationBase,
                     0))
    DumpLastError();

  SymSetOptions( SymGetOptions() & ~SYMOPT_UNDNAME );
  char undName[1024];
  if (! SymGetSymFromAddr(h_proc, addr,&symDisplacement, pSymbol) )
  {
    DumpLastError();
    // Couldn't retrieve symbol (no debug info?)
    strcpy(undName,"<unknown symbol>");
  }
  else
  {
    // Unmangle name, throwing away decorations
    // that don't affect uniqueness:
    if(0==UnDecorateSymbolName(pSymbol->Name, undName,
                               sizeof(undName),
                               UNDNAME_NO_MS_KEYWORDS |
                               UNDNAME_NO_ACCESS_SPECIFIERS |
                               UNDNAME_NO_FUNCTION_RETURNS |
                               UNDNAME_NO_ALLOCATION_MODEL |
                               UNDNAME_NO_ALLOCATION_LANGUAGE |
                               UNDNAME_NO_MEMBER_TYPE))
      strcpy(undName,pSymbol->Name);
  }
  SymUnloadModule(h_proc,(DWORD)mbi.AllocationBase);
  SymCleanup(h_proc);
  module = modShortNameBuf;
  funcName = undName;

  // Cache the information
  // Add it to BDB HASH
  if(g_pdb_funcinfo){
    FuncInfo fin;
    fin._calls=1;
    fin._profile=TRUE;
    strcpy(fin._modname,modShortNameBuf);
    strcpy(fin._funcname,undName);
    data.size=sizeof(fin);
    data.data=&fin;
    DEBUGCHK(!g_pdb_funcinfo->put(g_pdb_funcinfo,NULL,&key,&data,
                                  DB_NOOVERWRITE));
  }
  return(TRUE);
}
//End of file
