// -*-c++-*-
// Time-stamp: <2003-10-14 11:10:32 dhruva>
//-----------------------------------------------------------------------------
// File : ipc.h
// Desc : Header for inter process communication using named pipes & mailslots
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#pragma once
#pragma warning (disable:4786)

#include <string>
// Process related
#include <process.h>

//------------------------ MACROS AND DEFINED ---------------------------------
#ifndef BUFSIZE
#define BUFSIZE 1024
#endif

//------------------------ MACROS AND DEFINED ---------------------------------

#ifndef __IPC_SRC
class CRAMPMessaging;
//--------------------------- FUNCTION PROTOTYPES -----------------------------
extern std::string GetLocalHostName(void);
extern DWORD WINAPI MailSlotServerTH(LPVOID);
extern BOOLEAN WriteToMailSlot(char *,char *);
extern VOID PipeInstanceTH(LPVOID);
extern DWORD MultiThreadedPipeServerTH(LPVOID);
extern BOOLEAN WriteToPipe(CRAMPMessaging *&);
//--------------------------- FUNCTION PROTOTYPES -----------------------------
#endif
