// -*-c++-*-
// Time-stamp: <2003-10-03 15:26:41 dhruva>
//-----------------------------------------------------------------------------
// File  : cramp.cpp
// Misc  : C[ramp] R[uns] A[nd] M[onitors] P[rocesses]
// Desc  : Create a job, process inside the job which may create further
//         processes. Add a callback on the job to notify when a process
//         is added to the job. A timer to monitor the processes in the job.
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#include "cramp.h"
#include "TestCaseInfo.h"
#include "XMLParse.h"

#include <stdio.h>
#include <tchar.h>
#include <malloc.h>

//--------------------------- FUNCTION PROTOTYPES -----------------------------
void InitGlobals(void);
DWORD WINAPI JobNotifyTH(PVOID);
DWORD WINAPI CreateManagedProcesses(PVOID);
TestCaseInfo *GetTestCaseInfos(const char *ifile);
void CALLBACK MemoryPollCB(PVOID lpParameter,BOOLEAN TimerOrWaitFired);
PROC_INFO *GetHandlesToActiveProcesses(HANDLE h_Job);
//--------------------------- FUNCTION PROTOTYPES -----------------------------

//--------------------------- GLOBAL VARIABLES --------------------------------
FILE *g_LogFile;                   // Handle to log file
HANDLE g_hIOCP;                    // Completion port that receives Job notif
HANDLE g_hThreadIOCP;              // Completion port listening thread
//--------------------------- GLOBAL VARIABLES --------------------------------

//------------------------ IMPLEMENTATION BEGINS ------------------------------

//-----------------------------------------------------------------------------
// InitGlobals
//  Method to initialize all global values
//-----------------------------------------------------------------------------
void
InitGlobals(void){
  g_LogFile=0;
  g_hIOCP=0;
  g_hThreadIOCP=0;
  return;
}

//-----------------------------------------------------------------------------
// GetTestCaseInfos
//  Internally, call the XML parser and get a list of test cases
//-----------------------------------------------------------------------------
TestCaseInfo
*GetTestCaseInfos(const char *ifile){
  if(!ifile)
    return(0);
  XMLParse xml(ifile);
  if(!xml.ParseXMLFile())
    return(0);
  return(xml.GetScenario());
}

//-----------------------------------------------------------------------------
// GetHandlesToActiveProcesses
//-----------------------------------------------------------------------------
PROC_INFO
*GetHandlesToActiveProcesses(HANDLE h_Job){
  if(!h_Job)
    return(0);

  DWORD cb=0;
  // Get the number of processes in the job
  PJOBOBJECT_BASIC_ACCOUNTING_INFORMATION pjobin=0;
  cb=sizeof(JOBOBJECT_BASIC_ACCOUNTING_INFORMATION);
  pjobin=(PJOBOBJECT_BASIC_ACCOUNTING_INFORMATION)_alloca(cb);
  if(!QueryInformationJobObject(h_Job,JobObjectBasicAccountingInformation,
                                pjobin,cb,&cb))
    return(0);
  SIZE_T numprocs=pjobin->ActiveProcesses;

  // Get the actual list of processes
  cb=sizeof(JOBOBJECT_BASIC_PROCESS_ID_LIST)
    +(numprocs-1)*sizeof(DWORD);
  PJOBOBJECT_BASIC_PROCESS_ID_LIST pjobpil=0;
  pjobpil=(PJOBOBJECT_BASIC_PROCESS_ID_LIST)_alloca(cb);

  pjobpil->NumberOfAssignedProcesses=numprocs;
  if(!QueryInformationJobObject(h_Job,JobObjectBasicProcessIdList,
                                pjobpil,cb,&cb))
    return(0);
  PROC_INFO *pharr=0;
  pharr=new PROC_INFO[pjobpil->NumberOfProcessIdsInList];
  SIZE_T jj=0;
  for(int ii=0;ii<pjobpil->NumberOfProcessIdsInList;ii++){
    SIZE_T pid=pjobpil->ProcessIdList[ii];
    HANDLE h_proc=0;
    h_proc=OpenProcess(PROCESS_QUERY_INFORMATION|
                       PROCESS_VM_READ,
                       FALSE,pid);
    if(!h_proc)
      continue;
    DWORD pstat=0;
    GetExitCodeProcess(h_proc,&pstat);
    if(STILL_ACTIVE==pstat){
      pharr[jj].u_pid=pid;
      pharr[jj].h_proc=h_proc;
      jj++;
      pharr[jj].u_pid=0;
      pharr[jj].h_proc=0;
    }else{
      CloseHandle(h_proc);
      h_proc=0;
    }
  }
  return(pharr);
}

