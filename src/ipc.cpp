// -*-c++-*-
// Time-stamp: <2003-10-14 11:06:26 dhruva>
//-----------------------------------------------------------------------------
// File  : ipc.cpp
// Desc  : Contains code to do inter-process communication across computers
//         using named pipes or mail slot.
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 10-13-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __IPC_SRC

#include "cramp.h"
#include "engine.h"
#include "ipc.h"
#include "ipcmsg.h"

#include <stdio.h>
#include <tchar.h>
#include <stdlib.h>
#include <string.h>
#include <WindowsX.h>

//--------------------------- FUNCTION PROTOTYPES -----------------------------
std::string GetLocalHostName(void);
DWORD WINAPI MailSlotServerTH(LPVOID);
BOOLEAN WriteToMailSlot(char *,char *);
VOID PipeInstanceTH(LPVOID);
DWORD MultiThreadedPipeServerTH(LPVOID);
BOOLEAN WriteToPipe(CRAMPMessaging *&);
//--------------------------- FUNCTION PROTOTYPES -----------------------------

//------------------------ IMPLEMENTATION BEGINS ------------------------------

//-----------------------------------------------------------------------------
// GetLocalHostName
//-----------------------------------------------------------------------------
std::string
GetLocalHostName(void){
  DWORD chBuff=256;
  TCHAR buff[256];
  LPTSTR lpszSystemInfo;
  lpszSystemInfo=buff;
  DEBUGCHK(GetComputerName(lpszSystemInfo,&chBuff));
  return(std::string(lpszSystemInfo));
}

//-----------------------------------------------------------------------------
// MailSlotServerTH
//-----------------------------------------------------------------------------
DWORD WINAPI
MailSlotServerTH(LPVOID iMessageHandler){
  if(!iMessageHandler)
    return(1);

  HANDLE h_event=0;
  h_event=OpenEvent(EVENT_MODIFY_STATE|SYNCHRONIZE,FALSE,"THREAD_TERMINATE");
  if(!h_event)
    return(1);
  WaitForSingleObject(h_event,INFINITE);

  CRAMPMessaging *pmsg=0;
  pmsg=(CRAMPMessaging *)iMessageHandler;

  char filename[MAX_PATH];
  sprintf(filename,"\\\\%s\\mailslot\\cramp_mailslot",pmsg->Server().c_str());

  HANDLE h_mail=0;
  h_mail=CreateMailslot(filename,0,MAILSLOT_WAIT_FOREVER,NULL);
  if(h_mail==INVALID_HANDLE_VALUE)
    return(1);
  pmsg->FileHandle(h_mail);

  // Mail slot server loop
  DWORD wstate=-1;
  while(1){
    wstate=WaitForSingleObject(h_event,1000);
    if(WAIT_TIMEOUT==wstate||WAIT_FAILED==wstate)
      break;

    DWORD cbMessage=0,cMessage=0,cbRead=0;
    BOOL fResult;
    LPSTR lpszBuffer;
    DWORD cAllMessages;
    HANDLE h_event;
    OVERLAPPED ov;

    h_event=CreateEvent(NULL,FALSE,FALSE,"CRAMP_MAILSLOT");
    DEBUGCHK(h_event);
    ov.Offset=0;
    ov.OffsetHigh=0;
    ov.hEvent=h_event;
    fResult=GetMailslotInfo(h_mail,
                            (LPDWORD)NULL,
                            &cbMessage,
                            &cMessage,
                            (LPDWORD)NULL);
    DEBUGCHK(fResult);
    if(cbMessage==MAILSLOT_NO_MESSAGE)
      continue;
    cAllMessages=cMessage;

    // Mail slot loop
    while(cMessage){
      lpszBuffer=(LPSTR)GlobalAlloc(GPTR,cbMessage);
      DEBUGCHK(lpszBuffer);
      lpszBuffer[0]='\0';
      fResult=ReadFile(h_mail,
                       lpszBuffer,
                       cbMessage,
                       &cbRead,
                       &ov);
      if(!fResult)
        break;

      pmsg->Message(lpszBuffer);
      pmsg->Process();

      GlobalFree((HGLOBAL)lpszBuffer);
      fResult=GetMailslotInfo(h_mail,
                              (LPDWORD)NULL,
                              &cbMessage,
                              &cMessage,
                              (LPDWORD)NULL);
      if(!fResult)
        break;
    }
  }
  DEBUGCHK(ResetEvent(h_event));
  if(h_event)
    CloseHandle(h_event);
  h_event=0;
  return(0);
}

