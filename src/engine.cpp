// -*-c++-*-
// Time-stamp: <2003-10-11 13:53:17 dhruva>
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

//------------------------ IMPLEMENTATION BEGINS ------------------------------

//-----------------------------------------------------------------------------
// GetLocalHostName
//-----------------------------------------------------------------------------
std::string
GetLocalHostName(void){
  DWORD chBuff=256;
  TCHAR buff[256];
  LPTSTR lpszSystemInfo;
  lpszSystemInfo=buff;
  DEBUGCHK(GetComputerName(lpszSystemInfo,&chBuff));
  return(std::string(lpszSystemInfo));
}

//-----------------------------------------------------------------------------
// RemoteLog
//-----------------------------------------------------------------------------
void
RemoteLog(char *message){
  if(g_pRemote)
    g_pRemote->AddLog(message);
  return;
}

//-----------------------------------------------------------------------------
// InitGlobals
//  Method to initialize all global values
//-----------------------------------------------------------------------------
void
InitGlobals(void){
  g_hIOCP=0;
  g_pRemote=0;
  g_pScenario=0;
  g_CrampServer[0]='\0';
  if(getenv("CRAMP_SERVER"))
    sprintf(g_CrampServer,"%s",getenv("CRAMP_SERVER"));
  else
    sprintf(g_CrampServer,"%s",GetLocalHostName().c_str());
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

#ifdef CRAMP_DEBUG
    // Write to mail slot
    sprintf(msg,"Created process %s",str.c_str());
    WriteToMailSlot(msg,g_CrampServer);
#endif

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
  BOOLEAN fDone=FALSE;
  TestCaseInfo *pScenario=(TestCaseInfo *)lpParameter;
  HANDLE h_mutex=0;
  h_mutex=OpenMutex(SYNCHRONIZE,TRUE,"MEMORY_MUTEX");
  if(!h_mutex)
    return(1);
  while(1){
    WaitForSingleObject(h_mutex,INFINITE);
    ActiveProcessMemoryDetails(pScenario);
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
ActiveProcessMemoryDetails(TestCaseInfo *ipScenario){
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
        WriteToPipe(msg,0,g_CrampServer);
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

//-----------------------------------------------------------------------------
// MailSlotServerTH
//-----------------------------------------------------------------------------
DWORD WINAPI
MailSlotServerTH(LPVOID iMailSlotName){
  if(!iMailSlotName)
    return(1);

  HANDLE h_mail=0;
  h_mail=CreateMailslot((char *)iMailSlotName,0,MAILSLOT_WAIT_FOREVER,NULL);
  DEBUGCHK(!(h_mail==INVALID_HANDLE_VALUE));

  // Mail slot server loop
  while(1){
    DWORD cbMessage=0,cMessage=0,cbRead=0;
    BOOL fResult;
    LPSTR lpszBuffer;
    DWORD cAllMessages;
    HANDLE h_event;
    OVERLAPPED ov;

    h_event=CreateEvent(NULL,FALSE,FALSE,"CRAMP_MAILSLOT");
    DEBUGCHK(h_event);
    ov.Offset=0;
    ov.OffsetHigh=0;
    ov.hEvent=h_event;
    fResult=GetMailslotInfo(h_mail,
                            (LPDWORD)NULL,
                            &cbMessage,
                            &cMessage,
                            (LPDWORD)NULL);
    DEBUGCHK(fResult);
    if(cbMessage==MAILSLOT_NO_MESSAGE)
      continue;
    cAllMessages=cMessage;

    // Mail slot loop
    while(cMessage){
      lpszBuffer=(LPSTR)GlobalAlloc(GPTR,cbMessage);
      DEBUGCHK(lpszBuffer);
      lpszBuffer[0]='\0';
      fResult=ReadFile(h_mail,
                       lpszBuffer,
                       cbMessage,
                       &cbRead,
                       &ov);
      if(fResult)
        RemoteLog(lpszBuffer);

      GlobalFree((HGLOBAL)lpszBuffer);
      fResult=GetMailslotInfo(h_mail,
                              (LPDWORD)NULL,
                              &cbMessage,
                              &cMessage,
                              (LPDWORD)NULL);
      DEBUGCHK(fResult);
    }
  }
  return(0);
}

//-----------------------------------------------------------------------------
// WriteToMailSlot
//  Does not provide a response, okay just to post messages
//-----------------------------------------------------------------------------
BOOLEAN
WriteToMailSlot(char *msg,char *server){
  if(!msg||!server)
    return(FALSE);
  BOOLEAN ret=FALSE;
  HANDLE h_file=0;
  DWORD cbWritten=0;
  char msname[MAX_PATH];
  sprintf(msname,"\\\\%s\\mailslot\\cramp_mailslot",server);
  h_file=CreateFile(msname,
                    GENERIC_WRITE,
                    FILE_SHARE_READ,
                    NULL,
                    OPEN_EXISTING,
                    FILE_ATTRIBUTE_NORMAL,
                    NULL);
  DEBUGCHK(!(h_file==INVALID_HANDLE_VALUE));

  // Format the message and write
  TCHAR msgbuff[1024];
  DWORD msgSz=0;
  msgSz=sprintf(msgbuff,"%s:%s",GetLocalHostName().c_str(),msg);
  ret=WriteFile(h_file,msgbuff,msgSz+1,&cbWritten,NULL);
  DEBUGCHK(ret);

  ret=CloseHandle(h_file);
  DEBUGCHK(ret);
  return(ret);
}

//-----------------------------------------------------------------------------
// MultiThreadedPipeServerTH
//  Assigns a new pipe connection for each request, use it to send large
//  chunks of data.
//-----------------------------------------------------------------------------
DWORD
MultiThreadedPipeServerTH(LPVOID iPipeName){
  if(!iPipeName)
    return(0);

  DWORD conn=0;
  BOOL fConnected;
  DWORD dwThreadId;
  HANDLE h_pipe=0,h_pth=0;

  while(1){
    h_pipe=CreateNamedPipe((char *)iPipeName,
                           PIPE_ACCESS_DUPLEX,
                           PIPE_TYPE_MESSAGE|PIPE_READMODE_MESSAGE|PIPE_WAIT,
                           PIPE_UNLIMITED_INSTANCES,
                           BUFSIZE,
                           BUFSIZE,
                           NMPWAIT_USE_DEFAULT_WAIT,
                           NULL);
    DEBUGCHK(!(h_pipe==INVALID_HANDLE_VALUE));

    fConnected=ConnectNamedPipe(h_pipe,NULL)?
      TRUE:(GetLastError()==ERROR_PIPE_CONNECTED);
    if(!fConnected){
      CloseHandle(h_pipe);
      continue;
    }
    HANDLE h_pth=0;
    h_pth=chBEGINTHREADEX(NULL,0,PipeInstanceTH,(LPVOID)h_pipe,0,NULL);
    DEBUGCHK(h_pth);
    CloseHandle(h_pth);
    conn++;
  }
  return(conn);
}

//-----------------------------------------------------------------------------
// PipeInstanceTH
//  A threaded instance of the pipe
//-----------------------------------------------------------------------------
VOID
PipeInstanceTH(LPVOID lpvParam){
  CHAR chRequest[BUFSIZE];
  CHAR chReply[BUFSIZE];
  DWORD cbBytesRead=0,cbReplyBytes=0,cbWritten=0;
  BOOL fSuccess;
  HANDLE h_pipe=0;

  h_pipe=(HANDLE)lpvParam;
  while(1){
    fSuccess=ReadFile(h_pipe,
                      chRequest,
                      BUFSIZE,
                      &cbBytesRead,
                      NULL);
    if(!fSuccess||0==cbBytesRead)
      break;

    if(!GetAnswerToRequest(chRequest,chReply,&cbReplyBytes))
      continue;
    fSuccess=WriteFile(h_pipe,
                       chReply,
                       cbReplyBytes,
                       &cbWritten,
                       NULL);
    if(!fSuccess||cbReplyBytes!=cbWritten)
      break;
  }
  FlushFileBuffers(h_pipe);
  DisconnectNamedPipe(h_pipe);
  CloseHandle(h_pipe);
  return;
}

//-----------------------------------------------------------------------------
// WriteToPipe
//  Writing through pipe creates a pipe instance and writes through it.
//  USE IT ONLY FOR LARGE CHUNKS OF DATA WITH CONFIRMATION
//-----------------------------------------------------------------------------
BOOLEAN
WriteToPipe(char *iMsg,char *oResponse,char *iServer){
  if(!iMsg||!iServer)
    return(FALSE);

  HANDLE h_pipe=0;
  LPVOID lpvMessage;
  CHAR chReadBuf[BUFSIZE];
  BOOL fSuccess;
  DWORD cbRead=0,cbWritten=0,dwMode=0;
  char pipename[MAX_PATH];
  sprintf(pipename,"\\\\%s\\pipe\\cramp_pipe",iServer);

  do{
    h_pipe=CreateFile(pipename,
                      GENERIC_READ|GENERIC_WRITE,
                      0,
                      NULL,
                      OPEN_EXISTING,
                      0,
                      NULL);
    DEBUGCHK(!(h_pipe==INVALID_HANDLE_VALUE));
    DEBUGCHK(!(GetLastError()==ERROR_PIPE_BUSY));
    // Wait for 20 secs for server...
    if(!WaitNamedPipe(pipename,20000)){
      CloseHandle(h_pipe);
      return(FALSE);
    }
  }while(0);

  dwMode=PIPE_READMODE_MESSAGE;
  fSuccess=SetNamedPipeHandleState(h_pipe,
                                   &dwMode,
                                   NULL,
                                   NULL);
  DEBUGCHK(fSuccess);

  char message[BUFSIZE];
  DWORD msgSz=0;
  msgSz=sprintf(message,"%s:%s",GetLocalHostName().c_str(),iMsg);

  fSuccess=TransactNamedPipe(h_pipe,
                             message,
                             msgSz+1,
                             chReadBuf,
                             BUFSIZE,
                             &cbRead,
                             NULL);
  if(oResponse)
    strcpy(oResponse,chReadBuf);

  CloseHandle(h_pipe);
  h_pipe=0;

  return(fSuccess);
}

//-----------------------------------------------------------------------------
// GetAnswerToRequest
//  Only for PIPE communication
//-----------------------------------------------------------------------------
BOOLEAN
GetAnswerToRequest(LPTSTR iRequest,LPTSTR oReply,LPDWORD oSize){
  strcpy(oReply,"OKAY");
  *oSize=strlen(oReply)*sizeof(char);
  RemoteLog(iRequest);
  return(TRUE);
}

#if 0
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
#endif
