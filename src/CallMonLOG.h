// -*-c++-*-
// Time-stamp: <2003-10-16 18:12:00 dhruva>
//-----------------------------------------------------------------------------
// File: CallMonLOG.h
// Desc: Derived class to over ride the log file generation
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-30-2003  Mod                                                          dky
//-----------------------------------------------------------------------------
#pragma once
#pragma warning (disable:4786)

#include "cramp.h"
#include "CallMon.h"

class CallMonLOG : public CallMonitor{
public:
  CallMonLOG();
  CallMonLOG(const char *iLogFileName);
  ~CallMonLOG();

  void logEntry(CallInfo &ci);
  void logExit(CallInfo &ci,bool normalRet);
private:
  static __int64 u_counter;
  static FILE *f_logfile;
  static FILE *f_callfile;
  static CRITICAL_SECTION cs_log;
  static CRITICAL_SECTION cs_call;
};
