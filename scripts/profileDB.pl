#!perl
## Time-stamp: <2003-10-31 15:18:00 dhruva>
##-----------------------------------------------------------------------------
## File  : profileDB.pl
## Desc  : PERL script to dump contents of a DB hash and query
## Usage : perl profileDB.pl ARGS
## ARGS  : PID DUMP [ALL|RAW|TICK|ADDR]|
##         PID QUERY STAT [APPEND]
##         PID QUERY THREADS [APPEND]
##         PID QUERY thread_id|ALL RAW|TICK limit [APPEND]
##         PID QUERY ADDR function_address limit (-1 for count only) [APPEND]
## Output: Results are written or appended to query.psf
## Desc  : Call SetDBFilters on all DB handles
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-30-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
## Log file syntax:
##  Thread ID|Function address|Depth|Return status|Time in Ms|Ticks
## Function information syntax:
##  Function Address|Module name|Function name|Total number of calls
## Stat file syntax:
##  Function address|Number of calls|Total ticks|Single max tick
## Table names:
##  TID: RECNO of thread IDs
##  FUNC_INFO: HASH of function address VS module name and function name
##  TID_FUNC: HASH of thread ID VS function call details
##  TID_FUNC_SORT_TICK: BTREE of thread ID VS tick sorted function calls
##  ADDR_FUNC_SORT: BTREE of thread ID VS address sorted functions
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

##-----------------------------------------------------------------------------
## usage
##-----------------------------------------------------------------------------
sub usage{
    print"Usage : perl $progname ARGS
ARGS  : PID DUMP [ALL|RAW|TICK|ADDR]|
        PID QUERY STAT [APPEND]
        PID QUERY THREADS [APPEND]
        PID QUERY thread_id|ALL RAW|TICK limit [APPEND]
        PID QUERY ADDR function_address limit (-1 for count only) [APPEND]
Output: Results are written or appended to query.psf
";
    return 0;
}

