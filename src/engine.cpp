// -*-c++-*-
// Time-stamp: <2003-11-20 12:10:02 dhruva>
//-----------------------------------------------------------------------------
// File  : engine.cpp
// Misc  : C[ramp] R[uns] A[nd] M[onitors] P[rocesses]
// Desc  : Create a job, process inside the job which may create further
//         processes. Add a callback on the job to notify when a process
//         is added to the job. A timer to monitor the processes in the job.
// TODO  :
//         o Logging syntax
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

//--------------------------- FUNCTION PROTOTYPES -----------------------------
void InitGlobals(void);
DWORD WINAPI JobNotifyTH(LPVOID);
DWORD WINAPI CreateManagedProcesses(LPVOID);
DWORD WINAPI MemoryPollTH(LPVOID);
TestCaseInfo *GetTestCaseInfos(const char *);
BOOLEAN GetTestCaseMemoryDetails(HANDLE &,TestCaseInfo *&);
BOOLEAN ActiveProcessMemoryDetails(TestCaseInfo *);
PROC_INFO *GetHandlesToActiveProcesses(HANDLE);
SIZE_T GetProcessHandleFromName(const char *,std::list<PROCESS_INFORMATION> &);
//--------------------------- FUNCTION PROTOTYPES -----------------------------

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
  if(!g_CRAMP_Engine.g_pScenario)
    return(FALSE);
  TestCaseInfo *prem=0;
  prem=g_CRAMP_Engine.g_pScenario->Remote();
  if(!prem)
    return(FALSE);
  std::string &msg=Message();
  if(!msg.length())
    return(FALSE);
  if(std::string::npos==msg.find(GetLocalHostName()))
    prem->AddLog(Message());
  return(TRUE);
}

//-----------------------------------------------------------------------------
// InitGlobals
//  Method to initialize all global values
//-----------------------------------------------------------------------------
void
InitGlobals(void){
  g_CRAMP_Engine.g_hJOB=0;
  g_CRAMP_Engine.g_hIOCP=0;
  g_CRAMP_Engine.g_hJOBTimer=0;

  g_CRAMP_Engine.g_fLogFile=0;
  g_CRAMP_Engine.g_pScenario=0;

  g_CRAMP_Engine.g_l_stopengine=0;
  g_CRAMP_Engine.g_scenariostatus=0;
  return;
}

//-----------------------------------------------------------------------------
// JOBTimeLimitReachedCB
//-----------------------------------------------------------------------------
void CALLBACK
JOBTimeLimitReachedCB(PVOID data,BOOLEAN iTT){
  g_CRAMP_Engine.g_pScenario->AddLog("# SCENARIO Timeout");
  TerminateJobObject(g_CRAMP_Engine.g_hJOB,WAIT_TIMEOUT);
  g_CRAMP_Engine.g_scenariostatus=WAIT_TIMEOUT;
  InterlockedExchange(&g_CRAMP_Engine.g_l_stopengine,1);
  return;
}

//-----------------------------------------------------------------------------
// GetTestCaseInfos
//  Internally, call the XML parser and get a list of test cases
//  This does some updation like getting proc info for subprocs...
//-----------------------------------------------------------------------------
TestCaseInfo
*GetTestCaseInfos(const char *ifile){
  if(!ifile)
    return(0);
  XMLParse xml(ifile);
  if(!xml.ParseXMLFile())
    return(0);
  TestCaseInfo *pScenario=0;
  pScenario=xml.GetScenario();

  return(pScenario);
}

