// -*-c++-*-
// Time-stamp: <2003-10-17 18:00:02 dhruva>
//-----------------------------------------------------------------------------
// File : ProfileLimit.cpp
// Desc : Limit the profile data per thread basis
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 09-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#pragma once
#pragma warning (disable:4786)

#include <list>
#include <string>

typedef struct{
public:
  __int64 _ticks;
  std::string _log;
}ProfileData;

class ProfileLimit{
public:
  ProfileLimit(SIZE_T iLimit=500);
  virtual ~ProfileLimit(void);
  ProfileData &GetLeastEntry(void){
    return(_lprofdata.back());
  }
  BOOLEAN AddLog(__int64 iTicks,std::string iLog,BOOLEAN iForce=FALSE);
  void DumpProfileLogs(FILE *iLogFile);
private:
  SIZE_T _limit;
  std::list<ProfileData> _lprofdata;
};
