// -*-c++-*-
// Time-stamp: <2003-12-11 08:42:25 dhruva>
//-----------------------------------------------------------------------------
// File : PerfCounters.h
// Desc : Extract performance counters
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 12-09-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#pragma once
#pragma warning (disable:4786)

#include "cramp.h"
#include "TestCaseInfo.h"

#include <list>

#define MAX_COUNTERS 4
#define K_LANG "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Perflib\\009"

typedef struct{
  DWORD _pid;
  TestCaseInfo *_ptc;
}TCIPID;

#ifndef __PERFCOUNTERS_SRC
extern void WriteCounterData(void);
extern void CleanPIDCounterHash(void);
extern void RemovePIDCounterHash(DWORD);
extern BOOL UpdatePIDCounterHash(std::list<TCIPID> &);
#endif