//-----------------------------------------------------------------------------
// GetHandlesToActiveProcesses
//  Not used...
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
  if(!ipTestCaseInfo||!g_CRAMP_Engine.g_hJOB)
    return(-1);

  long dest=1;
  InterlockedCompareExchange(&dest,0,g_CRAMP_Engine.g_l_stopengine);
  if(!dest)
    return(WAIT_TIMEOUT);

  DWORD dwret=-1;
  SIZE_T psz=0;
  char msg[256];
  HANDLE *tharr=0;
  std::string str;
  SIZE_T numgroups=0;
  ListOfTestCaseInfo l_tci;
  PROCESS_INFORMATION *ppi=0;
  TestCaseInfo *pTopTC=(TestCaseInfo *)ipTestCaseInfo;

  // If remote node, just skip it
  if(pTopTC->RemoteStatus())
    return(0);

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
        dwret=CreateManagedProcesses(ptc);
        if(dwret){
          sprintf(msg,"# Failed to start:%d",dwret);
          porigtc->AddLog(msg);
        }
      }else if(tc<numgroups){
        tharr[tc]=chBEGINTHREADEX(NULL,0,CreateManagedProcesses,ptc,0,NULL);
        tc++;
      }
      continue;
    }else if(!ptc->ExeProcStatus()){
      // Keep updating the monitoring process dynamically
      ptc->MonProcStatus(porigtc->MonProcStatus());
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
      dwret=-1;
      porigtc->AddLog("# Failed to start:-1");
      continue;
    }

    BOOLEAN ret=FALSE;
    ret=AssignProcessToJobObject(g_CRAMP_Engine.g_hJOB,pi.hProcess);
    if(!ret){
      TerminateProcess(pi.hProcess,1);
      dwret=-1;
      porigtc->AddLog("# Failed to add to job:-1");
      continue;
    }

    // Set some process information
    porigtc->ProcessInfo(pi);

    if(blocked){
      ResumeThread(pi.hThread);
      CloseHandle(pi.hThread);
      SIZE_T maxwait=porigtc->MaxTimeLimit();
      if(!maxwait)
        maxwait=INFINITE;
      dwret=WaitForSingleObject(pi.hProcess,maxwait);
      if(WAIT_OBJECT_0==dwret||!dwret){
        dwret=0;
      }else if(WAIT_TIMEOUT==dwret){
        TerminateProcess(pi.hProcess,dwret);
        dwret=0;
      }else if(WAIT_ABANDONED==dwret){
        TerminateProcess(pi.hProcess,WAIT_ABANDONED);
      }else if(WAIT_FAILED==dwret){
        TerminateProcess(pi.hProcess,WAIT_FAILED);
      }
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
    for(cc=0;cc<numgroups;cc++)
      ptharr[psz+cc]=tharr[cc];

    for(cc=0;cc<psz;cc++){
      ResumeThread(ppi[cc].hThread);
      CloseHandle(ppi[cc].hThread);
    }

    SIZE_T maxwait=pTopTC->MaxTimeLimit();
    if(!maxwait)
      maxwait=INFINITE;
    dwret=WaitForMultipleObjects(psz+numgroups,ptharr,TRUE,maxwait);
    if(WAIT_TIMEOUT==dwret){
      for(int yy=0;yy<psz;yy++)
        TerminateProcess(ptharr[yy],WAIT_TIMEOUT);
      for(int zz=0;zz<numgroups;zz++)
        TerminateThread(tharr[zz],WAIT_TIMEOUT);
    }else{
      dwret=0;
    }

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

  SIZE_T monint=0;
  monint=g_CRAMP_Engine.g_pScenario->MonitorInterval();
  while(1){
    long dest=1;
    InterlockedCompareExchange(&dest,0,g_CRAMP_Engine.g_l_stopengine);
    if(!dest||!g_CRAMP_Engine.g_pScenario)
      break;
    ActiveProcessMemoryDetails(g_CRAMP_Engine.g_pScenario);
    Sleep(monint);
  }
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

  ListOfTestCaseInfo lgc;
  try{
    // Copy it to improve performance
    lgc=ipScenario->BlockListOfGC();
    ipScenario->ReleaseListOfGC();
  }
  catch(CRAMPException excep){
    DEBUGCHK(0);
  }

  if(!lgc.size())
    return(TRUE);

  // Get the memory snap shot
  HANDLE h_snapshot=0;
  h_snapshot=CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  DEBUGCHK(!(h_snapshot==INVALID_HANDLE_VALUE));

  std::list<PROCESS_INFORMATION> lpin;
  ListOfTestCaseInfo::iterator iter=lgc.begin();
  for(;iter!=lgc.end();iter++){
    TestCaseInfo *ptc=(*iter);
    if(!ptc||!ptc->MonProcStatus())
      continue;

    if(ptc->ExeProcStatus()){
      GetTestCaseMemoryDetails(h_snapshot,ptc);
      continue;
    }

    lpin.clear();
    if(!GetProcessHandleFromName(ptc->TestCaseExec().c_str(),lpin))
      continue;

    std::list<PROCESS_INFORMATION>::iterator lpiniter=lpin.begin();
    for(;lpiniter!=lpin.end();lpiniter++){
      PROCESS_INFORMATION pin=(*lpiniter);
      ptc->ProcessInfo(pin);
      GetTestCaseMemoryDetails(h_snapshot,ptc);
      CloseHandle(pin.hProcess);
      pin.hProcess=0;
    }
  }
  CloseHandle(h_snapshot);
  ret=TRUE;
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
    GetQueuedCompletionStatus(g_CRAMP_Engine.g_hIOCP,
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
          ptc=g_CRAMP_Engine.g_pScenario->FindTCFromPID((SIZE_T)po);
          do{
            // Has test case created a sub process?
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

            ptc=g_CRAMP_Engine.g_pScenario->FindTCFromPID(ppid);
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
              pctc=ptc->AddTestCase(0,ptc->Flag()|CRAMP_TC_SUBPROC);
              DEBUGCHK(pctc);
              pctc->ProcessInfo(pin);
              pctc->TestCaseName("Sub Process");
              pctc->TestCaseExec(ppe.szExeFile);
            }
            catch(CRAMPException excep){
            }
          }while(0);
          if(ptc)
            ptc->AddLog("# Process added");
          break;
        case JOB_OBJECT_MSG_EXIT_PROCESS:
          ptc=g_CRAMP_Engine.g_pScenario->FindTCFromPID((SIZE_T)po);
          if(!ptc)
            break;
          ptc->AddLog("# Normal exit");
          break;
        case JOB_OBJECT_MSG_ABNORMAL_EXIT_PROCESS:
          ptc=g_CRAMP_Engine.g_pScenario->FindTCFromPID((SIZE_T)po);
          if(!ptc)
            break;
          ptc->AddLog("# Abnormal exit");
          break;
        case JOB_OBJECT_MSG_END_OF_JOB_TIME:
          JOBTimeLimitReachedCB(NULL,FALSE);
          break;
        case JOB_OBJECT_TERMINATE_AT_END_OF_JOB:
          InterlockedExchange(&g_CRAMP_Engine.g_l_stopengine,1);
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
          // fprintf(g_CRAMP_Engine.g_LogFile,"%d:Unknown event in Job:%d\n",
          //         (SIZE_T)po,dwBytesXferred);
          break;
      }
      CompKey=1;
    }
  }
  InterlockedExchange(&g_CRAMP_Engine.g_l_stopengine,1);
  return(0);
}

