// -*-c++-*-
// Time-stamp: <2003-10-17 09:48:58 dhruva>
//-----------------------------------------------------------------------------
// File: CallMonLOG.h
// Desc: Derived class to over ride the log file generation
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-30-2003  Mod                                                          dky
//-----------------------------------------------------------------------------
#define __CALLMONLOG_SRC

#include "CallMonLOG.h"
#include "libCRAMP.h"

// To make it thread safe... Do not know when to delete!
__int64 CallMonLOG::u_counter=0;
FILE *CallMonLOG::f_logfile=0;
FILE *CallMonLOG::f_callfile=0;
CRITICAL_SECTION CallMonLOG::cs_log;
CRITICAL_SECTION CallMonLOG::cs_call;

inline void offset(int level){
  for(int i=0;i<level;i++) putchar('\t');
}

//-----------------------------------------------------------------------------
// CallMonLOG
//-----------------------------------------------------------------------------
CallMonLOG::CallMonLOG(){
  char filename[MAX_PATH];
  sprintf(filename,"%s/cramp_profile#%d.log",
          getenv("CRAMP_LOGPATH"),
          GetCurrentProcessId());

  if(InitializeCriticalSectionAndSpinCount(&cs_log,4000L)){
    if(!CallMonLOG::f_logfile)
      CallMonLOG::f_logfile=fopen(filename,"ac");
  }
  if(!CallMonLOG::f_logfile)
    CallMonLOG::f_logfile=stdout;

  sprintf(filename,"%s/cramp_call#%d.log",
          getenv("CRAMP_LOGPATH"),
          GetCurrentProcessId());
  if(InitializeCriticalSectionAndSpinCount(&cs_call,4000L)){
    if(!CallMonLOG::f_callfile)
      CallMonLOG::f_callfile=fopen(filename,"ac");
  }
  if(!CallMonLOG::f_callfile)
    CallMonLOG::f_callfile=stdout;
}

//-----------------------------------------------------------------------------
// CallMonLOG
//-----------------------------------------------------------------------------
CallMonLOG::CallMonLOG(const char *iLogFileName){
  char filename[MAX_PATH];
  sprintf(filename,"%s/%s_profile#%d.log",
          getenv("CRAMP_LOGPATH"),
          iLogFileName,
          GetCurrentProcessId());
  if(InitializeCriticalSectionAndSpinCount(&cs_log,4000L)){
    if(!CallMonLOG::f_logfile)
      CallMonLOG::f_logfile=fopen(filename,"ac");
  }
  if(!CallMonLOG::f_logfile)
    CallMonLOG::f_logfile=stdout;

  sprintf(filename,"%s/%s_call#%d.log",
          getenv("CRAMP_LOGPATH"),
          iLogFileName,
          GetCurrentProcessId());
  if(InitializeCriticalSectionAndSpinCount(&cs_call,4000L)){
    if(!CallMonLOG::f_callfile)
      CallMonLOG::f_callfile=fopen(filename,"ac");
  }
  if(!CallMonLOG::f_callfile)
    CallMonLOG::f_callfile=stdout;
}

//-----------------------------------------------------------------------------
// ~CallMonLOG
//-----------------------------------------------------------------------------
CallMonLOG::~CallMonLOG(){
  fflush(CallMonLOG::f_logfile);
  fflush(CallMonLOG::f_callfile);
}

//-----------------------------------------------------------------------------
// logEntry
//  Use this to generate function call graph
//-----------------------------------------------------------------------------
void
CallMonLOG::logEntry(CallInfo &ci){
  CallMonLOG::u_counter++;
  char msg[1024];
  msg[0]='\0';
  for(SIZE_T level=callInfoStack.size()-1;level>0;level--)
    strcat(msg,"\t");
  sprintf(msg,"%s%s:%s",msg,ci.modl.c_str(),ci.func.c_str());

  EnterCriticalSection(&CallMonLOG::cs_call);
  fprintf(CallMonLOG::f_callfile,"%s\n",msg);
  if(1000==CallMonLOG::u_counter){
    fflush(CallMonLOG::f_logfile);
    fflush(CallMonLOG::f_callfile);
    CallMonLOG::u_counter=0;
  }
  LeaveCriticalSection(&CallMonLOG::cs_call);

  return;
}

//-----------------------------------------------------------------------------
// logExit
//  Use this to output the profile information
//-----------------------------------------------------------------------------
void
CallMonLOG::logExit(CallInfo &ci,bool normalRet){
  TICKS ticksPerSecond;
  std::string module,name,rettype;
  if(!normalRet)
    rettype="exception";
  else
    rettype="normal";
  queryTickFreq(&ticksPerSecond);

  EnterCriticalSection(&CallMonLOG::cs_log);
  // ThreadID|Module|Func|FuncAddr|Rettype|TimeMS|Ticks
  fprintf(CallMonLOG::f_logfile,"%d|%s|%s|%08X|%s|%I64d|%I64d\n",
          GetCurrentThreadId(),
          ci.modl.c_str(),
          ci.func.c_str(),
          ci.funcAddr,
          rettype.c_str(),
          (ci.endTime-ci.startTime)/(ticksPerSecond/1000),
          (ci.endTime-ci.startTime));
  if(1000==CallMonLOG::u_counter){
    fflush(CallMonLOG::f_logfile);
    fflush(CallMonLOG::f_callfile);
    CallMonLOG::u_counter=0;
  }
  LeaveCriticalSection(&CallMonLOG::cs_log);

  return;
}
