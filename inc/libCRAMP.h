// -*-c++-*-
// Time-stamp: <2003-10-25 15:31:22 dhruva>
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

#ifndef __DLLMAIN_SRC
extern "C" void CRAMP_EnableProfile(void);
extern "C" void CRAMP_DisableProfile(void);
extern "C" void CRAMP_FlushProfileLogs(void);
extern "C" void CRAMP_SetCallDepthLimit(long);
#endif
