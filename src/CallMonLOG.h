// -*-c++-*-
// Time-stamp: <2003-10-17 10:36:06 dhruva>
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
  ~CallMonLOG();

  void logEntry(CallInfo &ci);
  void logExit(CallInfo &ci,bool normalRet);
private:
};
