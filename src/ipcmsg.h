// -*-c++-*-
// Time-stamp: <2003-10-14 13:08:38 dhruva>
//-----------------------------------------------------------------------------
// File : ipcmsg.h
// Desc : Header for messaging object for IPC
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#pragma once
#pragma warning (disable:4786)

#include <string>

// Class for handling client-server messaging
class CRAMPMessaging{
public:
  // For server to start threads
  CRAMPMessaging();
  // For client to write to server
  CRAMPMessaging(const char *iServer,BOOLEAN isAPipe=FALSE);
  virtual ~CRAMPMessaging();

  // Message
  virtual std::string Message(void);
  virtual void Message(std::string inMessage);

  // Process the message and generate a response
  virtual BOOLEAN Process(void);

  // Response
  virtual std::string Response(void);
  virtual void Response(std::string iResponse);

  BOOLEAN Pipe(void){return(b_pipe);};
  void Server(std::string iServer){s_server=iServer;};
  std::string Server(void){return(s_server);};

  void FileHandle(HANDLE iFileHandle){h_file=iFileHandle;};
  HANDLE FileHandle(void){return(h_file);};

private:
  HANDLE h_file;
  BOOLEAN b_pipe;
  std::string s_server;
  std::string s_inMessage;
  std::string s_outResponse;
};
