// -*-c++-*-
// Time-stamp: <2003-10-30 20:28:20 dhruva>
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

#include <tchar.h>
#include <fstream.h>

#include <queue>
#include <string>
#include <hash_map>

typedef std::string string;
typedef std::queue<std::string> squeue;
typedef std::hash_map<unsigned int,char> hash_tid;

char DEBUG;
unsigned long uid;
char logdir[MAX_PATH];
char dbfile[MAX_PATH];
char logfile[MAX_PATH];
char funcfile[MAX_PATH];
char queryfile[MAX_PATH];

int AddFunctionInfo(void);
int AddTickSortedData(void);
int AddAddrSortedData(void);
int AddThreadIDs(hash_tid &);
int TickCompare(DB *,const DBT *,const DBT *);

squeue GetThreadIDs(void);
void AppendFunctionInfo(squeue &,FILE *);
squeue GetDuplicateKeyValues(DB *,char *,unsigned int);
squeue GetTickSortedValues(char *,unsigned int);
squeue GetAddrSortedValues(char *,unsigned int);
int GetAddrSecondaryKey(DB *,const DBT *,const DBT *,DBT *);
int GetTickSecondaryKey(DB *,const DBT *,const DBT *,DBT *);

#ifndef DBERROR
#define DBERROR(ptr,ret,msg) do{                \
    if(DB_RUNRECOVERY==ret)                     \
      fprintf(stderr,"Fatal error\n");          \
    ptr->err(ptr,ret,"%s:%d",msg,__LINE__);     \
  }while(0)
#endif

//-----------------------------------------------------------------------------
// main
//-----------------------------------------------------------------------------
int
main(int argc,char *argv[]){
  uid=0;
  SIZE_T pid=atoi(argv[1]);
  BOOLEAN dump=FALSE;

  if(getenv("DEBUG"))
    DEBUG=1;
  else
    DEBUG=0;

  const char *ldir=getenv("CRAMP_LOGPATH");
  if(ldir)
    sprintf(logdir,"%s",ldir);
  else
    sprintf(logdir,".");

  sprintf(dbfile,"%s/cramp#%d.db",logdir,pid);
  sprintf(logfile,"%s/cramp_profile#%d.log",logdir,pid);
  sprintf(funcfile,"%s/cramp_funcinfo#%d.log",logdir,pid);
  sprintf(queryfile,"%s/query.psf",logdir);

  if(0==stricmp("DUMP",argv[2]))
    dump=TRUE;

  if(dump){
    if(0==stricmp("TICK",argv[3]))
      AddTickSortedData();
    if(0==stricmp("ADDR",argv[3]))
      AddAddrSortedData();
    AddFunctionInfo();
  }else{
    // Basic number of arguments for a query
    if(argc<4)
      return(-1);

    FILE *f_query=0;
    if(0==stricmp("APPEND",argv[argc-1]))
      f_query=fopen(queryfile,"a");
    else
      f_query=fopen(queryfile,"w");
    if(!f_query)
      return(-1);

    do{
      if(0==stricmp("THREADS",argv[3])){
        squeue &qtid=GetThreadIDs();
        while(!qtid.empty()){
          if(f_query)
            fprintf(f_query,"%s\n",qtid.front().c_str());
          if(DEBUG)
            fprintf(stdout,"%s\n",qtid.front().c_str());
          qtid.pop();
        }
        break;
      }

      if(argc<6)
        break;
      if(0==stricmp("TICK",argv[4])){
        squeue &qtick=GetTickSortedValues(argv[3],atoi(argv[5]));
        AppendFunctionInfo(qtick,f_query);
        break;
      }
      if(0==stricmp("ADDR",argv[3])){
        squeue &qaddr=GetAddrSortedValues(argv[4],atoi(argv[5]));
        AppendFunctionInfo(qaddr,f_query);
        break;
      }

      // Close query file
      if(f_query){
        fflush(f_query);
        fclose(f_query);
        f_query=0;
      }
    }while(0);
  }

  return(0);
}

