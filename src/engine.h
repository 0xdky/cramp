// -*-c++-*-
// Time-stamp: <2003-10-11 13:53:45 dhruva>
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
#include "TestCaseInfo.h"

//------------------------ MACROS AND DEFINED ---------------------------------
#define COMPKEY_TERMINATE  ((UINT_PTR) 0)
#define COMPKEY_STATUS     ((UINT_PTR) 1)
#define COMPKEY_JOBOBJECT  ((UINT_PTR) 2)

#ifndef BUFSIZE
#define BUFSIZE 1024
#endif

#ifdef __ENGINE_SRC
#define EXTERN
#else
#define EXTERN extern
#endif

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

//--------------------------- FUNCTION PROTOTYPES -----------------------------
EXTERN void InitGlobals(void);
EXTERN inline std::string GetLocalHostName(void);
EXTERN int DumpLogsToXML(char *);
EXTERN inline void RemoteLog(char *);
EXTERN DWORD WINAPI JobNotifyTH(LPVOID);
EXTERN DWORD WINAPI CreateManagedProcesses(LPVOID);
EXTERN DWORD WINAPI MemoryPollTH(LPVOID);
EXTERN TestCaseInfo *GetTestCaseInfos(const char *);
EXTERN BOOLEAN ActiveProcessMemoryDetails(TestCaseInfo *);
EXTERN PROC_INFO *GetHandlesToActiveProcesses(HANDLE);

EXTERN DWORD WINAPI MailSlotServerTH(LPVOID);
EXTERN BOOLEAN WriteToMailSlot(char *,char *);

EXTERN VOID PipeInstanceTH(LPVOID);
EXTERN DWORD MultiThreadedPipeServerTH(LPVOID);
EXTERN BOOLEAN WriteToPipe(char *,char *,char *);
EXTERN BOOLEAN GetAnswerToRequest(LPTSTR,LPTSTR,LPDWORD);

//--------------------------- FUNCTION PROTOTYPES -----------------------------

//--------------------------- GLOBAL VARIABLES --------------------------------
EXTERN HANDLE g_hIOCP;               // Completion port that receives Job notif
EXTERN TestCaseInfo *g_pScenario;    // Pointer to Scenario
EXTERN TestCaseInfo *g_pRemote;      // Pointer to remote log collection group
EXTERN char g_CrampServer[MAX_PATH]; // Cramp server name
//--------------------------- GLOBAL VARIABLES --------------------------------
