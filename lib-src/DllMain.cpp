// -*-c++-*-
// Time-stamp: <2004-03-11 11:29:20 dky>
//-----------------------------------------------------------------------------
// File : DllMain.cpp
// Desc : DllMain implementation for profiler and support code
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
// 02-28-2004  Mod Disable filtering, filter during dumping thru PERL       dky
// 03-09-2004  Mod Moved generation of function info to flush               dky
// 03-11-2004  Mod Undo previous changes and PCRE filtering                 dky
//-----------------------------------------------------------------------------
#define __DLLMAIN_SRC

#include "cramp.h"
#include "CallMonLOG.h"

#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <fstream.h>
#include <imagehlp.h>

#ifndef MB2BYTE
#define MB2BYTE 1048576
#endif

// The only permitted GLOBAL for the profiler library
Global_CRAMP_Profiler g_CRAMP_Profiler;

void OnProcessStart(void);
void OnProcessEnd(void);
BOOL WriteFuncInfo(unsigned int,unsigned long,FILE *f_func);
void LogFileSizeMonTH(void *);
DWORD WINAPI ProfilerMailSlotServerTH(LPVOID);

//-----------------------------------------------------------------------------
// CRAMP_FlushProfileLogs
//-----------------------------------------------------------------------------
extern "C" __declspec(dllexport)
    void CRAMP_FlushProfileLogs(void){
    // Usually this iscalled to collect all logs
    // Hence, flush all logs before getting logs
    CallMonitor::TICKS frequency=0;
    CallMonitor::queryTickFreq(&frequency);

    if(g_CRAMP_Profiler.g_fLogFile)
        fflush(g_CRAMP_Profiler.g_fLogFile);

    // Block the modification of hash
    CRAMP_CS csp(&g_CRAMP_Profiler.g_cs_prof);
    csp.enter();

    FILE *f_stat=0;
    char filename[MAX_PATH];
    sprintf(filename,"%s/cramp_stat#%d.log",
            g_CRAMP_Profiler.logpath,
            g_CRAMP_Profiler.g_pid);
    f_stat=fopen(filename,"wc");
    if(!f_stat){
        DEBUGCHK(0);
        return;
    }

    std::hash_map<unsigned int,FuncInfo>::iterator iter;
    iter=g_CRAMP_Profiler.g_hFuncCalls.begin();
    for(;iter!=g_CRAMP_Profiler.g_hFuncCalls.end();iter++){
        // Ignore filtered methods
        if((*iter).second._filtered)
            continue;

        // Dump statistics information
        fprintf(f_stat,"%08X|%d|%I64d|%I64d|%I64d\n",
                (*iter).first,
                (*iter).second._calls,
                frequency,
                (*iter).second._totalticks,
                (*iter).second._maxticks);

        // Ensure, you do not revisit between calls
        if(!(*iter).second._pending)
            continue;
        (*iter).second._pending=FALSE;
    }

    // Flush and close the file handles
    fclose(f_stat);

    // Unlock the hash
    csp.leave();

    return;
}

//-----------------------------------------------------------------------------
// CRAMP_EnableProfile
//  Thread safe, if logging has stopped, NEVER enable profiling
//-----------------------------------------------------------------------------
extern "C" __declspec(dllexport)
    void CRAMP_EnableProfile(void){

    long dest=1;
    InterlockedCompareExchange(&dest,0,g_CRAMP_Profiler.g_l_stoplogging);
    if(dest)
        InterlockedExchange(&g_CRAMP_Profiler.g_l_profile,1);
    else
        InterlockedExchange(&g_CRAMP_Profiler.g_l_profile,0);

    return;
}

//-----------------------------------------------------------------------------
// CRAMP_DisableProfile
//  Thread safe
//-----------------------------------------------------------------------------
extern "C" __declspec(dllexport)
    void CRAMP_DisableProfile(void){

    InterlockedExchange(&g_CRAMP_Profiler.g_l_profile,0);

    return;
}