##-----------------------------------------------------------------------------
## SetDBFilters
##  Install DBM Filters to make NULL terminated strings
##-----------------------------------------------------------------------------
sub SetDBFilters{
    if(!defined($_[0])){
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
    my $k1=$_[0];
    my $k2=$_[1];

    $k1=~s/\0$//;
    $k2=~s/\0$//;

    $k1=~s/([0-9]+)$/{$key1=$1}/e;
    $k2=~s/([0-9]+)$/{$key2=$1}/e;

    if($key1 < $key2){
        return 1;
    }elsif($key1 > $key2){
        return -1;
    }
    return 0;
}

##-----------------------------------------------------------------------------
## WriteResults
##-----------------------------------------------------------------------------
sub WriteResults{
    if(g_append){
        open(QUERYOUT,">>$f_queryout")
            || die("Cannot open \"$f_queryout\" for write");
    }else{
        open(QUERYOUT,">$f_queryout")
            || die("Cannot open \"$f_queryout\" for write");
    }

    foreach(@_){
        print QUERYOUT "$_\n";
        if($ENV{'DEBUG'}){
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

    if($ENV{'CRAMP_LOGPATH'}){
        $cramplogdir=$ENV{'CRAMP_LOGPATH'};
        $cramplogdir=~tr/\\/\//;
        $cramplogdir=~s/\/+$//g;
        $cramplogdir=~s/\/{2,}/\//g;
        if(! -d $cramplogdir){
            print STDERR "Error: Invalid \"$cramplogdir\" log path\n";
            return 1;
        }
    }

    @ARGV=map(uc,@ARGV);

    foreach(@ARGV){
        if(/HELP/){
            usage();
            return 0;
        }
    }

    if($#ARGV<1){
        print STDERR "Error: Insufficient argument\n";
        return 1;
    }

    if($ARGV[-1]=~/APPEND/){
        $g_append=1;
    }

    $g_pid=$ARGV[0];

    $f_logdb="$cramplogdir/cramp#$g_pid.db";
    $f_logtxt="$cramplogdir/cramp_profile#$g_pid.log";
    $f_logfin="$cramplogdir/cramp_funcinfo#$g_pid.log";
    $f_logstat="$cramplogdir/cramp_stat#$g_pid.log";

    if($ARGV[1]=~/DUMP/){
        foreach($ARGV[2]..$ARGV[-1]){
            UpdateDB($_);
        }
        return 1;
    }elsif($ARGV[1]=~/QUERY/){
        $f_queryout="$cramplogdir/query.psf";
        if(!$g_append){
            unlink $f_queryout;
        }

        if($ARGV[2]=~/STAT/){
            if(! -f $f_logstat){
                return -1;
            }
            return GetProfileStat();
        }

        if(! -f $f_logdb){
            print STDERR "Error: DB file for \"$g_pid\" PID not found\n";
            return 1;
        }

        my @tids=GetThreadIDs();
        if($ARGV[2]=~/THREAD[S]?/){
            WriteResults(@tids);
            return 0;
        }

        my $key=0;
        my $max=$ARGV[4];
        if($ARGV[2]=~/([0-9]+)|ALL/){
            my @tidlist=();
            if($ARGV[2]=~/ALL/){
                @tidlist=@tids;
            }else{
                foreach(@tids){
                    if($_==$ARGV[2]){
                        push(@tidlist,$_);
                        last;
                    }
                }
            }

            if($#tidlist<0){
                print STDERR "Error: Thread ID not found\n";
                return 1;
            }

            if($ARGV[3]=~/TICK/){
                foreach(@tidlist){
                    push(@values,GetTickSortedValues($_,$max));
                }
            }elsif($ARGV[3]=~/RAW/){
                foreach(@tidlist){
                    push(@values,GetRawValues($_,$max));
                }
            }
        }elsif($ARGV[2]=~/ADDR/){
            if($ARGV[3]=~/[0-9ABCDEFX]+/){
                $key=$ARGV[3];
                @values=GetFunctionCalls($key,$max);
            }
        }

        # Add the function name and module name for results
        AppendFuncInfoToLogs(@values);
        return WriteResults(@values);
    }else{
        print STDERR "Error: Unknown command\n";
        return 1;
    }

    return 0;
}

##-----------------------------------------------------------------------------
## UpdateDB
##-----------------------------------------------------------------------------
sub UpdateDB{
    if(!(-f $f_logtxt && -f $f_logfin)){
        print STDERR "Error: Log files for \"$g_pid\" PID not found\n";
        return 1;
    }

    if(-f $f_logdb){
        my $update=0;
        my @dbinfo=stat($f_logdb);
        my @loginfo=stat($f_logtxt);
        my @funinfo=stat($f_logfin);
        if($loginfo[9]>$dbinfo[9] || $funinfo[9]>$dbinfo[9]){
            unlink $f_logdb;
        }
    }

    if(DumpLogsToDB(@_)){
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
    if($table=~/RAW/){
        AddRawLogs();
    }elsif($table=~/TICK/){
        AddTickSortedData();
    }elsif($table=~/ADDR/){
        AddAddrSortedData();
    }elsif($table=~/ALL/){
        AddRawLogs();
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
    if(!defined($db)){
        return 1;
    }
    if(SetDBFilters($db)){
        return 1;
    }

    foreach(@_){
        my $key;
        my $buf=$_;
        $buf=~s/^([0-9]+)(\|)([0-9A-F]+)/{$key=$3}/e;
        my $val;
        if($db->db_get($key,$val)!=0){
            $val="Unknown Module|Unknown Function";
        }
        $_=~s/($key)/$val|$1/;
    }
    undef $db;

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
    if(!defined($db)){
        return 1;
    }
    if(SetDBFilters($db)){
        return 1;
    }

    my %h_stat;
    while(<STAT>){
        chomp();
        my $key;
        my $buf=$_;
        $buf=~s/^([0-9A-F]+)/{$key=$1}/e;
        $h_stat{$key}=$_;
    }
    close(STAT);

    my @list=();
    foreach(sort keys %h_stat){
        my $val;
        if($db->db_get($_,$val)!=0){
            $val="Unknown Module|Unknown Function";
        }
        my $sval=$h_stat{$_};
        $sval=~s/($key)/$val|$1/;
        push(@list,$sval);
    }
    undef $db;

    return WriteResults(@list);
}

##-----------------------------------------------------------------------------
## GetRawValues
##  0 => The sub database name, 1 => Thread ID, 2 => Max size (0 for all)
##-----------------------------------------------------------------------------
sub GetRawValues{
    my $db;
    $db=new BerkeleyDB::Hash
        -Filename    => $f_logdb,
        -Subname     => "TID_FUNC",
        -Flags       => DB_RDONLY,
        -Property    => DB_DUP
        || die("Error: $BerkeleyDB::Error");
    if(!defined($db)){
        return ();
    }
    if(SetDBFilters($db)){
        return ();
    }

    my @results=GetDuplicateKeyValues($db,$_[0],$_[1]);
    undef $db;
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
        -Subname     => "TID_FUNC_SORT_TICK",
        -Flags       => DB_RDONLY,
        -Property    => DB_DUP|DB_DUPSORT,
        -DupCompare  => \&TickCompare
        || die("Error: $BerkeleyDB::Error");
    if(!defined($db)){
        return ();
    }
    if(SetDBFilters($db)){
        return ();
    }

    my @results=GetDuplicateKeyValues($db,$_[0],$_[1]);
    undef $db;
    return @results;
}

##-----------------------------------------------------------------------------
## GetDuplicateKeyValues
##  0 => Handle to DB, 1 => Key, 2 => Max size (0 for all)
##-----------------------------------------------------------------------------
sub GetDuplicateKeyValues{
    if(!defined($_[0])){
        warn("GetDuplicateKeyValues: Undefined DB handle");
        return ();
    }

    my($k,$v)=($_[1],"");
    my $dbc=$_[0]->db_cursor();
    if(0!=$dbc->c_get($k,$v,DB_SET)){
        undef $dbc;
        return ();
    }

    my $max=0;
    $dbc->c_count($max);
    if($_[2] && $_[2]<$max){
        $max=$_[2];
    }

    my $cc=1;
    my @results=();
    push(@results,$v);
    while(0==$dbc->c_get($k,$v,DB_NEXT_DUP)){
        if($cc==$max){
            last;
        }
        $cc++;
        push(@results,$v);
    }

    undef $dbc;
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
    if(!defined($db)){
        return ();
    }
    if(SetDBFilters($db)){
        return ();
    }

    my @results=();
    foreach(@tie_TID){
        push(@results,$_);
    }
    undef $db;
    untie @tie_TID;

    return @results;
}

##-----------------------------------------------------------------------------
## GetFunctionCalls
##-----------------------------------------------------------------------------
sub GetFunctionCalls{
    my $db;
    $db=new BerkeleyDB::Btree
        -Filename    => $f_logdb,
        -Subname     => "ADDR_FUNC_SORT",
        -Flags       => DB_RDONLY,
        -Property    => DB_DUP|DB_DUPSORT
        || die("Error: $BerkeleyDB::Error");
    if(!defined($db)){
        return ();
    }
    if(SetDBFilters($db)){
        return ();
    }

    my($k,$v)=($_[0],"");
    my $dbc=$db->db_cursor();
    if(0!=$dbc->c_get($k,$v,DB_SET)){
        undef $dbc;
        return ();
    }
    my $count=0;
    $dbc->c_count($count);
    undef $dbc;

    my @results=();
    if($_[1]<0){
        push(@results,"0|$_[0]|0|0|0|$count");
    }else{
        @results=GetDuplicateKeyValues($db,$_[0],$_[1]);
    }

    undef $db;

    return @results;
}

##-----------------------------------------------------------------------------
## AddRawLogs
##-----------------------------------------------------------------------------
sub AddRawLogs{
    open(LOGTXT,$f_logtxt) || die("Cannot open \"$f_logtxt\" for read");
    my $db;
    $db=new BerkeleyDB::Hash
        -Filename    => $f_logdb,
        -Subname     => "TID_FUNC",
        -Flags       => DB_EXCL|DB_CREATE,
        -Property    => DB_DUP
        || die("Error: $BerkeleyDB::Error");
    if(!defined($db)){
        return 1;
    }
    if(SetDBFilters($db)){
        return 1;
    }
    my $count=0;
    $db->truncate($count);

    my %h_tid;
    while(<LOGTXT>){
        chomp();
        my $key;
        my $buf=$_;
        $buf=~s/^([0-9]+)/{$key=$1}/e;
        $h_tid{$key}='';
        $db->db_put($key,$_);
    }
    close(LOGTXT);
    undef $db;

    my @tids=();
    foreach(keys %h_tid){
        push(@tids,$_);
    }
    AddThreadIDs(@tids);

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
    if(!defined($db)){
        return 1;
    }
    if(SetDBFilters($db)){
        return 1;
    }
    my $count=0;
    $db->truncate($count);

    foreach(@_){
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
    open(LOGTXT,$f_logtxt) || die("Cannot open \"$f_logtxt\" for read");
    my $db;
    $db=new BerkeleyDB::Btree
        -Filename    => $f_logdb,
        -Subname     => "ADDR_FUNC_SORT",
        -Flags       => DB_EXCL|DB_CREATE,
        -Property    => DB_DUP|DB_DUPSORT
        || die("Error: $BerkeleyDB::Error");
    if(!defined($db)){
        return 1;
    }
    if(SetDBFilters($db)){
        return 1;
    }
    my $count=0;
    $db->truncate($count);

    my %h_tid;
    while(<LOGTXT>){
        chomp();
        my $key1,$key2;
        my $buf=$_;
        $buf=~s/^([0-9]+)(\|)([0-9A-F]+)/{$key1=$1;$key2=$3}/e;
        $h_tid{$key1}='';
        $db->db_put($key2,$_);
    }
    close(LOGTXT);
    undef $db;

    my @tids=();
    foreach(keys %h_tid){
        push(@tids,$_);
    }
    AddThreadIDs(@tids);

    return 0;
}

##-----------------------------------------------------------------------------
## AddTickSortedData
##-----------------------------------------------------------------------------
sub AddTickSortedData{
    open(LOGTXT,$f_logtxt) || die("Cannot open \"$f_logtxt\" for read");
    my $db;
    $db=new BerkeleyDB::Btree
        -Filename    => $f_logdb,
        -Subname     => "TID_FUNC_SORT_TICK",
        -Flags       => DB_EXCL|DB_CREATE,
        -Property    => DB_DUP|DB_DUPSORT,
        -DupCompare  => \&TickCompare
        || die("Error: $BerkeleyDB::Error");
    if(!defined($db)){
        return 1;
    }
    if(SetDBFilters($db)){
        return 1;
    }
    my $count=0;
    $db->truncate($count);

    my %h_tid;
    while(<LOGTXT>){
        chomp();
        my $key;
        my $buf=$_;
        $buf=~s/^([0-9]+)/{$key=$1}/e;
        $h_tid{$key}='';
        $db->db_put($key,$_);
    }
    close(LOGTXT);
    undef $db;

    my @tids=();
    foreach(keys %h_tid){
        push(@tids,$_);
    }
    AddThreadIDs(@tids);

    return 0;
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
    if(!defined($db)){
        return 1;
    }
    if(SetDBFilters($db)){
        return 1;
    }
    my $count=0;
    $db->truncate($count);

    open(LOGFIN,$f_logfin) || die("Cannot open \"$f_logfin\" for read");
    while(<LOGFIN>){
        chomp();
        my $key,$val;
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
