// -*-c++-*-
// Time-stamp: <2003-10-14 11:05:53 dhruva>
//-----------------------------------------------------------------------------
// File  : ipcmsg.cpp
// Desc  : Contains code to for messaging object for IPC
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 10-13-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __IPCMSG_SRC

#include "cramp.h"
#include "ipcmsg.h"

#include <stdio.h>
#include <tchar.h>
#include <stdlib.h>
#include <string.h>
#include <WindowsX.h>

//-----------------------------------------------------------------------------
// CRAMPMessaging
//-----------------------------------------------------------------------------
CRAMPMessaging::CRAMPMessaging(){
  b_pipe=TRUE;
  h_file=0;
};

//-----------------------------------------------------------------------------
// CRAMPMessaging
//-----------------------------------------------------------------------------
CRAMPMessaging::CRAMPMessaging(const char *iServer,BOOLEAN isAPipe){
  h_file=0;
  b_pipe=isAPipe;

  BOOLEAN status=FALSE;
  do{
    if(!iServer)
      break;

    HANDLE h_event=0;
    h_event=OpenEvent(EVENT_MODIFY_STATE|SYNCHRONIZE,FALSE,"THREAD_TERMINATE");
    if(!h_event)
      break;
    DWORD wstate=-1;
    wstate=WaitForSingleObject(h_event,5000);
    if(WAIT_TIMEOUT==wstate||WAIT_FAILED==wstate)
      break;

    char filename[MAX_PATH];
    if(b_pipe){
      sprintf(filename,"\\\\%s\\pipe\\cramp_pipe",iServer);
      h_file=CreateFile(filename,
                        GENERIC_READ|GENERIC_WRITE,
                        0,
                        NULL,
                        OPEN_EXISTING,
                        0,
                        NULL);
      if(h_file==INVALID_HANDLE_VALUE)
        break;
      if(GetLastError()==ERROR_PIPE_BUSY)
        break;
      // Wait for 20 secs for server...
      if(!WaitNamedPipe(filename,20000)){
        CloseHandle(h_file);
        break;
      }
      DWORD dwMode=PIPE_READMODE_MESSAGE;
      if(!SetNamedPipeHandleState(h_file,&dwMode,NULL,NULL))
        break;
    }else{
      sprintf(filename,"\\\\%s\\mailslot\\cramp_mailslot",iServer);
      h_file=CreateFile(filename,
                        GENERIC_WRITE,
                        FILE_SHARE_READ,
                        NULL,
                        OPEN_EXISTING,
                        FILE_ATTRIBUTE_NORMAL,
                        NULL);
      if(h_file==INVALID_HANDLE_VALUE)
        break;
    }
    s_server=(*iServer);
    status=TRUE;
  }while(0);

  if(!status){
    CRAMPException excep;
    excep._message="Error:Unable to initialize connection to server";
    throw(excep);
  }
};

//-----------------------------------------------------------------------------
// ~CRAMPMessaging
//-----------------------------------------------------------------------------
CRAMPMessaging::~CRAMPMessaging(){
  s_server.erase();
  s_inMessage.erase();
  s_outResponse.erase();
  FlushFileBuffers(h_file);
  DisconnectNamedPipe(h_file);
  CloseHandle(h_file);
}

//-----------------------------------------------------------------------------
// Message
//-----------------------------------------------------------------------------
void
CRAMPMessaging::Message(std::string inMessage){
  s_inMessage=inMessage;
  return;
}

//-----------------------------------------------------------------------------
// Message
//-----------------------------------------------------------------------------
std::string
CRAMPMessaging::Message(void){
  return(s_inMessage);
}

//-----------------------------------------------------------------------------
// Process
//-----------------------------------------------------------------------------
BOOLEAN
CRAMPMessaging::Process(void){
  Response("OKAY");
  return(TRUE);
}

//-----------------------------------------------------------------------------
// Response
//-----------------------------------------------------------------------------
void
CRAMPMessaging::Response(std::string iResponse){
  s_inMessage=iResponse;
  return;
}

//-----------------------------------------------------------------------------
// Response
//-----------------------------------------------------------------------------
std::string
CRAMPMessaging::Response(void){
  return(s_outResponse);
}
