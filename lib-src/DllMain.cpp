// -*-c++-*-
// Time-stamp: <2003-10-21 14:36:38 dhruva>
//-----------------------------------------------------------------------------
// File : DllMain.cpp
// Desc : DllMain implementation for profiler
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __DLLMAIN_SRC

#include "cramp.h"
#include "CallMonLOG.h"

long g_l_profile=0;
FILE *g_f_logfile=0;
FILE *g_f_callfile=0;
__int64 g_u_counter=0;

// Berkeley database
// Hash of function address and funcinfo structure
DB *g_pdb_funcinfo=0;

CRITICAL_SECTION g_cs_log;
CRITICAL_SECTION g_cs_call;
CRITICAL_SECTION g_cs_prof;

BOOL OnProcessStart(void);
BOOL OnProcessEnd(void);
//-----------------------------------------------------------------------------
// CRAMP_EnableProfile
//  Thread safe
//-----------------------------------------------------------------------------
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

//-----------------------------------------------------------------------------
// CRAMP_DisableProfile
//  Thread safe
//-----------------------------------------------------------------------------
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

//-----------------------------------------------------------------------------
// DllMain
//-----------------------------------------------------------------------------
BOOL WINAPI DllMain(HINSTANCE hinstDLL,
                    DWORD fdwReason,
                    LPVOID lpvReserved){
  static BOOL valid=FALSE;

  switch (fdwReason)
  {
    case DLL_PROCESS_ATTACH:
      valid=OnProcessStart();
    case DLL_THREAD_ATTACH:
      if(valid)
        CallMonitor::threadAttach(new CallMonLOG());
      break;
    case DLL_PROCESS_DETACH:
      if(valid)
        OnProcessEnd();
    case DLL_THREAD_DETACH:
      if(valid)
        CallMonitor::threadDetach();
      break;
  }
  return(TRUE);
}
//End of file

//-----------------------------------------------------------------------------
// OnProcessStart
//-----------------------------------------------------------------------------
BOOL
OnProcessStart(void){
  BOOL valid=FALSE;
  char filename[256];
  char logpath[256]=".";
  CallMonitor::TICKS frequency=0;

  if(getenv("CRAMP_LOGPATH"))
    sprintf(logpath,"%s",getenv("CRAMP_LOGPATH"));

  do{
    // Open a database handle for storing function details
    g_pdb_funcinfo=0;
    if(db_create(&g_pdb_funcinfo,NULL,0))
      break;
    sprintf(filename,"%s/cramp_profile.db",
            logpath,GetCurrentProcessId());
    int bret=0;
    bret=g_pdb_funcinfo->open(g_pdb_funcinfo,NULL,filename,"FuncInfo",
                              DB_HASH,
                              DB_EXCL|DB_CREATE|
                              DB_INIT_CDB|DB_THREAD|DB_DIRTY_READ,0644);
    if(bret){
      bret=g_pdb_funcinfo->open(g_pdb_funcinfo,NULL,filename,"FuncInfo",
                                DB_HASH,
                                DB_THREAD|DB_DIRTY_READ,
                                0644);
      if(!bret){
        unsigned int cnt=0;
        bret=g_pdb_funcinfo->truncate(g_pdb_funcinfo,NULL,&cnt,0);
      }
    }
    if(bret){
      g_pdb_funcinfo->err(g_pdb_funcinfo,bret,"Error opening db");
      g_pdb_funcinfo=0;
      break;
    }

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
    sprintf(filename,"%s/cramp_profile#%d.log",
            logpath,
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
            logpath,
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

  return(valid);
}

//-----------------------------------------------------------------------------
// OnProcessEnd
//-----------------------------------------------------------------------------
BOOL
OnProcessEnd(void){
  BOOL valid=FALSE;

  // Close the database
  if(g_pdb_funcinfo)
    g_pdb_funcinfo->close(g_pdb_funcinfo,0);
  g_pdb_funcinfo=0;

  // Close the log file
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
  valid=TRUE;

  return(valid);
}
