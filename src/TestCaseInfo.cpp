// -*-c++-*-
// Time-stamp: <2003-10-10 12:55:01 dhruva>
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

#include <xercesc/util/XMLString.hpp>
#include <xercesc/util/PlatformUtils.hpp>

#include <xercesc/dom/DOMAttr.hpp>
#include <xercesc/dom/DOMNode.hpp>
#include <xercesc/dom/DOMText.hpp>
#include <xercesc/dom/DOMElement.hpp>
#include <xercesc/dom/DOMDocument.hpp>

// Initialize static
ListOfTestCaseInfo TestCaseInfo::l_gc;

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
  b_subproc=FALSE;
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
                           BOOLEAN iBlock,
                           BOOLEAN iSubProc){
  Init();

  // Spin count may be used if on multi-processor
  if(!InitializeCriticalSectionAndSpinCount(&cs_log,4000L)){
    CRAMPException excep;
    excep._message="ERROR: Unable to initialize log critical section";
    excep._error=GetLastError();
    throw(excep);
  }
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
  }
  b_block=iBlock;
  b_group=iGroup;
  b_subproc=iSubProc;
  p_pgroup=ipParentGroup;
  p_scenario=(p_pgroup)?p_pgroup->Scenario():this;

  // Very important phase... Setting UID, establish links
  if(b_uid){
    TestCaseInfo *ptc=FindTCFromUID(u_uid);
    if(ptc){
      if(!IsReferenceValid(ipParentGroup,ptc)){
        CRAMPException excep;
        excep._message="ERROR: Cyclic dependency!";
        excep._error=u_uid;
        throw(excep);
      }
      // Since this is a reference, generate a uid
      u_uid=0;
      b_uid=FALSE;
      ReferStatus(TRUE);
      Reference(ptc);
    }
  }

  // Adding group/testcase to group. Scenerio does not have parent!
  // Add this at end or you will find it and create a CYCLIC link!!
  if(p_pgroup){
    try{
      EnterCriticalSection(&cs_tci);
      p_pgroup->l_tci.push_back(this);
      LeaveCriticalSection(&cs_tci);
      ListOfTestCaseInfo &lgc=BlockListOfGC();
      lgc.push_back(this);
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
  EnterCriticalSection(&cs_log);
  l_log.clear();
  LeaveCriticalSection(&cs_log);
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
  DeleteCriticalSection(&cs_log);
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
  return(p_scenario);
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
  if(!ipGroup||!ipGroup->GroupStatus())
    return(FALSE);
  BOOLEAN ret=TRUE;
  ListOfTestCaseInfo &l_tc=ipGroup->BlockListOfTCI();
  ListOfTestCaseInfo::iterator iter=l_tc.begin();
  for(;TRUE==ret&&iter!=l_tc.end();iter++){
    TestCaseInfo *ptc=(*iter);
    if(ptc->GroupStatus())
      if(ipEntry->u_uid==ptc->u_uid)
        ret=FALSE;
      else
        ret=IsReferenceValid(ipEntry,ptc);
  }
  ipGroup->ReleaseListOfTCI();
  return(ret);
}

//-----------------------------------------------------------------------------
// AddLog
//-----------------------------------------------------------------------------
void
TestCaseInfo::AddLog(std::string ilog){
  EnterCriticalSection(&cs_log);
  l_log.push_back(ilog);
  LeaveCriticalSection(&cs_log);
  return;
}

//-----------------------------------------------------------------------------
// DumpLog
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::DumpLog(ofstream &ifout){
  if(!ifout.is_open())
    return(FALSE);

  EnterCriticalSection(&cs_log);
  std::list<std::string>::iterator liter=l_log.begin();
  for(;liter!=l_log.end();liter++)
    ifout << (*liter).c_str() << endl;
  LeaveCriticalSection(&cs_log);

  ListOfTestCaseInfo::iterator iter=l_tci.begin();
  for(;iter!=l_tci.end();iter++)
    (*iter)->DumpLog(ifout);

  return(TRUE);
}

//-----------------------------------------------------------------------------
// DumpLogToDOM
//-----------------------------------------------------------------------------
BOOLEAN
TestCaseInfo::DumpLogToDOM(DOMNode *ipDomNode){
  if(!ipDomNode)
    return(FALSE);

  XMLCh xmlstr[256];
  DOMText *pDomText=0;
  DOMElement *pDomElem=0;
  DOMDocument *pDomDoc=0;

  // Get the document or factory
  pDomDoc=ipDomNode->getOwnerDocument();

  // Create the element
  if(GroupStatus()){
    if(GetParentGroup())
      XMLString::transcode("GROUP",xmlstr,255);
    else
      XMLString::transcode("SCENARIO",xmlstr,255);
  }else
    XMLString::transcode("TESTCASE",xmlstr,255);
  pDomElem=pDomDoc->createElement(xmlstr);
  ipDomNode->appendChild(pDomElem);

  // Create the text for element
  if(GroupStatus())
    XMLString::transcode(TestCaseName().c_str(),xmlstr,255);
  else
    XMLString::transcode(TestCaseExec().c_str(),xmlstr,255);
  pDomText=pDomDoc->createTextNode(xmlstr);
  pDomElem->appendChild(pDomText);

  EnterCriticalSection(&cs_log);
  std::list<std::string>::iterator liter=l_log.begin();
  for(;liter!=l_log.end();liter++){
    DOMElement *pDomChildElem=0;
    XMLString::transcode("LOG",xmlstr,255);
    pDomChildElem=pDomDoc->createElement(xmlstr);
    pDomElem->appendChild(pDomChildElem);
    XMLString::transcode((*liter).c_str(),xmlstr,255);
    pDomText=pDomDoc->createTextNode(xmlstr);
    pDomChildElem->appendChild(pDomText);
  }
  LeaveCriticalSection(&cs_log);

  ListOfTestCaseInfo::iterator iter=l_tci.begin();
  for(;iter!=l_tci.end();iter++)
    (*iter)->DumpLogToDOM(pDomElem);

  return(TRUE);
}
