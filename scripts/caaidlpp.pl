#!perl
## Time-stamp: <2003-11-06 16:13:40 dhruva>
##-----------------------------------------------------------------------------
## File  : caaidlpp.pl
## Usage : caaidlpp.pl listOfIdl OUTPATH
## Desc  : Comment out the square brackets for doc generation
## TODO  : Needs refinement
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                     user
## 11-06-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
my $default="// COPYRIGHT DASSAULT SYSTEMES 2000 / DELMIA CORP 2003
/**
  *  \@CAA2Level L1
  *  \@CAA2Usage U4
  */
";

if($#ARGV<1){
    print STDERR "Error: Specifiy file list";
    exit 1;
}

my $f_list=$ARGV[0];
$f_list=~s/\\/\//g;
if(! -f $f_list){
    print STDERR "Error: \"$f_list\" file does not exist";
    exit 1;
}

my $OUTPATH=$ARGV[1];
$OUTPATH=~s/\\/\//g;
if(! -d $OUTPATH){
    print STDERR "Error: \"$OUTPATH\" folder does not exist";
    exit 1;
}

open(LIST,"<$f_list") || die("Cannot open \"$f_list\" for read");
while(<LIST>){
    chomp();
    s/\\/\//g;
    if(! -f $_){
        next;
    }

    my @arr=split(/\//,$_);
    print "Processing: $arr[-1]\n";
    my $f_out="$OUTPATH/$arr[-1]";
    open(IDLIN,"<$_") || die("Cannot open \"$_\" for read");
    open(IDLOUT,">$f_out") || die("Cannot open \"$f_out\" for write");
    print IDLOUT $default;
    while(<IDLIN>){
        s/(\[)/\/\*$1/g;
        s/(\])/$1\*\//g;
        print IDLOUT $_;
    }
    close(IDLIN);
    close(IDLOUT);
}
close(LIST);
