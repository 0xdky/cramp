// -*-c++-*-
// Time-stamp: <2003-10-03 15:49:32 dhruva>
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

// Process related
#include <process.h>
#include <basetsd.h>
#include <psapi.h>

//------------------------ MACROS AND DEFINED ---------------------------------
#define BARF() do{                                  \
    fprintf(g_LogFile,"%d:%s\n",__LINE__,__FILE__); \
    fflush(g_LogFile);                              \
  }while(0)

#define COMPKEY_TERMINATE  ((UINT_PTR) 0)
#define COMPKEY_STATUS     ((UINT_PTR) 1)
#define COMPKEY_JOBOBJECT  ((UINT_PTR) 2)

// User defined Unique ID's cannot be greater than this
#define AUTO_UNIQUE_BASE 55555
#define JOB_NAME "CRAMP_JOB"

// Courtesy: Jeffrey Richter
#ifdef _X86_
#define DebugBreak() _asm { int 3 }
#endif

#ifndef DEBUGCHK
#define DEBUGCHK(expr) if(!expr) DebugBreak()
#endif

typedef unsigned (__stdcall *PTHREAD_START) (void *);
#define chBEGINTHREADEX(psa, cbStack, pfnStartAddr,         \
                        pvParam, fdwCreate, pdwThreadId)    \
  ((HANDLE)_beginthreadex(                                  \
    (void *)        (psa),                                  \
    (unsigned)      (cbStack),                              \
    (PTHREAD_START) (pfnStartAddr),                         \
    (void *)        (pvParam),                              \
    (unsigned)      (fdwCreate),                            \
    (unsigned *)    (pdwThreadId)))

//------------------------ MACROS AND DEFINED ---------------------------------
