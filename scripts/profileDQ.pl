#!perl
## Time-stamp: <2004-03-01 11:20:47 dky>
##-----------------------------------------------------------------------------
## File  : profileDQ.pl
## Desc  : PERL script to dump contents of a DB hash and query
## Usage : perl -S profileDQ.pl help
## Output: Results are written or appended to query.psf
## Desc  : Call SetDBFilters on all DB handles
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-30-2003  Cre                                                          dky
## 12-17-2003  Mod  Complete re-write to support advanced options like      dky
##                  stack trace and reduced DB file size. Results except
##                  thread ID are prefixed by position in RAW record. This
##                  is mainly for STACK trace.
## 01-01-2004  Mod  Bufferred reading of log file to reduce process memory  dky
##                  footprint. Env 'PROFILEDB_BUFFER_LIMIT' to alter size.
##                  If set, MUST be greater than 5000.
## 01-02-2004  Mod  Reduced variables                                       dky
## 02-22-2004  Mod  Proper call stack results by re-ordering                dky
## 02-25-2004  Bug  Implemented call stack using correct algo           sjm/dky
## 02-28-2004  Mod  Added filtering during dumping                          dky
##-----------------------------------------------------------------------------
## Log file syntax:
##  Thread ID|Function address|Depth|Raw Ticks|Time in Ns|Ticks
## Function information syntax:
##  Function Address|Module name|Function name|Total number of calls
## Stat file syntax:
##  Function address|Number of calls|Total ticks|Single max tick
##-----------------------------------------------------------------------------
use DB_File;
use BerkeleyDB;

# Global variables
my $g_pid;                      # Process ID of the profiled program
my $f_logdb;                    # Berkeley DB file
my $f_logtxt;                   # Profiler stack log file
my $f_logfin;                   # Profiler unique function list
my $f_filter;                   # Filter file
my $f_logstat;                  # Profiler summary/statistics file
my $f_queryout;                 # QUERY results
my $g_append=0;                 # Flag to determine appending of query results
my $cramplogdir=".";            # Env variable for profile log folder
my $progname=$0;                # Current PERL script name

my $g_exclude=!exists($ENV{'CRAMP_PROFILE_INCLUSION'}); # Filter option
my $g_filterstring=0;           # Filter string for regexp comparison
my %g_filteredhash=();          # Hash of addressed to be removed

my @g_TIDs=();                  # Caching thread ID's in a single call
my $g_BUFFER_LIMIT=50000;       # Number of lines read from profile log

$progname=~s,.*/,,;
##-----------------------------------------------------------------------------
## usage
##-----------------------------------------------------------------------------
sub usage{
  print STDERR "usage : $progname ARGS
ARGS  : PID DUMP STAT|TICK|ADDR|ALL
        PID QUERY STAT [APPEND]
        PID QUERY THREADS [APPEND]
        PID QUERY thread_id STACK pos Start End [APPEND]
        PID QUERY thread_id|ALL RAW Start End (-1 till end) [APPEND]
        PID QUERY thread_id|ALL TICK limit [APPEND]
        PID QUERY thread_id|ALL ADDR function_address limit [APPEND]
output: Results are written or appended to query.psf";
  return 0;
}

##-----------------------------------------------------------------------------
## PrintTime
##  A debug print utility function which can be used for script profiling
##-----------------------------------------------------------------------------
sub PrintTime{
  if (!exists($ENV{'CRAMP_DEBUG'})) {
    return;
  }

  my @curr=localtime();
  $curr[4]+=1;
  $curr[5]+=1900;
  print STDOUT
    "@_ => $curr[4]/$curr[3]/$curr[5] at $curr[2]:$curr[1]:$curr[0] :: ";
  @curr=times();
  print STDOUT "User:$curr[0] System:$curr[1]\n";

  return;
}

