// -*-c++-*-
// Time-stamp: <2003-10-15 15:44:15 dhruva>
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
#include "ipcmsg.h"
#include "TestCaseInfo.h"
#include <list>

//------------------------ MACROS AND DEFINED ---------------------------------
#define COMPKEY_TERMINATE  ((UINT_PTR) 0)
#define COMPKEY_STATUS     ((UINT_PTR) 1)
#define COMPKEY_JOBOBJECT  ((UINT_PTR) 2)

#ifndef BUFSIZE
#define BUFSIZE 1024
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

//-----------------------------------------------------------------------------
// CRAMPServerMessaging
//-----------------------------------------------------------------------------
class CRAMPServerMessaging : public CRAMPMessaging{
public:
  CRAMPServerMessaging();
  CRAMPServerMessaging(const char *iServer,BOOLEAN isPipe=TRUE);
  BOOLEAN Process(void);
};

#ifndef __ENGINE_SRC
//--------------------------- FUNCTION PROTOTYPES -----------------------------
extern void InitGlobals(void);
extern int DumpLogsToXML(char *);
extern DWORD WINAPI JobNotifyTH(LPVOID);
extern DWORD WINAPI CreateManagedProcesses(LPVOID);
extern DWORD WINAPI MemoryPollTH(LPVOID);
extern TestCaseInfo *GetTestCaseInfos(const char *);
extern BOOLEAN GetTestCaseMemoryDetails(HANDLE &,TestCaseInfo *&);
extern BOOLEAN ActiveProcessMemoryDetails(TestCaseInfo *,CRAMPMessaging *);
extern PROC_INFO *GetHandlesToActiveProcesses(HANDLE);
extern SIZE_T GetProcessHandleFromName(const char *,
                                       std::list<PROCESS_INFORMATION> &);
//--------------------------- FUNCTION PROTOTYPES -----------------------------

//--------------------------- GLOBAL VARIABLES --------------------------------
extern HANDLE g_hIOCP;               // Completion port that receives Job notif
extern TestCaseInfo *g_pScenario;    // Pointer to Scenario
extern char g_CrampServer[MAX_PATH]; // Cramp server name
//--------------------------- GLOBAL VARIABLES --------------------------------
#endif
