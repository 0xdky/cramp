// -*-c++-*-
// Time-stamp: <2003-10-29 20:42:15 dhruva>
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

#include <queue>
#include <hash_map>
typedef std::queue<std::string> squeue;
typedef std::hash_map<unsigned int,char> hash_tid;

char DEBUG;
char logdir[1024];
char dbfile[1024];
char logfile[1024];
char funcfile[1024];
char queryfile[1024];

int AddTickSortedData(void);
int AddAddrSortedData(void);
int AddThreadIDs(hash_tid &);
int TickCompare(DB *,const DBT *,const DBT *);

squeue GetThreadIDs(void);
squeue GetDuplicateKeyValues(DB *,char *,unsigned int);
squeue GetTickSortedValues(char *,unsigned int);
squeue GetAddrSortedValues(char *,unsigned int);

#ifndef DBERROR
#define DBERROR(ptr,ret,msg) do{                \
    if(DB_RUNRECOVERY==ret)                     \
      fprintf(stderr,"Fatal error\n");          \
    ptr->err(ptr,ret,"%s:%d",msg,__LINE__);     \
  }while(0)
#endif

#ifndef QUERYOUT
#define QUERYOUT(que) while(!que.empty()){          \
    fprintf(f_query,"%s\n",que.front().c_str());    \
    if(DEBUG)                                       \
      fprintf(stdout,"%s\n",que.front().c_str());   \
    que.pop();                                      \
  }
#endif

