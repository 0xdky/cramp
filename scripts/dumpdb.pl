#!perl
## Time-stamp: <2003-10-25 18:47:35 dhruva>
##-----------------------------------------------------------------------------
## File  : dumpdb.pl
## Desc  : PERL script to dump contents of a DB hash
## Usage : perl dumpdb.pl PID
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-30-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
## Log file syntax:
##  Thread ID|Function address|Depth|Return status|Time in Ms|Ticks
## Function information syntax:
##  Function Address|Module name|Function name|Total number of calls
##-----------------------------------------------------------------------------
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
## GetDuplicateKeyValues
##  0 => The sub database name, 1 => Key, 2 => Max size (0 for all)
##-----------------------------------------------------------------------------
sub GetDuplicateKeyValues{
    my @results=();

    my $db=new BerkeleyDB::Hash
        -Filename => $f_logdb,
        -Subname  => @_[0],
        -Property => DB_DUP
        || die("Error: $BerkeleyDB::Error");

    my($k,$v)=(@_[1],"");
    my $dbc=$db->db_cursor();
    if(0!=$dbc->c_get($k,$v,DB_SET)){
        undef $dbc;
        undef $db;
        return @results;
    }

    my $max=@_[2]-1;
    push(@results,$v);
    while(0==$dbc->c_get($k,$v,DB_NEXT_DUP)){
        if(@_[2] && $max==$#results){
            last;
        }
        push(@results,$v);
    }

    undef $dbc;
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
    return(0);
}

##-----------------------------------------------------------------------------
## LogToDB
##-----------------------------------------------------------------------------
sub LogToDB{
    # Process the main log file
    my $db_TID_FUNC;
    $db_TID_FUNC=new BerkeleyDB::Hash
        -Filename => $f_logdb,
        -Subname  => "TID_FUNC",
        -Property => DB_DUP,
        -Flags    => DB_CREATE
        || die("Error: $BerkeleyDB::Error");

    $db_TID_FUNC_SORT_TICK=new BerkeleyDB::Hash
        -Filename    => $f_logdb,
        -Subname     => "TID_FUNC_SORT_TICK",
        -Property    => DB_DUP|DB_DUPSORT,
        -DupCompare  => \&TickCompare,
        -Flags       => DB_CREATE
        || die("Error: $BerkeleyDB::Error");

    open(LOGTXT,$f_logtxt) || die("Cannot open \"$f_logtxt\" for read");
    while(<LOGTXT>){
        chomp();
        my @tokens=split(/\|/,$_);
        my $key=$tokens[0];
        shift @tokens;
        my $value=join('|',@tokens);
        $db_TID_FUNC->db_put($key,$value);
        $db_TID_FUNC_SORT_TICK->db_put($key,$value);
    }
    close(LOGTXT);
    undef $db_TID_FUNC;
    undef $db_TID_FUNC_SORT_TICK;

    # Add the func info (module and function name)
    my $db_FUNC_INFO;
    $db_FUNC_INFO=new BerkeleyDB::Hash
        -Filename => $f_logdb,
        -Subname  => "FUNC_INFO",
        -Flags    => DB_CREATE
        || die("Error: $BerkeleyDB::Error");

    open(LOGFIN,$f_logfin) || die("Cannot open \"$f_logfin\" for read");
    while(<LOGFIN>){
        chomp();
        my @tokens=split(/\|/,$_);
        $db_FUNC_INFO->db_put($tokens[0],"$tokens[1]|$tokens[2]");
    }
    close(LOGFIN);
    undef $db_FUNC_INFO;
}

##-----------------------------------------------------------------------------
## AddFuncInfoToLogs
##  Adds the function name and module name to logs. Use it for results.
##-----------------------------------------------------------------------------
sub AddFuncInfoToLogs{
    my $db_FUNC_INFO;
    $db_FUNC_INFO=new BerkeleyDB::Hash
        -Filename => $f_logdb,
        -Subname  => "FUNC_INFO",
        || die("Error: $BerkeleyDB::Error");

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
# @values=&GetDuplicateKeyValues("TID_FUNC",$ARGV[1]);
@values=&GetDuplicateKeyValues("TID_FUNC_SORT_TICK",$ARGV[1],2);
&AddFuncInfoToLogs(@values);

foreach(@values){
    print "$_\n";
}
