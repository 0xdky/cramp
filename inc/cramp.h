// -*-c++-*-
// Time-stamp: <2003-10-23 13:00:47 dhruva>
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
#include <string>
#include <process.h>

//------------------------ MACROS AND DEFINED ---------------------------------
#define JOB_NAME "CRAMP_JOB"
#define CRAMP_PROFILE_LIMIT 1000

#define BARF() do{                                  \
    fprintf(g_LogFile,"%d:%s\n",__LINE__,__FILE__); \
    fflush(g_LogFile);                              \
  }while(0)

// Courtesy: Jeffrey Richter
#ifdef _X86_
#define DebugBreak() _asm { int 3 }
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

#ifndef DEBUGCHK
#define DEBUGCHK(expr) if(!expr) DebugBreak()
#endif
//------------------------ MACROS AND DEFINED ---------------------------------

//-----------------------------------------------------------------------------
// Class: CRAMPException
// Desc : A generic CRAMP exception class. Derive all cramp exceptions from
//        CRAMPException.
//-----------------------------------------------------------------------------
class CRAMPException{
public:
  CRAMPException(){};
  ~CRAMPException(){};

  SIZE_T _error;
  std::string _message;
};
