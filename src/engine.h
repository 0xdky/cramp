// -*-c++-*-
// Time-stamp: <2003-10-07 11:56:19 dhruva>
//-----------------------------------------------------------------------------
// File : engine.h
// Desc : engine header file
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#pragma once
#pragma warning (disable:4786)

// Process related
#include <process.h>
#include <basetsd.h>
#include <psapi.h>

//------------------------ MACROS AND DEFINED ---------------------------------
#define COMPKEY_TERMINATE  ((UINT_PTR) 0)
#define COMPKEY_STATUS     ((UINT_PTR) 1)
#define COMPKEY_JOBOBJECT  ((UINT_PTR) 2)

// User defined Unique ID's cannot be greater than this
#define AUTO_UNIQUE_BASE 55555

// Courtesy: Jeffrey Richter
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
