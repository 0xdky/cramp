// -*-c++-*-
// Time-stamp: <2003-10-24 14:45:28 dhruva>
//-----------------------------------------------------------------------------
// File  : proflog2db.cpp
// Desc  : Dumps the raw text cramp profile log file to Berkeley DB
//-----------------------------------------------------------------------------
// mm-dd-yyyy  History                                                      tri
// 10-22-2003  Cre                                                          dky
//-----------------------------------------------------------------------------
#define __PROFLOG2DB_SRC
#include "cramp.h"
#include "db.h"

#define DB_FILE "E:/tmp/logs/cramp_profile.db"
#define TID_FUNC "TID_FUNC"

int readdb(char *);

int
main(int argc,char *argv[]){
  DEBUGCHK(!readdb(argv[2]));
  return(0);
}

int
readdb(char *keystr){
  DB *pdb_funcinfo=0;
  char filename[256];
  char logpath[256]=".";
  DBC *pdbc_funcinfo=0;
  DB_ENV *pdbenv_funcinfo=0;
  int bret=0;

  if(db_create(&pdb_funcinfo,NULL,0))
    return(1);

  bret=pdb_funcinfo->open(pdb_funcinfo,NULL,DB_FILE,TID_FUNC,
                          DB_HASH,
                          DB_RDONLY,
                          0644);
  if(bret){
    pdb_funcinfo->err(pdb_funcinfo,bret,"Error opening db");
    pdb_funcinfo=0;
    DEBUGCHK(0);
    return(1);
  }

  pdb_funcinfo->set_flags(pdb_funcinfo,DB_DUP);
  if(pdb_funcinfo->cursor(pdb_funcinfo,NULL,&pdbc_funcinfo,0))
    DEBUGCHK(0);

  // Try reading the DB!!
  do{
    DBT key,value;
    char *chrstr=(char *)malloc(256);

    memset(&key,0,sizeof(key));
    memset(&value,0,sizeof(value));

    key.size=strlen(keystr);
    key.data=keystr;
    key.size=strlen("1732");
    key.data="1732";
    value.flags=DB_DBT_REALLOC;

    bret=pdbc_funcinfo->c_get(pdbc_funcinfo,&key,&value,
                              DB_FIRST);
    if(bret){
      pdb_funcinfo->err(pdb_funcinfo,bret,"Error in c_get FIRST");
      pdb_funcinfo=0;
      break;
    }

    db_recno_t count=0;
    bret=pdbc_funcinfo->c_count(pdbc_funcinfo,&count,0);
    if(bret){
      pdb_funcinfo->err(pdb_funcinfo,bret,"Error in c_count");
      pdb_funcinfo=0;
      break;
    }

    do{
      memset(chrstr,0,256);
      memcpy(chrstr,value.data,value.size);
      DEBUGCHK(chrstr);
      printf("Value:%s\n",chrstr);
    }while(DB_NOTFOUND!=pdbc_funcinfo->c_get(pdbc_funcinfo,&key,&value,
                                             DB_NEXT_DUP));
  }while(0);

  if(pdbc_funcinfo)
    pdbc_funcinfo->c_close(pdbc_funcinfo);
  pdbc_funcinfo=0;

  if(pdb_funcinfo)
    pdb_funcinfo->close(pdb_funcinfo,0);
  pdb_funcinfo=0;

  return(0);
}
