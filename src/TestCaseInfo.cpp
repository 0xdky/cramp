// -*-c++-*-
// Time-stamp: <2003-10-08 12:08:00 dhruva>
//-----------------------------------------------------------------------------
// File  : TestCaseInfo.cpp
// Desc  : Data structures for CRAMP
// TODO  :
//         o Add garbage collection and reuse of objects
//         o Fix the Number of run issue
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#include "cramp.h"
#include "TestCaseInfo.h"
#include <algorithm>

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
  b_refer=FALSE;
  b_block=TRUE;
  b_group=FALSE;
  b_pseudogroup=FALSE;

  s_name.erase();
  s_exec.erase();

  p_pgroup=0;
  p_refertc=0;
  p_scenario=0;

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
                           BOOLEAN iBlock){
  Init();

  if(iUniqueID)
    u_uid=hashstring(iUniqueID);
  b_block=iBlock;
  b_group=iGroup;
  p_pgroup=ipParentGroup;
  p_scenario=(p_pgroup)?p_pgroup->Scenario():this;

  // Very important phase... Setting UID, establish links
  if(0!=u_uid){
    TestCaseInfo *ptc=FindTCFromUID(u_uid);
    if(ptc){
      if(!IsReferenceValid(ipParentGroup,ptc)){
        CRAMPException excep;
        excep._message="ERROR: Cyclic dependency!";
        excep._error=u_uid;
        throw(excep);
      }
      ReferStatus(TRUE);
      Reference(ptc);
    }
  }

  // Adding group/testcase to group. Scenerio does not have parent!
  // Add this at end or you will find it and create a CYCLIC link!!
  if(p_pgroup){
    try{
      ListOfTestCaseInfo lgc=GetListOfGC();
      p_pgroup->l_tci.push_back(this);
      lgc.push_back(this);
      if(!u_uid)
        u_uid=AUTO_UNIQUE_BASE+lgc.size();
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
    l_tci.clear();
  }else{
    // Do not check for thread, it is closed after creation
    // to avoid holding on to threads which have spawned other
    // threads and want to die
    if(pi_procinfo.hProcess)
      CloseHandle(pi_procinfo.hProcess);
  }
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

  if(!CreateMutex(NULL,FALSE,GC_MUTEX)){
    CRAMPException excep;
    excep._error=ERROR_INVALID_HANDLE;
    excep._message="ERROR: Unable to create MUTEX object!";
    SetLastError(excep._error);
    throw(excep);
  }

  TestCaseInfo *pScenario=0;
  try{
    pScenario=new TestCaseInfo(0,iUniqueID,TRUE,iBlock);
  }
  catch(CRAMPException excep){
    DEBUGCHK(0);
  }

  return(pScenario);
}

//-----------------------------------------------------------------------------
// DeleteScenario
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::DeleteScenario(TestCaseInfo *ipScenario){
  if(!ipScenario||!ipScenario->GroupStatus()||ipScenario->GetParentGroup())
    return(FALSE);
  try{
    ListOfTestCaseInfo lgc=ipScenario->GetListOfGC();
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
  return(TRUE);
}

//-----------------------------------------------------------------------------
// AddGroup
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::AddGroup(const char *iUniqueID,BOOLEAN iBlock){
  if(!GroupStatus()&&!PseudoGroupStatus())
    return(0);
  TestCaseInfo *pTCG=0;
  try{
    pTCG=new TestCaseInfo(this,iUniqueID,TRUE,iBlock);
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
*TestCaseInfo::AddTestCase(const char *iUniqueID,BOOLEAN iBlock){
  if(!GroupStatus()&&!PseudoGroupStatus())
    return(0);
  TestCaseInfo *pTC=0;
  try{
    pTC=new TestCaseInfo(this,iUniqueID,FALSE,iBlock);
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
// ReferStatus
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::ReferStatus(void){
  return(b_refer);
}

//-----------------------------------------------------------------------------
// BlockStatus
//-----------------------------------------------------------------------------
void
TestCaseInfo::ReferStatus(BOOLEAN iIsReference){
  b_refer=iIsReference;
  return;
}

//-----------------------------------------------------------------------------
// UniqueID
//-----------------------------------------------------------------------------
SIZE_T
TestCaseInfo::UniqueID(void){
  return(u_uid);
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
  ListOfTestCaseInfo ltc=GetListOfTCI();
  ListOfTestCaseInfo::iterator iter=ltc.begin();
  for(;iter!=ltc.end();iter++)
    delete (*iter);
  ltc.clear();
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
  pi_procinfo=iProcInfo;
  return;
}

//-----------------------------------------------------------------------------
// GetListOfGC
//-----------------------------------------------------------------------------
ListOfTestCaseInfo
&TestCaseInfo::GetListOfGC(void){
  DEBUGCHK(Scenario());
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
  return(Scenario()->l_gc);
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
  CloseHandle(h_mutex);
  ReleaseMutex(h_mutex);
  return;
}

//-----------------------------------------------------------------------------
// GetListOfTCI
//-----------------------------------------------------------------------------
ListOfTestCaseInfo
&TestCaseInfo::GetListOfTCI(void){
  return(l_tci);
}

//-----------------------------------------------------------------------------
// Scenario
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::Scenario(void){
  return(p_scenario);
}

//-----------------------------------------------------------------------------
// Reference
//-----------------------------------------------------------------------------
TestCaseInfo
*TestCaseInfo::Reference(void){
  if(!ReferStatus())
    return(0);
  return(p_refertc);
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
    ListOfTestCaseInfo lgc=GetListOfGC();
    do{
      if(!lgc.size())
        break;
      ListOfTestCaseInfo::iterator iter=pscenario->l_gc.begin();
      for(;iter!=pscenario->l_gc.end();iter++){
        TestCaseInfo *pttc=(*iter);
        if(!pttc)
          continue;
        if(pttc->UniqueID()==iuid){
          if(pttc->ReferStatus())
            ptc=pttc->Reference();
          else
            ptc=pttc;
          break;
        }
      }
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
  if(!ipGroup||!ipGroup->GroupStatus())
    return(FALSE);
  BOOLEAN ret=TRUE;
  ListOfTestCaseInfo l_tc=ipGroup->GetListOfTCI();
  ListOfTestCaseInfo::iterator iter=l_tc.begin();
  for(;TRUE==ret&&iter!=l_tc.end();iter++){
    TestCaseInfo *ptc=(*iter);
    if(ptc->GroupStatus())
      if(ipEntry->UniqueID()==ptc->UniqueID())
        ret=FALSE;
      else
        ret=IsReferenceValid(ipEntry,ptc);
  }
  return(ret);
}

//-----------------------------------------------------------------------------
// AddLog
//-----------------------------------------------------------------------------
void
TestCaseInfo::AddLog(std::string ilog){
  l_log.push_back(ilog);
  return;
}

//-----------------------------------------------------------------------------
// DumpLog
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::DumpLog(ofstream &ifout){
  if(!ifout.is_open())
    return(FALSE);
  std::list<std::string>::iterator iter=l_log.begin();
  for(;iter!=l_log.end();iter++){
    ifout << (*iter).c_str() << endl;
  }
  return(TRUE);
}
