// -*-c++-*-
// Time-stamp: <2003-11-07 08:18:55 dhruva>
//-----------------------------------------------------------------------------
// File: CallMonLOG.h
// Desc: Derived class to over ride the log file generation
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-30-2003  Cre                                                          dky
// 09-30-2003  Mod  Made time in micro seconds                              dky
//-----------------------------------------------------------------------------
#define __CALLMONLOG_SRC

#include "CallMonLOG.h"

#include <queue>
#include <string>
#include <hash_map>

extern Global_CRAMP_Profiler g_CRAMP_Profiler;

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
  TICKS elapsedticks=(ci.endTime-ci.startTime-ci.ProfilingTicks);

  queryTickFreq(&ticksPerSecond);

  std::hash_map<ADDR,FuncInfo>::iterator iter;
  EnterCriticalSection(&g_CRAMP_Profiler.g_cs_prof);
  iter=g_CRAMP_Profiler.g_hFuncCalls.find(ci.funcAddr);
  if(iter==g_CRAMP_Profiler.g_hFuncCalls.end()){
    LeaveCriticalSection(&g_CRAMP_Profiler.g_cs_prof);
    return;
  }
  (*iter).second._totalticks+=elapsedticks;
  if((*iter).second._maxticks<elapsedticks)
    (*iter).second._maxticks=elapsedticks;
  LeaveCriticalSection(&g_CRAMP_Profiler.g_cs_prof);

  // For stats only
  if(!g_CRAMP_Profiler.g_fLogFile)
    return;

  EnterCriticalSection(&g_CRAMP_Profiler.g_cs_log);
  fprintf(g_CRAMP_Profiler.g_fLogFile,"%d|%08X|%d|%d|%I64d|%I64d\n",
          _tid,
          ci.funcAddr,
          callInfoStack.size(),
          !normalRet,
          elapsedticks/(ticksPerSecond/1000000),
          elapsedticks);
  LeaveCriticalSection(&g_CRAMP_Profiler.g_cs_log);

  return;
}