//-----------------------------------------------------------------------------
// CRAMP_SetCallDepthLimit
//  Thread safe
//-----------------------------------------------------------------------------
extern "C" __declspec(dllexport)
    void CRAMP_SetCallDepthLimit(long iCallDepth){

    InterlockedExchange(&g_CRAMP_Profiler.g_l_calldepthlimit,iCallDepth);

    return;
}

//-----------------------------------------------------------------------------
// WriteFuncInfo
//-----------------------------------------------------------------------------
BOOL
WriteFuncInfo(unsigned int addr,unsigned long calls,FILE *f_func){
    if(!f_func)
        f_func=g_CRAMP_Profiler.g_fFuncInfo;
    if(!f_func)
        return(FALSE);

    BOOL ret=FALSE;
    HANDLE h_proc=0;

    do{
        CRAMP_CS csf(&g_CRAMP_Profiler.g_cs_fun);
        h_proc=GetCurrentProcess();
        if(!h_proc)
            break;

        char msg[MAX_PATH*4];
        TCHAR moduleName[MAX_PATH];
        TCHAR modShortNameBuf[MAX_PATH];
        MEMORY_BASIC_INFORMATION mbi;
        BYTE symbolBuffer[sizeof(IMAGEHLP_SYMBOL)+1024];
        PIMAGEHLP_SYMBOL pSymbol=(PIMAGEHLP_SYMBOL)&symbolBuffer[0];

        VirtualQuery((void *)addr,&mbi,sizeof(mbi));

        // Faster Module level filtering
        csf.enter();
        std::hash_map<unsigned int,BOOLEAN>::iterator iter;
        iter=g_CRAMP_Profiler.h_FilteredModAddr.find(
            (unsigned int)mbi.AllocationBase);
        if(iter!=g_CRAMP_Profiler.h_FilteredModAddr.end())
            return(!(*iter).second);
        csf.leave();

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

        csf.enter();
        if(!SymLoadModule(h_proc,
                          NULL,
                          moduleName,
                          NULL,
                          (DWORD)mbi.AllocationBase,
                          0))
            break;

        SymSetOptions(SymGetOptions()&~SYMOPT_UNDNAME);
        bool match=TRUE;
        char undName[1024];
        if(!SymGetSymFromAddr(h_proc,addr,&symDisplacement,pSymbol)){
            strcpy(undName,"<unknown symbol>");
            match=FALSE;
        }else{
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
        csf.leave();

        // Find if method is filtered
        do{
            ret=TRUE;
            if(!g_CRAMP_Profiler.g_regcomp||!match)
                break;
            ret=g_CRAMP_Profiler.g_exclusion;

            // If module level filtering
            int rc;
            int ovector[256];
            rc=pcre_exec(g_CRAMP_Profiler.g_regcomp,
                         g_CRAMP_Profiler.g_regstudy,
                         modShortNameBuf,
                         strlen(modShortNameBuf),
                         0,
                         0,
                         ovector,
                         256);
            if(rc<0){
                rc=pcre_exec(g_CRAMP_Profiler.g_regcomp,
                             g_CRAMP_Profiler.g_regstudy,
                             undName,
                             strlen(undName),
                             0,
                             0,
                             ovector,
                             256);
                if(rc<0)
                    break;
            }else{
                csf.enter();
                g_CRAMP_Profiler.h_FilteredModAddr[
                    (unsigned int)mbi.AllocationBase]=FALSE;
                csf.leave();
            }
            ret=!ret;
        }while(0);

        if(ret){
            csf.enter();
            fprintf(f_func,"%08X|%s|%s|%ld\n",
                    addr,modShortNameBuf,undName,calls);
            csf.leave();
        }
    }while(0);

    return(ret);
}

//-----------------------------------------------------------------------------
// OnProcessStart
//-----------------------------------------------------------------------------
void
OnProcessStart(void){
    long dest=1;
    InterlockedCompareExchange(&dest,0,g_CRAMP_Profiler.IsInitialised);
    if(!dest)
        return;

    char filename[256];

    strcpy(g_CRAMP_Profiler.logpath,".");
    g_CRAMP_Profiler.IsInitialised=0;
    g_CRAMP_Profiler.g_exclusion=TRUE;
    g_CRAMP_Profiler.g_fLogFile=0;
    g_CRAMP_Profiler.g_fFuncInfo=0;
    g_CRAMP_Profiler.g_pid=0;
    g_CRAMP_Profiler.g_l_profile=0;
    g_CRAMP_Profiler.g_l_stoplogging=0;
    g_CRAMP_Profiler.g_l_maxcalllimit=0;
    g_CRAMP_Profiler.g_l_logsizelimit=0;
    g_CRAMP_Profiler.g_l_calldepthlimit=0;
    g_CRAMP_Profiler.g_h_mailslot=0;
    g_CRAMP_Profiler.g_h_mailslotTH=0;
    g_CRAMP_Profiler.g_h_logsizemonTH=0;
    g_CRAMP_Profiler.g_regcomp=0;
    g_CRAMP_Profiler.g_regstudy=0;
    g_CRAMP_Profiler.g_pid=GetCurrentProcessId();

    if(getenv("CRAMP_LOGPATH"))
        sprintf(g_CRAMP_Profiler.logpath,"%s",getenv("CRAMP_LOGPATH"));

    // Get maximum call limit (ensure it is a number)
    char *buff=getenv("CRAMP_PROFILE_MAXCALLLIMIT");
    if(buff){
        g_CRAMP_Profiler.g_l_maxcalllimit=atol(buff);
        sprintf(filename,"%ld",g_CRAMP_Profiler.g_l_maxcalllimit);
        if(strcmp(filename,buff))
            g_CRAMP_Profiler.g_l_maxcalllimit=0;
    }

    buff=getenv("CRAMP_PROFILE_CALLDEPTH");
    if(buff){
        g_CRAMP_Profiler.g_l_calldepthlimit=atol(buff);
        sprintf(filename,"%ld",g_CRAMP_Profiler.g_l_calldepthlimit);
        if(strcmp(filename,buff))
            g_CRAMP_Profiler.g_l_calldepthlimit=0;
    }

    if(getenv("CRAMP_PROFILE_INCLUSION"))
        g_CRAMP_Profiler.g_exclusion=FALSE;

#ifdef HAVE_FILTER
    // Build the REGEXP filter string
    do{
        char fltstr[MAX_PATH];
        std::list<std::string> l_flt;
        sprintf(filename,"%s/cramp_profile.flt",g_CRAMP_Profiler.logpath);
        fstream f_flt;
        f_flt.open(filename,ios::in|ios::nocreate);
        if(!(f_flt.rdbuf())->is_open())
            break;

        while(!f_flt.eof()){
            f_flt.getline(filename,MAX_PATH,'\n');
            if(!strlen(filename))
                continue;

            // Clean up the filter string
            int ep=0;
            fltstr[ep]='\0';
            for(int cc=0;filename[cc];cc++){
                if(isspace(filename[cc]))
                    continue;
                if(isalnum(filename[cc])){
                    fltstr[ep]=filename[cc];
                    ep++;
                }else{
                    fltstr[ep]='\\'; // Escape non alpha numerics
                    ep++;
                    fltstr[ep]=filename[cc];
                    ep++;
                }
            }
            fltstr[ep]='\0';
            if(!strlen(fltstr))
                continue;
            l_flt.push_back(fltstr);
        }
        f_flt.close();

        if(l_flt.empty())
            break;

        char first=1;
        l_flt.unique();         // Make the filter unique
        for(std::list<std::string>::iterator iter=l_flt.begin();
            iter!=l_flt.end();iter++){
            if(!first)
                g_CRAMP_Profiler.g_FilterString.append("|");
            else
                first=0;

            g_CRAMP_Profiler.g_FilterString.append("\\b");
            g_CRAMP_Profiler.g_FilterString.append((*iter));
            g_CRAMP_Profiler.g_FilterString.append("\\b");
        }

        const char *error;
        int erroffset;
        g_CRAMP_Profiler.g_regcomp=
            pcre_compile(g_CRAMP_Profiler.g_FilterString.c_str(),
                         0,
                         &error,
                         &erroffset,
                         NULL);

        if(!g_CRAMP_Profiler.g_regcomp)
            break;
    }while(0);
#endif

    do{
        sprintf(filename,"%s/cramp_profile#%d.log",
                g_CRAMP_Profiler.logpath,
                g_CRAMP_Profiler.g_pid);

        // If only STAT is required
        if(!getenv("CRAMP_PROFILE_STAT")){
            g_CRAMP_Profiler.g_fLogFile=fopen(filename,"wc");
            if(!g_CRAMP_Profiler.g_fLogFile)
                break;
        }

#ifdef HAVE_FILTER
        sprintf(filename,"%s/cramp_funcinfo#%d.log",
                g_CRAMP_Profiler.logpath,
                g_CRAMP_Profiler.g_pid);
        g_CRAMP_Profiler.g_fFuncInfo=fopen(filename,"wc");
        if(!g_CRAMP_Profiler.g_fFuncInfo)
            break;
#endif

        if(getenv("CRAMP_PROFILE"))
            InterlockedExchange(&g_CRAMP_Profiler.g_l_profile,1);
        else
            InterlockedExchange(&g_CRAMP_Profiler.g_l_profile,0);

        // Initialize critical sections
        if(!InitializeCriticalSectionAndSpinCount(&g_CRAMP_Profiler.g_cs_prof,
                                                  4000L))
            break;
        if(!InitializeCriticalSectionAndSpinCount(&g_CRAMP_Profiler.g_cs_log,
                                                  4000L)){
            DeleteCriticalSection(&g_CRAMP_Profiler.g_cs_prof);
            break;
        }
        if(!InitializeCriticalSectionAndSpinCount(&g_CRAMP_Profiler.g_cs_fun,
                                                  4000L)){
            DeleteCriticalSection(&g_CRAMP_Profiler.g_cs_prof);
            DeleteCriticalSection(&g_CRAMP_Profiler.g_cs_log);
            break;
        }

        // Create a log file size monitoring thread
        buff=getenv("CRAMP_PROFILE_LOGSIZE");
        if(buff){
            g_CRAMP_Profiler.g_l_logsizelimit=atol(buff);
            sprintf(filename,"%ld",g_CRAMP_Profiler.g_l_logsizelimit);
            if(strcmp(filename,buff))
                g_CRAMP_Profiler.g_l_logsizelimit=0;
        }
        if(g_CRAMP_Profiler.g_l_logsizelimit)
            g_CRAMP_Profiler.g_h_logsizemonTH=chBEGINTHREADEX(NULL,0,
                                                              LogFileSizeMonTH,
                                                              NULL,0,NULL);
        if(g_CRAMP_Profiler.g_h_logsizemonTH)
            SetThreadPriority(g_CRAMP_Profiler.g_h_logsizemonTH,
                              THREAD_PRIORITY_BELOW_NORMAL);

        // Create a messaging thread for IPC
        g_CRAMP_Profiler.g_h_mailslotTH=
            chBEGINTHREADEX(NULL,0,
                            ProfilerMailSlotServerTH,
                            NULL,0,NULL);
        if(g_CRAMP_Profiler.g_h_mailslotTH)
            SetThreadPriority(g_CRAMP_Profiler.g_h_mailslotTH,
                              THREAD_PRIORITY_BELOW_NORMAL);

        // Initialize all debug symbols at start
        if(!SymInitialize(GetCurrentProcess(),NULL,FALSE))
            break;

        // Set this if all succeeds
        InterlockedExchange(&g_CRAMP_Profiler.IsInitialised,1);
    }while(0);

    return;
}

//-----------------------------------------------------------------------------
// CleanEmptyLogs
//-----------------------------------------------------------------------------
void
CleanEmptyLogs(void){
    struct _stat buf;
    static char filename[256];

    memset(&buf,0,sizeof(struct _stat));
    sprintf(filename,"%s/cramp_profile#%d.log",
            g_CRAMP_Profiler.logpath,
            g_CRAMP_Profiler.g_pid);

    // Return if stat fail or non-zero
    if(_stat(filename,&buf)||buf.st_size)
        return;

    // Delete empty logs
    _unlink(filename);

    sprintf(filename,"%s/cramp_stat#%d.log",
            g_CRAMP_Profiler.logpath,
            g_CRAMP_Profiler.g_pid);
    _unlink(filename);

    sprintf(filename,"%s/cramp_funcinfo#%d.log",
            g_CRAMP_Profiler.logpath,
            g_CRAMP_Profiler.g_pid);
    _unlink(filename);

    return;
}

//-----------------------------------------------------------------------------
// OnProcessEnd
//-----------------------------------------------------------------------------
void
OnProcessEnd(void){
    long dest=1;
    InterlockedCompareExchange(&dest,0,g_CRAMP_Profiler.IsInitialised);
    if(dest)
        return;

    InterlockedExchange(&g_CRAMP_Profiler.g_l_stoplogging,1);
    CRAMP_FlushProfileLogs();

    if(g_CRAMP_Profiler.g_fLogFile)
        fclose(g_CRAMP_Profiler.g_fLogFile);
    if(g_CRAMP_Profiler.g_fFuncInfo)
        fclose(g_CRAMP_Profiler.g_fFuncInfo);

    g_CRAMP_Profiler.g_fLogFile=0;
    g_CRAMP_Profiler.g_fFuncInfo=0;

    if(g_CRAMP_Profiler.g_h_mailslot)
        CloseHandle(g_CRAMP_Profiler.g_h_mailslot);
    g_CRAMP_Profiler.g_h_mailslot=0;

    if(g_CRAMP_Profiler.g_h_mailslotTH)
        TerminateThread(g_CRAMP_Profiler.g_h_mailslotTH,0);
    g_CRAMP_Profiler.g_h_mailslotTH=0;

    if(g_CRAMP_Profiler.g_h_logsizemonTH)
        TerminateThread(g_CRAMP_Profiler.g_h_logsizemonTH,0);
    g_CRAMP_Profiler.g_h_logsizemonTH=0;

    DeleteCriticalSection(&g_CRAMP_Profiler.g_cs_fun);
    DeleteCriticalSection(&g_CRAMP_Profiler.g_cs_log);
    DeleteCriticalSection(&g_CRAMP_Profiler.g_cs_prof);

    if(g_CRAMP_Profiler.g_regcomp){
        free(g_CRAMP_Profiler.g_regcomp);
        g_CRAMP_Profiler.g_regcomp=0;
    }
    if(g_CRAMP_Profiler.g_regstudy){
        free(g_CRAMP_Profiler.g_regstudy);
        g_CRAMP_Profiler.g_regstudy=0;
    }

    // Cleanup all debug information
    SymCleanup(GetCurrentProcess());

    CleanEmptyLogs();

    return;
}

//-----------------------------------------------------------------------------
// LogFileSizeMonTH
//  Get out of thread once the file size exceeds
//-----------------------------------------------------------------------------
void
LogFileSizeMonTH(void *iLogThread){
    if(!g_CRAMP_Profiler.g_fLogFile)
        return;
    struct _stat buf={0};
    char filename[256];

    sprintf(filename,"%s/cramp_profile#%d.log",
            g_CRAMP_Profiler.logpath,
            g_CRAMP_Profiler.g_pid);

    while(1){
        if(!g_CRAMP_Profiler.g_fLogFile)
            break;

        if(_stat(filename,&buf))
            continue;

        if(buf.st_size/MB2BYTE>g_CRAMP_Profiler.g_l_logsizelimit){
            InterlockedExchange(&g_CRAMP_Profiler.g_l_profile,0);
            InterlockedExchange(&g_CRAMP_Profiler.g_l_stoplogging,1);
            DeleteTimerQueueTimer(NULL,g_CRAMP_Profiler.g_h_logsizemonTH,NULL);
            g_CRAMP_Profiler.g_h_logsizemonTH=0;
            break;
        }

        Sleep(1000);
    }
    return;
}

//-----------------------------------------------------------------------------
// ProfilerMailSlotServerTH
//-----------------------------------------------------------------------------
DWORD WINAPI
ProfilerMailSlotServerTH(LPVOID idata){
    char filename[MAX_PATH];
    sprintf(filename,"\\\\.\\mailslot\\cramp_mailslot#%ld",
            GetCurrentProcessId());

    g_CRAMP_Profiler.g_h_mailslot=CreateMailslot(filename,
                                                 0,
                                                 MAILSLOT_WAIT_FOREVER,
                                                 NULL);
    if(INVALID_HANDLE_VALUE==g_CRAMP_Profiler.g_h_mailslot)
        return(-1);

    // Mail slot server loop
    DWORD wstate=-1;
    HANDLE h_event;
    char msevtname[256];

    sprintf(msevtname,"CRAMP_MAILSLOT#%ld",GetCurrentProcessId());
    h_event=CreateEvent(NULL,FALSE,FALSE,msevtname);
    DEBUGCHK(h_event);

    while(1){
        DWORD cbMessage=0,cMessage=0,cbRead=0;
        BOOL fResult;
        LPSTR lpszBuffer;
        DWORD cAllMessages;
        OVERLAPPED ov;

        ov.Offset=0;
        ov.OffsetHigh=0;
        ov.hEvent=h_event;
        fResult=GetMailslotInfo(g_CRAMP_Profiler.g_h_mailslot,
                                (LPDWORD)NULL,
                                &cbMessage,
                                &cMessage,
                                (LPDWORD)NULL);
        DEBUGCHK(fResult);
        if(cbMessage==MAILSLOT_NO_MESSAGE){
            Sleep(500);		// To reduce CPU usage or yield
            continue;
        }
        cAllMessages=cMessage;

        // Mail slot loop
        while(cMessage){
            lpszBuffer=(LPSTR)GlobalAlloc(GPTR,cbMessage);
            DEBUGCHK(lpszBuffer);
            lpszBuffer[0]='\0';
            fResult=ReadFile(g_CRAMP_Profiler.g_h_mailslot,
                             lpszBuffer,
                             cbMessage,
                             &cbRead,
                             &ov);
            if(!fResult||!strlen(lpszBuffer))
                break;

            // Process the message HERE
            if(!stricmp(lpszBuffer,"STOP"))
                CRAMP_DisableProfile();
            else if(!stricmp(lpszBuffer,"START"))
                CRAMP_EnableProfile();
            else if(!stricmp(lpszBuffer,"FLUSH"))
                CRAMP_FlushProfileLogs();

            GlobalFree((HGLOBAL)lpszBuffer);
            fResult=GetMailslotInfo(g_CRAMP_Profiler.g_h_mailslot,
                                    (LPDWORD)NULL,
                                    &cbMessage,
                                    &cMessage,
                                    (LPDWORD)NULL);
            if(!fResult)
                break;
        }
    }

    return(0);
}

//-----------------------------------------------------------------------------
// DllMain
//-----------------------------------------------------------------------------
BOOL WINAPI DllMain(HINSTANCE hinstDLL,
                    DWORD fdwReason,
                    LPVOID lpvReserved){
    long dest=1;
    switch (fdwReason){
        case DLL_PROCESS_ATTACH:
            OnProcessStart();
        case DLL_THREAD_ATTACH:
            InterlockedCompareExchange(&dest,0,g_CRAMP_Profiler.IsInitialised);
            if(!dest)
                CallMonitor::threadAttach(new CallMonLOG());
            break;
        case DLL_PROCESS_DETACH:
            OnProcessEnd();
        case DLL_THREAD_DETACH:
            InterlockedCompareExchange(&dest,0,g_CRAMP_Profiler.IsInitialised);
            if(!dest){
                CallMonitor::threadDetach();
                if(g_CRAMP_Profiler.g_fLogFile)
                    fflush(g_CRAMP_Profiler.g_fLogFile);
                if(g_CRAMP_Profiler.g_fFuncInfo)
                    fflush(g_CRAMP_Profiler.g_fFuncInfo);
            }
            break;
    }
    return(TRUE);
}
