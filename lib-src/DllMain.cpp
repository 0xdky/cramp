// -*-c++-*-
// Time-stamp: <2003-10-17 18:11:36 dhruva>
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
long g_l_profile=0;
FILE *g_f_logfile=0;
FILE *g_f_callfile=0;
__int64 g_u_counter=0;

CRITICAL_SECTION g_cs_log;
CRITICAL_SECTION g_cs_call;
CRITICAL_SECTION g_cs_prof;

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

  InterlockedExchange(&g_l_profile,1);

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

  InterlockedExchange(&g_l_profile,0);

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
          InterlockedExchange(&g_l_profile,1);
        else
          InterlockedExchange(&g_l_profile,0);

        // Initialize critical sections
        if(!InitializeCriticalSectionAndSpinCount(&g_cs_prof,4000L))
          break;
        if(!InitializeCriticalSectionAndSpinCount(&g_cs_log,4000L)){
          DeleteCriticalSection(&g_cs_prof);
          break;
        }

#ifdef CRAMP_CALLGRAPH
        if(!InitializeCriticalSectionAndSpinCount(&g_cs_call,4000L)){
          DeleteCriticalSection(&g_cs_log);
          DeleteCriticalSection(&g_cs_prof);
          break;
        }
#endif

        // Set output file handles
        char filename[256];
        filename[0]='\0';
        sprintf(filename,"%s/cramp_profile#%d.log",
                getenv("CRAMP_LOGPATH"),
                GetCurrentProcessId());
        g_f_logfile=fopen(filename,"ac");
        if(!g_f_logfile){
          DeleteCriticalSection(&g_cs_log);
          DeleteCriticalSection(&g_cs_call);
          DeleteCriticalSection(&g_cs_prof);
          break;
        }

#ifdef CRAMP_CALLGRAPH
        sprintf(filename,"%s/cramp_call#%d.log",
                getenv("CRAMP_LOGPATH"),
                GetCurrentProcessId());
        g_f_callfile=fopen(filename,"ac");
        if(!g_f_callfile){
          fclose(g_f_logfile);
          g_f_logfile=0;
          DeleteCriticalSection(&g_cs_log);
          DeleteCriticalSection(&g_cs_call);
          DeleteCriticalSection(&g_cs_prof);
          break;
        }
#endif

        // Set this if all succeeds
        valid=TRUE;
      }while(0);
    case DLL_THREAD_ATTACH:
      if(valid)
        CallMonitor::threadAttach(new CallMonLOG());
      break;
    case DLL_PROCESS_DETACH:
      if(valid){
        fflush(g_f_logfile);
        fclose(g_f_logfile);
        g_f_logfile=0;
        DeleteCriticalSection(&g_cs_log);

#ifdef CRAMP_CALLGRAPH
        fflush(g_f_callfile);
        fclose(g_f_callfile);
        g_f_callfile=0;
        DeleteCriticalSection(&g_cs_call);
#endif

        DeleteCriticalSection(&g_cs_prof);
      }
    case DLL_THREAD_DETACH:
      if(valid)
        CallMonitor::threadDetach();
      break;
  }
  return(TRUE);
}
//End of file
