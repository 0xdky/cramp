// -*-c++-*-
// Time-stamp: <2003-10-14 11:25:59 dhruva>
//-----------------------------------------------------------------------------
// File: CallMonLOG.h
// Desc: Derived class to over ride the log file generation
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-30-2003  Mod                                                          dky
//-----------------------------------------------------------------------------
#define __CALLMONLOG_SRC

#include <Windows.h>
#include "CallMonLOG.h"

inline void offset(int level){
  for(int i=0;i<level;i++) putchar('\t');
}

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
  // offset(callInfoStack.size()-1);
  // std::string module,name;
  // getFuncInfo(ci.funcAddr,module,name);
  // printf("%d:%s:%s (%08X)\n",GetCurrentThreadId(),module.c_str(),
  //        name.c_str(),ci.funcAddr);
  return;
}

//-----------------------------------------------------------------------------
// logExit
//  Use this to output the profile information
//-----------------------------------------------------------------------------
void
CallMonLOG::logExit(CallInfo &ci,bool normalRet){
  // offset(callInfoStack.size()-1);

  TICKS ticksPerSecond;
  std::string module,name,rettype;
  if(!normalRet)
    rettype="exception";
  else
    rettype="normal";

  queryTickFreq(&ticksPerSecond);
  getFuncInfo(ci.funcAddr,module,name);
  // ThreadID|Module|Func|FuncAddr|Rettype|TimeMS|Ticks
  printf("%d|%s|%s|%08X|%s|%I64d|%I64d\n",
         GetCurrentThreadId(),
         module.c_str(),
         name.c_str(),
         ci.funcAddr,
         rettype.c_str(),
         (ci.endTime-ci.startTime)/(ticksPerSecond/1000),
         (ci.endTime-ci.startTime));

  // printf("%d:exit %08X, elapsed time=%I64d ms (%I64d ticks)\n",
  //        GetCurrentThreadId(),ci.funcAddr,
  //        (ci.endTime-ci.startTime)/(ticksPerSecond/1000),
  //        (ci.endTime-ci.startTime));
  return;
}