//-----------------------------------------------------------------------------
// main
//-----------------------------------------------------------------------------
int
main(int argc,char *argv[]){
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
  }else{
    // Basic number of arguments for a query
    if(argc<4)
      return(-1);

    FILE *f_query=0;
    f_query=fopen(queryfile,"w");
    if(!f_query)
      return(-1);

    do{
      if(0==stricmp("THREADS",argv[3])){
        squeue &qtid=GetThreadIDs();
        QUERYOUT(qtid);
        break;
      }

      if(argc<6)
        break;
      if(0==stricmp("TICK",argv[4])){
        squeue &qtid=GetTickSortedValues(argv[3],atoi(argv[5]));
        QUERYOUT(qtid);
        break;
      }
      if(0==stricmp("ADDR",argv[3])){
        squeue &qtid=GetAddrSortedValues(argv[4],atoi(argv[5]));
        QUERYOUT(qtid);
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
                  DB_CREATE,
                  0644);
    if(ret){
      pdb=0;
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
// AddTickSortedData
//-----------------------------------------------------------------------------
int
AddTickSortedData(void){
  FILE *f_log=0;
  f_log=fopen(logfile,"r");
  if(!f_log)
    return(-1);

  int ret=0;
  DB *pdb=0;
  DBC *pdbc=0;
  if(db_create(&pdb,NULL,0)){
    fclose(f_log);
    return(-1);
  }

  hash_tid h_tid;
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

    ret=pdb->open(pdb,NULL,dbfile,"TID_FUNC_SORT_TICK",
                  DB_BTREE,
                  DB_CREATE,
                  0644);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      pdb=0;
      break;
    }

    // Truncate the contents if any
    unsigned int count=0;
    ret=pdb->truncate(pdb,NULL,&count,0);
    if(ret)
      DBERROR(pdb,ret,"Truncate");

    ret=pdb->cursor(pdb,NULL,&pdbc,0);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      pdb=0;
      break;
    }

    char *buff=0;
    char orig[1024];
    char line[1024];
    const char *sep="|";
    while(EOF!=fscanf(f_log,"%s",&line)){
      sprintf(orig,"%s",line);

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
      val.size=strlen(orig)+1;
      val.data=orig;

      h_tid[atoi(buff)]=1;
      ret=pdbc->c_put(pdbc,&key,&val,DB_KEYLAST);
      if(ret){
        DBERROR(pdb,ret,dbfile);
      }
    }
  }while(0);

  if(pdbc){
    pdbc->c_close(pdbc);
    pdbc=0;
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
  FILE *f_log=0;
  f_log=fopen(logfile,"r");
  if(!f_log)
    return(-1);

  int ret=0;
  DB *pdb=0;
  DBC *pdbc=0;
  if(db_create(&pdb,NULL,0)){
    fclose(f_log);
    return(-1);
  }

  hash_tid h_tid;
  do{
    // Set the flags for db table
    ret=pdb->set_flags(pdb,DB_DUP|DB_DUPSORT);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      break;
    }

    ret=pdb->open(pdb,NULL,dbfile,"ADDR_FUNC_SORT",
                  DB_BTREE,
                  DB_CREATE,
                  0644);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      pdb=0;
      break;
    }

    // Truncate the contents if any
    unsigned int count=0;
    ret=pdb->truncate(pdb,NULL,&count,0);
    if(ret)
      DBERROR(pdb,ret,"Truncate");

    ret=pdb->cursor(pdb,NULL,&pdbc,0);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      pdb=0;
      break;
    }

    char *buff=0;
    char orig[1024];
    char line[1024];
    const char *sep="|";
    while(EOF!=fscanf(f_log,"%s",&line)){
      sprintf(orig,"%s",line);

      buff=0;
      buff=strtok(line,sep);
      if(!buff)
        continue;
      buff=strtok(0,sep);
      if(!buff)
        continue;

      DBT key;
      DBT val;
      memset(&key,0,sizeof(key));
      memset(&val,0,sizeof(val));

      key.size=strlen(buff)+1;
      key.data=buff;
      val.size=strlen(orig)+1;
      val.data=orig;

      h_tid[atoi(buff)]=1;
      ret=pdbc->c_put(pdbc,&key,&val,DB_KEYLAST);
      if(ret){
        DBERROR(pdb,ret,dbfile);
      }
    }
  }while(0);

  if(pdbc){
    pdbc->c_close(pdbc);
    pdbc=0;
  }

  if(pdb){
    pdb->close(pdb,0);
    pdb=0;
  }

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

    ret=pdb->open(pdb,NULL,dbfile,"TID_FUNC_SORT_TICK",
                  DB_BTREE,
                  DB_RDONLY,
                  0644);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      pdb=0;
      break;
    }
    oque=GetDuplicateKeyValues(pdb,stid,max);
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
GetAddrSortedValues(char *saddr,unsigned int max){
  squeue oque;
  if(!saddr)
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

    ret=pdb->open(pdb,NULL,dbfile,"ADDR_FUNC_SORT",
                  DB_BTREE,
                  DB_RDONLY,
                  0644);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      pdb=0;
      break;
    }
    oque=GetDuplicateKeyValues(pdb,saddr,max);
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
      pdb=0;
      break;
    }

    ret=pdb->cursor(pdb,NULL,&pdbc,0);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      pdb=0;
      break;
    }

    DBT key,val;
    char ctid[32];
    memset(&key,0,sizeof(key));
    memset(&val,0,sizeof(val));
    val.flags=DB_DBT_MALLOC;

    ret=pdbc->c_get(pdbc,&key,&val,DB_FIRST);
    if(ret){
      DBERROR(pdb,ret,dbfile);
      pdb=0;
      break;
    }
    sprintf(ctid,"%s",val.data);
    free(val.data);
    oque.push(ctid);

    while(0==(ret=pdbc->c_get(pdbc,&key,&val,DB_NEXT))){
      sprintf(ctid,"%s",val.data);
      free(val.data);
      oque.push(ctid);
    }

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
    val.flags=DB_DBT_MALLOC;

    ret=pdbc->c_get(pdbc,&key,&val,DB_SET);
    if(ret){
      DBERROR(pdb,ret,keystr);
      break;
    }
    sprintf(cval,"%s",val.data);
    free(val.data);
    oque.push(cval);

    while(0==(ret=pdbc->c_get(pdbc,&key,&val,DB_NEXT_DUP))){
      sprintf(cval,"%s",val.data);
      free(val.data);
      oque.push(cval);
      if(max&&oque.size()==max)
        break;
    }

  }while(0);

  if(pdbc)
    pdbc->c_close(pdbc);
  pdbc=0;

  return(oque);
}
