// -*-c++-*-
// Time-stamp: <2003-10-11 13:52:06 dhruva>
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

  do{
    // Create an IO completion port to positively identify adding
    // or removal of processes into/from a job
    g_hIOCP=CreateIoCompletionPort(INVALID_HANDLE_VALUE,NULL,0,0);

    // Start the thread to monitor the job notifications
    h_arr[0]=chBEGINTHREADEX(NULL,0,JobNotifyTH,NULL,0,NULL);

    JOBOBJECT_ASSOCIATE_COMPLETION_PORT joacp;
    joacp.CompletionKey=(void *)COMPKEY_JOBOBJECT;
    joacp.CompletionPort=g_hIOCP;
    SetInformationJobObject(h_job,
                            JobObjectAssociateCompletionPortInformation,
                            &joacp,
                            sizeof(joacp));

    // Parse the XML file and populate the list
    g_pScenario=GetTestCaseInfos(scenario);
    if(!g_pScenario)
      break;

    // Create a dummy remote object to store server responses
    try{
      g_pRemote=g_pScenario->AddGroup();
      if(!g_pRemote)
        break;
      g_pRemote->TestCaseName("REMOTE LOGS");
    }
    catch(CRAMPException excep){
      break;
    }

    h_arr[1]=CreateMutex(NULL,TRUE,"MEMORY_MUTEX");
    DEBUGCHK(h_arr[1]);
    ReleaseMutex(h_arr[1]);

    // Memory polling thread
    h_arr[2]=chBEGINTHREADEX(NULL,0,MemoryPollTH,(PVOID)g_pScenario,0,NULL);
    DEBUGCHK(h_arr[2]);

    // Mail slot server thread
    h_arr[3]=chBEGINTHREADEX(NULL,0,MailSlotServerTH,
                             (LPVOID)"\\\\.\\mailslot\\cramp_mailslot",
                             0,NULL);

    // Pipe communication
    h_arr[4]=chBEGINTHREADEX(NULL,0,MultiThreadedPipeServerTH,
                             (LPVOID)"\\\\.\\pipe\\cramp_pipe",
                             0,NULL);
    DEBUGCHK(h_arr[4]);

    sprintf(msg,"MESSAGE|OKAY|SCENARIO|File: %s",scenario);
    g_pScenario->AddLog(msg);
    if(!CreateManagedProcesses(g_pScenario))
      g_pScenario->AddLog("MESSAGE|ERROR|SCENARIO|Unsuccessful run");
    else
      g_pScenario->AddLog("MESSAGE|OKAY|SCENARIO|Successful run");

    // Post msg to terminate job monitoring thread and wait for termination
    PostQueuedCompletionStatus(g_hIOCP,0,COMPKEY_TERMINATE,NULL);
    WaitForMultipleObjects(2,h_arr,TRUE,INFINITE);
    TerminateThread(h_arr[2],0);
    TerminateThread(h_arr[3],0);

    // Clean up everything properly
    CloseHandle(g_hIOCP);
    for(SIZE_T xx=0;h_arr[xx];xx++){
      CloseHandle(h_arr[xx]);
      h_arr[xx]=0;
    }

    // Return OKAY
    ret=0;
  }while(0);

  if(h_memtimer)
    CloseHandle(h_memtimer);
  if(h_job)
    CloseHandle(h_job);

  if(g_pScenario){
    do{
      ofstream logfile("C:\\tmp\\cramp.log",ios::out,filebuf::sh_none);
      if(!logfile.is_open())
        break;
      g_pScenario->DumpLog(logfile);
      logfile.close();
      DumpLogsToXML("C:\\tmp\\cramp.xml");
    }while(0);
    TestCaseInfo::DeleteScenario(g_pScenario);
  }

  g_pScenario=0;
  GlobalFree(argvW);

  InitGlobals();
  return(ret);
}
