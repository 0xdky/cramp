// -*-c++-*-
// Time-stamp: <2003-10-17 10:26:44 dhruva>
//-----------------------------------------------------------------------------
// File : DllMain.cpp
// Desc : DllMain implementation for profiler
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __DLLMAIN_SRC

#include "cramp.h"
// Include derived class header here
#include "CallMonLOG.h"

// To control profiling
extern long g_profile;
extern CRITICAL_SECTION cs_prof;

// Methods to toggle profiling programmatically
extern "C" __declspec(dllexport)
  void __declspec(naked) CRAMP_EnableProfile(void){
  __asm
  {
    PUSH EBP
      MOV  EBP , ESP
      PUSH EAX
      MOV  EAX , ESP
      SUB  ESP , __LOCAL_SIZE
      PUSHAD
      }

  InterlockedExchange(&g_profile,1);

  __asm
  {
    POPAD
      ADD ESP , __LOCAL_SIZE
      POP EAX
      MOV ESP , EBP
      POP EBP
      RET
      }
}

extern "C" __declspec(dllexport)
  void __declspec(naked) CRAMP_DisableProfile(void){
  __asm
  {
    PUSH EBP
      MOV  EBP , ESP
      PUSH EAX
      MOV  EAX , ESP
      SUB  ESP , __LOCAL_SIZE
      PUSHAD
      }

  InterlockedExchange(&g_profile,0);

  __asm
  {
    POPAD
      ADD ESP , __LOCAL_SIZE
      POP EAX
      MOV ESP , EBP
      POP EBP
      RET
      }
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL,
                    DWORD fdwReason,
                    LPVOID lpvReserved){

  CallMonitor::TICKS frequency=0;
  static BOOL valid=FALSE;

  switch (fdwReason)
  {
    case DLL_PROCESS_ATTACH:
      do{
        CallMonitor::queryTickFreq(&frequency);
        if(getenv("CRAMP_PROFILE"))
          InterlockedExchange(&g_profile,1);
        else
          InterlockedExchange(&g_profile,0);
        if(!InitializeCriticalSectionAndSpinCount(&cs_prof,4000L))
          break;
        valid=TRUE;
      }while(0);
    case DLL_THREAD_ATTACH:
      if(valid)
        CallMonitor::threadAttach(new CallMonLOG());
      break;
    case DLL_PROCESS_DETACH:
      if(valid)
        DeleteCriticalSection(&cs_prof);
    case DLL_THREAD_DETACH:
      if(valid)
        CallMonitor::threadDetach();
      break;
  }
  return(TRUE);
}
//End of file