##-----------------------------------------------------------------------------
## SetDBFilters
##  Install DBM Filters to make NULL terminated strings
##-----------------------------------------------------------------------------
sub SetDBFilters{
  if (!defined($_[0])) {
    warn("SetDBFilters: Undefined DB handle");
    return 1;
  }
  $_[0]->filter_fetch_key  ( sub { s/\0$//    } ) ;
  $_[0]->filter_store_key  ( sub { $_ .= "\0" } ) ;
  $_[0]->filter_fetch_value( sub { s/\0$//    } ) ;
  $_[0]->filter_store_value( sub { $_ .= "\0" } ) ;

  return 0;
}

##-----------------------------------------------------------------------------
## TickCompare
##  For use in sort, use $a and $b instead of $_[0] and $_[1]
##-----------------------------------------------------------------------------
sub TickCompare{
  my $k1=$_[0];
  my $k2=$_[1];

  $k1=~s/^([0-9]+)\|//g;
  $k2=~s/^([0-9]+)\|//g;

  if ($k1 < $k2) {
    return 1;
  } elsif ($k1 > $k2) {
    return -1;
  }
  return 0;
}

##-----------------------------------------------------------------------------
## ThreadCompare
##-----------------------------------------------------------------------------
sub ThreadCompare{
  $a=~/^([0-9]+)/;
  my $k1=$1;
  $b=~/^([0-9]+)/;

  if ($k1 < $1) {
    return 1;
  } elsif ($k1 > $1) {
    return -1;
  }
  return 0;
}

##-----------------------------------------------------------------------------
## CallStackSort
##  A recursive method to sort and get proper call stack: Algo be SJM
##-----------------------------------------------------------------------------
sub CallStackSort{
  my $nd;
  my $cd=-1;
  my $cc=-1;
  my $found=0;
  my @sp=();
  my @retlist=();

  foreach (@_) {
    @sp=split(/\|/,$_);
    if (-1 == $cc) {            # First time...
      $cd=$sp[3];               # Depth field
      $cc=0;
      next;
    }
    $nd=$sp[3];                 # Depth field
    if ($nd <= $cd) {
      push(@retlist,splice(@_,$cc,1));
      $found=1;
      if ($#_>=0) {
        push(@retlist,CallStackSort(@_));
      }
      last;
    }
    $cc++;
  }

  if (!$found) {
    push(@retlist,$_[0]);
  }

  return(@retlist);
}

##-----------------------------------------------------------------------------
## GetCallStack
##  Generate call stack from return stack!
##-----------------------------------------------------------------------------
sub GetCallStack{
  my $topfunc=pop(@_);
  my @sp=split(/\|/,$topfunc);
  my $td=$sp[3];

  my @limit=();
  foreach (reverse(@_)) {
    @sp=split(/\|/,$_);
    if ($sp[3] <= $td) {
      last;
    }
    push(@limit,$_);
  }

  if ($#limit<0) {
    return ();
  }

  # Passing the reversed list
  return(reverse(CallStackSort(@limit)));
}

##-----------------------------------------------------------------------------
## WriteResults
##  Write QUERY results to query.psf
##-----------------------------------------------------------------------------
sub WriteResults{
  if (g_append) {
    open(QUERYOUT,">>$f_queryout")
      || die("Cannot open \"$f_queryout\" for write");
  } else {
    open(QUERYOUT,">$f_queryout")
      || die("Cannot open \"$f_queryout\" for write");
  }

  foreach (@_) {
    print QUERYOUT "$_\n";
    if (exists($ENV{'CRAMP_DEBUG'})) {
      print STDOUT "$_\n";
    }
  }

  close(QUERYOUT);

  return 0;
}

##-----------------------------------------------------------------------------
## ProcessArgs
##  Entry function, aka main
##-----------------------------------------------------------------------------
sub ProcessArgs{
  chomp(@ARGV);

  if (exists($ENV{'CRAMP_LOGPATH'})) {
    $cramplogdir=$ENV{'CRAMP_LOGPATH'};
    $cramplogdir=~tr/\\/\//;
    $cramplogdir=~s/\/+$//g;
    $cramplogdir=~s/\/{2,}/\//g;
    if (! -d $cramplogdir) {
      print STDERR "Error: Invalid \"$cramplogdir\" log path\n";
      return 1;
    }
  }

  if (exists($ENV{'PROFILEDB_BUFFER_LIMIT'})) {
    my $buff=$ENV{'PROFILEDB_BUFFER_LIMIT'};
    $buff=~s/[^0-9]//g;
    if (length($buff) && $buff>5000) {
      $g_BUFFER_LIMIT=$buff;
    }
  }

  @ARGV=map(uc,@ARGV);

  foreach (@ARGV) {
    if (/HELP/) {
      usage();
      return 0;
    }
  }

  if ($#ARGV<1) {
    print STDERR "Error: Insufficient argument\n";
    return 1;
  }

  if ($ARGV[-1]=~/APPEND/) {
    $g_append=1;
  }

  $g_pid=$ARGV[0];

  $f_logdb="$cramplogdir/cramp#$g_pid.db";
  $f_filter="$cramplogdir/cramp_profile.flt";
  $f_logtxt="$cramplogdir/cramp_profile#$g_pid.log";
  $f_logfin="$cramplogdir/cramp_funcinfo#$g_pid.log";
  $f_logstat="$cramplogdir/cramp_stat#$g_pid.log";

  if ($ARGV[1]=~/DUMP/) {
    ApplyFilter();
    foreach ($ARGV[2]..$ARGV[-1]) {
      UpdateDB($_);
    }
    return 1;
  } elsif ($ARGV[1]=~/QUERY/) {
    $f_queryout="$cramplogdir/query.psf";
    if (!$g_append) {
      unlink $f_queryout;
    }

    if ($ARGV[2]=~/STAT/) {
      if (! -f $f_logstat) {
        return -1;
      }
      return GetProfileStat();
    }

    if (! -f $f_logdb) {
      print STDERR "Error: DB file for \"$g_pid\" PID not found\n";
      return 1;
    }

    my @tids=GetThreadIDs();
    if ($ARGV[2]=~/THREAD[S]?/) {
      WriteResults(@tids);
      return 0;
    }

    my $key=0;
    my $max=0;
    if ($ARGV[2]=~/([0-9]+)|ALL/) {
      my @tidlist=();
      if ($ARGV[2]=~/ALL/) {
        @tidlist=@tids;
      } else {
        foreach (@tids) {
          if ($_==$ARGV[2]) {
            push(@tidlist,$_);
            last;
          }
        }
      }

      if ($#tidlist<0) {
        print STDERR "Error: Thread ID not found\n";
        return 1;
      }

      if ($ARGV[3]=~/TICK/) {
        if ($#ARGV>=4) {
          $max=$ARGV[4];
        }
        foreach (@tidlist) {
          push(@values,GetTickSortedValues($_,$max));
        }
      } elsif ($ARGV[3]=~/RAW/) {
        $min=$ARGV[4];
        if ($min < 0) {
          $min=0;
        }

        $max=-1;
        if ($#ARGV>=5) {
          $max=$ARGV[5]-1;
        }

        my @idx=();
        if ($min>=0 && $max>=0) {
          @idx=($min..($min+$max));
        }
        foreach (@tidlist) {
          push(@values,GetRawValuesFromIDs($_,$min,@idx));
        }
      } elsif ($ARGV[3]=~/ADDR/) {
        if ($ARGV[4]=~/[0-9ABCDEFX]+/) {
          $key=$ARGV[4];
          if ($#ARGV>=5) {
            $max=$ARGV[5];
          }
          foreach (@tidlist) {
            push(@values,GetAddrSortedData($_,$key,$max));
          }
        }
      } elsif ($ARGV[3]=~/STACK/) {
        $max=10;
        $key=abs($ARGV[4]);
        if ($#ARGV>=5) {
          $max=abs($ARGV[5]);
        }

        if (($key-$max) < 0) {
          $max=$key;
          $key=0;
        } else {
          $key-=$max;           # Call stack is reverse order of return order
          $max+=$key;
        }
        @values=GetCallStack(GetRawValuesFromIDs($tidlist[0],0,
                                                 ($key..$max)));
      }
    }

    # Add the function name and module name for results
    AppendFuncInfoToLogs(@values);
    return WriteResults(@values);
  } else {
    print STDERR "Error: Unknown command\n";
    return 1;
  }

  return 0;
}

##-----------------------------------------------------------------------------
## DumpLogsToDB
##  Dumping various tables in Berkeley DB
##-----------------------------------------------------------------------------
sub DumpLogsToDB{
  my @curr=();
  my $table=$_[0];

  PrintTime("Dump started");
  PrintTime("Entering Func Info");
  AddFunctionInformation();

  if ($table=~/STAT/) {
    PrintTime("Dump Completed");
    return 0;
  }

  PrintTime("Entering Raw");
  AddRawLogs($f_logtxt);

  if ($table=~/TICK/) {
    PrintTime("Entering Tick");
    AddTickSortedData($f_logtxt);
  } elsif ($table=~/ADDR/) {
    PrintTime("Entering Addr");
    AddAddrSortedData();
  } elsif ($table=~/ALL/) {
    PrintTime("Entering Tick");
    AddTickSortedData($f_logtxt);
    PrintTime("Entering Addr");
    AddAddrSortedData();
  }

  PrintTime("Dump Completed");

  return 0;
}

##-----------------------------------------------------------------------------
## UpdateDB
##  Dump only if change in time stamp of log files versus DB file
##-----------------------------------------------------------------------------
sub UpdateDB{
  if (-f $f_logdb) {
    my $update=0;
    my @dbinfo=stat($f_logdb);
    my @loginfo=stat($f_logtxt);
    my @funinfo=stat($f_logfin);
    if ($loginfo[9]>$dbinfo[9] || $funinfo[9]>$dbinfo[9]) {
      unlink $f_logdb;
    }
  }

  if (DumpLogsToDB(@_)) {
    print STDERR "Error: Failed to dump logs to DB\n";
    return 1;
  }

  return 0;
}

##-----------------------------------------------------------------------------
## GetProfileStat
##  Gets the decorated profile statistics
##-----------------------------------------------------------------------------
sub GetProfileStat{
  open(STAT,"<$f_logstat") || return -1;

  AddFunctionInformation();
  my $db;
  $db=new BerkeleyDB::Hash
    -Filename    => $f_logdb,
      -Subname     => "FUNC_INFO",
        -Flags       => DB_RDONLY
          || die("Error: $BerkeleyDB::Error");
  if (!defined($db)) {
    return 1;
  }
  if (SetDBFilters($db)) {
    return 1;
  }

  my %h_stat;
  while (<STAT>) {
    chomp();
    /^([0-9A-F]+)/;
    $h_stat{$1}=$_;
  }
  close(STAT);

  my @list=();
  foreach (sort keys %h_stat) {
    my $val;
    if ($db->db_get($_,$val)!=0) {
      $val="Unknown Module|Unknown Function";
    }
    my $sval=$h_stat{$_};
    $sval=~s/($_)/$val|$1/;
    push(@list,$sval);
  }
  undef $db;

  return WriteResults(@list);
}

##-----------------------------------------------------------------------------
## AddRawLogs
##  Buffered reading of log file to handle list size for sorting
##-----------------------------------------------------------------------------
sub AddRawLogs{
  my $db;
  my $ptid=0;
  my %h_tid;
  my $chunks=0;
  my @rawlogs=();

  open(LOGTXT,$_[0]) || die("Cannot open \"$_[0]\" for read");
  while (<LOGTXT>) {
    chomp();
    push(@rawlogs,$_);
    $chunks++;
    if (!eof(LOGTXT) && $chunks<$g_BUFFER_LIMIT) {
      next;
    }

    foreach (sort ThreadCompare @rawlogs) {
      /^([0-9]+)/;
      if ($1 != $ptid) {
        $ptid=$1;
        if (defined($db)) {
          undef $db;
        }

        $db=new BerkeleyDB::Recno
          -Filename    => $f_logdb,
            -Subname     => "RAW#$ptid",
              -Flags       => DB_CREATE
                || die("Error in creating/opening RAW#$tid table");
        die if !defined($db);
        if (SetDBFilters($db)) {
          return 1;
        }

        if (!exists($h_tid{$ptid})) {
          my $count=0;
          $db->truncate($count);
          $h_tid{$ptid}=1;
        }
      }

      my $key=$ptid;
      $db->db_put($key,$_,DB_APPEND);
    }

    $chunks=0;
    @rawlogs=();
  }
  close(LOGTXT);

  # Close the last open DB handle
  if (defined($db)) {
    undef $db;
  }

  @g_TIDs=keys(%h_tid);
  if ($#g_TIDs>=0) {
    AddThreadIDs(@g_TIDs);
  }

  return 0;
}

##-----------------------------------------------------------------------------
## GetRawValuesFromIDs
##  0 => Thread ID, 1 => Offset, 2 => List Of IDs (empty for all)
##-----------------------------------------------------------------------------
sub GetRawValuesFromIDs{
  my ($tid,$off,@idx)=@_;
  my $db;
  my @tie_RAW=();
  $db=tie(@tie_RAW,'BerkeleyDB::Recno',
          -Filename    => $f_logdb,
          -Subname     => "RAW#$tid",
          -Flags       => DB_RDONLY)
    || die("Error: $BerkeleyDB::Error");
  if (!defined($db)) {
    return ();
  }
  if (SetDBFilters($db)) {
    return ();
  }

  if ($#idx<0) {
    if (!defined($off) || $off<0) {
      $off=0;
    }
    @idx=($off..$#tie_RAW);
  }

  my @results=();
  foreach (@idx) {
    if ($_<0||$_>$#tie_RAW) {
      next;
    }
    push(@results,$_."|".$tie_RAW[$_]);
  }

  undef $db;
  untie @tie_RAW;

  return @results;
}

##-----------------------------------------------------------------------------
## AddThreadIDs
##  Add a list/record of threads from profile log file
##-----------------------------------------------------------------------------
sub AddThreadIDs{
  my @tie_TID=();
  my $db;
  $db=tie(@tie_TID,'BerkeleyDB::Recno',
          -Filename    => $f_logdb,
          -Subname     => "TID",
          -Flags       => DB_CREATE)
    || die("Error in dumping thread id");
  if (!defined($db)) {
    return 1;
  }
  if (SetDBFilters($db)) {
    return 1;
  }

  $count=0;
  $db->truncate($count);

  @tie_TID=@_;

  undef $db;
  untie @tie_TID;

  return 0;
}

##-----------------------------------------------------------------------------
## GetThreadIDs
##  Added caching during dumping, performance improvement
##-----------------------------------------------------------------------------
sub GetThreadIDs{
  if ($#g_TIDs>=0) {
    return @g_TIDs;
  }

  my @tie_TID=();
  my $db;
  $db=tie(@tie_TID,'BerkeleyDB::Recno',
          -Filename    => $f_logdb,
          -Subname     => "TID",
          -Flags       => DB_RDONLY)
    || return ();
  if (!defined($db)) {
    return ();
  }
  if (SetDBFilters($db)) {
    return ();
  }

  @g_TIDs=@tie_TID;

  undef $db;
  untie @tie_TID;

  return @g_TIDs;
}

##-----------------------------------------------------------------------------
## AddAddrSortedData
##  Address sorted table for getting instances of a given function in thread
##-----------------------------------------------------------------------------
sub AddAddrSortedData{
  foreach (GetThreadIDs()) {
    my $tid=$_;
    my $db;
    my @tie_RAW=();
    $db=tie(@tie_RAW,'BerkeleyDB::Recno',
            -Filename    => $f_logdb,
            -Subname     => "RAW#$tid",
            -Flags       => DB_RDONLY)
      || next;
    if (!defined($db)) {
      next;
    }
    if (SetDBFilters($db)) {
      untie @tie_RAW;
      undef $db;
      next;
    }

    my $key;
    my %h_func;
    foreach (0..$#tie_RAW) {
      $tie_RAW[$_]=~/^([0-9]+)(\|)([0-9A-F]+)/;
      $key=$3;
      if (exists($h_func{$key})) {
        $h_func{$key}.=" $_";
      } else {
        $h_func{$key}="$_";
      }
    }

    undef $db;
    untie @tie_RAW;

    my %tie_h_func;
    $db=tie(%tie_h_func,'BerkeleyDB::Hash',
            -Filename    => $f_logdb,
            -Subname     => "FUNCALL#$tid",
            -Flags       => DB_CREATE)
      || die("Error: $BerkeleyDB::Error");
    if (!defined($db)) {
      next;
    }
    if (SetDBFilters($db)) {
      untie %tie_h_func;
      undef $db;
      next;
    }

    my $count=0;
    $db->truncate($count);

    %tie_h_func=%h_func;

    undef $db;
    untie %tie_h_func;
  }

  return 0;
}

##-----------------------------------------------------------------------------
## GetAddrSortedData
##  Getting all instances of a given function in a thread
##-----------------------------------------------------------------------------
sub GetAddrSortedData{
  my ($tid,$key,$max)=@_;
  if ($max<0) {
    return ();
  }

  my $db;
  my %tie_h_func=();
  $db=tie(%tie_h_func,'BerkeleyDB::Hash',
          -Filename    => $f_logdb,
          -Subname     => "FUNCALL#$tid",
          -Flags       => DB_RDONLY)
    || die("Error: $BerkeleyDB::Error");
  if (!defined($db)) {
    untie %tie_h_func;
    return ();
  }
  if (SetDBFilters($db)) {
    undef $db;
    untie %tie_h_func;
    return ();
  }

  my @addr_idx=();
  if (exists($tie_h_func{$key})) {
    @addr_idx=split(/ /,$tie_h_func{$key});
    if ($max>$#addr_idx) {
      $max=0;
    }
  }

  undef $db;
  untie %tie_h_func;

  if ($#addr_idx<0) {
    return ();
  }

  my @results=();
  if ($max) {
    @results=GetRawValuesFromIDs($tid,0,@addr_idx[0..$max-1]);
  } else {
    @results=GetRawValuesFromIDs($tid,0,@addr_idx);
  }

  return @results;
}

##-----------------------------------------------------------------------------
## AddTickSortedData
##  Dump tick sorted information on a thread basis
##-----------------------------------------------------------------------------
sub AddTickSortedData{
  my $db;
  $db=new BerkeleyDB::Btree
    -Filename    => $f_logdb,
      -Subname     => "TICK",
        -Flags       => DB_CREATE,
          -Property    => DB_DUP|DB_DUPSORT,
            -DupCompare  => \&TickCompare
              || die("Error: $BerkeleyDB::Error");
  if (!defined($db)) {
    return 1;
  }
  if (SetDBFilters($db)) {
    return 1;
  }

  my $key;
  my %h_tid;
  my $count=0;
  $db->truncate($count);

  open(LOGTXT,$_[0]) || die("Cannot open \"$_[0]\" for read");
  while (<LOGTXT>) {
    chomp();
    /^([0-9]+)/;
    $key=$1;
    if (exists($h_tid{$key})) {
      $h_tid{$key}+=1;
    } else {
      $h_tid{$key}=0;
    }
    $count=$h_tid{$key};
    /([0-9]+)$/;
    $count.="|$1";
    $db->db_put($key,$count);
  }
  close(LOGTXT);
  undef $db;

  return 0;
}

##-----------------------------------------------------------------------------
## GetDuplicateKeyValues
##  0 => Handle to DB, 1 => Key, 2 => Max size (0 for all)
##-----------------------------------------------------------------------------
sub GetDuplicateKeyValues{
  if (!defined($_[0])) {
    warn("GetDuplicateKeyValues: Undefined DB handle");
    return ();
  }

  my($k,$v)=($_[1],"");
  my $dbc=$_[0]->db_cursor();
  if (0!=$dbc->c_get($k,$v,DB_SET)) {
    undef $dbc;
    return ();
  }

  my $max=0;
  $dbc->c_count($max);
  if ($_[2] && $_[2]<$max) {
    $max=$_[2];
  }

  my $cc=1;
  my @results=();
  push(@results,$v);

  while (0==$dbc->c_get($k,$v,DB_NEXT_DUP)) {
    if ($cc==$max) {
      last;
    }
    $cc++;
    push(@results,$v);
  }
  undef $dbc;

  return @results;
}

##-----------------------------------------------------------------------------
## GetTickSortedValues
##  0 => The sub database name, 1 => Thread ID, 2 => Max size (0 for all)
##-----------------------------------------------------------------------------
sub GetTickSortedValues{
  my $db;
  $db=new BerkeleyDB::Btree
    -Filename    => $f_logdb,
      -Subname     => "TICK",
        -Flags       => DB_RDONLY,
          -Property    => DB_DUP|DB_DUPSORT,
            -DupCompare  => \&TickCompare
              || die("Error: $BerkeleyDB::Error");
  if (!defined($db)) {
    return ();
  }
  if (SetDBFilters($db)) {
    return ();
  }

  my @results=GetDuplicateKeyValues($db,$_[0],$_[1]);
  undef $db;

  if ($#results>=0) {
    map(s/\|([0-9]+)$//g,@results);
    @results=GetRawValuesFromIDs($_[0],0,@results);
  }

  return @results;
}

##-----------------------------------------------------------------------------
## AddFunctionInformation
##  Multiple calls to this function is supported.
##-----------------------------------------------------------------------------
sub AddFunctionInformation{
  open(LOGFIN,$f_logfin) || die("Cannot open \"$f_logfin\" for read");
  my @flogs=<LOGFIN>;
  close(LOGFIN);

  my $db;
  $db=new BerkeleyDB::Hash
    -Filename    => $f_logdb,
      -Subname     => "FUNC_INFO",
        -Flags       => DB_EXCL|DB_CREATE
          || die("Error: $BerkeleyDB::Error");
  if (!defined($db)) {
    return 1;
  }
  if (SetDBFilters($db)) {
    return 1;
  }

  my $count=0;
  $db->truncate($count);

  my $key;
  foreach (@flogs) {
    chomp();
    /^([0-9A-F]+)(\|)(.+)(\|[0-9]+)$/;
    $key=$1;
    $db->db_put($key,$3);
  }
  close(LOGFIN);
  undef $db;

  return 0;
}

##-----------------------------------------------------------------------------
## AppendFuncInfoToLogs
##  Adds the function name and module name to logs. Use it for results.
##-----------------------------------------------------------------------------
sub AppendFuncInfoToLogs{
  my $db;
  $db=new BerkeleyDB::Hash
    -Filename    => $f_logdb,
      -Subname     => "FUNC_INFO",
        -Flags       => DB_RDONLY
          || die("Error: $BerkeleyDB::Error");
  if (!defined($db)) {
    return 1;
  }
  if (SetDBFilters($db)) {
    return 1;
  }

  foreach (@_) {
    /^([0-9]+\|)([0-9]+\|)([0-9A-F]+)/;
    my $val;
    if ($db->db_get($3,$val)!=0) {
      $val="Unknown Module|Unknown Function";
    }
    s/($3)/$val|$1/;
  }
  undef $db;

  return 0;
}

##-----------------------------------------------------------------------------
##                            Filtering during dumping
##-----------------------------------------------------------------------------
##-----------------------------------------------------------------------------
## MakeFilterString
##-----------------------------------------------------------------------------
sub MakeFilterString{
  open(FILTER,"<$f_filter") ||
    return 1;

  my %filterhash=();
  while (<FILTER>) {
    chomp();
    if (length($_)) {
      s/\s//g;
      $_="\\b$_\\b";
      $filterhash{$_}=1;
    }
  }
  close(FILTER);

  if (scalar(keys %filterhash)) {
    $g_filterstring=join('|',keys %filterhash);
    $g_filterstring=~s/\|{2,}/\|/g;
    $g_filterstring=~s/(^\|)|(\|$)//g;
  } else {
    return 1;
  }

  return 0;
}

##-----------------------------------------------------------------------------
## ApplyFilterOnFuncInfo
##  Important function which makes a hash of functions to be removed
##-----------------------------------------------------------------------------
sub ApplyFilterOnFuncInfo{
  open(I_FUNC,"<$f_logfin")
    || return 1;
  open(O_FUNC,">$f_logfin.fo")
    || return 1;

  my $addr;
  my $orig;
  while (<I_FUNC>) {
    chomp();
    $orig=$_;
    $addr=$_;
    s/[\(\<]+.+//g;
    s/\|[0-9]+$//g;
    $addr=~s/\|.+//g;
    if ($g_exclude) {
      if (/$g_filterstring/o) {
        $g_filteredhash{$addr}=1;
      } else {
        print O_FUNC "$orig\n";
      }
    } else {
      if (/$g_filterstring/o) {
        print O_FUNC "$orig\n";
      } else {
        $g_filteredhash{$addr}=1;
      }
    }
  }
  close(O_FUNC);
  close(I_FUNC);

  if (0==scalar(keys(%g_filteredhash))) {
    return 1;
  }

  return 0;
}

##-----------------------------------------------------------------------------
## ApplyFilterOnProfile
##  Applies the hash of functions to be removed from ApplyFilterOnFuncInfo on
##  profile log file
##-----------------------------------------------------------------------------
sub ApplyFilterOnProfile{
  open(I_PROF,"<$f_logtxt")
    || return 1;
  open(O_PROF,">$f_logtxt.fo")
    || return 1;

  my $addr;
  my $filtered;
  while (<I_PROF>) {
    chomp();
    $_=~/^([0-9]+)(\|)([0-9a-fA-F]+)/;
    $addr=$3;
    if (!exists($g_filteredhash{$addr})) {
      print O_PROF "$_\n";
    }
  }
  close(O_PROF);
  close(I_PROF);

  return 0;
}

##-----------------------------------------------------------------------------
## ApplyFilterOnStat
##  Applies the hash of functions to be removed from ApplyFilterOnFuncInfo on
##  stat log file
##-----------------------------------------------------------------------------
sub ApplyFilterOnStat{
  open(I_STAT,"<$f_logstat")
    || return 1;
  open(O_STAT,">$f_logstat.fo")
    || return 1;

  my $addr;
  my $filtered;
  while (<I_STAT>) {
    chomp();
    $_=~/^([0-9a-fA-F]+)/;
    $addr=$1;
    if (!exists($g_filteredhash{$addr})) {
      print O_STAT "$_\n";
    }
  }
  close(O_STAT);
  close(I_STAT);

  return 0;
}

##-----------------------------------------------------------------------------
## ApplyFilter
##  Entry method for applying filtering. Handles multiple calls.
##-----------------------------------------------------------------------------
sub ApplyFilter{
  my $ret=0;

  PrintTime("Filtering started");
  if (MakeFilterString()) {
    $ret=1;
    PrintTime("MakeFilterString failed");
  } elsif (ApplyFilterOnFuncInfo()) {
    $ret=1;
    PrintTime("ApplyFilterOnFuncInfo failed");
  } elsif (ApplyFilterOnProfile()) {
    $ret=1;
    PrintTime("ApplyFilterOnProfile failed");
  } elsif (ApplyFilterOnStat()) {
    $ret=1;
    PrintTime("ApplyFilterOnStat failed");
  }

  # If all goes well, overwrite the files
  if (!exists($ENV{'CRAMP_DEBUG'})) {
    if (0==$ret) {
      unlink($f_logtxt);
      unlink($f_logfin);
      unlink($f_logstat);
      rename("$f_logtxt.fo",$f_logtxt);
      rename("$f_logfin.fo",$f_logfin);
      rename("$f_logstat.fo",$f_logstat);
    } else {
      unlink("$f_logtxt.fo");
      unlink("$f_logfin.fo");
      unlink("$f_logstat.fo");
    }
  }

  return 0;
}

##------------------------ Execution starts here ------------------------------
exit ProcessArgs();
