// -*-c++-*-
// Time-stamp: <2003-10-14 11:07:05 dhruva>
//-----------------------------------------------------------------------------
// File  : engine.cpp
// Misc  : C[ramp] R[uns] A[nd] M[onitors] P[rocesses]
// Desc  : Create a job, process inside the job which may create further
//         processes. Add a callback on the job to notify when a process
//         is added to the job. A timer to monitor the processes in the job.
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __ENGINE_SRC

#include "cramp.h"
#include "ipc.h"
#include "ipcmsg.h"
#include "engine.h"
#include "TestCaseInfo.h"
#include "XMLParse.h"

#include <stdio.h>
#include <tchar.h>
#include <malloc.h>
#include <stdlib.h>
#include <string.h>
#include <Tlhelp32.h>
#include <WindowsX.h>

#include <xercesc/util/XMLUni.hpp>
#include <xercesc/util/XMLUniDefs.hpp>
#include <xercesc/dom/DOMWriter.hpp>
#include <xercesc/dom/DOMImplementation.hpp>
#include <xercesc/dom/DOMImplementationLS.hpp>
#include <xercesc/dom/DOMImplementationRegistry.hpp>
#include <xercesc/framework/LocalFileFormatTarget.hpp>

//--------------------------- FUNCTION PROTOTYPES -----------------------------
void InitGlobals(void);
int DumpLogsToXML(char *);
DWORD WINAPI JobNotifyTH(LPVOID);
DWORD WINAPI CreateManagedProcesses(LPVOID);
DWORD WINAPI MemoryPollTH(LPVOID);
TestCaseInfo *GetTestCaseInfos(const char *);
BOOLEAN ActiveProcessMemoryDetails(TestCaseInfo *,CRAMPMessaging *);
PROC_INFO *GetHandlesToActiveProcesses(HANDLE);
//--------------------------- FUNCTION PROTOTYPES -----------------------------

//--------------------------- GLOBAL VARIABLES --------------------------------
HANDLE g_hIOCP;               // Completion port that receives Job notif
TestCaseInfo *g_pScenario;    // Pointer to Scenario
//--------------------------- GLOBAL VARIABLES --------------------------------

//------------------------ IMPLEMENTATION BEGINS ------------------------------

//-----------------------------------------------------------------------------
// CRAMPServerMessaging
//-----------------------------------------------------------------------------
CRAMPServerMessaging::CRAMPServerMessaging(){
}

//-----------------------------------------------------------------------------
// CRAMPServerMessaging
//-----------------------------------------------------------------------------
CRAMPServerMessaging::CRAMPServerMessaging(const char *iServer,BOOLEAN isPipe)
  :CRAMPMessaging(iServer,isPipe){
  }

//-----------------------------------------------------------------------------
// Process
//-----------------------------------------------------------------------------
BOOLEAN
CRAMPServerMessaging::Process(void){
  if(!g_pScenario)
    return(FALSE);
  TestCaseInfo *prem=0;
  prem=g_pScenario->Remote();
  if(!prem)
    return(FALSE);
  prem->AddLog(Message());
  return(TRUE);
}

