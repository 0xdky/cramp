#!perl
## Time-stamp: <2003-12-17 12:29:53 dhruva>
##-----------------------------------------------------------------------------
## File  : profileDB.pl
## Desc  : PERL script to dump contents of a DB hash and query
## Usage : perl -S profileDB.pl help
## Output: Results are written or appended to query.psf
## Desc  : Call SetDBFilters on all DB handles
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-30-2003  Cre                                                          dky
## 12-17-2003  Mod  Complete re-write to support advanced options like      dky
##                  stack trace and reduced DB file size. Results except
##                  thread ID are prefixed by position in RAW record. This
##                  is mainly for STACK trace.
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

my $g_pid;
my $f_logdb;
my $f_logtxt;
my $f_logfin;
my $f_logstat;
my $f_queryout;
my $g_append=0;
my $cramplogdir=".";
my $progname=$0;
$progname=~s,.*/,,;

# Global variables
my $g_db_RAW;
my @g_tie_RAW=();

##-----------------------------------------------------------------------------
## usage
##-----------------------------------------------------------------------------
sub usage{
  print"usage : $progname ARGS
ARGS  : PID DUMP ALL|TICK|ADDR
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
##  Removed explicit conversion to "int" in regexp. Guess, it is not required
##-----------------------------------------------------------------------------
sub TickCompare{
  my $k1=$g_tie_RAW[$a];
  my $k2=$g_tie_RAW[$b];

  $k1=~s/\0$//;
  $k2=~s/\0$//;

  $k1=~s/([0-9]+)$/{$key1=$1}/e;
  $k2=~s/([0-9]+)$/{$key2=$1}/e;

  if ($key1 < $key2) {
    return 1;
  } elsif ($key1 > $key2) {
    return -1;
  }
  return 0;
}

##-----------------------------------------------------------------------------
## WriteResults
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
    if ($ENV{'DEBUG'}) {
      print STDOUT "$_\n";
    }
  }

  close(QUERYOUT);

  return 0;
}

