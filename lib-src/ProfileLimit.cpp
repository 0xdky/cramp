// -*-c++-*-
// Time-stamp: <2003-10-17 19:09:43 dhruva>
//-----------------------------------------------------------------------------
// File : ProfileLimit.cpp
// Desc : Limit the profile data per thread basis. The latest entries are kept
//        in descending order of ticks. Exceptions have forced entry.
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __PROFILELIMIT_SRC

#include "cramp.h"
#include "ProfileLimit.h"

extern CRITICAL_SECTION g_cs_log;

//-----------------------------------------------------------------------------
// ProfileLimit
//-----------------------------------------------------------------------------
ProfileLimit::ProfileLimit(SIZE_T iLimit){
  _limit=iLimit;
}

//-----------------------------------------------------------------------------
// ~ProfileLimit
//-----------------------------------------------------------------------------
ProfileLimit::~ProfileLimit(void){
  _limit=0;
  _lprofdata.clear();
}

//-----------------------------------------------------------------------------
// AddLog
//-----------------------------------------------------------------------------
BOOLEAN
ProfileLimit::AddLog(__int64 iTicks,std::string iLog,BOOLEAN iForce){
  BOOLEAN ret=FALSE;
  do{
    // If first entry
    if(!_lprofdata.size()){
      ProfileData pd;
      pd._ticks=iTicks;
      pd._log=iLog;
      _lprofdata.push_back(pd);
      ret=TRUE;
      break;
    }

    // If it is less significant than the least significant in the
    // full list, do nothing
    if(_lprofdata.size()==_limit){
      if(iTicks<_lprofdata.back()._ticks){
        if(iForce){
          // Though this is smaller than the least, remove the least
          // and add in least pos
          _lprofdata.pop_back();
          ProfileData pd;
          pd._ticks=iTicks;
          pd._log=iLog;
          _lprofdata.push_back(pd);
          ret=TRUE;
        }
        break;
      }
    }else{
      // We are sure to add this, create space
      _lprofdata.pop_back();

      // If it is greater than the greatest, add it to top
      if(iTicks>_lprofdata.front()._ticks){
        ProfileData pd;
        pd._ticks=iTicks;
        pd._log=iLog;
        _lprofdata.push_front(pd);
        ret=TRUE;
        break;
      }
    }

    // Create the entry object
    ProfileData pdata;
    pdata._ticks=iTicks;
    pdata._log=iLog;


    BOOLEAN fdir=TRUE;


    // Find a suitable traversal direction, crude optimization
    if(pdata._ticks<(_lprofdata.front()._ticks+_lprofdata.back()._ticks)/2){
      fdir=FALSE;
      _lprofdata.reverse();
    }

    // Find a proper entry location in the list
    std::list<ProfileData>::iterator iter=_lprofdata.begin();
    for(;iter!=_lprofdata.end();iter++){
      if(iTicks>(*iter)._ticks){
        _lprofdata.insert(iter,pdata);
        ret=TRUE;
        break;
      }
    }

    // Do not forget to reverse it back if reversed
    if(!fdir)
      _lprofdata.reverse();

    // If this is the least... can happen only if previous least
    // and its previous least have same value
    if(!ret)
      _lprofdata.push_back(pdata);

    ret=TRUE;
  }while(0);

  return(ret);
}

//-----------------------------------------------------------------------------
// DumpProfileLogs
//  Write out the logs to file
//-----------------------------------------------------------------------------
void
ProfileLimit::DumpProfileLogs(FILE *iLogFile){
  if(!iLogFile)
    return;
  std::list<ProfileData>::iterator iter=_lprofdata.begin();
  EnterCriticalSection(&g_cs_log);
  for(;iter!=_lprofdata.end();iter++){
    fprintf(iLogFile,"%s\n",(*iter)._log.c_str());
  }
  LeaveCriticalSection(&g_cs_log);
  _lprofdata.clear();
  _limit=0;
  return;
}
