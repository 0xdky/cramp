// -*-c++-*-
// Time-stamp: <2004-03-09 10:57:56 dky>
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
// 03-09-2004  Mod Disable filtering, filter during dumping thru PERL       dky
//-----------------------------------------------------------------------------
#define __CALLMON_SRC

#include "cramp.h"
#include <imagehlp.h>
#include <stdio.h>
#include <stdlib.h>
#include "CallMon.h"
#include "CallMonLOG.h"

using namespace std;

typedef CallMonitor::ADDR ADDR;

// Processor-specific offset from
// _penter return address to start of
// caller.
static const unsigned OFFSET_CALL_BYTES=5;
extern Global_CRAMP_Profiler g_CRAMP_Profiler;
extern BOOL WriteFuncInfo(unsigned int,unsigned long,FILE *f_func);

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
    return;
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

// Patch due to Derek Young:
// _penter is called on entry to each client function
#ifdef CRAMP_STUB
extern "C" __declspec(dllexport) __declspec(naked)
    void _penter()
{
    __asm
        {
            PUSH EBP
                MOV  EBP , ESP
                PUSH EAX
                MOV  EAX , ESP
                SUB  ESP , __LOCAL_SIZE
                PUSHAD
                }

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
#else
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
        CallMonitor::TICKS entryTime;
        CallMonitor::queryTicks(&entryTime); // Track entry time

        // Profiling is disabled
        long dest=0;
        InterlockedCompareExchange(&dest,1,g_CRAMP_Profiler.g_l_profile);
        if(dest)
            break;

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
void CallMonitor::queryTickFreq(TICKS *t){
    static TICKS ticksPerSec=0;
    if(!ticksPerSec){
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
    *t=ticksPerSec;
}
#endif
// End of MSVC-specific code

// Figure 2:  CallMonitor class implementation (CallMon.cpp)
// Copyright (c) 1998 John Panzer.  Permission is granted to
// use, copy, modify, distribute, and sell this source code as
// long as this copyright notice appears in all source files.

//-----------------------------------------------------------------------------
// indent
//   Utility functions
//-----------------------------------------------------------------------------
void indent(int level){
    for(int i=0;i<level;i++)
        putchar('\t');
    return;
}

//
// class CallMonitor
//
DWORD CallMonitor::tlsSlot=0xFFFFFFFF;

//-----------------------------------------------------------------------------
// CallMonitor
//-----------------------------------------------------------------------------
CallMonitor::CallMonitor(){
    queryTicks(&threadStartTime);
}

//-----------------------------------------------------------------------------
// ~CallMonitor
//-----------------------------------------------------------------------------
CallMonitor::~CallMonitor(){
}

//-----------------------------------------------------------------------------
// threadAttach
//-----------------------------------------------------------------------------
void
CallMonitor::threadAttach(CallMonitor *newObj){
    if (tlsSlot==0xFFFFFFFF) tlsSlot = TlsAlloc();
    TlsSetValue(tlsSlot,newObj);
}

//-----------------------------------------------------------------------------
// threadDetach
//-----------------------------------------------------------------------------
void
CallMonitor::threadDetach(){
    delete &threadObj();
    return;
}

//-----------------------------------------------------------------------------
// threadObj
//-----------------------------------------------------------------------------
CallMonitor &CallMonitor::threadObj(){
    CallMonitor *self = (CallMonitor *)
        TlsGetValue(tlsSlot);
    return(*self);
}

//-----------------------------------------------------------------------------
// threadPtr
//-----------------------------------------------------------------------------
CallMonitor *CallMonitor::threadPtr(){
    CallMonitor *self=(CallMonitor *)TlsGetValue(tlsSlot);
    return(self);
}

//-----------------------------------------------------------------------------
// enterProcedure
//   Performs standard entry processing
//-----------------------------------------------------------------------------
void
CallMonitor::enterProcedure(ADDR parentFramePtr,
                            ADDR funcAddr,
                            ADDR *retAddrPtr,
                            const TICKS &entryTime){
    long deep=0;
    BOOLEAN filtered=FALSE;
    do{
        deep=callInfoStack.size();
        if(deep){
            // Max call depth has reached
            InterlockedCompareExchange(&deep,0,g_CRAMP_Profiler.g_l_calldepthlimit);
            if(!deep){
                filtered=TRUE;
                break;
            }
        }

        std::hash_map<ADDR,FuncInfo>::iterator iter;
        EnterCriticalSection(&g_CRAMP_Profiler.g_cs_prof);

        iter=g_CRAMP_Profiler.g_hFuncCalls.find(funcAddr);
        if(iter==g_CRAMP_Profiler.g_hFuncCalls.end()){
            FuncInfo fi;
            memset(&fi,0,sizeof(FuncInfo));
            fi._calls=1;
            fi._pending=FALSE;
#ifdef HAVE_FILTER
            fi._filtered=!g_CRAMP_Profiler.g_exclusion;
            // Any error/filtered, ignore profiling the method in the future
            fi._filtered=!WriteFuncInfo(funcAddr,1,NULL);
#else
            fi._filtered=FALSE;
#endif
            g_CRAMP_Profiler.g_hFuncCalls[funcAddr]=fi;

            // If the first call is filtered
            if(fi._filtered){
                filtered=TRUE;
                break;
            }
        }else{
            if((*iter).second._filtered){
                filtered=TRUE;
                break;
            }else if(g_CRAMP_Profiler.g_l_maxcalllimit&&
                     (*iter).second._calls>=g_CRAMP_Profiler.g_l_maxcalllimit){
                (*iter).second._filtered=TRUE;
                filtered=TRUE;
                break;
            }else{
                (*iter).second._calls++;
            }
        }
    }while(0);
    LeaveCriticalSection(&g_CRAMP_Profiler.g_cs_prof);

    // Handle filtered methods
    if(filtered){
        if(deep){
            CallInfo &prev=callInfoStack.back();
            TICKS leave=0;
            CallMonitor::queryTicks(&leave);
            prev.ProfilingTicks+=leave-entryTime;
        }
        return;
    }

    callInfoStack.push_back(CallInfo());
    CallInfo &ci=callInfoStack.back();
    memset(&ci,0,sizeof(CallInfo));

    ci.funcAddr=funcAddr;
    ci.parentFrame=parentFramePtr;
    ci.origRetAddr=*retAddrPtr;
    ci.entryTime=entryTime;
    logEntry(ci);

    *retAddrPtr=(ADDR)_pexitThunk; // Redirect eventual return to local thunk
    queryTicks(&ci.startTime);     // Track approx. start time

    return;
}

//-----------------------------------------------------------------------------
// exitProcedure
//   Performs standard exit processing
//-----------------------------------------------------------------------------
void
CallMonitor::exitProcedure(ADDR parentFramePtr,
                           ADDR *retAddrPtr,
                           const TICKS &endTime){
    // Pops shadow stack until finding a call record
    // that matches the current stack layout.
    TICKS elapsedtick=0;
    TICKS childprofiletick=0;
    while(1){
        // Retrieve original call record
        CallInfo &ci=callInfoStack.back();
        ci.endTime=endTime;
        *retAddrPtr=ci.origRetAddr;

        childprofiletick=ci.ProfilingTicks+(ci.startTime-ci.entryTime);
        elapsedtick=ci.endTime-ci.startTime-ci.ProfilingTicks;

        // Record NORMAL function exit
        if(ci.parentFrame==parentFramePtr){
            logExit(ci,true);
            callInfoStack.pop_back();
            break;
        }

        // Record EXCEPTIONAL function exit
        logExit(ci,false);
        callInfoStack.pop_back();

        // Update the Raw Child ticks
        if(callInfoStack.empty())
            return;
        CallInfo &prev=callInfoStack.back();
        prev.RawChildTicks+=elapsedtick;
        TICKS leave=0;
        CallMonitor::queryTicks(&leave);
        prev.ProfilingTicks+=leave-endTime+childprofiletick;
    }

    // Update the Raw Child ticks
    if(callInfoStack.empty())
        return;
    CallInfo &prev=callInfoStack.back();
    prev.RawChildTicks+=elapsedtick;
    TICKS leave=0;
    CallMonitor::queryTicks(&leave);
    prev.ProfilingTicks+=leave-endTime+childprofiletick;

    return;
}

//-----------------------------------------------------------------------------
// logEntry
//   Default entry logging procedure
//-----------------------------------------------------------------------------
void
CallMonitor::logEntry(CallInfo &ci){
    indent(callInfoStack.size()-1);
    string module,name;
    getFuncInfo(ci.funcAddr,module,name);
    printf("%s!%s (%08X)\n",module.c_str(),
           name.c_str(),ci.funcAddr);
    return;
}

//-----------------------------------------------------------------------------
// logExit
//   Default exit logging procedure
//-----------------------------------------------------------------------------
void
CallMonitor::logExit(CallInfo &ci,bool normalRet){
    indent(callInfoStack.size()-1);
    if (!normalRet) printf("exception ");
    TICKS ticksPerSecond;
    queryTickFreq(&ticksPerSecond);
    printf("exit %08X, elapsed time=%I64d ms (%I64d ticks)\n",ci.funcAddr,
           (ci.endTime-ci.startTime)/(ticksPerSecond/1000),
           (ci.endTime-ci.startTime));
    return;
}

//-----------------------------------------------------------------------------
// DumpLastError
//-----------------------------------------------------------------------------
void
DumpLastError(){
    LPVOID lpMsgBuf;
    FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |
                  FORMAT_MESSAGE_FROM_SYSTEM |
                  FORMAT_MESSAGE_IGNORE_INSERTS,
                  NULL,
                  GetLastError(),
                  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
                  (LPTSTR) &lpMsgBuf,    0,    NULL );
    OutputDebugString((LPCTSTR)lpMsgBuf);
    LocalFree(lpMsgBuf);
    return;
}

//-----------------------------------------------------------------------------
// getFuncInfo
//-----------------------------------------------------------------------------
void
CallMonitor::getFuncInfo(ADDR addr,
                         string &module,
                         string &funcName){
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
    return;
}
