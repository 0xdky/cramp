// -*-c++-*-
// Time-stamp: <2003-12-09 16:37:10 dhruva>
//-----------------------------------------------------------------------------
// File  : TestCaseInfo.cpp
// Desc  : Data structures for CRAMP
// TODO  :
//         o Add garbage collection and reuse of objects
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __TESTCASEINFO_SRC

#include "cramp.h"
#include "TestCaseInfo.h"

#include <algorithm>

// Initialize static
ListOfTestCaseInfo TestCaseInfo::l_gc;
SIZE_T TestCaseInfo::u_moninterval=1000;
TestCaseInfo *TestCaseInfo::p_remote=0;
TestCaseInfo *TestCaseInfo::p_scenario=0;

//-----------------------------------------------------------------------------
// ApplyDelete
//  Helper method
//-----------------------------------------------------------------------------
inline
void
ApplyDelete(TestCaseInfo *ipTC){
  if(!ipTC)
    return;
  ::delete ipTC;
  ipTC=0;
  return;
}

//-----------------------------------------------------------------------------
// Init
//-----------------------------------------------------------------------------
void
TestCaseInfo::Init(void){
  b_gc=FALSE;
  b_uid=FALSE;
  b_refer=FALSE;
  b_block=TRUE;
  b_group=FALSE;
  b_remote=FALSE;
  b_monproc=TRUE;
  b_exeproc=TRUE;
  b_subproc=FALSE;
  b_pseudogroup=FALSE;

  s_name.erase();
  s_exec.erase();

  p_pgroup=0;
  p_refertc=0;

  u_uid=0;
  u_flag=0;
  u_numruns=1;
  u_maxtimelimit=0;

  h_deltimer=0;
  memset(&pi_procinfo,0,sizeof(pi_procinfo));

  return;
}

//-----------------------------------------------------------------------------
// TestCaseInfo
//-----------------------------------------------------------------------------
TestCaseInfo::TestCaseInfo(){
}

//-----------------------------------------------------------------------------
// TestCaseInfo
//  Do not change the order of the code here
//  Throws an exception of SIZE_T on error
//-----------------------------------------------------------------------------
TestCaseInfo::TestCaseInfo(TestCaseInfo *ipParentGroup,
                           const char *iUniqueID,
                           SIZE_T iFlags){
  Init();
  u_flag=iFlags;

  // Spin count may be used if on multi-processor
  if(!InitializeCriticalSectionAndSpinCount(&cs_tci,4000L)){
    CRAMPException excep;
    excep._message="ERROR: Unable to initialize tci critical section";
    excep._error=GetLastError();
    throw(excep);
  }
  if(!InitializeCriticalSectionAndSpinCount(&cs_pin,4000L)){
    CRAMPException excep;
    excep._message="ERROR: Unable to initialize pin critical section";
    excep._error=GetLastError();
    throw(excep);
  }

  if(iUniqueID){
    b_uid=TRUE;
    s_uid=iUniqueID;
    u_uid=hashstring(iUniqueID);
    if(FindTCFromUID(u_uid)){
      CRAMPException excep;
      excep._message="ERROR: ID is not unique!";
      excep._error=u_uid;
      throw(excep);
    }
  }

  b_block=!!(iFlags&CRAMP_TC_BLOCK);
  b_group=!!(iFlags&CRAMP_TC_GROUP);
  p_pgroup=ipParentGroup;

  b_monproc=!!(iFlags&CRAMP_TC_MONPROC);
  b_exeproc=!!(iFlags&CRAMP_TC_EXEPROC);
  b_subproc=!!(iFlags&CRAMP_TC_SUBPROC);

  // Adding group/testcase to group. Scenario does not have parent!
  // Add this at end or you will find it and create a CYCLIC link!!
  if(p_pgroup){
    try{
      EnterCriticalSection(&cs_tci);
      p_pgroup->l_tci.push_back(this);
      SIZE_T sztci=p_pgroup->l_tci.size();
      LeaveCriticalSection(&cs_tci);
      ListOfTestCaseInfo &lgc=BlockListOfGC();
      lgc.push_back(this);
      // Assign some unique ID if not assigned to handle
      // log processing and do not set b_uid as this is generated!
      if(!b_uid){
        char uidstr[32];
        if(b_subproc)
          sprintf(uidstr,"%s_sp#%d",p_pgroup->s_uid.c_str(),sztci);
        else
          sprintf(uidstr,"%s_??#%d",p_pgroup->s_uid.c_str(),sztci);
        u_uid=hashstring(uidstr);
        s_uid=uidstr;
      }
      ReleaseListOfGC();
    }
    catch(CRAMPException excep){
      throw(excep);
    }
  }
}

