// -*-c++-*-
// Time-stamp: <2003-11-01 19:03:38 dhruva>
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
  b_subproc=FALSE;
  b_pseudogroup=FALSE;

  s_name.erase();
  s_exec.erase();

  p_pgroup=0;
  p_refertc=0;

  u_uid=0;
  u_numruns=1;
  u_maxtimelimit=0;

  h_deltimer=0;
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
                           BOOLEAN iGroup,
                           BOOLEAN iBlock,
                           BOOLEAN iSubProc){
  Init();

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
    u_uid=hashstring(iUniqueID);
    if(FindTCFromUID(u_uid)){
      CRAMPException excep;
      excep._message="ERROR: ID is not unique!";
      excep._error=u_uid;
      throw(excep);
    }
  }

  b_block=iBlock;
  b_group=iGroup;
  b_subproc=iSubProc;
  p_pgroup=ipParentGroup;

  // Adding group/testcase to group. Scenario does not have parent!
  // Add this at end or you will find it and create a CYCLIC link!!
  if(p_pgroup){
    try{
      EnterCriticalSection(&cs_tci);
      p_pgroup->l_tci.push_back(this);
      LeaveCriticalSection(&cs_tci);
      ListOfTestCaseInfo &lgc=BlockListOfGC();
      lgc.push_back(this);
      // Assign some unique ID if not assigned to handle
      // log processing and do not set b_uid as this is generated!
      if(!b_uid){
        char uidstr[32];
        sprintf(uidstr,"CRAMP_NAME#%d",lgc.size());
        u_uid=hashstring(uidstr);
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
    if(pi_procinfo.hProcess)
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
  if(!iIDREF)
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
  HANDLE h_mutex=0;
  h_mutex=OpenMutex(SYNCHRONIZE,TRUE,GC_MUTEX);
  if(h_mutex){
    CloseHandle(h_mutex);
    CRAMPException excep;
    excep._error=ERROR_ALREADY_EXISTS;
    excep._message="ERROR: Another CRAMP process running currently!";
    SetLastError(excep._error);
    throw(excep);
  }

  h_mutex=CreateMutex(NULL,TRUE,GC_MUTEX);
  if(!h_mutex){
    CRAMPException excep;
    excep._error=ERROR_INVALID_HANDLE;
    excep._message="ERROR: Unable to create MUTEX object!";
    SetLastError(excep._error);
    throw(excep);
  }
  ReleaseMutex(h_mutex);

  try{
    TestCaseInfo::p_scenario=new TestCaseInfo(0,iUniqueID,TRUE,iBlock);
    DEBUGCHK(TestCaseInfo::p_scenario);
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
  DeleteCriticalSection(&g_CRAMP_Engine.g_cs_log);

  return(TRUE);
}

//-----------------------------------------------------------------------------
// AddGroup
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::AddGroup(const char *iUniqueID,
                        BOOLEAN iBlock){
  if(!GroupStatus()&&!PseudoGroupStatus())
    return(0);
  TestCaseInfo *pTCG=0;
  try{
    pTCG=new TestCaseInfo(this,iUniqueID,TRUE,iBlock,FALSE);
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
                           BOOLEAN iBlock,
                           BOOLEAN iSubProc){
  if(!iSubProc&&!GroupStatus()&&!PseudoGroupStatus())
    return(0);
  TestCaseInfo *pTC=0;
  try{
    pTC=new TestCaseInfo(this,iUniqueID,FALSE,iBlock,iSubProc);
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
// SubProcStatus
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::SubProcStatus(void){
  return(b_subproc);
}

//-----------------------------------------------------------------------------
// SubProcStatus
//-----------------------------------------------------------------------------
void
TestCaseInfo::SubProcStatus(BOOLEAN iIsSubProc){
  b_subproc=iIsSubProc;
  // To prevent this from being found for link or reference
  b_uid=FALSE;
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
  for(unsigned int ii=0;ii<iNumberOfRuns;ii++){
    TestCaseInfo *nptc=0;
    if(GroupStatus())
      nptc=AddGroup(0,BlockStatus());
    else
      nptc=AddTestCase(0,BlockStatus());
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
// TestCaseExec
//-----------------------------------------------------------------------------
std::string
&TestCaseInfo::TestCaseName(void){
  return(s_name);
}

//-----------------------------------------------------------------------------
// Name
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
  HANDLE h_mutex=0;
  h_mutex=OpenMutex(SYNCHRONIZE,TRUE,GC_MUTEX);
  if(!h_mutex){
    CRAMPException excep;
    excep._error=ERROR_INVALID_HANDLE;
    excep._message="ERROR: Cannot find l_gc mutex object";
    SetLastError(excep._error);
    throw(excep);
  }
  WaitForSingleObject(h_mutex,INFINITE);
  CloseHandle(h_mutex);
  return(l_gc);
}

//-----------------------------------------------------------------------------
// ReleaseListOfGC
//-----------------------------------------------------------------------------
void
TestCaseInfo::ReleaseListOfGC(void){
  HANDLE h_mutex=0;
  h_mutex=OpenMutex(SYNCHRONIZE,TRUE,GC_MUTEX);
  if(!h_mutex){
    CRAMPException excep;
    excep._error=ERROR_INVALID_HANDLE;
    excep._message="ERROR: Cannot find l_gc mutex object for release";
    SetLastError(excep._error);
    throw(excep);
  }
  DEBUGCHK(ReleaseMutex(h_mutex));
  CloseHandle(h_mutex);
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
TestCaseInfo::AddLog(std::string ilog){
  if(!g_CRAMP_Engine.g_fLogFile)
    return;

  EnterCriticalSection(&g_CRAMP_Engine.g_cs_log);
  fprintf(g_CRAMP_Engine.g_fLogFile,"%s\n",ilog.c_str());
  LeaveCriticalSection(&g_CRAMP_Engine.g_cs_log);

  return;
}