//-----------------------------------------------------------------------------
// InitGlobals
//  Method to initialize all global values
//-----------------------------------------------------------------------------
void
InitGlobals(void){
  g_hIOCP=0;
  g_pScenario=0;
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
    h_proc=OpenProcess(PROCESS_QUERY_INFORMATION|PROCESS_VM_READ,
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
CreateManagedProcesses(LPVOID ipTestCaseInfo){
  if(!ipTestCaseInfo)
    return(0);

  DWORD dwret=1;
  SIZE_T psz=0;
  char msg[256];
  HANDLE *tharr=0;
  std::string str;
  SIZE_T numgroups=0;
  ListOfTestCaseInfo l_tci;
  PROCESS_INFORMATION *ppi=0;
  TestCaseInfo *pTopTC=(TestCaseInfo *)ipTestCaseInfo;

  // Make a copy... better performance
  l_tci=pTopTC->BlockListOfTCI();
  pTopTC->ReleaseListOfTCI();

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
    // Sub processes are not executed!
    if((*iter)->SubProcStatus())
      continue;

    TestCaseInfo *ptc=(*iter);
    TestCaseInfo *porigtc=ptc;
    if(ptc->ReferStatus())
      ptc=ptc->Reference();
    DEBUGCHK(ptc);

    // If it is a group OR original is a pseudo group
    // call recursively
    if(ptc->GroupStatus()||porigtc->PseudoGroupStatus()){
      ptc=(ptc->GroupStatus())?ptc:porigtc;
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
    str=ptc->TestCaseExec();
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
      ptc->AddLog("MESSAGE|ERROR|PROC|Could not create process");
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
      porigtc->AddLog("MESSAGE|ERROR|JOB|Could not attach process to job");
      continue;
    }

    // Set some process information
    porigtc->ProcessInfo(pi);
    porigtc->AddLog("MESSAGE|OKAY|PROC|Created process");

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
  return(dwret);
}

//-----------------------------------------------------------------------------
// MemoryPollTH
//  This is called by the timer object at specified intervals till process
//  is alive
//-----------------------------------------------------------------------------
DWORD WINAPI
MemoryPollTH(LPVOID lpParameter){
  if(!lpParameter)
    return(1);

  HANDLE h_event=0;
  h_event=OpenEvent(EVENT_MODIFY_STATE|SYNCHRONIZE,FALSE,"THREAD_TERMINATE");
  if(!h_event)
    return(1);
  WaitForSingleObject(h_event,INFINITE);
  CloseHandle(h_event);

  BOOLEAN fDone=FALSE;
  TestCaseInfo *pScenario=(TestCaseInfo *)lpParameter;
  HANDLE h_mutex=0;
  h_mutex=OpenMutex(SYNCHRONIZE,TRUE,"MEMORY_MUTEX");
  if(!h_mutex)
    return(1);

  CRAMPServerMessaging *pmsg=0;
  try{
    pmsg=new CRAMPServerMessaging("pchiwi7deg",TRUE);
  }
  catch(CRAMPException excep){
    DEBUGCHK(0);
    return(1);
  }
  while(1){
    WaitForSingleObject(h_mutex,INFINITE);
    ActiveProcessMemoryDetails(pScenario,pmsg);
    ReleaseMutex(h_mutex);
    Sleep(2000);
  }
  CloseHandle(h_mutex);
  return(0);
}

//-----------------------------------------------------------------------------
// ActiveProcessMemoryDetails
//  This method actually gets the process's memory information.
//-----------------------------------------------------------------------------
BOOLEAN
ActiveProcessMemoryDetails(TestCaseInfo *ipScenario,CRAMPMessaging *ioMsg){
  BOOLEAN ret=FALSE;
  DEBUGCHK(ipScenario);
  if(!ipScenario)
    return(ret);
  try{
    ListOfTestCaseInfo &lgc=ipScenario->BlockListOfGC();
    ListOfTestCaseInfo::iterator iter=lgc.begin();
    for(;iter!=lgc.end();iter++){
      TestCaseInfo *ptc=(*iter);
      PROCESS_MEMORY_COUNTERS pmc={0};
      PROCESS_INFORMATION pin=ptc->ProcessInfo();
      if(!pin.hProcess)
        continue;
      DWORD pstat=0;
      GetExitCodeProcess(pin.hProcess,&pstat);
      if(STILL_ACTIVE!=pstat)
        continue;
      do{
        if(!GetProcessMemoryInfo(pin.hProcess,&pmc,sizeof(pmc)))
          break;;
        // Actual RAM pmc.WorkingSetSize;
        char msg[256];
        sprintf(msg,"LOG|MEMORY|RAM|%ld",pmc.WorkingSetSize);
        ptc->AddLog(msg);

#ifdef CRAMP_DEBUG
        // Some large data
        ioMsg->Message(msg);
        WriteToPipe(ioMsg);
#endif

      }while(0);
    }
    ipScenario->ReleaseListOfGC();
    ret=TRUE;
  }
  catch(CRAMPException excep){
    DEBUGCHK(0);
  }
  return(ret);
}

//-----------------------------------------------------------------------------
// JobNotifyTH
//  Method invoked in a seperate thread to monitor the job. All messages
//  due to adding a process to the job or termination of process in the job
//  is listened here
//-----------------------------------------------------------------------------
DWORD WINAPI
JobNotifyTH(LPVOID){
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
    TestCaseInfo *ptc=0;

    if(CompKey==COMPKEY_JOBOBJECT){
      char msg[256];
      switch(dwBytesXferred){
        case JOB_OBJECT_MSG_NEW_PROCESS:
          ptc=g_pScenario->FindTCFromPID((SIZE_T)po);
          // Test case created a sub process
          do{
            if(ptc)
              break;
            // Get the parent process and the test case to append to
            HANDLE h_snap=0;
            h_snap=CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
            DEBUGCHK(!(h_snap==INVALID_HANDLE_VALUE));
            PROCESSENTRY32 ppe={0};
            ppe.dwSize=sizeof(PROCESSENTRY32);
            SIZE_T ppid=(SIZE_T)po;
            BOOLEAN ret=FALSE;
            ret=Process32First(h_snap,&ppe);
            for(;ret;ret=Process32Next(h_snap,&ppe)){
              if(ppe.th32ProcessID==(SIZE_T)po){
                ppid=ppe.th32ParentProcessID;
                break;
              }
            }
            CloseHandle(h_snap);
            if(ppid==(SIZE_T)po)
              break;

            ptc=g_pScenario->FindTCFromPID(ppid);
            if(!ptc)
              break;
            HANDLE h_proc=0;
            // May not find handle if process is too short
            // Hence, do not check the handle!
            h_proc=OpenProcess(PROCESS_QUERY_INFORMATION|PROCESS_VM_READ,
                               FALSE,(SIZE_T)po);
            PROCESS_INFORMATION pin={0};
            pin.hProcess=h_proc;
            pin.dwProcessId=(SIZE_T)po;
            TestCaseInfo *pctc=0;
            try{
              pctc=ptc->AddTestCase(0,FALSE,TRUE);
              DEBUGCHK(pctc);
              pctc->ProcessInfo(pin);
              pctc->TestCaseName("Sub Process");
              pctc->TestCaseExec(ppe.szExeFile);
              sprintf(msg,"MESSAGE|OKAY|SUBPROC|Added:%s",ppe.szExeFile);
              ptc->AddLog(msg);
            }
            catch(CRAMPException excep){
            }
          }while(0);
          break;
        case JOB_OBJECT_MSG_EXIT_PROCESS:
          ptc=g_pScenario->FindTCFromPID((SIZE_T)po);
          {
            DWORD ec=0;
            GetExitCodeProcess(ptc->ProcessInfo().hProcess,&ec);
            sprintf(msg,"MESSAGE|OKAY|PROC|Terminated:%d",ec);
            ptc->AddLog(msg);
          }
          break;
        case JOB_OBJECT_MSG_ABNORMAL_EXIT_PROCESS:
          ptc=g_pScenario->FindTCFromPID((SIZE_T)po);
          {
            DWORD ec=0;
            GetExitCodeProcess(ptc->ProcessInfo().hProcess,&ec);
            sprintf(msg,"MESSAGE|ERROR|PROC|Terminated:%d",ec);
            ptc->AddLog(msg);
          }
          break;
        case JOB_OBJECT_MSG_END_OF_JOB_TIME:
        case JOB_OBJECT_TERMINATE_AT_END_OF_JOB:
          // fprintf(g_LogFile,"%d:End of Job\n",(SIZE_T)po);
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
          // fprintf(g_LogFile,"%d:Unknown event in Job:%d\n",
          //         (SIZE_T)po,dwBytesXferred);
          break;
      }
      CompKey=1;
    }
  }
  return(0);
}

//-----------------------------------------------------------------------------
// DumpLogsToXML
//-----------------------------------------------------------------------------
int
DumpLogsToXML(char *logfile){
  try{
    XMLPlatformUtils::Initialize();
  }
  catch(const XMLException& toCatch){
    return(1);
  }

  {
    DOMDocument *doc=0;
    DOMImplementation *impl=0;

    XMLCh tempStr[100];
    XMLString::transcode("Core",tempStr,99);
    impl=DOMImplementationRegistry::getDOMImplementation(tempStr);
    DEBUGCHK(impl);

    XMLString::transcode("CRAMPLOG",tempStr,99);
    doc=impl->createDocument(0,tempStr,0);
    DEBUGCHK(doc);
    DOMElement *rootElem=doc->getDocumentElement();
    g_pScenario->DumpLogToDOM(rootElem);

    DOMWriter *theSerializer=0;
    XMLString::transcode("LS",tempStr,99);
    impl=DOMImplementationRegistry::getDOMImplementation(tempStr);
    DEBUGCHK(impl);
    theSerializer=((DOMImplementationLS *)impl)->createDOMWriter();
    DEBUGCHK(theSerializer);

    XMLFormatTarget *myFormTarget=0;
    myFormTarget=new LocalFileFormatTarget(logfile);
    theSerializer->writeNode(myFormTarget,*doc);

    delete theSerializer;
    delete myFormTarget;
    doc->release();
  }
  XMLPlatformUtils::Terminate();
  return(0);
}