//-----------------------------------------------------------------------------
// ~TestCaseInfo
//-----------------------------------------------------------------------------
TestCaseInfo::~TestCaseInfo(){
  if(GroupStatus()||PseudoGroupStatus()){
    EnterCriticalSection(&cs_tci);
    l_tci.clear();
    LeaveCriticalSection(&cs_tci);
  }else{
    // Do not check for thread, it is closed after creation
    // to avoid holding on to threads which have spawned other
    // threads and want to die
    if(!MonProcStatus()&&pi_procinfo.hProcess)
      CloseHandle(pi_procinfo.hProcess);
  }
  DeleteCriticalSection(&cs_tci);
  DeleteCriticalSection(&cs_pin);
  Init();
}

//-----------------------------------------------------------------------------
// delete
//  Manage using GC
//-----------------------------------------------------------------------------
void
TestCaseInfo::operator delete(void *ipTCI){
  if(!ipTCI)
    return;
  TestCaseInfo *ptc=(TestCaseInfo *)ipTCI;
  ptc->b_gc=TRUE;
  return;
}

//-----------------------------------------------------------------------------
// hashstring
//-----------------------------------------------------------------------------
SIZE_T
TestCaseInfo::hashstring(const char *s){
  if(!s)
    return(0);

  SIZE_T h=0;
  for(int i=0;s[i]!='\0';i+=1)
    h=(h<<5)-h+s[i];
  return(h);
}

//-----------------------------------------------------------------------------
// SetIDREF
//-----------------------------------------------------------------------------
void
TestCaseInfo::SetIDREF(const char *iIDREF){
  if(!iIDREF||!strlen(iIDREF))
    return;

  SIZE_T refid=hashstring(iIDREF);
  TestCaseInfo *ptc=FindTCFromUID(refid);
  if(ptc){
    if(!IsReferenceValid(ptc,GetParentGroup())){
      CRAMPException excep;
      excep._message="ERROR: Cyclic dependency!";
      excep._error=refid;
      throw(excep);
    }
    ReferStatus(TRUE);
    Reference(ptc);
  }else{
    CRAMPException excep;
    excep._message="ERROR: Reference not found!";
    excep._error=refid;
    throw(excep);
  }

  return;
}

//-----------------------------------------------------------------------------
// CreateScenario
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::CreateScenario(const char *iUniqueID,
                              BOOLEAN iBlock){
  SIZE_T iFlags=CRAMP_TC_GROUP;
  if(iBlock)
    iFlags|=CRAMP_TC_BLOCK;

  if(!InitializeCriticalSectionAndSpinCount(&g_CRAMP_Engine.g_cs_gc,4000L)){
    CRAMPException excep;
    excep._message="ERROR: Unable to initialize GC critical section";
    excep._error=GetLastError();
    throw(excep);
  }

  try{
    TestCaseInfo::p_scenario=new TestCaseInfo(0,iUniqueID,iFlags);
    DEBUGCHK(TestCaseInfo::p_scenario);
    PROCESS_INFORMATION pin={0};
    pin.dwProcessId=GetCurrentProcessId();
    TestCaseInfo::p_scenario->ProcessInfo(pin);

    TestCaseInfo::p_remote=TestCaseInfo::p_scenario->AddGroup("REMOTE");
    DEBUGCHK(TestCaseInfo::p_remote);
    TestCaseInfo::p_remote->b_remote=TRUE;
    TestCaseInfo::p_remote->TestCaseName("REMOTE");
  }
  catch(CRAMPException excep){
    DEBUGCHK(0);
  }

  return(TestCaseInfo::p_scenario);
}

