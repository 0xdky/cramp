// -*-c++-*-
// Time-stamp: <2003-10-23 16:37:11 dhruva>
//-----------------------------------------------------------------------------
// File: CallMonLOG.h
// Desc: Derived class to over ride the log file generation
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-30-2003  Mod                                                          dky
//-----------------------------------------------------------------------------
#define __CALLMONLOG_SRC

#include "CallMonLOG.h"
#include "ProfileLimit.h"

#include <queue>
#include <string>

extern CRITICAL_SECTION g_cs_log;
extern std::queue<std::string> g_LogQueue;

//-----------------------------------------------------------------------------
// CallMonLOG
//-----------------------------------------------------------------------------
CallMonLOG::CallMonLOG(){
}

//-----------------------------------------------------------------------------
// ~CallMonLOG
//-----------------------------------------------------------------------------
CallMonLOG::~CallMonLOG(){
}

//-----------------------------------------------------------------------------
// logEntry
//  Use this to generate function call graph
//-----------------------------------------------------------------------------
void
CallMonLOG::logEntry(CallInfo &ci){
  return;
}

//-----------------------------------------------------------------------------
// logExit
//  Use this to output the profile information
//-----------------------------------------------------------------------------
void
CallMonLOG::logExit(CallInfo &ci,bool normalRet){
  TICKS ticksPerSecond;
  queryTickFreq(&ticksPerSecond);

  char logmsg[256];
  sprintf(logmsg,"%d|%08X|%d|%d|%I64d|%I64d",
          GetCurrentThreadId(),
          ci.funcAddr,
          callInfoStack.size(),
          !normalRet,
          (ci.endTime-ci.startTime)/(ticksPerSecond/1000),
          (ci.endTime-ci.startTime));

  // Buffered output
  EnterCriticalSection(&g_cs_log);
  g_LogQueue.push(logmsg);
  LeaveCriticalSection(&g_cs_log);

  return;
}