##-----------------------------------------------------------------------------
## ProcessArgs
##-----------------------------------------------------------------------------
sub ProcessArgs{
  chomp(@ARGV);

  if ($ENV{'CRAMP_LOGPATH'}) {
    $cramplogdir=$ENV{'CRAMP_LOGPATH'};
    $cramplogdir=~tr/\\/\//;
    $cramplogdir=~s/\/+$//g;
    $cramplogdir=~s/\/{2,}/\//g;
    if (! -d $cramplogdir) {
      print STDERR "Error: Invalid \"$cramplogdir\" log path\n";
      return 1;
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
  $f_logtxt="$cramplogdir/cramp_profile#$g_pid.log";
  $f_logfin="$cramplogdir/cramp_funcinfo#$g_pid.log";
  $f_logstat="$cramplogdir/cramp_stat#$g_pid.log";

  if ($ARGV[1]=~/DUMP/) {
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
        $max=$ARGV[4];
        foreach (@tidlist) {
          push(@values,GetTickSortedValues($_,$max));
        }
      } elsif ($ARGV[3]=~/RAW/) {
        $min=$ARGV[4]-1;
        $max=-1;
        if ($#ARGV>=5) {
          $max=$ARGV[5]-1;
        }

        my @idx;
        if ($max<$min) {
          @idx=();
        } elsif ($min>=0 && $max>=0) {
          if ($min==$max) {
            @idx=($min);
          } else {
            @idx=($min..$max);
            print "$#idx: $min $max\n";
          }
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
        # Not yet supported
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
## UpdateDB
##-----------------------------------------------------------------------------
sub UpdateDB{
  if (!(-f $f_logtxt && -f $f_logfin)) {
    print STDERR "Error: Log files for \"$g_pid\" PID not found\n";
    return 1;
  }

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
## DumpLogsToDB
##-----------------------------------------------------------------------------
sub DumpLogsToDB{
  my $table=$_[0];
  AddRawLogs();
  if ($table=~/TICK/) {
    AddTickSortedData();
  } elsif ($table=~/ADDR/) {
    AddAddrSortedData();
  } elsif ($table=~/ALL/) {
    AddTickSortedData();
    AddAddrSortedData();
  }
  AddFunctionInformation();
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
    my $key;
    my $buf=$_;
    $buf=~s/^([0-9]+\|)([0-9]+\|)([0-9A-F]+)/{$key=$3}/e;
    my $val;
    if ($db->db_get($key,$val)!=0) {
      $val="Unknown Module|Unknown Function";
    }
    $_=~s/($key)/$val|$1/;
  }
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
    my $key;
    my $buf=$_;
    $buf=~s/^([0-9A-F]+)/{$key=$1}/e;
    $h_stat{$key}=$_;
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
## GetRawValuesFromIDs
##  0 => Thread ID, 1 => List Of IDs (empty for all)
##-----------------------------------------------------------------------------
sub GetRawValuesFromIDs{
  my ($tid,$off,@idx)=@_;

  $g_db_RAW=tie(@g_tie_RAW,'BerkeleyDB::Recno',
                -Filename    => $f_logdb,
                -Subname     => "RAW#$tid",
                -Flags       => DB_RDONLY,
                -Property    => DB_RENUMBER)
    || die("Error: $BerkeleyDB::Error");
  if (!defined($g_db_RAW)) {
    return ();
  }
  if (SetDBFilters($g_db_RAW)) {
    return ();
  }

  my @results=();
  if ($#idx<0) {
    if (!defined($off) || $off<0) {
      $off=0;
    }
    @idx=($off..$#g_tie_RAW);
  }

  foreach (@idx) {
    push(@results,$_."|".$g_tie_RAW[$_]);
  }


  undef $g_db_RAW;
  untie @g_tie_RAW;

  return @results;
}

##-----------------------------------------------------------------------------
## GetTickSortedValues
##  0 => The sub database name, 1 => Thread ID, 2 => Max size (0 for all)
##-----------------------------------------------------------------------------
sub GetTickSortedValues{
  return GetSortedData("TICK",$_[0],$_[1]-1);
}

##-----------------------------------------------------------------------------
## GetAddrSortedData
##-----------------------------------------------------------------------------
sub GetAddrSortedData{
  my ($tid,$key,$max)=@_;
  if ($max<0) {
    return ();
  }

  my $db;
  $db=new BerkeleyDB::Btree
    -Filename    => $f_logdb,
      -Subname     => "FUNCALL#$tid",
        -Flags       => DB_RDONLY,
          -Property    => DB_DUP|DB_DUPSORT
            || die("Error: $BerkeleyDB::Error");
  if (!defined($db)) {
    return ();
  }
  if (SetDBFilters($db)) {
    return ();
  }

  my $v="";
  my $dbc=$db->db_cursor();
  if (0!=$dbc->c_get($key,$v,DB_SET)) {
    undef $dbc;
    return ();
  }
  my $count=0;
  $dbc->c_count($count);
  undef $dbc;

  my @addr_idx=();
  @addr_idx=GetDuplicateKeyValues($db,$key,$max);
  undef $db;

  my @results=();
  @results=GetRawValuesFromIDs($tid,0,@addr_idx);

  return @results;
}

##-----------------------------------------------------------------------------
## GetThreadIDs
##-----------------------------------------------------------------------------
sub GetThreadIDs{
  my @tie_TID=();
  my $db;
  $db=tie(@tie_TID,'BerkeleyDB::Recno',
          -Filename    => $f_logdb,
          -Subname     => "TID",
          -Flags       => DB_RDONLY,
          -Property    => DB_RENUMBER)
    || die("Error: $BerkeleyDB::Error");
  if (!defined($db)) {
    return ();
  }
  if (SetDBFilters($db)) {
    return ();
  }

  my @results=@tie_TID;

  undef $db;
  untie @tie_TID;

  return @results;
}

##-----------------------------------------------------------------------------
## AddRawLogs
##-----------------------------------------------------------------------------
sub AddRawLogs{
  open(LOGTXT,$f_logtxt) || die("Cannot open \"$f_logtxt\" for read");
  my $key;
  my %h_tid;
  while (<LOGTXT>) {
    chomp();
    my $buf=$_;
    $buf=~s/^([0-9]+)/{$key=$1}/e;
    if (!exists($h_tid{$key})) {
      $h_tid{$key}=new BerkeleyDB::Recno
        -Filename    => $f_logdb,
          -Subname     => "RAW#$key",
            -Flags       => DB_EXCL|DB_CREATE,
              -Property    => DB_RENUMBER
                || return 1;
      next if !defined($h_tid{$key});
      if (SetDBFilters($h_tid{$key})) {
        return 1;
      }
      my $count=0;
      $h_tid{$key}->truncate($count);
    }
    $h_tid{$key}->db_put($key,$_,DB_APPEND);
  } continue {
    delete $h_tid{$key};
  }
  close(LOGTXT);

  my @tids=();
  foreach (keys %h_tid) {
    push(@tids,$_);
    undef $h_tid{$_};
  }

  if ($#tids) {
    AddThreadIDs(@tids);
  }

  return 0;
}

##-----------------------------------------------------------------------------
## AddThreadIDs
##-----------------------------------------------------------------------------
sub AddThreadIDs{
  my @tie_TID=();
  my $db;
  $db=tie(@tie_TID,'BerkeleyDB::Recno',
          -Filename    => $f_logdb,
          -Subname     => "TID",
          -Flags       => DB_EXCL|DB_CREATE,
          -Property    => DB_RENUMBER)
    || return 1;
  if (!defined($db)) {
    return 1;
  }
  if (SetDBFilters($db)) {
    return 1;
  }
  my $count=0;
  $db->truncate($count);

  foreach (@_) {
    push(@tie_TID,$_);
  }
  undef $db;
  untie @tie_TID;

  return 0;
}

##-----------------------------------------------------------------------------
## AddAddrSortedData
##-----------------------------------------------------------------------------
sub AddAddrSortedData{
  foreach (GetThreadIDs()) {
    my $tid=$_;
    my $db;
    $db=new BerkeleyDB::Btree
      -Filename    => $f_logdb,
        -Subname     => "FUNCALL#$tid",
          -Flags       => DB_EXCL|DB_CREATE,
            -Property    => DB_DUP|DB_DUPSORT
              || die("Error: $BerkeleyDB::Error");
    if (!defined($db)) {
      next;
    }
    if (SetDBFilters($db)) {
      next;
    }
    my $count=0;
    $db->truncate($count);

    $g_db_RAW=tie(@g_tie_RAW,'BerkeleyDB::Recno',
                  -Filename    => $f_logdb,
                  -Subname     => "RAW#$tid",
                  -Flags       => DB_RDONLY,
                  -Property    => DB_RENUMBER)
      || last;
    if (!defined($g_db_RAW)) {
      next;
    }
    if (SetDBFilters($g_db_RAW)) {
      next;
    }

    foreach (0..$#g_tie_RAW) {
      my $key;
      my $buf=$g_tie_RAW[$_];
      $buf=~s/^([0-9]+)(\|)([0-9A-F]+)/{$key=$3}/e;
      $db->db_put($key,$_);
    }

    undef $db;
    undef $g_db_RAW;
    untie @g_tie_RAW;
  } continue {
  }

  return 0;
}

##-----------------------------------------------------------------------------
## AddTickSortedData
##-----------------------------------------------------------------------------
sub AddTickSortedData{
  return AddSortedData("TICK",\&TickCompare);
}

##-----------------------------------------------------------------------------
## AddSortedData
##-----------------------------------------------------------------------------
sub AddSortedData{
  my ($base,$func)=@_;
  my $count=0;
  foreach (GetThreadIDs()) {
    my $tid=$_;
    $g_db_RAW=tie(@g_tie_RAW,'BerkeleyDB::Recno',
                  -Filename    => $f_logdb,
                  -Subname     => "RAW#$tid",
                  -Flags       => DB_RDONLY,
                  -Property    => DB_RENUMBER)
      || last;
    if (!defined($g_db_RAW)) {
      last;
    }
    if (SetDBFilters($g_db_RAW)) {
      last;
    }

    my @tie_SORT=();
    my $dbw=tie(@tie_SORT,'BerkeleyDB::Recno',
                -Filename    => $f_logdb,
                -Subname     => "$base#$tid",
                -Flags       => DB_EXCL|DB_CREATE,
                -Property    => DB_RENUMBER)
      || next;
    if (!defined($dbw)) {
      next;
    }
    if (SetDBFilters($dbw)) {
      next;
    }
    $count=0;
    $dbw->truncate($count);

    foreach (sort $func (0..$#g_tie_RAW)) {
      push(@tie_SORT,$_);
    }

    undef $dbw;
    untie @tie_SORT;

    undef $g_db_RAW;
    untie @g_tie_RAW;
  } continue {
  }

  return 0;
}

##-----------------------------------------------------------------------------
## GetSortedData
##-----------------------------------------------------------------------------
sub GetSortedData{
  my ($base,$tid,$max)=@_;

  my $db;
  my @tie_DATA=();
  $db=tie(@tie_DATA,'BerkeleyDB::Recno',
          -Filename    => $f_logdb,
          -Subname     => "$base#$tid",
          -Flags       => DB_RDONLY,
          -Property    => DB_RENUMBER)
    || die("Error: $BerkeleyDB::Error");
  if (!defined($db)) {
    return ();
  }
  if (SetDBFilters($db)) {
    return ();
  }

  my $data_sz=$#tie_DATA;
  if ($data_sz<0) {
    return ();
  }

  if (!defined($max) || $max<0 || $max>$data_sz) {
    $max=$data_sz;
  }

  $g_db_RAW=tie(@g_tie_RAW,'BerkeleyDB::Recno',
                -Filename    => $f_logdb,
                -Subname     => "RAW#$tid",
                -Flags       => DB_RDONLY,
                -Property    => DB_RENUMBER)
    || return ();
  if (!defined($g_db_RAW)) {
    return ();
  }
  if (SetDBFilters($g_db_RAW)) {
    return ();
  }

  my @results=();
  foreach (@tie_DATA[0..$max]) {
    push(@results,$_."|".$g_tie_RAW[$_]);
  }

  undef $db;
  untie @tie_DATA;

  undef $g_db_RAW;
  untie @g_tie_RAW;

  return @results;
}

##-----------------------------------------------------------------------------
## AddFunctionInformation
##-----------------------------------------------------------------------------
sub AddFunctionInformation{
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

  open(LOGFIN,$f_logfin) || die("Cannot open \"$f_logfin\" for read");
  while (<LOGFIN>) {
    chomp();
    my $key;
    my $val;
    my $buf=$_;
    $buf=~s/^([0-9A-F]+)(\|)(.+)(\|[0-9]+)$/{$key=$1;$val=$3}/e;
    $db->db_put($key,$val);
  }
  close(LOGFIN);
  undef $db;

  return 0;
}

##------------------------ Execution starts here ------------------------------
exit ProcessArgs();