//-----------------------------------------------------------------------------
// AddThreadIDs
//-----------------------------------------------------------------------------
int
AddThreadIDs(hash_tid &h_tid){
  int ret=0;
  DB *pdb=0;
  if(db_create(&pdb,NULL,0))
    return(-1);

  do{
    ret=pdb->set_flags(pdb,DB_RENUMBER);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    ret=pdb->open(pdb,NULL,dbfile,"TID",
                  DB_RECNO,
                  DB_EXCL|DB_CREATE,
                  0644);
    if(ret){
      break;
    }

    // Truncate the contents if any
    unsigned int count=0;
    ret=pdb->truncate(pdb,NULL,&count,0);
    if(ret)
      DBERROR(pdb,ret,"Truncate");

    DBT key;
    DBT val;
    char ctid[32];
    db_recno_t rn=0;
    hash_tid::iterator iter=h_tid.begin();
    for(;iter!=h_tid.end();iter++,rn++){
      memset(&key,0,sizeof(key));
      memset(&val,0,sizeof(val));

      key.size=sizeof(db_recno_t);
      key.data=&rn;

      val.size=sprintf(ctid,"%d",(*iter).first)+1;
      val.data=ctid;

      ret=pdb->put(pdb,0,&key,&val,DB_APPEND);
      if(ret)
        DEBUGCHK(0);
    }
  }while(0);

  if(pdb){
    pdb->close(pdb,0);
    pdb=0;
  }

  return(0);
}

//-----------------------------------------------------------------------------
// GetTickSecondaryKey
//-----------------------------------------------------------------------------
int
GetTickSecondaryKey(DB *pdb,const DBT *pkey,const DBT *pval,DBT *skey){
  if(!pdb||!pkey||!pval||!pkey->size||!pkey->data)
    return(DB_DONOTINDEX);
  memset(skey,0,sizeof(DBT));

  char *buff=0;
  char pdata[1024];
  memcpy(pdata,pval->data,pval->size);

  buff=strtok(pdata,"|");
  if(!buff)
    return(DB_DONOTINDEX);

  skey->size=strlen(buff)+1;
  skey->data=buff;

  return(0);
}

//-----------------------------------------------------------------------------
// GetAddrSecondaryKey
//-----------------------------------------------------------------------------
int
GetAddrSecondaryKey(DB *pdb,const DBT *pkey,const DBT *pval,DBT *skey){
  if(!pdb||!pkey||!pval||!pkey->size||!pkey->data)
    return(DB_DONOTINDEX);
  memset(skey,0,sizeof(DBT));

  char *buff=0;
  char pdata[1024];
  memcpy(pdata,pval->data,pval->size);

  buff=strtok(pdata,"|");
  if(!buff)
    return(DB_DONOTINDEX);
  buff=strtok(0,"|");
  if(!buff)
    return(DB_DONOTINDEX);

  skey->size=strlen(buff)+1;
  skey->data=buff;

  return(0);
}

//-----------------------------------------------------------------------------
// AddFunctionInfo
//-----------------------------------------------------------------------------
int
AddFunctionInfo(void){
  fstream f_fun;
  f_fun.open(funcfile,ios::in|ios::nocreate);
  if(!(f_fun.rdbuf())->is_open())
    return(-1);

  int ret=0;
  DB *pdb=0;

  // Create primary database
  if(db_create(&pdb,NULL,0)){
    f_fun.close();
    return(-1);
  }

  do{
    unsigned int count=0;
    ret=pdb->open(pdb,NULL,dbfile,"FUNCTION_INFO",
                  DB_HASH,
                  DB_EXCL|DB_CREATE,
                  0644);
    if(ret){
      break;
    }
    ret=pdb->truncate(pdb,NULL,&count,0);
    if(ret)
      DBERROR(pdb,ret,"Truncate");

    char *buff=0;
    char line[1024];
    char *orig=(char *)calloc(1024,sizeof(char));
    const char *sep="|";
    while(!f_fun.eof()){
      f_fun.getline(line,1024,'\n');
      strcpy(orig,line);

      buff=0;
      buff=strtok(line,sep);
      if(!buff)
        continue;
      DBT key;
      DBT val;
      memset(&key,0,sizeof(key));
      memset(&val,0,sizeof(val));

      key.size=strlen(buff)+1;
      key.data=buff;

      val.size=strlen(orig)-key.size+1;
      val.data=orig+key.size;

      ret=pdb->put(pdb,NULL,&key,&val,0);
      if(ret)
        DBERROR(pdb,ret,(char *)key.data);
    }
    if(orig)
      free(orig);
    orig=0;
  }while(0);

  f_fun.close();
  if(pdb){
    pdb->close(pdb,0);
    pdb=0;
  }

  return(ret);
}