//-----------------------------------------------------------------------------
// GetProcessHandleFromName
//-----------------------------------------------------------------------------
SIZE_T
GetProcessHandleFromName(const char *iProcName,
                         std::list<PROCESS_INFORMATION> &olPIN){
  if(!iProcName)
    return(0);

  DWORD aProcesses[1024],cbNeeded,cProcesses;
  if(!EnumProcesses(aProcesses,sizeof(aProcesses),&cbNeeded))
    return(0);

  SIZE_T found=0;
  HMODULE hMod=0;
  HANDLE h_proc=0;
  char ext[_MAX_EXT];
  char szProcName[1024];
  char szShortName[1024]="unknown";
  char szLongName[1024]="unknown";

  cProcesses=cbNeeded/sizeof(DWORD);
  for(unsigned int i=0;i<cProcesses;i++){
    h_proc=OpenProcess(PROCESS_QUERY_INFORMATION|PROCESS_VM_READ,
                       FALSE,aProcesses[i]);
    if(!h_proc)
      continue;

    if(!EnumProcessModules(h_proc,&hMod,sizeof(hMod),&cbNeeded))
      continue;

    cbNeeded=1024;
    if(!GetModuleFileNameEx(h_proc,hMod,szShortName,cbNeeded))
      continue;
    if(!GetLongPathName(szShortName,szLongName,cbNeeded))
      continue;

    strcpy(szProcName,iProcName);

    // Get filename with ext
    _splitpath(szLongName,0,0,szLongName,ext);
    strcat(szLongName,ext);

    if(!strstr(_strlwr(szProcName),_strlwr(szLongName))){
      CloseHandle(h_proc);
      h_proc=0;
      continue;
    }

    PROCESS_INFORMATION pin={0};
    pin.dwProcessId=aProcesses[i];
    pin.hProcess=h_proc;
    olPIN.push_back(pin);
    found++;
  }

  return(found);
}

