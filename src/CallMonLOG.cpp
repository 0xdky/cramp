// -*-c++-*-
// Time-stamp: <2003-10-17 10:45:39 dhruva>
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

extern FILE *g_f_logfile;
extern FILE *g_f_callfile;
extern __int64 g_u_counter;

extern CRITICAL_SECTION g_cs_log;
extern CRITICAL_SECTION g_cs_call;

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
  fflush(g_f_logfile);
  fflush(g_f_callfile);
}

//-----------------------------------------------------------------------------
// logEntry
//  Use this to generate function call graph
//-----------------------------------------------------------------------------
void
CallMonLOG::logEntry(CallInfo &ci){
  char msg[1024];
  msg[0]='\0';
  for(SIZE_T level=callInfoStack.size()-1;level>0;level--)
    strcat(msg,"\t");
  sprintf(msg,"%s%s:%s",msg,ci.modl.c_str(),ci.func.c_str());

  EnterCriticalSection(&g_cs_call);
  g_u_counter++;
  fprintf(g_f_callfile,"%s\n",msg);
  if(1000==g_u_counter){
    fflush(g_f_logfile);
    fflush(g_f_callfile);
    g_u_counter=0;
  }
  LeaveCriticalSection(&g_cs_call);

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

  EnterCriticalSection(&g_cs_log);
  // ThreadID|Module|Func|FuncAddr|Rettype|TimeMS|Ticks
  fprintf(g_f_logfile,"%d|%s|%s|%08X|%s|%I64d|%I64d\n",
          GetCurrentThreadId(),
          ci.modl.c_str(),
          ci.func.c_str(),
          ci.funcAddr,
          rettype.c_str(),
          (ci.endTime-ci.startTime)/(ticksPerSecond/1000),
          (ci.endTime-ci.startTime));
  if(1000==g_u_counter){
    fflush(g_f_logfile);
    fflush(g_f_callfile);
    g_u_counter=0;
  }
  LeaveCriticalSection(&g_cs_log);

  return;
}