//-----------------------------------------------------------------------------
// AddTickSortedData
//-----------------------------------------------------------------------------
int
AddTickSortedData(void){
  fstream f_log;
  f_log.open(logfile,ios::in|ios::nocreate);
  if(!(f_log.rdbuf())->is_open())
    return(-1);

  int ret=0;
  DB *pdb=0;
  DB *psdb=0;

  // Create primary database
  if(db_create(&pdb,NULL,0)){
    f_log.close();
    return(-1);
  }

  // Create secondary database
  if(db_create(&psdb,NULL,0)){
    f_log.close();
    return(-1);
  }

  hash_tid h_tid;
  do{
    unsigned int count=0;
    ret=pdb->open(pdb,NULL,dbfile,"TID_FUNC_SORT_TICK",
                  DB_BTREE,
                  DB_EXCL|DB_CREATE,
                  0644);
    if(ret){
      break;
    }
    ret=pdb->truncate(pdb,NULL,&count,0);
    if(ret)
      DBERROR(pdb,ret,"Truncate");

    // Set the flags for db table
    ret=psdb->set_flags(psdb,DB_DUP|DB_DUPSORT);
    if(ret){
      DBERROR(psdb,ret,dbfile);
      break;
    }

    // Set duplicate data compare to tick
    ret=psdb->set_dup_compare(psdb,TickCompare);
    if(ret){
      DBERROR(psdb,ret,dbfile);
      break;
    }

    ret=psdb->set_cachesize(psdb,0,100000000,5);
    if(ret)
      DBERROR(psdb,ret,"cache");

    ret=psdb->open(psdb,NULL,dbfile,"S_TID_FUNC_SORT_TICK",
                   DB_BTREE,
                   DB_EXCL|DB_CREATE,
                   0644);
    if(ret){
      break;
    }
    ret=psdb->truncate(psdb,NULL,&count,0);
    if(ret)
      DBERROR(psdb,ret,"Truncate");

    // Associate the secondary with the primary
	ret=pdb->associate(pdb,NULL,psdb,GetTickSecondaryKey,0);
    if(ret){
      DBERROR(pdb,ret,"associate");
      break;
    }

    char *buff=0;
    char line[1024];
    char *orig=(char *)calloc(1024,sizeof(char));
    const char *sep="|";
    while(!f_log.eof()){
      f_log.getline(line,1024,'\n');
      strcpy(orig,line);

      buff=0;
      buff=strtok(line,sep);
      if(!buff)
        continue;
      DBT key;
      DBT val;
      memset(&key,0,sizeof(key));
      memset(&val,0,sizeof(val));

      // Unique primary key
      uid++;
      char skey[32];
      key.size=sprintf(skey,"%ld",uid)+1;
      key.data=skey;

      val.size=strlen(orig)+1;
      val.data=orig;

      h_tid[atoi(buff)]=1;
      ret=pdb->put(pdb,NULL,&key,&val,0);
      if(ret)
        DBERROR(pdb,ret,(char *)key.data);
    }
    if(orig)
      free(orig);
    orig=0;
  }while(0);

  f_log.close();
  if(psdb){
    psdb->close(psdb,0);
    psdb=0;
  }

  if(pdb){
    pdb->close(pdb,0);
    pdb=0;
  }

  // Add the thread IDs
  AddThreadIDs(h_tid);

  return(ret);
}

