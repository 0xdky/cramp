// -*-c++-*-
// Time-stamp: <2003-10-01 10:11:43 dhruva>
//-----------------------------------------------------------------------------
// File : DllMain.cpp
// Desc : DllMain implementation for profiler
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#include <windows.h>
// Include derived class header here
#include "CallMonLOG.h"

BOOL WINAPI DllMain(
  HINSTANCE hinstDLL,
  DWORD fdwReason,
  LPVOID lpvReserved
  )
{
  CallMonitor::TICKS frequency=0;
  switch (fdwReason)
  {
    case DLL_PROCESS_ATTACH: // fall through
      CallMonitor::queryTickFreq(&frequency); // Initialize frequency ratio
    case DLL_THREAD_ATTACH:
      // Create instance of derived class below
      CallMonitor::threadAttach(new CallMonLOG);
      break;
    case DLL_THREAD_DETACH:  // fall through
    case DLL_PROCESS_DETACH:
      CallMonitor::threadDetach();
      break;
  }
  return TRUE;
}
//End of file