//-----------------------------------------------------------------------------
// DeleteScenario
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::DeleteScenario(TestCaseInfo *ipScenario){
  if(!ipScenario||!ipScenario->GroupStatus()||ipScenario->GetParentGroup())
    return(FALSE);
  try{
    ListOfTestCaseInfo &lgc=ipScenario->BlockListOfGC();
    ListOfTestCaseInfo::iterator start=lgc.begin();
    ListOfTestCaseInfo::iterator end=lgc.end();
    std::for_each(start,end,ApplyDelete);
    ipScenario->ReleaseListOfGC();
  }
  catch(CRAMPException excep){
    // Do nothing now!
  }
  ::delete ipScenario;
  ipScenario=0;

  EnterCriticalSection(&g_CRAMP_Engine.g_cs_log);
  if(g_CRAMP_Engine.g_fLogFile)
    fclose(g_CRAMP_Engine.g_fLogFile);
  g_CRAMP_Engine.g_fLogFile=0;
  LeaveCriticalSection(&g_CRAMP_Engine.g_cs_log);

  DeleteCriticalSection(&g_CRAMP_Engine.g_cs_gc);
  DeleteCriticalSection(&g_CRAMP_Engine.g_cs_log);

  return(TRUE);
}

//-----------------------------------------------------------------------------
// AddGroup
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::AddGroup(const char *iUniqueID,
                        SIZE_T iFlag){
  if(!GroupStatus()&&!PseudoGroupStatus())
    return(0);

  TestCaseInfo *pTCG=0;
  iFlag=iFlag|CRAMP_TC_GROUP;

  try{
    pTCG=new TestCaseInfo(this,iUniqueID,iFlag);
  }
  catch(CRAMPException excep){
    DEBUGCHK(0);
  }

  return(pTCG);
}

//-----------------------------------------------------------------------------
// AddTestCase
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::AddTestCase(const char *iUniqueID,
                           SIZE_T iFlag){
  // Parent should either be MON/SUB OR Group/Pseudo
  if(!(MonProcStatus()||SubProcStatus()||GroupStatus()||PseudoGroupStatus()))
    return(0);

  // Unset the group setting
  iFlag=iFlag&~CRAMP_TC_GROUP;

  TestCaseInfo *pTC=0;
  try{
    pTC=new TestCaseInfo(this,iUniqueID,iFlag);
  }
  catch(CRAMPException excep){
    DEBUGCHK(0);
  }
  return(pTC);
}

//-----------------------------------------------------------------------------
// GetParentGroup
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::GetParentGroup(void){
  return(p_pgroup);
}

//-----------------------------------------------------------------------------
// PseudoGroupStatus
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::PseudoGroupStatus(void){
  return(b_pseudogroup);
}

//-----------------------------------------------------------------------------
// GroupStatus
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::GroupStatus(void){
  return(b_group);
}

//-----------------------------------------------------------------------------
// GroupStatus
//-----------------------------------------------------------------------------
void
TestCaseInfo::GroupStatus(BOOLEAN iIsGroup){
  b_group=iIsGroup;
  return;
}

//-----------------------------------------------------------------------------
// BlockStatus
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::BlockStatus(void){
  return(b_block);
}

//-----------------------------------------------------------------------------
// BlockStatus
//-----------------------------------------------------------------------------
void
TestCaseInfo::BlockStatus(BOOLEAN iIsBlocked){
  b_block=iIsBlocked;
  return;
}

//-----------------------------------------------------------------------------
// ExeProcStatus
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::ExeProcStatus(void){
  return(b_exeproc);
}

//-----------------------------------------------------------------------------
// ExeProcStatus
//-----------------------------------------------------------------------------
void
TestCaseInfo::ExeProcStatus(BOOLEAN iIsExeProc){
  b_exeproc=iIsExeProc;
  return;
}

//-----------------------------------------------------------------------------
// SubProcStatus
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::SubProcStatus(void){
  return(b_subproc);
}

//-----------------------------------------------------------------------------
// MonProcStatus
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::MonProcStatus(void){
  return(b_monproc);
}

//-----------------------------------------------------------------------------
// MonProcStatus
//-----------------------------------------------------------------------------
void
TestCaseInfo::MonProcStatus(BOOLEAN iIsMonProc){
  b_monproc=iIsMonProc;
  return;
}

//-----------------------------------------------------------------------------
// RemoteStatus
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::RemoteStatus(void){
  return(b_remote);
}