//-----------------------------------------------------------------------------
// AddAddrSortedData
//-----------------------------------------------------------------------------
int
AddAddrSortedData(void){
  fstream f_log;
  f_log.open(logfile,ios::in|ios::nocreate);
  if(!(f_log.rdbuf())->is_open())
    return(-1);

  int ret=0;
  DB *pdb=0;
  DB *psdb=0;

  // Create primary database
  if(db_create(&pdb,NULL,0)){
    f_log.close();
    return(-1);
  }

  // Create secondary database
  if(db_create(&psdb,NULL,0)){
    f_log.close();
    return(-1);
  }

  hash_tid h_tid;
  do{
    unsigned int count=0;
    ret=pdb->open(pdb,NULL,dbfile,"TID_FUNC_SORT_ADDR",
                  DB_BTREE,
                  DB_EXCL|DB_CREATE,
                  0644);
    if(ret){
      break;
    }
    ret=pdb->truncate(pdb,NULL,&count,0);
    if(ret)
      DBERROR(pdb,ret,"Truncate");

    // Set the flags for db table
    ret=psdb->set_flags(psdb,DB_DUP|DB_DUPSORT);
    if(ret){
      DBERROR(psdb,ret,dbfile);
      break;
    }

    ret=psdb->open(psdb,NULL,dbfile,"S_TID_FUNC_SORT_ADDR",
                   DB_BTREE,
                   DB_EXCL|DB_CREATE,
                   0644);
    if(ret){
      break;
    }
    ret=psdb->truncate(psdb,NULL,&count,0);
    if(ret)
      DBERROR(psdb,ret,"Truncate");

    // Associate the secondary with the primary
	ret=pdb->associate(pdb,NULL,psdb,GetAddrSecondaryKey,0);
    if(ret){
      DBERROR(pdb,ret,"associate");
      break;
    }

    char *buff=0;
    char line[1024];
    char *orig=(char *)calloc(1024,sizeof(char));
    const char *sep="|";
    while(!f_log.eof()){
      f_log.getline(line,1024,'\n');
      strcpy(orig,line);

      buff=0;
      buff=strtok(line,sep);
      if(!buff)
        continue;
      h_tid[atoi(buff)]=1;
      buff=strtok(0,sep);
      if(!buff)
        continue;

      DBT key;
      DBT val;
      memset(&key,0,sizeof(key));
      memset(&val,0,sizeof(val));

      // Unique primary key
      uid++;
      char skey[32];
      key.size=sprintf(skey,"%ld",uid)+1;
      key.data=skey;

      val.size=strlen(orig)+1;
      val.data=orig;

      ret=pdb->put(pdb,NULL,&key,&val,0);
      if(ret)
        DBERROR(pdb,ret,(char *)key.data);
    }
    if(orig)
      free(orig);
    orig=0;
  }while(0);

  f_log.close();
  if(psdb){
    psdb->close(psdb,0);
    psdb=0;
  }

  if(pdb){
    pdb->close(pdb,0);
    pdb=0;
  }

  // Add the thread IDs
  AddThreadIDs(h_tid);

  return(ret);
}

//-----------------------------------------------------------------------------
// GetTickSortedValues
//-----------------------------------------------------------------------------
squeue
GetTickSortedValues(char *stid,unsigned int max){
  squeue oque;
  if(!stid)
    return(oque);

  int ret=0;
  DB *pdb=0;

  if(db_create(&pdb,NULL,0))
    return(oque);

  do{
    // Set the flags for db table
    ret=pdb->set_flags(pdb,DB_DUP|DB_DUPSORT);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    // Set duplicate data compare to tick
    ret=pdb->set_dup_compare(pdb,TickCompare);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    ret=pdb->open(pdb,NULL,dbfile,"S_TID_FUNC_SORT_TICK",
                  DB_BTREE,
                  DB_RDONLY,
                  0644);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }
    squeue pkeyque;
    pkeyque=GetDuplicateKeyValues(pdb,stid,max);
    if(pkeyque.empty())
      break;

    if(pdb)
      pdb->close(pdb,0);
    pdb=0;

    if(db_create(&pdb,NULL,0))
      break;

    ret=pdb->open(pdb,NULL,dbfile,"TID_FUNC_SORT_TICK",
                  DB_BTREE,
                  DB_RDONLY,
                  0644);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    DBT key,val;
    char cpkey[32];
    memset(&key,0,sizeof(key));
    memset(&val,0,sizeof(val));
    val.flags=DB_DBT_REALLOC;

    while(!pkeyque.empty()){
      sprintf(cpkey,pkeyque.front().c_str());
      pkeyque.pop();

      key.size=strlen(cpkey)+1;
      key.data=cpkey;
      ret=pdb->get(pdb,NULL,&key,&val,0);
      if(ret){
        DBERROR(pdb,ret,(char *)key.data);
        continue;
      }
      oque.push((char *)val.data);
    }
    free(val.data);
  }while(0);

  if(pdb)
    pdb->close(pdb,0);
  pdb=0;

  return(oque);
}

