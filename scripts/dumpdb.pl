#!perl
## Time-stamp: <2003-10-26 14:53:32 dhruva>
##-----------------------------------------------------------------------------
## File  : dumpdb.pl
## Desc  : PERL script to dump contents of a DB hash
## Usage : perl dumpdb.pl PID
## Desc  : Call SetDBFilters on all DB handles
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-30-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
## Log file syntax:
##  Thread ID|Function address|Depth|Return status|Time in Ms|Ticks
## Function information syntax:
##  Function Address|Module name|Function name|Total number of calls
##-----------------------------------------------------------------------------
use DB_File;
use BerkeleyDB;

my $f_logdb;
my $f_logtxt;
my $f_logfin;

if($#ARGV>=0){
    $f_logtxt="cramp_profile#$ARGV[0].log";
    $f_logfin="cramp_funcinfo#$ARGV[0].log";
    $f_logdb="cramp#$ARGV[0].db";
    if(!(-f $f_logtxt && -f $f_logfin)){
        print(STDERR "Error: Log files for \"$ARGV[0]\" PID not found");
        exit 1;
    }
}else{
    print(STDERR "Error: Please specify CRAMP log and db file");
    exit 1;
}

##-----------------------------------------------------------------------------
## SetDBFilters
##  Install DBM Filters to make NULL terminated strings
##-----------------------------------------------------------------------------
sub SetDBFilters{
    if(!defined(@_[0])){
        warn("Undefined DB handle");
        return;
    }
    @_[0]->filter_fetch_key  ( sub { s/\0$//    } ) ;
    @_[0]->filter_store_key  ( sub { $_ .= "\0" } ) ;
    @_[0]->filter_fetch_value( sub { s/\0$//    } ) ;
    @_[0]->filter_store_value( sub { $_ .= "\0" } ) ;
    return;
}

##-----------------------------------------------------------------------------
## GetRawDuplicateKeyValues
##  0 => The sub database name, 1 => Key, 2 => Max size (0 for all)
##-----------------------------------------------------------------------------
sub GetRawDuplicateKeyValues{
    my $db=new BerkeleyDB::Hash
        -Filename    => $f_logdb,
        -Subname     => @_[0],
        -Flags       => DB_RDONLY,
        -Property    => DB_DUP
        || die("Error: $BerkeleyDB::Error");
    my @results=&GetDuplicateKeyValues($db,@_[1],@_[2]);
    undef $db;
    return @results;
}

##-----------------------------------------------------------------------------
## GetSortedDuplicateKeyValues
##  0 => The sub database name, 1 => Key, 2 => Max size (0 for all)
##-----------------------------------------------------------------------------
sub GetSortedDuplicateKeyValues{
    my $db=new BerkeleyDB::Btree
        -Filename    => $f_logdb,
        -Subname     => @_[0],
        -Flags       => DB_RDONLY,
        -Property    => DB_DUP|DB_DUPSORT,
        -Compare     => \&TickCompare,
        -DupCompare  => \&TickCompare
        || die("Error: $BerkeleyDB::Error");
    my @results=&GetDuplicateKeyValues($db,@_[1],@_[2]);
    undef $db;
    return @results;
}

##-----------------------------------------------------------------------------
## GetDuplicateKeyValues
##  0 => Handle to DB, 1 => Key, 2 => Max size (0 for all)
##-----------------------------------------------------------------------------
sub GetDuplicateKeyValues{
    my @results=();
    if(!defined(@_[0])){
        warn("Undefined DB handle");
        return @results;
    }

    &SetDBFilters(@_[0]);
    my($k,$v)=(@_[1],"");
    my $dbc=@_[0]->db_cursor();
    if(0!=$dbc->c_get($k,$v,DB_SET)){
        warn("Key \"$k\" not found");
        undef $dbc;
        return @results;
    }

    my $max=0;
    $dbc->c_count($max);
    if(@_[2] && @_[2]<$max){
        $max=@_[2];
    }

    my $cc=1;
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
    tie(@tie_TID,'BerkeleyDB::Recno',
        -Filename    => $f_logdb,
        -Subname     => "TID",
        -Flags       => DB_RDONLY,
        -Property    => DB_RENUMBER)
        || die("Error: $BerkeleyDB::Error");
    foreach(@tie_TID){
        s/\0$//;
        push(@results,$_);
    }
    untie @tie_TID;
    return @results;
}

##-----------------------------------------------------------------------------
## TickCompare
##-----------------------------------------------------------------------------
sub TickCompare{
    my ($key1,$key2)=@_;
    my @l1=split(/\|/,$key1);
    my @l2=split(/\|/,$key2);
    if($l1[-1]<$l2[-1]){
        return 1;
    }elsif($l1[-1]>$l2[-1]){
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
    if($l1[-4]<$l2[-4]){
        return 1;
    }elsif($l1[-4]>$l2[-4]){
        return -1;
    }
    return 0;
}

##-----------------------------------------------------------------------------
## LogToDB
##-----------------------------------------------------------------------------
sub LogToDB{
    # Process the main log file
    my $db_TID_FUNC;
    $db_TID_FUNC=new BerkeleyDB::Hash
        -Filename    => $f_logdb,
        -Subname     => "TID_FUNC",
        -Flags       => DB_CREATE,
        -Property    => DB_DUP
        || die("Error: $BerkeleyDB::Error");
    &SetDBFilters($db_TID_FUNC);

    my %h_tid;
    open(LOGTXT,$f_logtxt) || die("Cannot open \"$f_logtxt\" for read");
    while(<LOGTXT>){
        chomp();
        my @tokens=split(/\|/,$_);
        my $key=$tokens[0];
        $h_tid{$key}='';
        shift @tokens;
        my $val=join('|',@tokens);
        $db_TID_FUNC->db_put($key,$val);
    }
    close(LOGTXT);
    undef $db_TID_FUNC;

    # Add RECNO of thread IDs
    my @tie_TID=();
    tie(@tie_TID,'BerkeleyDB::Recno',
        -Filename    => $f_logdb,
        -Subname     => "TID",
        -Flags       => DB_CREATE,
        -Property    => DB_RENUMBER)
        || die("Error: $BerkeleyDB::Error");
    foreach(keys %h_tid){
        $_.="\0";
        push(@tie_TID,$_);
    }
    untie @tie_TID;

    # Open the DB and get info to avoid mem corruption
    $db_TID_FUNC=new BerkeleyDB::Hash
        -Filename    => $f_logdb,
        -Subname     => "TID_FUNC",
        -Flags       => DB_RDONLY,
        -Property    => DB_DUP
        || die("Error: $BerkeleyDB::Error");
    &SetDBFilters($db_TID_FUNC);

    $db_TID_FUNC_SORT_TICK=new BerkeleyDB::Btree
        -Filename    => $f_logdb,
        -Subname     => "TID_FUNC_SORT_TICK",
        -Flags       => DB_CREATE,
        -Property    => DB_DUP|DB_DUPSORT,
        -Compare     => \&TickCompare,
        -DupCompare  => \&TickCompare
        || die("Error: $BerkeleyDB::Error");
    &SetDBFilters($db_TID_FUNC_SORT_TICK);

    my $dbc_TID_FUNC=$db_TID_FUNC->db_cursor();
    foreach(keys %h_tid){
        my($key,$val)=($_,"");
        if(0!=$dbc_TID_FUNC->c_get($key,$val,DB_SET)){
            warn("Key \"$key\" not found");
            last;
        }

        $db_TID_FUNC_SORT_TICK->db_put($key,$val);
        while(0==$dbc_TID_FUNC->c_get($key,$val,DB_NEXT_DUP)){
            $db_TID_FUNC_SORT_TICK->db_put($key,$val);
        }
    }
    undef $dbc_TID_FUNC;
    undef $db_TID_FUNC;
    undef $db_TID_FUNC_SORT_TICK;

    # Add the func info (module and function name)
    my $db_FUNC_INFO;
    $db_FUNC_INFO=new BerkeleyDB::Hash
        -Filename    => $f_logdb,
        -Subname     => "FUNC_INFO",
        -Flags       => DB_CREATE
        || die("Error: $BerkeleyDB::Error");
    &SetDBFilters($db_FUNC_INFO);

    open(LOGFIN,$f_logfin) || die("Cannot open \"$f_logfin\" for read");
    while(<LOGFIN>){
        chomp();
        my @tokens=split(/\|/,$_);
        $db_FUNC_INFO->db_put($tokens[0],"$tokens[1]|$tokens[2]");
    }
    close(LOGFIN);
    undef $db_FUNC_INFO;

    return;
}

##-----------------------------------------------------------------------------
## AddFuncInfoToLogs
##  Adds the function name and module name to logs. Use it for results.
##-----------------------------------------------------------------------------
sub AddFuncInfoToLogs{
    my $db_FUNC_INFO;
    $db_FUNC_INFO=new BerkeleyDB::Hash
        -Filename    => $f_logdb,
        -Subname     => "FUNC_INFO",
        -Flags       => DB_RDONLY
        || die("Error: $BerkeleyDB::Error");
    &SetDBFilters($db_FUNC_INFO);

    foreach(@_){
        my @info=split(/\|/,$_);
        my $fin;
        if($db_FUNC_INFO->db_get($info[0],$fin)==0){
            $_=~s/$info[0]/$fin/;
        }
    }
    undef $db_FUNC_INFO;
    return;
}

##------------------------ Execution starts here ------------------------------
if(! -f $f_logdb){
    &LogToDB();
}

# Test code
# @values=&GetRawDuplicateKeyValues("TID_FUNC",$ARGV[1],50);
@values=&GetSortedDuplicateKeyValues("TID_FUNC_SORT_TICK",$ARGV[1],50);
# &AddFuncInfoToLogs(@values);
# @values=&GetThreadIDs();

foreach(@values){
    print "$_\n";
}