//-----------------------------------------------------------------------------
// ReferStatus
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::ReferStatus(void){
  return(b_refer);
}

//-----------------------------------------------------------------------------
// ReferStatus
//-----------------------------------------------------------------------------
void
TestCaseInfo::ReferStatus(BOOLEAN iIsReference){
  b_refer=iIsReference;
  return;
}

//-----------------------------------------------------------------------------
// NumberOfRuns
//-----------------------------------------------------------------------------
SIZE_T
TestCaseInfo::NumberOfRuns(void){
  return(u_numruns);
}

//-----------------------------------------------------------------------------
// NumberOfRuns
//-----------------------------------------------------------------------------
void
TestCaseInfo::NumberOfRuns(SIZE_T iNumberOfRuns){
  if(u_numruns==iNumberOfRuns)
    return;
  ListOfTestCaseInfo &ltc=BlockListOfTCI();
  ListOfTestCaseInfo::iterator iter=ltc.begin();
  for(;iter!=ltc.end();iter++)
    delete (*iter);
  ltc.clear();
  ReleaseListOfTCI();

  u_numruns=iNumberOfRuns;
  if(u_numruns<2)
    return;
  b_pseudogroup=TRUE;
  char id[256];

  for(unsigned int ii=0;ii<iNumberOfRuns;ii++){
    TestCaseInfo *nptc=0;
    sprintf(id,"%s#%d",s_uid.c_str(),ii+1);
    if(GroupStatus())
      nptc=AddGroup(id,u_flag);
    else
      nptc=AddTestCase(id,u_flag);
    DEBUGCHK(nptc);
    nptc->ReferStatus(TRUE);
    nptc->Reference(this);
  }
  return;
}

//-----------------------------------------------------------------------------
// MaxTimeLimit
//-----------------------------------------------------------------------------
SIZE_T
TestCaseInfo::MaxTimeLimit(void){
  return(u_maxtimelimit);
}

//-----------------------------------------------------------------------------
// MaxTimeLimit
//-----------------------------------------------------------------------------
void
TestCaseInfo::MaxTimeLimit(SIZE_T iMaxTimeLimit){
  u_maxtimelimit=iMaxTimeLimit;
  return;
}

//-----------------------------------------------------------------------------
// MonitorInterval
//-----------------------------------------------------------------------------
SIZE_T
TestCaseInfo::MonitorInterval(void){
  return(TestCaseInfo::u_moninterval);
}

//-----------------------------------------------------------------------------
// MonitorInterval
//-----------------------------------------------------------------------------
void
TestCaseInfo::MonitorInterval(SIZE_T iMonitorInterval){
  TestCaseInfo::u_moninterval=iMonitorInterval;
  return;
}

//-----------------------------------------------------------------------------
// TestCaseName
//-----------------------------------------------------------------------------
std::string
&TestCaseInfo::TestCaseName(void){
  return(s_name);
}

//-----------------------------------------------------------------------------
// TestCaseName
//-----------------------------------------------------------------------------
void
TestCaseInfo::TestCaseName(const char *iName){
  s_name=iName;
  return;
}

//-----------------------------------------------------------------------------
// TestCaseExec
//-----------------------------------------------------------------------------
std::string
&TestCaseInfo::TestCaseExec(void){
  return(s_exec);
}

//-----------------------------------------------------------------------------
// TestCaseExec
//-----------------------------------------------------------------------------
void
TestCaseInfo::TestCaseExec(const char *iExec){
  s_exec=iExec;
  return;
}

//-----------------------------------------------------------------------------
// SetDelTimer
//-----------------------------------------------------------------------------
void
TestCaseInfo::SetDelTimer(HANDLE ihTimer){
  if(h_deltimer){
    DeleteTimerQueueTimer(NULL,h_deltimer,NULL);
    CloseHandle(h_deltimer);
    h_deltimer=0;
  }
  h_deltimer=ihTimer;
  return;
}

//-----------------------------------------------------------------------------
// ProcessInfo
//-----------------------------------------------------------------------------
PROCESS_INFORMATION
&TestCaseInfo::ProcessInfo(void){
  return(pi_procinfo);
}

