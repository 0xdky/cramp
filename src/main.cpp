// -*-c++-*-
// Time-stamp: <2003-11-24 14:22:12 dhruva>
//-----------------------------------------------------------------------------
// File  : main.cpp
// Misc  : C[ramp] R[uns] A[nd] M[onitors] P[rocesses]
// Desc  : Contains the entry method, actual code is in "engine.cpp"
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __MAIN_SRC

#include "cramp.h"
#include "ipc.h"
#include "ipcmsg.h"
#include "engine.h"
#include "XMLParse.h"
#include "TestCaseInfo.h"

#include <stdio.h>
#include <tchar.h>
#include <malloc.h>
#include <stdlib.h>
#include <string.h>
#include <Tlhelp32.h>
#include <WindowsX.h>

// The only permitted GLOBAL for CRAMP engine
Global_CRAMP_Engine g_CRAMP_Engine;

//-----------------------------------------------------------------------------
// WinMain
//-----------------------------------------------------------------------------
int
WINAPI WinMain(HINSTANCE hinstExe,
               HINSTANCE,
               PSTR pszCmdLine,
               int nCmdShow){
  DEBUGCHK(!getenv("CRAMP_DEBUG"));

  int ret=-1;
  int crampret=0;
  InitGlobals();

  // Get the JOB name
  sprintf(g_CRAMP_Engine.g_JOBNAME,
          "%s#%d",JOB_NAME,GetCurrentProcessId());

  // Prevent overwritting or overlapped monitoring
  g_CRAMP_Engine.g_hJOB=OpenJobObject(JOB_OBJECT_QUERY,
                                      FALSE,
                                      g_CRAMP_Engine.g_JOBNAME);
  if(g_CRAMP_Engine.g_hJOB)
    return(-1);

  // Create a MUTEX for synchronizing (could be used to make this singleton)
  g_CRAMP_Engine.g_hMUT=OpenMutex(MUTEX_MODIFY_STATE,FALSE,"CRAMP_MUTEX");
  if(!g_CRAMP_Engine.g_hMUT)
    g_CRAMP_Engine.g_hMUT=CreateMutex(NULL,FALSE,"CRAMP_MUTEX");
  if(!g_CRAMP_Engine.g_hMUT)
    return(-1);

  char logdir[256]=".";
  char logfile[256];
  if(getenv("CRAMP_LOGPATH"))
    strcpy(logdir,getenv("CRAMP_LOGPATH"));
  sprintf(logfile,"%s/cramp_scenario#%d.log",logdir,GetCurrentProcessId());
  g_CRAMP_Engine.g_fLogFile=fopen(logfile,"w");
  if(!g_CRAMP_Engine.g_fLogFile)
    return(ret);

  if(!InitializeCriticalSectionAndSpinCount(&g_CRAMP_Engine.g_cs_log,
                                            4000L)){
    fclose(g_CRAMP_Engine.g_fLogFile);
    return(ret);
  }

  // Get the command line stuff
  int argcW=0;
  LPWSTR *argvW=0;
  argvW=CommandLineToArgvW(GetCommandLineW(),&argcW);
  if(!argvW)
    return(ret);
  if(argcW<2){
    GlobalFree(argvW);
    return(ret);
  }

  // Currently supports only 1 arg
  char *buff=0;
  char msg[256];
  char scenario[256];
  WideCharToMultiByte(CP_ACP,0,argvW[1],-1,
                      scenario,256,0,0);
  GetFullPathName(scenario,256,scenario,&buff);

  HANDLE h_arr[3];
  h_arr[0]=0;                   // Job monitoring thread
  h_arr[1]=0;                   // Memory polling thread
  h_arr[2]=0;                   // Last must be 0

  g_CRAMP_Engine.g_hJOB=CreateJobObject(NULL,g_CRAMP_Engine.g_JOBNAME);
  if(!g_CRAMP_Engine.g_hJOB)
    return(ret);

  do{
    // Parse the XML file and populate the list
    g_CRAMP_Engine.g_pScenario=GetTestCaseInfos(scenario);
    sprintf(msg,"# Running SCENARIO: %s",scenario);
    g_CRAMP_Engine.g_pScenario->AddLog(msg);
    if(!g_CRAMP_Engine.g_pScenario)
      break;

    // Start the thread to monitor the job notifications
    h_arr[0]=chBEGINTHREADEX(NULL,0,JobNotifyTH,NULL,0,NULL);

    // Create an IO completion port to positively identify adding
    // or removal of processes into/from a job
    g_CRAMP_Engine.g_hIOCP=CreateIoCompletionPort(INVALID_HANDLE_VALUE,
                                                  NULL,0,0);

    // JOB communication port
    JOBOBJECT_ASSOCIATE_COMPLETION_PORT joacp;
    joacp.CompletionKey=(void *)COMPKEY_JOBOBJECT;
    joacp.CompletionPort=g_CRAMP_Engine.g_hIOCP;
    SetInformationJobObject(g_CRAMP_Engine.g_hJOB,
                            JobObjectAssociateCompletionPortInformation,
                            &joacp,
                            sizeof(joacp));

    // Start only after making SCENARIO
    h_arr[1]=chBEGINTHREADEX(NULL,0,MemoryPollTH,
                             (LPVOID)g_CRAMP_Engine.g_pScenario,
                             0,NULL);
    DEBUGCHK(h_arr[1]);

    // JOB time limit just before running
    SIZE_T jobmaxtime=0;
    jobmaxtime=g_CRAMP_Engine.g_pScenario->MaxTimeLimit();
    if(jobmaxtime){
      CreateTimerQueueTimer(&g_CRAMP_Engine.g_hJOBTimer,
                            NULL,
                            JOBTimeLimitReachedCB,
                            NULL,
                            jobmaxtime,
                            0,
                            WT_EXECUTEONLYONCE|WT_EXECUTEINTIMERTHREAD);
    }

    // Run the engine
    ret=CreateManagedProcesses(g_CRAMP_Engine.g_pScenario);

    // Post msg to terminate job monitoring thread and wait for termination
    PostQueuedCompletionStatus(g_CRAMP_Engine.g_hIOCP,0,
                               COMPKEY_TERMINATE,NULL);
    WaitForMultipleObjects(2,h_arr,TRUE,INFINITE);

    // Clean up everything properly
    CloseHandle(g_CRAMP_Engine.g_hIOCP);
    for(SIZE_T xx=0;h_arr[xx];xx++){
      CloseHandle(h_arr[xx]);
      h_arr[xx]=0;
    }
  }while(0);

  // Get all exit status and delete the internal tree
  if(g_CRAMP_Engine.g_pScenario){
    DWORD ec=0;
    ListOfTestCaseInfo &l_gc=g_CRAMP_Engine.g_pScenario->BlockListOfGC();
    ListOfTestCaseInfo::iterator iter=l_gc.begin();
    for(;iter!=l_gc.end();iter++){
      TestCaseInfo *ptc=(*iter);
      if(!ptc||ptc->GroupStatus()||ptc->PseudoGroupStatus())
        continue;
      GetExitCodeProcess(ptc->ProcessInfo().hProcess,&ec);
      if(ptc->SubProcStatus()){
        if(ec)
          sprintf(msg,"SP|KO|-1|%d",ec);
        else
          sprintf(msg,"SP|OK|0|%d",ec);
        ptc->AddLog(msg);
      }else if(ptc->ExeProcStatus()){
        if(ec)
          sprintf(msg,"TP|KO|-1|%d",ec);
        else
          sprintf(msg,"TP|OK|0|%d",ec);
        ptc->AddLog(msg);
      }
    }
    g_CRAMP_Engine.g_pScenario->ReleaseListOfGC();

    ret=g_CRAMP_Engine.g_scenariostatus;
    if(g_CRAMP_Engine.g_scenariostatus)
      sprintf(msg,"SC|KO|%d|%d",crampret,g_CRAMP_Engine.g_scenariostatus);
    else
      sprintf(msg,"SC|OK|%d|%d",crampret,g_CRAMP_Engine.g_scenariostatus);
    g_CRAMP_Engine.g_pScenario->AddLog(msg);

    TestCaseInfo::DeleteScenario(g_CRAMP_Engine.g_pScenario);
    g_CRAMP_Engine.g_pScenario=0;
  }

  if(g_CRAMP_Engine.g_hJOB){
    CloseHandle(g_CRAMP_Engine.g_hJOB);
    g_CRAMP_Engine.g_hJOB=0;
  }

  if(g_CRAMP_Engine.g_hJOBTimer){
    DeleteTimerQueueTimer(NULL,g_CRAMP_Engine.g_hJOBTimer,NULL);
    CloseHandle(g_CRAMP_Engine.g_hJOBTimer);
    g_CRAMP_Engine.g_hJOBTimer=0;
  }

  if(g_CRAMP_Engine.g_hMUT){
    CloseHandle(g_CRAMP_Engine.g_hMUT);
    g_CRAMP_Engine.g_hMUT=0;
  }

  GlobalFree(argvW);
  InitGlobals();

  return(ret);
}
