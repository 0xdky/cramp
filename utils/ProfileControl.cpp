// -*-c++-*-
// Time-stamp: <2004-06-21 17:57:15 dky>
//-----------------------------------------------------------------------------
// File  : ProfileControl.cpp
// Usage : ProfileControl.exe PROFILE_HOST PID START|STOP|FLUSH
// Desc  : Profiler control through IPC
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 12-03-2003  Cre                                                          dky
// 02-04-2004  Mod  Can give list of PID (comma separated) to control       dky
// 06-21-2004  Mod  Replace localhost with "." to support it as default     dky
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
    int ret=0;
    char *buff=0;
    char *pid=0;
    char msg[256];
    char comp[256];
    char mspath[MAX_PATH];
    char pidlist[MAX_PATH];
    HANDLE h_file=0;

    WideCharToMultiByte(CP_ACP,0,argvW[1],-1,
                        comp,256,0,0);
    WideCharToMultiByte(CP_ACP,0,argvW[2],-1,
                        pidlist,MAX_PATH,0,0);
    WideCharToMultiByte(CP_ACP,0,argvW[3],-1,
                        msg,256,0,0);

    // Use "." notation for local host
    if(!stricmp(comp,"localhost")){
        comp[0]='.';
        comp[1]='\0';
    }

    // Loop through all PID's
    pid=strtok(pidlist,",");
    while(pid){
        sprintf(mspath,"\\\\%s\\mailslot\\cramp_mailslot#%s",comp,pid);
        pid=strtok(NULL,",");

        h_file=CreateFile(mspath,
                          GENERIC_WRITE,
                          FILE_SHARE_READ,
                          NULL,
                          OPEN_EXISTING,
                          FILE_ATTRIBUTE_NORMAL,
                          NULL);
        if(h_file==INVALID_HANDLE_VALUE){
            ret=1;
            continue;
        }

        DWORD cbWritten=0;
        if(!WriteFile(h_file,msg,strlen(msg)+1,&cbWritten,NULL))
            ret=1;

        CloseHandle(h_file);
        h_file=0;
    }
    return(ret);
}