//-----------------------------------------------------------------------------
// ProcessInfo
//-----------------------------------------------------------------------------
void
TestCaseInfo::ProcessInfo(PROCESS_INFORMATION iProcInfo){
  EnterCriticalSection(&cs_pin);
  pi_procinfo=iProcInfo;
  LeaveCriticalSection(&cs_pin);
  return;
}

//-----------------------------------------------------------------------------
// BlockListOfGC
//-----------------------------------------------------------------------------
ListOfTestCaseInfo
&TestCaseInfo::BlockListOfGC(void){
  EnterCriticalSection(&g_CRAMP_Engine.g_cs_gc);
  return(l_gc);
}

//-----------------------------------------------------------------------------
// ReleaseListOfGC
//-----------------------------------------------------------------------------
void
TestCaseInfo::ReleaseListOfGC(void){
  LeaveCriticalSection(&g_CRAMP_Engine.g_cs_gc);
  return;
}

//-----------------------------------------------------------------------------
// BlockListOfTCI
//-----------------------------------------------------------------------------
ListOfTestCaseInfo
&TestCaseInfo::BlockListOfTCI(void){
  EnterCriticalSection(&cs_tci);
  return(l_tci);
}

//-----------------------------------------------------------------------------
// ReleaseListOfTCI
//-----------------------------------------------------------------------------
void
TestCaseInfo::ReleaseListOfTCI(void){
  LeaveCriticalSection(&cs_tci);
  return;
}

//-----------------------------------------------------------------------------
// Scenario
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::Scenario(void){
  return(TestCaseInfo::p_scenario);
}

//-----------------------------------------------------------------------------
// Remote
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::Remote(void){
  return(TestCaseInfo::p_remote);
}

//-----------------------------------------------------------------------------
// Reference
//  Gets the deep reference. Immediate reference is not useful
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::Reference(void){
  if(!ReferStatus())
    return(0);
  TestCaseInfo *ptc=p_refertc;
  while(ptc->ReferStatus())
    ptc=ptc->p_refertc;
  return(ptc);
}

//-----------------------------------------------------------------------------
// Reference
//-----------------------------------------------------------------------------
void
TestCaseInfo::Reference(TestCaseInfo *ipRefTC){
  p_refertc=ipRefTC;
  return;
}

//-----------------------------------------------------------------------------
// FindTCFromUID
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::FindTCFromUID(SIZE_T iuid){
  TestCaseInfo *pscenario=Scenario();
  if(!pscenario)
    return(0);

  TestCaseInfo *ptc=0;
  try{
    ListOfTestCaseInfo &lgc=BlockListOfGC();
    do{
      if(!lgc.size())
        break;
      ListOfTestCaseInfo::iterator iter=lgc.begin();
      for(;!ptc&&iter!=lgc.end();iter++)
        if((*iter)&&(*iter)->b_uid&&((*iter)->u_uid==iuid))
          ptc=(*iter);
    }while(0);
    ReleaseListOfGC();
  }
  catch(CRAMPException excep){
    DEBUGCHK(ptc);
  }
  return(ptc);
}

//-----------------------------------------------------------------------------
// FindTCFromPID
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::FindTCFromPID(SIZE_T ipid){
  TestCaseInfo *pscenario=Scenario();
  if(!pscenario)
    return(0);

  TestCaseInfo *ptc=0;
  try{
    ListOfTestCaseInfo &lgc=BlockListOfGC();
    do{
      if(!lgc.size())
        break;
      ListOfTestCaseInfo::iterator iter=lgc.begin();
      for(;!ptc&&iter!=lgc.end();iter++)
        if((*iter)&&((*iter)->ProcessInfo().dwProcessId==ipid))
          ptc=(*iter);
    }while(0);
    ReleaseListOfGC();
  }
  catch(CRAMPException excep){
    DEBUGCHK(ptc);
  }
  return(ptc);
}

