// -*-c++-*-
// Time-stamp: <2003-10-16 11:22:07 dhruva>
//-----------------------------------------------------------------------------
// File: CallMonLOG.h
// Desc: Derived class to over ride the log file generation
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-30-2003  Mod                                                          dky
//-----------------------------------------------------------------------------
#define __CALLMONLOG_SRC

#include "CallMonLOG.h"

// To make it thread safe... Do not know when to delete!
CRITICAL_SECTION CallMonLOG::cs_log;

inline void offset(int level){
  for(int i=0;i<level;i++) putchar('\t');
}

//-----------------------------------------------------------------------------
// CallMonLOG
//-----------------------------------------------------------------------------
CallMonLOG::CallMonLOG(){
  f_logfile=0;
  char logfile[MAX_PATH];
  sprintf(logfile,"%s/cramp_profile#%d.log",
          getenv("CRAMP_LOGPATH"),
          GetCurrentProcessId());
  if(InitializeCriticalSectionAndSpinCount(&cs_log,4000L)){
    f_logfile=fopen(logfile,"a");
  }
  if(!f_logfile)
    f_logfile=stdout;
}

//-----------------------------------------------------------------------------
// CallMonLOG
//-----------------------------------------------------------------------------
CallMonLOG::CallMonLOG(const char *iLogFileName){
  f_logfile=0;
  if(InitializeCriticalSectionAndSpinCount(&cs_log,4000L)){
    f_logfile=fopen(iLogFileName,"a");
  }
  if(!f_logfile)
    f_logfile=stdout;
}

//-----------------------------------------------------------------------------
// ~CallMonLOG
//-----------------------------------------------------------------------------
CallMonLOG::~CallMonLOG(){
  if(f_logfile)
    fclose(f_logfile);
  f_logfile=0;
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

  EnterCriticalSection(&CallMonLOG::cs_log);
  // ThreadID|Module|Func|FuncAddr|Rettype|TimeMS|Ticks
  fprintf(f_logfile,"%d|%s|%s|%08X|%s|%I64d|%I64d\n",
          GetCurrentThreadId(),
          module.c_str(),
          name.c_str(),
          ci.funcAddr,
          rettype.c_str(),
          (ci.endTime-ci.startTime)/(ticksPerSecond/1000),
          (ci.endTime-ci.startTime));
  LeaveCriticalSection(&CallMonLOG::cs_log);

  return;
}