//-----------------------------------------------------------------------------
// CreateManagedProcesses
//  For multiple blocking/non-blocking call. Can be called in a thread
//-----------------------------------------------------------------------------
DWORD WINAPI
CreateManagedProcesses(PVOID ipTestCaseInfo){
  if(!ipTestCaseInfo)
    return(0);

  DWORD dwret=1;
  SIZE_T psz=0;
  HANDLE *tharr=0;
  SIZE_T numgroups=0;
  PROCESS_INFORMATION *ppi=0;
  ListOfTestCaseInfo l_tci;

  TestCaseInfo *pTopTC=(TestCaseInfo *)ipTestCaseInfo;
  l_tci=pTopTC->GetListOfTCI();
  BOOLEAN blocked=pTopTC->BlockStatus();
  if(!blocked){
    ppi=new PROCESS_INFORMATION[l_tci.size()];
    // Count number of groups for non-block run
    ListOfTestCaseInfo::iterator iter=l_tci.begin();
    for(;iter!=l_tci.end();iter++)
      if((*iter)->GroupStatus()||(*iter)->PseudoGroupStatus())
        numgroups++;
    if(numgroups)
      tharr=new HANDLE[numgroups];
  }

  ListOfTestCaseInfo::iterator iter=l_tci.begin();
  for(SIZE_T tc=0;iter!=l_tci.end();iter++){
    TestCaseInfo *ptc=(*iter);
    TestCaseInfo *porigtc=ptc;
    while(ptc&&ptc->ReferStatus())
      ptc=ptc->Reference();
    if(!ptc)
      continue;

    // If it is a group OR original is a pseudo group
    // call recursively
    if(ptc->GroupStatus()||porigtc->PseudoGroupStatus()){
      if(blocked){
        CreateManagedProcesses(ptc);
      }else if(tc<numgroups){
        tharr[tc]=chBEGINTHREADEX(NULL,0,CreateManagedProcesses,ptc,0,NULL);
        tc++;
      }
      continue;
    }

    STARTUPINFO si={sizeof(si)};
    PROCESS_INFORMATION pi={0};
    std::string str=ptc->TestCaseExec();
    if(!CreateProcess(NULL,
                      (char *)str.c_str(),
                      NULL,
                      NULL,
                      FALSE,
                      CREATE_SUSPENDED,
                      NULL,
                      NULL,
                      &si,
                      &pi)){
      dwret=0;
      continue;
    }

    HANDLE h_job=0;
    h_job=OpenJobObject(JOB_OBJECT_ASSIGN_PROCESS,TRUE,JOB_NAME);
    if(!h_job)
      continue;
    BOOLEAN ret=FALSE;
    ret=AssignProcessToJobObject(h_job,pi.hProcess);
    CloseHandle(h_job);
    if(!ret){
      TerminateProcess(pi.hProcess,1);
      dwret=0;
      continue;
    }

    // Set some process information
    porigtc->ProcessInfo(pi);

    if(blocked){
      ResumeThread(pi.hThread);
      CloseHandle(pi.hThread);
      WaitForSingleObject(pi.hProcess,INFINITE);
    }else{
      ppi[psz]=pi;
      psz++;
    }
  }

  if(!blocked){
    SIZE_T cc=0;
    HANDLE *ptharr=new HANDLE[psz+numgroups];
    // Add non blocking process
    for(cc=0;cc<psz;cc++)
      ptharr[cc]=ppi[cc].hProcess;
    // Add non blocking groups
    for(cc=psz;cc<numgroups;cc++)
      ptharr[cc]=tharr[cc];

    for(cc=0;cc<psz;cc++){
      ResumeThread(ppi[cc].hThread);
      CloseHandle(ppi[cc].hThread);
    }

    dwret=WaitForMultipleObjects(psz+numgroups,ptharr,TRUE,INFINITE);

    delete [] ppi;
    delete [] tharr;
    delete [] ptharr;
    ppi=0;
    tharr=0;
    ptharr=0;
  }
  fflush(g_LogFile);
  return(dwret);
}

//-----------------------------------------------------------------------------
// MemoryPollCB
//  This method actually gets the process's memory information. This is called
//  by the timer object at specified intervals till process is alive
//-----------------------------------------------------------------------------
void
CALLBACK MemoryPollCB(PVOID lpParameter,
                      BOOLEAN TimerOrWaitFired){
  if(!TimerOrWaitFired)
    return;

  HANDLE h_job=0;
  h_job=OpenJobObject(JOB_OBJECT_QUERY,TRUE,JOB_NAME);
  if(!h_job)
    return;
  PROC_INFO *pharr=GetHandlesToActiveProcesses(h_job);
  CloseHandle(h_job);
  h_job=0;

  for(SIZE_T ii=0;pharr[ii].h_proc;ii++){
    HANDLE h_proc=pharr[ii].h_proc;
    PROCESS_MEMORY_COUNTERS pmc={0};
    SIZE_T pid=pharr[ii].u_pid;
    do{
      if(!GetProcessMemoryInfo(h_proc,&pmc,sizeof(pmc))){
        fprintf(g_LogFile,"%d:Memory usage fail:IMI\n",pid);
        break;;
      }
      // Actual RAM pmc.WorkingSetSize;
      fprintf(g_LogFile,"%d:Memory usage:%d\n",pid,pmc.WorkingSetSize);
    }while(0);
    CloseHandle(h_proc);
  }
  fflush(g_LogFile);
  delete [] pharr;
  pharr=0;
  return;
}

