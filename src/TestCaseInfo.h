// -*-c++-*-
// Time-stamp: <2003-11-03 11:10:54 dhruva>
//-----------------------------------------------------------------------------
// File : TestCaseInfo.h
// Desc : Header file with data structures
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#pragma once
#pragma warning (disable:4786)

#include <Windows.h>
#include <process.h>
#include <fstream.h>

#include <list>
#include <string>

// Could use CS instead of mutex
#define GC_MUTEX "GC_LIST_MUTEX"

//----------------------- GENERIC STRUCTS AND TYPEDEFS-------------------------
// For getting active processes
typedef struct{
  SIZE_T u_pid;
  HANDLE h_proc;
}PROC_INFO;

//-----------------------------------------------------------------------------
// Class: TestCaseInfo
//  Class holding the test scenerio details
//-----------------------------------------------------------------------------
class TestCaseInfo
{
public:
  // Never delete the memory of TestCaseInfo object directly
  void operator delete(void *ipTCI);
  ~TestCaseInfo();

  // To create a new scenario
  // Can throw CRAMPException on error
  static TestCaseInfo *CreateScenario(const char *iUniqueID=0,
                                      BOOLEAN iBlock=TRUE);

  // Use this to delete the whole scenario tree
  static BOOLEAN DeleteScenario(TestCaseInfo *ipScenario);

  // Must be called from the Scenario or a group
  TestCaseInfo *AddGroup(const char *ipUniqueID=0,
                         BOOLEAN iBlock=TRUE);
  // Must be called from the Scenario or a group
  TestCaseInfo *AddTestCase(const char *ipUniqueID=0,
                            BOOLEAN iBlock=TRUE,
                            BOOLEAN iSub=FALSE);

  // Can throw CRAMPException if reference is not valid
  void SetIDREF(const char *iIDREF);

  TestCaseInfo *GetParentGroup(void);

  // Use this to ensure thread safety
  // Call ReleaseListOfGC() after using the list
  // Can throw CRAMPException on error
  std::list<TestCaseInfo *> &BlockListOfGC(void);
  std::list<TestCaseInfo *> &BlockListOfTCI(void);
  // Call this to release the MUTEX object
  // Can throw CRAMPException on error
  void ReleaseListOfGC(void);
  void ReleaseListOfTCI(void);

  TestCaseInfo *Scenario(void);
  TestCaseInfo *Remote(void);

  BOOLEAN GroupStatus(void);
  // To support group like behaviour for
  // multi run entities
  BOOLEAN PseudoGroupStatus(void);

  BOOLEAN SubProcStatus(void);
  // Set this to monitor a running process
  // Will be monitored only if it is still running at the time of monitoring
  void SubProcStatus(BOOLEAN iIsSubProc);

  BOOLEAN RemoteStatus(void);

  BOOLEAN BlockStatus(void);
  void BlockStatus(BOOLEAN iIsBlocked);

  BOOLEAN ReferStatus(void);

  std::string &TestCaseName(void);
  void TestCaseName(const char *iName);

  std::string &TestCaseExec(void);
  void TestCaseExec(const char *iExec);

  // In milli seconds
  SIZE_T MonitorInterval(void);
  void MonitorInterval(SIZE_T iMonitorInterval);

  SIZE_T MaxTimeLimit(void);
  void MaxTimeLimit(SIZE_T iTime);

  SIZE_T NumberOfRuns(void);
  void NumberOfRuns(SIZE_T iNumberOfRuns);

  void AddLog(std::string ilog);

  // Internal methods: Not to be used other than in main engine
  TestCaseInfo *Reference(void);
  void Reference(TestCaseInfo *ipRefTC);
  void SetDelTimer(HANDLE ihTimer);
  PROCESS_INFORMATION &ProcessInfo(void);
  void ProcessInfo(PROCESS_INFORMATION iProcInfo);
  TestCaseInfo *FindTCFromPID(SIZE_T ipid);

private:
  BOOLEAN b_gc;                     // Marked for deletion
  BOOLEAN b_uid;                    // Has user specified UID
  BOOLEAN b_refer;                  // Should I refer an existing test case
  BOOLEAN b_group;                  // Is this a group
  BOOLEAN b_block;                  // Blocking or non blocking run
  BOOLEAN b_remote;                 // Is it for remote logging
  BOOLEAN b_subproc;                // Sub process, no execution
  BOOLEAN b_pseudogroup;            // Test case with multi run

  SIZE_T u_uid;                     // Unique ID to build references
  SIZE_T u_numruns;                 // Number of runs
  SIZE_T u_maxtimelimit;            // Max time limit for the process

  std::string s_uid;                // UID as string for logging
  std::string s_name;               // Executable for test case
  std::string s_exec;               // Executable for test case

  TestCaseInfo *p_pgroup;           // Pointer to the group this belongs to
  TestCaseInfo *p_refertc;          // Pointer to reference element

  std::list<TestCaseInfo *> l_tci;  // For groups, test cases are stored here

  // Process monitoring data
  std::string s_pname;              // Process name
  PROCESS_INFORMATION pi_procinfo;  // Test case's process information
  HANDLE h_deltimer;                // Timer to kill proc if time limited

  // Static declarations
  static SIZE_T u_moninterval;           // Memory monitoring interval
  static TestCaseInfo *p_scenario;       // Head pointer to search based on UID
  static TestCaseInfo *p_remote;         // For remote data collection
  static std::list<TestCaseInfo *> l_gc; // For garbage collection

  // Critical sections
  CRITICAL_SECTION cs_tci;          // Critical section for TCI
  CRITICAL_SECTION cs_pin;          // Critical section for Process Info
private:
  TestCaseInfo();
  // Throws an exception of type CRAMPException on error
  TestCaseInfo(TestCaseInfo *ipParent,
               const char *iUniqueID=0,
               BOOLEAN iGroup=FALSE,
               BOOLEAN iBlock=TRUE,
               BOOLEAN iSubProc=FALSE);

  // Internal methods
  inline void Init(void);
  inline SIZE_T hashstring(const char *s);
  void GroupStatus(BOOLEAN iIsGroup);
  void ReferStatus(BOOLEAN iIsReference);
  TestCaseInfo *FindTCFromUID(SIZE_T iuid);
  // First arg is the parent to which the "this" is getting added
  // We could have added "this" and avoided the 1st arg but if
  // invalid, we have to remove it. This is more expensive.
  BOOLEAN IsReferenceValid(TestCaseInfo *ipEntry,TestCaseInfo *ipGroup);
};
typedef std::list<TestCaseInfo *> ListOfTestCaseInfo;
