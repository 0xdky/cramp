// -*-c++-*-
// Time-stamp: <2003-12-09 14:11:37 dhruva>
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
#include <list>

#define MAX_COUNTERS 4
#define K_LANG "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Perflib\\009"

#ifndef __PERFCOUNTERS_SRC
extern BOOL GetNameStrings(void);
extern void WriteCounterData(void);
extern void CleanPIDCounterHash(void);
extern void RemovePIDCounterHash(DWORD);
extern BOOL UpdatePIDCounterHash(std::list<DWORD> &);
#endif
