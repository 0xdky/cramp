// -*-c++-*-
// Time-stamp: <2003-10-17 18:20:30 dhruva>
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