//-----------------------------------------------------------------------------
// GetTestCaseMemoryDetails
//-----------------------------------------------------------------------------
BOOLEAN
GetTestCaseMemoryDetails(HANDLE &h_snapshot,TestCaseInfo *&ipTestCase){
  if(!h_snapshot||!ipTestCase)
    return(FALSE);

  PROCESS_MEMORY_COUNTERS pmc={0};
  PROCESS_INFORMATION pin=ipTestCase->ProcessInfo();
  if(!pin.hProcess)
    return(TRUE);
  DWORD pstat=0;
  GetExitCodeProcess(pin.hProcess,&pstat);
  if(STILL_ACTIVE!=pstat)
    return(TRUE);

  BOOLEAN ret=FALSE;
  PROCESSENTRY32 ppe={0};
  ppe.dwSize=sizeof(PROCESSENTRY32);
  ret=Process32First(h_snapshot,&ppe);
  char msg[BUFSIZE];
  for(;ret;ret=Process32Next(h_snapshot,&ppe)){
    if(pin.dwProcessId!=ppe.th32ProcessID)
      continue;

#if 0
    // Disable detailed memory information logging
    sprintf(msg,"LOG|MEMORY|PROC|SUMMARY|Count %d,Threads %d",
            ppe.cntUsage,ppe.cntThreads);
    ipTestCase->AddLog(msg);
#endif

    // Add process's RAM, later PDH
    do{
      if(!GetProcessMemoryInfo(pin.hProcess,&pmc,sizeof(pmc)))
        break;
      // Actual RAM pmc.WorkingSetSize;
      sprintf(msg,"# RAM: %ld bytes",pmc.WorkingSetSize);
      ipTestCase->AddLog(msg);
    }while(0);

    // Disable detailed memory information logging
    return(TRUE);

    // Get a module snap shot... this could be cached in the test case
    HANDLE h_snapmod=0;
    h_snapmod=CreateToolhelp32Snapshot(TH32CS_SNAPMODULE,ppe.th32ProcessID);
    DEBUGCHK(!(h_snapmod==INVALID_HANDLE_VALUE));
    MODULEENTRY32 me={0};
    me.dwSize=sizeof(MODULEENTRY32);
    BOOLEAN mret=FALSE;
    mret=Module32First(h_snapmod,&me);
    for(;mret;mret=Module32Next(h_snapmod,&me)){
      sprintf(msg,"LOG|MEMORY|MOD|SUMMARY|Name %s",me.szModule);
      ipTestCase->AddLog(msg);

      // Walk the module memory
      BYTE *pbase=me.modBaseAddr;
      DWORD bsz=0;
      MEMORY_BASIC_INFORMATION mbi={0};
      bsz=VirtualQueryEx(pin.hProcess,pbase,&mbi,sizeof(mbi));
      if(!bsz)
        break;

      PVOID pvRgnBaseAddress=mbi.AllocationBase;
      PVOID pvAddressBlk=pvRgnBaseAddress;
      SIZE_T freesz=0,commitsz=0,reservesz=0;
      do{
        bsz=VirtualQueryEx(pin.hProcess,pvAddressBlk,&mbi,sizeof(mbi));
        if(!bsz)
          break;

        switch(mbi.State){
          case MEM_COMMIT:
            commitsz+=mbi.RegionSize;
            break;
          case MEM_FREE:
            freesz+=mbi.RegionSize;
            break;
          case MEM_RESERVE:
            reservesz+=mbi.RegionSize;
            break;
          default:
            break;
        }
        pvAddressBlk=(PVOID)((PBYTE) pvAddressBlk+mbi.RegionSize);
      }while(mbi.AllocationBase==pvRgnBaseAddress);

      // To handle error in walking through module's memory
      if(!bsz)
        continue;

      sprintf(msg,"LOG|MEMORY|MOD|VM|Commit %ld,Free %ld,Reserve %ld",
              commitsz,freesz,reservesz);
      ipTestCase->AddLog(msg);
    }
  }
  return(TRUE);
}