//-----------------------------------------------------------------------------
// JobNotifyTH
//  Method invoked in a seperate thread to monitor the job. All messages
//  due to adding a process to the job or termination of process in the job
//  is listened here
//-----------------------------------------------------------------------------
DWORD WINAPI
JobNotifyTH(PVOID){
  BOOL fDone=FALSE;
  while(!fDone){
    DWORD dwBytesXferred;
    ULONG_PTR CompKey;
    LPOVERLAPPED po;
    GetQueuedCompletionStatus(g_hIOCP,
                              &dwBytesXferred,
                              &CompKey,
                              &po,
                              INFINITE);

    // The app is shutting down, exit this thread
    fDone=(CompKey==COMPKEY_TERMINATE);

    if(CompKey==COMPKEY_JOBOBJECT){
      switch(dwBytesXferred){
        case JOB_OBJECT_MSG_NEW_PROCESS:
          fprintf(g_LogFile,"%d:Process added\n",(SIZE_T)po);
          break;
        case JOB_OBJECT_MSG_EXIT_PROCESS:
          fprintf(g_LogFile,"%d:Process terminated\n",(SIZE_T)po);
          break;
        case JOB_OBJECT_MSG_ABNORMAL_EXIT_PROCESS:
          fprintf(g_LogFile,"%d:Process abnormally terminated\n",(SIZE_T)po);
          break;
        case JOB_OBJECT_MSG_END_OF_JOB_TIME:
        case JOB_OBJECT_TERMINATE_AT_END_OF_JOB:
          fprintf(g_LogFile,"%d:End of Job\n",(SIZE_T)po);
          break;
        case JOB_OBJECT_MSG_ACTIVE_PROCESS_LIMIT:
          break;
        case JOB_OBJECT_MSG_ACTIVE_PROCESS_ZERO:
          break;
        case JOB_OBJECT_MSG_PROCESS_MEMORY_LIMIT:
          break;
        case JOB_OBJECT_MSG_JOB_MEMORY_LIMIT:
          break;
        default:
          fprintf(g_LogFile,"%d:Unknown event in Job:%d\n",
                  (SIZE_T)po,
                  dwBytesXferred);
          break;
      }
      fflush(g_LogFile);
      CompKey=1;
    }
  }
  return(0);
}

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

  if(getenv("DEBUG"))
    DebugBreak();

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
  char scenario[256];
  WideCharToMultiByte(CP_ACP,0,argvW[1],-1,
                      scenario,256,0,0);
  // Open log file at top
  g_LogFile=fopen("c:/tmp/cramp.log","w");
  if(!g_LogFile)
    return(ret);
  fprintf(g_LogFile,"Starting scenario:%s\n",scenario);

  HANDLE h_job=0;
  h_job=CreateJobObject(NULL,JOB_NAME);
  if(!h_job)
    return(ret);
  HANDLE h_memtimer=0;

  do{
    // Add a timed memory polling on the job for active processes
    if(!CreateTimerQueueTimer(&h_memtimer,NULL,
                              MemoryPollCB,(void *)h_job,
                              1000,5000,0))
      break;

    // Create an IO completion port to positively identify adding
    // or removal of processes into/from a job
    g_hIOCP=CreateIoCompletionPort(INVALID_HANDLE_VALUE,NULL,0,0);

    // Start the thread to monitor the job notifications
    g_hThreadIOCP=chBEGINTHREADEX(NULL,0,JobNotifyTH,NULL,0,NULL);

    JOBOBJECT_ASSOCIATE_COMPLETION_PORT joacp;
    joacp.CompletionKey=(void *)COMPKEY_JOBOBJECT;
    joacp.CompletionPort=g_hIOCP;
    SetInformationJobObject(h_job,
                            JobObjectAssociateCompletionPortInformation,
                            &joacp,
                            sizeof(joacp));

    // Parse the XML file and populate the list
    TestCaseInfo *ptop=GetTestCaseInfos(scenario);
    if(!ptop)
      break;

    if(!CreateManagedProcesses(ptop))
      fprintf(g_LogFile,"Error in run\n");
    fflush(g_LogFile);

    TestCaseInfo::DeleteScenario(ptop);
    ptop=0;

    // Post msg to terminate job monitoring thread and wait for termination
    PostQueuedCompletionStatus(g_hIOCP,0,COMPKEY_TERMINATE,NULL);
    WaitForSingleObject(g_hThreadIOCP,INFINITE);

    // Clean up everything properly
    CloseHandle(g_hIOCP);
    CloseHandle(g_hThreadIOCP);

    // Return OKAY
    ret=0;
  }while(0);

  if(h_memtimer)
    CloseHandle(h_memtimer);
  if(h_job)
    CloseHandle(h_job);

  fprintf(g_LogFile,"Closing scenario:%s\n",scenario);
  fclose(g_LogFile);
  GlobalFree(argvW);

  InitGlobals();
  return(ret);
}
