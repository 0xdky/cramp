#!perl
## Time-stamp: <2003-10-25 14:20:26 dhruva>
##-----------------------------------------------------------------------------
## File  : dumpdb.pl
## Desc  : PERL script to dump contents of a DB hash
## Usage : perl dumpdb.pl CRAMP_PROFILE.db
## TODO  : Dump dupicate values for a key
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-30-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
use BerkeleyDB;

my $f_logdb;
my $f_logtxt;

if($#ARGV>=0){
    $f_logtxt=$ARGV[0];
    $f_logtxt=~tr/\\/\//;
    $f_logdb=$f_logtxt;
    $f_logdb=~s/\..+$//g;
    $f_logdb.=".db";
}else{
    print(STDERR "Error: Please specify CRAMP log and db file");
    exit 1;
}

##-----------------------------------------------------------------------------
## GetKeyValues
##  0 => The sub database name, 1 => Key
##-----------------------------------------------------------------------------
sub GetKeyValues{
    my @results=();

    my $db=new BerkeleyDB::Hash
        -Filename => $f_logdb,
        -Subname  => $_[0],
        -Property => DB_DUP
        || die("Cannot open file $f_logdb: $! $BerkeleyDB::Error\n");

    my($k,$v)=($_[1],"");
    my $cursor=$db->db_cursor();
    if($cursor->c_get($k,$v,DB_FIRST)){
        die("No Keys in DB!");
    }

    # Access the right key
    while($k!=$_[1] && $cursor->c_get($k,$v,DB_NEXT)==0){};

    do{
        push(@results,$v);
    }while($cursor->c_get($k,$v,DB_NEXT_DUP)==0);

    undef $cursor;
    undef $db;
    return @results;
}

##-----------------------------------------------------------------------------
## LogToDB
##  0 => Flat log file, 1 => Output DB file
##-----------------------------------------------------------------------------
sub LogToDB{
    open(LOGTXT,"<$_[0]") || die("Cannot open \"$_[0]\" for read");
    unlink $_[1];

    my $db_TID_FUNC;
    $db_TID_FUNC=new BerkeleyDB::Hash
        -Filename => $_[1],
        -Subname  => "TID_FUNC",
        -Property => DB_DUP,
        -Flags    => DB_CREATE
        || die("Cannot open \"$_[1]\" file: $BerkeleyDB::Error");

    while(<LOGTXT>){
        chomp();
        my @tokens=split(/\|/,$_);
        $db_TID_FUNC->db_put($tokens[0],$tokens[1]);
    }
    close(LOGTXT);
    undef $db_TID_FUNC;
}

&LogToDB($f_logtxt,$f_logdb);
@values=&GetKeyValues("TID_FUNC",$ARGV[1]);
print "Thread: $ARGV[1] made $#values calls\n"
