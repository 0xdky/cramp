// -*-c++-*-
// Time-stamp: <2003-10-08 16:00:05 dhruva>
//-----------------------------------------------------------------------------
// File : TestCaseInfo.h
// Desc : Header file with data structures
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#pragma once
#pragma warning (disable:4786)

#include "Windows.h"
#include <process.h>

#include <list>
#include <string>
#include <fstream.h>

// User defined Unique ID's cannot be greater than this
#define AUTO_UNIQUE_BASE 55555
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
                            BOOLEAN iBlock=TRUE);

  TestCaseInfo *GetParentGroup(void);
  std::list<TestCaseInfo *> &GetListOfTCI(void);

  // Use this to ensure thread safety
  // Call ReleaseListOfGC() after using the list
  // Can throw CRAMPException on error
  std::list<TestCaseInfo *> &BlockListOfGC(void);
  // Call this to release the MUTEX object
  // Can throw CRAMPException on error
  void ReleaseListOfGC(void);

  TestCaseInfo *Scenario(void);

  BOOLEAN GroupStatus(void);
  // To support group like behaviour for
  // multi run entities
  BOOLEAN PseudoGroupStatus(void);

  BOOLEAN BlockStatus(void);
  void BlockStatus(BOOLEAN iIsBlocked);

  BOOLEAN ReferStatus(void);

  std::string &TestCaseName(void);
  void TestCaseName(const char *iName);

  std::string &TestCaseExec(void);
  void TestCaseExec(const char *iExec);

  SIZE_T MaxTimeLimit(void);
  void MaxTimeLimit(SIZE_T iTime);

  SIZE_T NumberOfRuns(void);
  void NumberOfRuns(SIZE_T iNumberOfRuns);

  void AddLog(std::string ilog);
  BOOLEAN DumpLog(ofstream &ifout);

  // Internal methods: Not to be used other than in main engine
  TestCaseInfo *Reference(void);
  void Reference(TestCaseInfo *ipRefTC);
  void SetDelTimer(HANDLE ihTimer);
  PROCESS_INFORMATION &ProcessInfo(void);
  void ProcessInfo(PROCESS_INFORMATION iProcInfo);

private:
  BOOLEAN b_gc;                     // Marked for deletion
  BOOLEAN b_refer;                  // Should I refer an existing test case
  BOOLEAN b_group;                  // Is this a group
  BOOLEAN b_block;                  // Blocking or non blocking run
  BOOLEAN b_pseudogroup;            // Test case with multi run

  SIZE_T u_uid;                     // Unique ID to build references
  SIZE_T u_numruns;                 // Number of runs
  SIZE_T u_maxtimelimit;            // Max time limit for the process

  std::string s_name;               // Executable for test case
  std::string s_exec;               // Executable for test case

  TestCaseInfo *p_pgroup;           // Pointer to the group this belongs to
  TestCaseInfo *p_refertc;          // Pointer to reference element
  TestCaseInfo *p_scenario;         // Head pointer to search based on UID

  std::list<std::string> l_log;     // Test case Log list
  std::list<TestCaseInfo *> l_tci;  // For groups, test cases are stored here

  // Process monitoring data
  std::string s_pname;              // Process name
  PROCESS_INFORMATION pi_procinfo;  // Test case's process information
  HANDLE h_deltimer;                // Timer to kill proc if time limited

public:
  // For garbage collection:At Scenerio
  static std::list<TestCaseInfo *> l_gc;

private:
  TestCaseInfo();
  // Throws an exception of type CRAMPException on error
  TestCaseInfo(TestCaseInfo *ipParent,
               const char *iUniqueID=0,
               BOOLEAN iGroup=FALSE,
               BOOLEAN iBlock=TRUE);

  // Internal methods
  inline void Init(void);
  SIZE_T UniqueID(void);
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