//-----------------------------------------------------------------------------
// IsReferenceValid
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::IsReferenceValid(TestCaseInfo *ipEntry,
                               TestCaseInfo *ipGroup){
  if(!ipGroup&&!ipGroup->GroupStatus())
    return(FALSE);
  if(!ipEntry&&!ipEntry->GroupStatus()&&!ipEntry->PseudoGroupStatus())
    return(FALSE);
  if(ipEntry->u_uid==u_uid)
    return(FALSE);

  BOOLEAN ret=TRUE;
  ListOfTestCaseInfo &l_tc=ipEntry->BlockListOfTCI();
  ListOfTestCaseInfo::iterator iter=l_tc.begin();
  for(;TRUE==ret&&iter!=l_tc.end();iter++){
    TestCaseInfo *ptc=(*iter);
    if(ptc->GroupStatus())
      if(ipGroup->u_uid==ptc->u_uid)
        ret=FALSE;
      else
        ret=IsReferenceValid(ipEntry,ptc);
  }
  ipEntry->ReleaseListOfTCI();
  return(ret);
}

//-----------------------------------------------------------------------------
// AddLog
//-----------------------------------------------------------------------------
void
TestCaseInfo::AddLog(DWORD iRetVal){
  if(!g_CRAMP_Engine.g_fLogFile)
    return;

  PROCESS_INFORMATION &pin=ProcessInfo();
  if(!pin.dwProcessId)
    return;

  DWORD ec=0;
  char type[32]="??";
  char msg[BUFSIZE];
  SYSTEMTIME st={0};
  FILETIME ft[4],ftr={0};

  if(u_uid==g_CRAMP_Engine.g_pScenario->u_uid)
    pin.hProcess=GetCurrentProcess();

  do{
    if(SubProcStatus()){
      strcpy(type,"SP");
    }else if(ExeProcStatus()){
      strcpy(type,"TP");
    }else if(MonProcStatus()){
      strcpy(type,"MP");
    }else if(u_uid==g_CRAMP_Engine.g_pScenario->u_uid){
      strcpy(type,"SC");
    }else{
      return;                   // If Monitoring is disabled
    }

    // Some sub procs are too fast to get proc handle
    if(!pin.hProcess)
      break;

    GetExitCodeProcess(pin.hProcess,&ec);
    if(!GetProcessTimes(pin.hProcess,
                        &ft[0],&ft[1],&ft[2],&ft[3]))
      break;
    if(!FileTimeToLocalFileTime(&ft[0],&ft[2]))
      break;

    if(STILL_ACTIVE==ec){
      SYSTEMTIME lst={0};
      GetLocalTime(&lst);
      if(!SystemTimeToFileTime(&lst,&ft[3]))
        break;
    }else{
      if(!FileTimeToLocalFileTime(&ft[1],&ft[3]))
        break;
    }

    ftr.dwLowDateTime=ft[3].dwLowDateTime-ft[2].dwLowDateTime;
    ftr.dwHighDateTime=ft[3].dwHighDateTime-ft[2].dwHighDateTime;

    if(!FileTimeToSystemTime(&ftr,&st))
      break;

    if(STILL_ACTIVE==ec)
      ec=iRetVal;
  }while(0);

  if(ec)
    sprintf(msg,"%s|KO|%ld:%ld:%ld:%ld|%d",
            type,
            st.wHour,st.wMinute,st.wSecond,st.wMilliseconds,
            ec);
  else
    sprintf(msg,"%s|OK|%ld:%ld:%ld:%ld|%d",
            type,
            st.wHour,st.wMinute,st.wSecond,st.wMilliseconds,
            ec);
  AddLog(msg);

  return;
}

//-----------------------------------------------------------------------------
// AddLog
//-----------------------------------------------------------------------------
void
TestCaseInfo::AddLog(std::string ilog){
  if(!g_CRAMP_Engine.g_fLogFile||!ilog.length())
    return;

  char msg[BUFSIZE];
  if(RemoteStatus())
    sprintf(msg,"REMOTE");
  else
    sprintf(msg,"%s|%d",
            s_uid.c_str(),
            ProcessInfo().dwProcessId);

  EnterCriticalSection(&g_CRAMP_Engine.g_cs_log);

  if('#'==ilog[0])
    fprintf(g_CRAMP_Engine.g_fLogFile,"# %s|%s\n",
            msg,
            ilog.substr(1,ilog.length()).c_str());
  else
    fprintf(g_CRAMP_Engine.g_fLogFile,"%s|%s\n",msg,ilog.c_str());

  LeaveCriticalSection(&g_CRAMP_Engine.g_cs_log);

  return;
}
