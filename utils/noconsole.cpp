// -*-c++-*-
// Time-stamp: <2004-03-03 13:54:42 dky>
//-----------------------------------------------------------------------------
// File  : noconsole.cpp
// Usage : noconsole.exe COMMAND [ARGUMENTS ....]
// Desc  : Launches console applications with out console window
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 03-03-2004  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __NOCONSOLE_SRC

#include "cramp.h"

//-----------------------------------------------------------------------------
// WinMain
//-----------------------------------------------------------------------------
int
WINAPI WinMain(HINSTANCE hinstExe,
               HINSTANCE,
               PSTR pszCmdLine,
               int nCmdShow){

    char argv[MAX_PATH];
    sprintf(argv,"%s",pszCmdLine);
    if(0==strlen(argv))
        return(-1);

    PROCESS_INFORMATION pi={0};
    STARTUPINFO sui={sizeof(STARTUPINFO)};
    return(!CreateProcess(NULL,
                          argv,
                          NULL,
                          NULL,
                          FALSE,
                          CREATE_NO_WINDOW,
                          NULL,
                          NULL,
                          &sui,
                          &pi));
}
