#!perl
## Time-stamp: <2003-10-27 15:56:58 dhruva>
##-----------------------------------------------------------------------------
## File  : profileDB.pl
## Desc  : PERL script to dump contents of a DB hash and query
## Usage : perl profileDB.pl PID DUMP|QUERY
##                           THREADS|TID
##                           SORT|RAW|ADDR
##                           COUNT|-1 (for count info only)
##         Results are writte to query.psf
## Desc  : Call SetDBFilters on all DB handles
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-30-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
## Log file syntax:
##  Thread ID|Function address|Depth|Return status|Time in Ms|Ticks
## Function information syntax:
##  Function Address|Module name|Function name|Total number of calls
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
my $f_queryout;
my $cramplogdir=".";

##-----------------------------------------------------------------------------
## WriteResults
##-----------------------------------------------------------------------------
sub WriteResults{
    open(QUERYOUT,">$f_queryout")
        || die("Cannot open \"$f_queryout\" for write");
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
            print STDERR "Error: Invalid \"$cramplogdir\" log path";
            return 1;
        }
    }

    @ARGV=map(uc,@ARGV);
    if($#ARGV<1){
        print STDERR "Error: Insufficient argument";
        return 1;
    }

    $g_pid=$ARGV[0];
    $f_logdb="$cramplogdir/cramp#$g_pid.db";

    if($ARGV[1]=~/DUMP/){
        UpdateDB();
        return 0;
    }elsif($ARGV[1]=~/QUERY/){
        $f_queryout="$cramplogdir/query.psf";
        unlink $f_queryout;

        if(! -f $f_logdb){
            print STDERR "Error: DB file for \"$g_pid\" PID not found";
            return 1;
        }

        my @tids=GetThreadIDs();
        if($ARGV[2]=~/THREAD[S]?/){
            WriteResults(@tids);
            return 0;
        }

        my $key=0;
        my $max=$ARGV[4];
        if($ARGV[2]=~/[0-9]+/){
            foreach(@tids){
                if($_==$ARGV[2]){
                    $key=$_;
                    last;
                }
            }
            if(!$key){
                print STDERR "Error: Thread ID not found";
                return 1;
            }

            if($ARGV[3]=~/SORT/){
                @values=GetTickSortedValues($key,$max);
            }elsif($ARGV[3]=~/RAW/){
                @values=GetRawValues($key,$max);
            }
        }elsif($ARGV[2]=~/COUNT/){
            if($ARGV[3]=~/[0-9ABCDEF]+/){
                $key=$ARGV[3];
                @values=GetFunctionCalls($key,$max);
            }
        }

        # Add the function name and module name for results
        AppendFuncInfoToLogs(@values);
        return WriteResults(@values);
    }else{
        print STDERR "Error: Unknown command";
        return 1;
    }
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
## UpdateDB
##-----------------------------------------------------------------------------
sub UpdateDB{
    $f_logtxt="$cramplogdir/cramp_profile#$g_pid.log";
    $f_logfin="$cramplogdir/cramp_funcinfo#$g_pid.log";

    if(!(-f $f_logtxt && -f $f_logfin)){
        print STDERR "Error: Log files for \"$g_pid\" PID not found";
        exit 1;
    }

    if(! -f $f_logdb){
        print "Creating Berkeley DB from logs";
        if(DumpLogsToDB()){
            print STDERR "Error: Failed to dump logs to DB";
            exit 1;
        }
        print STDOUT "\nSuccessfully created Berkeley DB from logs";
        exit 0;
    }else{
        my $update=0;
        my @dbinfo=stat($f_logdb);
        my @loginfo=stat($f_logtxt);
        my @funinfo=stat($f_logfin);

        if($loginfo[9]>$dbinfo[9]){
            $update=1;
            print STDOUT "Updating Berkeley DB from logs";
            if(AddRawLogs()){
                print STDERR "Error: Failed in adding raw logs to DB";
                exit 1;
            }elsif(AddTickSortedData()){
                print STDERR "Error: Failed in adding sorted logs to DB";
                exit 1;
            }
        }
        if($funinfo[9]>$dbinfo[9]){
            $update=1;
            print STDOUT "Updating function info in Berkeley DB from logs";
            if(AddFunctionInformation()){
                print STDERR "Error: Failed in adding function info to DB";
                exit 1;
            }
        }
        if($update){
            print STDOUT "\nSuccessfully updated Berkeley DB from logs";
            exit 0;
        }else{
            print STDOUT "Berkeley DB is upto date";
            exit 0;
        }
    }
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

    my $deffin="Module|Function";
    foreach(@_){
        my @info=split(/\|/,$_);
        my $fin;
        if($db->db_get($info[-5],$fin)!=0){
            $fin="Unknown Module|Unknown Function";
        }
        $_=~s/($info[-5])/$fin|$1/;
    }
    undef $db;

    return 0;
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
        -Compare     => \&TickCompare,
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
## TickCompare
##-----------------------------------------------------------------------------
sub TickCompare{
    my ($key1,$key2)=@_;
    my @l1=split(/\|/,$key1);
    my @l2=split(/\|/,$key2);
    if($l1[-1] lt $l2[-1]){
        return 1;
    }elsif($l1[-1] gt $l2[-1]){
        return -1;
    }
    return 0;
}

##-----------------------------------------------------------------------------
## DepthCompare
##  Higher depth has lower precedence
##-----------------------------------------------------------------------------
sub DepthCompare{
    my ($key1,$key2)=@_;
    my @l1=split(/\|/,$key1);
    my @l2=split(/\|/,$key2);
    if($l1[-4] lt $l2[-4]){
        return 1;
    }elsif($l1[-4] gt $l2[-4]){
        return -1;
    }
    return 0;
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
        -Flags       => DB_CREATE,
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
        my @tokens=split(/\|/,$_);
        $h_tid{$tokens[0]}='';
        $db->db_put($tokens[0],$_);
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
    my @tids=@_;
    my @tie_TID=();
    my $db;
    $db=tie(@tie_TID,'BerkeleyDB::Recno',
            -Filename    => $f_logdb,
            -Subname     => "TID",
            -Flags       => DB_CREATE,
            -Property    => DB_RENUMBER)
        || die("Error: $BerkeleyDB::Error");
    if(!defined($db)){
        return 1;
    }
    if(SetDBFilters($db)){
        return 1;
    }
    my $count=0;
    $db->truncate($count);

    foreach(@tids){
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
        -Flags       => DB_CREATE,
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

    while(<LOGTXT>){
        chomp();
        my @tokens=split(/\|/,$_);
        $db->db_put($tokens[1],$_);
    }
    close(LOGTXT);
    undef $db;

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
        -Flags       => DB_CREATE,
        -Property    => DB_DUP|DB_DUPSORT,
        -Compare     => \&TickCompare,
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

    while(<LOGTXT>){
        chomp();
        my @tokens=split(/\|/,$_);
        $db->db_put($tokens[0],$_);
    }
    close(LOGTXT);
    undef $db;

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
        -Flags       => DB_CREATE
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
        my @tokens=split(/\|/,$_);
        $db->db_put($tokens[0],"$tokens[1]|$tokens[2]");
    }
    close(LOGFIN);
    undef $db;

    return 0;
}

##-----------------------------------------------------------------------------
## DumpLogsToDB
##-----------------------------------------------------------------------------
sub DumpLogsToDB{
    if(AddRawLogs()){
        print STDERR "Error: Failed in adding raw logs to DB";
        return 1;
    }elsif(AddAddrSortedData()){
        print STDERR "Error: Failed in adding sorted logs to DB";
        return 1;
    }elsif(AddTickSortedData()){
        print STDERR "Error: Failed in adding sorted logs to DB";
        return 1;
    }elsif(AddFunctionInformation()){
        print STDERR "Error: Failed in adding function information to DB";
        return 1;
    }
    return 0;
}

##------------------------ Execution starts here ------------------------------
ProcessArgs();
