// -*-c++-*-
// Time-stamp: <2003-10-23 12:14:03 dhruva>
//-----------------------------------------------------------------------------
// File : cramp.h
// Desc : cramp header file
// Usage: Include this in all CRAMP source files
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#pragma once
#pragma warning (disable:4786)

// Needed for W2K
#define _WIN32_WINNT 0x0500

// Windows definitions
#include <Windows.h>

#ifndef __CALLMON_SRC
extern "C" void CRAMP_EnableProfile(void);
extern "C" void CRAMP_DisableProfile(void);
extern "C" void CRAMP_SetCallDepthLimit(long);
#endif