//-----------------------------------------------------------------------------
// GetAddrSortedValues
//-----------------------------------------------------------------------------
squeue
GetAddrSortedValues(char *stid,unsigned int max){
  squeue oque;
  if(!stid)
    return(oque);

  int ret=0;
  DB *pdb=0;

  if(db_create(&pdb,NULL,0))
    return(oque);

  do{
    // Set the flags for db table
    ret=pdb->set_flags(pdb,DB_DUP|DB_DUPSORT);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    ret=pdb->open(pdb,NULL,dbfile,"S_TID_FUNC_SORT_ADDR",
                  DB_BTREE,
                  DB_RDONLY,
                  0644);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }
    squeue pkeyque;
    pkeyque=GetDuplicateKeyValues(pdb,stid,max);
    if(pkeyque.empty())
      break;

    if(pdb)
      pdb->close(pdb,0);
    pdb=0;

    if(db_create(&pdb,NULL,0))
      break;

    ret=pdb->open(pdb,NULL,dbfile,"TID_FUNC_SORT_ADDR",
                  DB_BTREE,
                  DB_RDONLY,
                  0644);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    DBT key,val;
    char cpkey[32];
    memset(&key,0,sizeof(key));
    memset(&val,0,sizeof(val));
    val.flags=DB_DBT_REALLOC;

    while(!pkeyque.empty()){
      sprintf(cpkey,pkeyque.front().c_str());
      pkeyque.pop();

      key.size=strlen(cpkey)+1;
      key.data=cpkey;
      ret=pdb->get(pdb,NULL,&key,&val,0);
      if(ret){
        DBERROR(pdb,ret,(char *)key.data);
        continue;
      }
      oque.push((char *)val.data);
    }
    free(val.data);
  }while(0);

  if(pdb)
    pdb->close(pdb,0);
  pdb=0;

  return(oque);
}

//-----------------------------------------------------------------------------
// TickCompare
//-----------------------------------------------------------------------------
int
TickCompare(DB *pdb,const DBT *first,const DBT *second){
  if(!first||!second)
    return(0);

  char val1[1024];
  char val2[1024];

  memcpy(val1,first->data,first->size);
  memcpy(val2,second->data,second->size);

  char *buff=0;
  char *pbuff=0;
  const char *sep="|";
  long tick1=0,tick2=0;

  buff=strtok(val1,sep);
  if(!buff)
    return(0);
  pbuff=buff;
  while(0!=(buff=strtok(0,sep))){
    pbuff=buff;
  }
  if(!pbuff)
    return(0);

  tick1=atol(pbuff);

  buff=strtok(val2,sep);
  if(!buff)
    return(0);
  pbuff=buff;
  while(0!=(buff=strtok(0,sep))){
    pbuff=buff;
  }
  if(!pbuff)
    return(0);

  tick2=atol(pbuff);

  if(tick1<tick2)
    return(1);
  else if(tick1>tick2)
    return(-1);

  return(0);
}

