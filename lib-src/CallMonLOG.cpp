// -*-c++-*-
// Time-stamp: <2003-10-28 17:07:10 dhruva>
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

extern FILE *g_fLogFile;
extern CRITICAL_SECTION g_cs_log;
extern std::queue<std::string> g_LogQueue;

//-----------------------------------------------------------------------------
// CallMonLOG
//-----------------------------------------------------------------------------
CallMonLOG::CallMonLOG(){
  _tid=GetCurrentThreadId();
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

#if BUFFERED_OUTPUT
  char logmsg[256];
  sprintf(logmsg,"%d|%08X|%d|%d|%I64d|%I64d",
          _tid,
          ci.funcAddr,
          callInfoStack.size(),
          !normalRet,
          (ci.endTime-ci.startTime)/(ticksPerSecond/1000),
          (ci.endTime-ci.startTime));
  EnterCriticalSection(&g_cs_log);
  g_LogQueue.push(logmsg);
  LeaveCriticalSection(&g_cs_log);
#else
  EnterCriticalSection(&g_cs_log);
  fprintf(g_fLogFile,"%d|%08X|%d|%d|%I64d|%I64d\n",
          _tid,
          ci.funcAddr,
          callInfoStack.size(),
          !normalRet,
          (ci.endTime-ci.startTime)/(ticksPerSecond/1000),
          (ci.endTime-ci.startTime));
  LeaveCriticalSection(&g_cs_log);
#endif

  return;
}
