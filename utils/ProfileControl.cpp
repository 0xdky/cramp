// -*-c++-*-
// Time-stamp: <2003-12-03 10:44:40 dhruva>
//-----------------------------------------------------------------------------
// File  : ProfileControl.cpp
// Usage : ProfileControl.exe PROFILE_HOST PID START|STOP|FLUSH
// Desc  : Profiler control through IPC
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 12-03-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __PROFILECONTROL_SRC

#include <stdio.h>
#include <tchar.h>
#include <Windows.h>

//-----------------------------------------------------------------------------
// WinMain
//-----------------------------------------------------------------------------
int
WINAPI WinMain(HINSTANCE hinstExe,
               HINSTANCE,
               PSTR pszCmdLine,
               int nCmdShow){
  // Get the command line stuff
  int argcW=0;
  LPWSTR *argvW=0;
  argvW=CommandLineToArgvW(GetCommandLineW(),&argcW);
  if(!argvW)
    return(-1);
  if(argcW<4){
    GlobalFree(argvW);
    return(-1);
  }

  // Currently supports only 1 arg
  char *buff=0;
  char pid[256];
  char msg[256];
  char comp[256];
  char mspath[MAX_PATH];
  WideCharToMultiByte(CP_ACP,0,argvW[1],-1,
                      comp,256,0,0);
  WideCharToMultiByte(CP_ACP,0,argvW[2],-1,
                      pid,256,0,0);
  WideCharToMultiByte(CP_ACP,0,argvW[3],-1,
                      msg,256,0,0);
  sprintf(mspath,"\\\\%s\\mailslot\\cramp_mailslot#%s",comp,pid);

  HANDLE h_file=0;
  h_file=CreateFile(mspath,
                    GENERIC_WRITE,
                    FILE_SHARE_READ,
                    NULL,
                    OPEN_EXISTING,
                    FILE_ATTRIBUTE_NORMAL,
                    NULL);
  if(h_file==INVALID_HANDLE_VALUE)
    return(-1);

  DWORD cbWritten=0;
  int ret=0;
  ret=WriteFile(h_file,msg,strlen(msg)+1,&cbWritten,NULL);
  CloseHandle(h_file);
  h_file=0;

  return(!ret);
}
