// -*-c++-*-
// Time-stamp: <2003-11-03 16:03:39 dhruva>
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
  int ret=-1;
  InitGlobals();

  DEBUGCHK(!getenv("CRAMP_DEBUG"));

  char logdir[256]=".";
  char logfile[256];
  if(getenv("CRAMP_LOGPATH"))
    strcpy(logdir,getenv("CRAMP_LOGPATH"));
  sprintf(logfile,"%s/cramp.log",logdir);
  g_CRAMP_Engine.g_fLogFile=fopen(logfile,"w+");
  if(!g_CRAMP_Engine.g_fLogFile)
    return(ret);

  if(!InitializeCriticalSectionAndSpinCount(&g_CRAMP_Engine.g_cs_log,
                                            4000L)){
    fprintf(g_CRAMP_Engine.g_fLogFile,"Error in CRITICAL SECTION init!\n");
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
  char msg[256];
  char scenario[256];
  WideCharToMultiByte(CP_ACP,0,argvW[1],-1,
                      scenario,256,0,0);

  HANDLE h_job=0;
  HANDLE h_memtimer=0;
  HANDLE h_arr[5];
  h_arr[0]=0;                   // Job monitoring thread
  h_arr[1]=0;                   // MUTEX object to kill memory thread
  h_arr[2]=0;                   // Memory polling thread
  h_arr[3]=0;                   // Mail slot communication thread
  h_arr[4]=0;                   // Pipe communication server thread
  h_arr[5]=0;                   // Last must be 0

  h_job=CreateJobObject(NULL,JOB_NAME);
  if(!h_job)
    return(ret);

  CRAMPServerMessaging *pSlotMsg=0;
  CRAMPServerMessaging *pPipeMsg=0;

  do{
    // Create an IO completion port to positively identify adding
    // or removal of processes into/from a job
    g_CRAMP_Engine.g_hIOCP=CreateIoCompletionPort(INVALID_HANDLE_VALUE,
                                                  NULL,0,0);

    // Start the thread to monitor the job notifications
    h_arr[0]=chBEGINTHREADEX(NULL,0,JobNotifyTH,NULL,0,NULL);

    JOBOBJECT_ASSOCIATE_COMPLETION_PORT joacp;
    joacp.CompletionKey=(void *)COMPKEY_JOBOBJECT;
    joacp.CompletionPort=g_CRAMP_Engine.g_hIOCP;
    SetInformationJobObject(h_job,
                            JobObjectAssociateCompletionPortInformation,
                            &joacp,
                            sizeof(joacp));

    // Parse the XML file and populate the list
    g_CRAMP_Engine.g_pScenario=GetTestCaseInfos(scenario);
    if(!g_CRAMP_Engine.g_pScenario)
      break;

    h_arr[1]=CreateMutex(NULL,TRUE,"MEMORY_MUTEX");
    DEBUGCHK(h_arr[1]);
    ReleaseMutex(h_arr[1]);

    // Mail slot & pipe server thread
    try{
      // Use default ctor
      pSlotMsg=new CRAMPServerMessaging();
      pPipeMsg=new CRAMPServerMessaging();
    }
    catch(CRAMPException excep){
      DEBUGCHK(0);
      break;
    }
    pSlotMsg->Server(".");
    pPipeMsg->Server(".");

    HANDLE h_event=0;
    h_event=CreateEvent(NULL,TRUE,FALSE,"THREAD_TERMINATE");
    h_arr[2]=chBEGINTHREADEX(NULL,0,MemoryPollTH,
                             (LPVOID)g_CRAMP_Engine.g_pScenario,
                             0,NULL);
    DEBUGCHK(h_arr[2]);
    h_arr[3]=chBEGINTHREADEX(NULL,0,MailSlotServerTH,
                             (LPVOID)pSlotMsg,
                             0,NULL);
    DEBUGCHK(h_arr[3]);

    // Do not use PIPE, some problem
    // h_arr[4]=chBEGINTHREADEX(NULL,0,MultiThreadedPipeServerTH,
    //                          (LPVOID)pPipeMsg,
    //                          0,NULL);
    // DEBUGCHK(h_arr[4]);

    SetEvent(h_event);          // So that threads can resume

    sprintf(msg,"MESSAGE|OKAY|SCENARIO|File: %s",scenario);
    g_CRAMP_Engine.g_pScenario->AddLog(msg);
    ret=CreateManagedProcesses(g_CRAMP_Engine.g_pScenario);


    // Kill the threads
    DEBUGCHK(ResetEvent(h_event));
    // Post msg to terminate job monitoring thread and wait for termination
    PostQueuedCompletionStatus(g_CRAMP_Engine.g_hIOCP,0,
                               COMPKEY_TERMINATE,NULL);
    WaitForMultipleObjects(2,h_arr,TRUE,INFINITE);
    TerminateThread(h_arr[3],0);

    if(ret)
      g_CRAMP_Engine.g_pScenario->AddLog(
        "MESSAGE|OKAY|SCENARIO|Successful run");
    else
      g_CRAMP_Engine.g_pScenario->AddLog(
        "MESSAGE|ERROR|SCENARIO|Unsuccessful run");

    // Clean up everything properly
    CloseHandle(g_CRAMP_Engine.g_hIOCP);
    for(SIZE_T xx=0;h_arr[xx];xx++){
      CloseHandle(h_arr[xx]);
      h_arr[xx]=0;
    }

    // Return OKAY
    ret=!ret;
  }while(0);

  if(pSlotMsg){
    delete pSlotMsg;
    pSlotMsg=0;
  }

  if(pPipeMsg){
    delete pSlotMsg;
    pSlotMsg=0;
  }

  if(h_memtimer){
    CloseHandle(h_memtimer);
    h_memtimer=0;
  }

  if(h_job){
    CloseHandle(h_job);
    h_job=0;
  }

  if(g_CRAMP_Engine.g_pScenario){
    // do{
    //   char logdir[256]=".";
    //   char logfile[256];
    //   if(getenv("CRAMP_LOGPATH"))
    //     strcpy(logdir,getenv("CRAMP_LOGPATH"));
    //   sprintf(logfile,"%s/cramp.log",logdir);
    //   ofstream flog(logfile,ios::out,filebuf::sh_none);
    //   if(!flog.is_open())
    //     break;
    //   g_CRAMP_Engine.g_pScenario->DumpLog(flog);
    //   flog.close();
    //   Disable XML file dumping, use PSF files
    //   sprintf(logfile,"%s/cramp.xml",logdir);
    //   DumpLogsToXML(logfile);
    // }while(0);
    TestCaseInfo::DeleteScenario(g_CRAMP_Engine.g_pScenario);
  }

  g_CRAMP_Engine.g_pScenario=0;
  GlobalFree(argvW);

  InitGlobals();
  return(ret);
}