//-----------------------------------------------------------------------------
// MultiThreadedPipeServerTH
//  Assigns a new pipe connection for each request, use it to send large
//  chunks of data.
//-----------------------------------------------------------------------------
DWORD
MultiThreadedPipeServerTH(LPVOID ipMsg){
  if(!ipMsg)
    return(0);

  HANDLE h_event=0;
  h_event=OpenEvent(EVENT_MODIFY_STATE|SYNCHRONIZE,FALSE,"THREAD_TERMINATE");
  if(!h_event)
    return(1);
  WaitForSingleObject(h_event,INFINITE);

  CRAMPMessaging *pmsg=0;
  pmsg=(CRAMPMessaging *)ipMsg;

  DWORD conn=0;
  BOOL fConnected;
  DWORD dwThreadId;
  HANDLE h_pipe=0,h_pth=0;

  char filename[MAX_PATH];
  sprintf(filename,"\\\\%s\\pipe\\cramp_pipe",pmsg->Server().c_str());

  DWORD wstate=-1;
  while(1){
    wstate=WaitForSingleObject(h_event,1000);
    if(WAIT_TIMEOUT==wstate||WAIT_FAILED==wstate)
      break;
    h_pipe=CreateNamedPipe(filename,
                           PIPE_ACCESS_DUPLEX,
                           PIPE_TYPE_MESSAGE|PIPE_READMODE_MESSAGE|PIPE_WAIT,
                           PIPE_UNLIMITED_INSTANCES,
                           BUFSIZE,
                           BUFSIZE,
                           NMPWAIT_USE_DEFAULT_WAIT,
                           NULL);
    DEBUGCHK(!(h_pipe==INVALID_HANDLE_VALUE));
    fConnected=ConnectNamedPipe(h_pipe,NULL)?
      TRUE:(GetLastError()==ERROR_PIPE_CONNECTED);
    if(!fConnected){
      CloseHandle(h_pipe);
      continue;
    }
    HANDLE h_pth=0;
    pmsg->FileHandle(h_pipe);
    h_pth=chBEGINTHREADEX(NULL,0,PipeInstanceTH,(LPVOID)pmsg,0,NULL);
    DEBUGCHK(h_pth);
    CloseHandle(h_pth);
    conn++;
  }
  DEBUGCHK(0);
  DEBUGCHK(ResetEvent(h_event));
  if(h_event)
    CloseHandle(h_event);
  h_event=0;
  return(conn);
}

//-----------------------------------------------------------------------------
// PipeInstanceTH
//  A threaded instance of the pipe
//-----------------------------------------------------------------------------
VOID
PipeInstanceTH(LPVOID lpvParam){
  if(!lpvParam)
    return;

  HANDLE h_event=0;
  h_event=OpenEvent(EVENT_MODIFY_STATE|SYNCHRONIZE,FALSE,"THREAD_TERMINATE");
  if(!h_event)
    return;
  WaitForSingleObject(h_event,INFINITE);

  CHAR chRequest[BUFSIZE];
  CHAR chReply[BUFSIZE];
  DWORD cbBytesRead=0,cbReplyBytes=0,cbWritten=0;
  BOOL fSuccess;
  HANDLE h_pipe=0;

  CRAMPMessaging *pmsg=0;
  pmsg=(CRAMPMessaging *)lpvParam;
  h_pipe=pmsg->FileHandle();
  DWORD wstate=-1;
  while(1){
    wstate=WaitForSingleObject(h_event,1000);
    if(WAIT_TIMEOUT==wstate||WAIT_FAILED==wstate)
      break;
    fSuccess=ReadFile(h_pipe,
                      chRequest,
                      BUFSIZE,
                      &cbBytesRead,
                      NULL);
    if(!fSuccess)
      DEBUGCHK(0);
    if(0==cbBytesRead){
      Sleep(500);
      continue;
    }

    if(!stricmp(chRequest,"DISCONNECT"))
      break;

    pmsg->Message(chRequest);
    if(pmsg->Process()){
      std::string resp=pmsg->Response().c_str();
      fSuccess=WriteFile(h_pipe,
                         resp.c_str(),
                         resp.length(),
                         &cbWritten,
                         NULL);
      if(!fSuccess||cbReplyBytes!=cbWritten)
        DEBUGCHK(0);
    }
    FlushFileBuffers(h_pipe);
  }
  DEBUGCHK(ResetEvent(h_event));
  if(h_event)
    CloseHandle(h_event);
  h_event=0;

  delete pmsg;
  pmsg=0;
  return;
}

//-----------------------------------------------------------------------------
// WriteToMailSlot
//  Does not provide a response, okay just to post messages
//-----------------------------------------------------------------------------
BOOLEAN
WriteToMailSlot(CRAMPMessaging *&ioMsg){
  if(!ioMsg||!ioMsg->FileHandle())
    return(FALSE);
  BOOLEAN ret=FALSE;
  DWORD cbWritten=0;

  // Format the message and write
  TCHAR msgbuff[BUFSIZE];
  DWORD msgSz=0;
  msgSz=sprintf(msgbuff,"%s",ioMsg->Message().c_str());
  ret=WriteFile(ioMsg->FileHandle(),msgbuff,msgSz+1,&cbWritten,NULL);
  return(ret);
}

//-----------------------------------------------------------------------------
// WriteToPipe
//  Writing through pipe creates a pipe instance and writes through it.
//  USE IT ONLY FOR LARGE CHUNKS OF DATA WITH CONFIRMATION
//-----------------------------------------------------------------------------
BOOLEAN
WriteToPipe(CRAMPMessaging *&ioMsg){
  if(!ioMsg)
    return(FALSE);

  LPVOID lpvMessage;
  CHAR chReadBuf[BUFSIZE];
  BOOL fSuccess;
  DWORD cbRead=0,cbWritten=0,dwMode=0;

  char message[BUFSIZE];
  DWORD msgSz=0;
  if(stricmp(ioMsg->Message().c_str(),"DISCONNECT"))
    msgSz=sprintf(message,"%s:%s",
                  ioMsg->Server().c_str(),
                  ioMsg->Message().c_str());
  else
    msgSz=sprintf(message,"%s",ioMsg->Message().c_str());

  fSuccess=TransactNamedPipe(ioMsg->FileHandle(),
                             message,
                             msgSz+1,
                             chReadBuf,
                             BUFSIZE,
                             &cbRead,
                             NULL);
  if(fSuccess)
    ioMsg->Response(chReadBuf);
  return(fSuccess);
}