//-----------------------------------------------------------------------------
// GetThreadIDs
//-----------------------------------------------------------------------------
squeue
GetThreadIDs(void){
  int ret=0;
  DB *pdb=0;
  DBC *pdbc=0;
  FILE *fptr=0;
  squeue oque;

  if(db_create(&pdb,NULL,0))
    return(oque);

  BOOLEAN status=FALSE;
  do{
    ret=pdb->set_flags(pdb,DB_RENUMBER);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    ret=pdb->open(pdb,NULL,dbfile,"TID",
                  DB_RECNO,
                  DB_RDONLY,
                  0644);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    ret=pdb->cursor(pdb,NULL,&pdbc,0);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    DBT key,val;
    char ctid[32];
    memset(&key,0,sizeof(key));
    memset(&val,0,sizeof(val));
    val.flags=DB_DBT_REALLOC;

    ret=pdbc->c_get(pdbc,&key,&val,DB_FIRST);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }
    sprintf(ctid,"%s",val.data);
    oque.push(ctid);

    while(0==(ret=pdbc->c_get(pdbc,&key,&val,DB_NEXT))){
      sprintf(ctid,"%s",val.data);
      oque.push(ctid);
    }
    free(val.data);
    status=TRUE;
  }while(0);

  if(pdbc)
    pdbc->c_close(pdbc);
  pdbc=0;

  if(pdb)
    pdb->close(pdb,0);
  pdb=0;

  return(oque);
}

//-----------------------------------------------------------------------------
// GetDuplicateKeyValues
//-----------------------------------------------------------------------------
squeue
GetDuplicateKeyValues(DB *pdb,char *keystr,unsigned int max){
  squeue oque;
  if(!pdb||!keystr)
    return(oque);

  int ret=0;
  DBC *pdbc=0;
  do{
    ret=pdb->cursor(pdb,NULL,&pdbc,0);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    DBT key,val;
    char cval[1024];
    memset(&key,0,sizeof(key));
    memset(&val,0,sizeof(val));
    key.size=strlen(keystr)+1;
    key.data=keystr;
    val.flags=DB_DBT_REALLOC;

    ret=pdbc->c_get(pdbc,&key,&val,DB_SET_RANGE);
    if(ret){
      DBERROR(pdb,ret,keystr);
      break;
    }

    sprintf(cval,"%s",val.data);
    oque.push(cval);

    while(0==(ret=pdbc->c_get(pdbc,&key,&val,DB_NEXT_DUP))){
      sprintf(cval,"%s",val.data);
      oque.push(cval);
      if(max&&oque.size()==max)
        break;
    }
    free(val.data);

  }while(0);

  if(pdbc)
    pdbc->c_close(pdbc);
  pdbc=0;

  return(oque);
}

//-----------------------------------------------------------------------------
// AppendFunctionInfo
//-----------------------------------------------------------------------------
void
AppendFunctionInfo(squeue &ique,FILE *f_query){
  int ret=0;
  DB *pdb=0;

  if(db_create(&pdb,NULL,0))
    return;

  do{
    ret=pdb->open(pdb,NULL,dbfile,"FUNCTION_INFO",
                  DB_HASH,
                  DB_RDONLY,
                  0644);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }
    DBT key,val;
    memset(&key,0,sizeof(DBT));
    memset(&val,0,sizeof(DBT));
    val.flags=DB_DBT_REALLOC;

    char tid[32];
    char addr[32];
    char *orig=(char *)calloc(1024,sizeof(char));
    char *origloc=orig;
    while(!ique.empty()){
      orig=origloc;
      string line=ique.front();
      ique.pop();

      strcpy(orig,line.c_str());

      char *buff=0;
      buff=strtok(orig,"|");
      if(!buff)
        continue;
      buff=strtok(0,"|");
      if(!buff)
        continue;

      key.size=strlen(buff)+1;
      key.data=buff;
      ret=pdb->get(pdb,NULL,&key,&val,0);
      line.insert(line.find("|")+1,(char *)val.data);
      if(f_query)
        fprintf(f_query,"%s\n",line.c_str());
      if(DEBUG)
        fprintf(stdout,"%s\n",line.c_str());
    }
    if(orig)
      free(orig);
    orig=0;
  }while(0);

  if(pdb)
    pdb->close(pdb,0);
  pdb=0;

  return;
}
