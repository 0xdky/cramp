#!perl
##-----------------------------------------------------------------------------
## File  : querysort.pl
## Desc  : PERL script to sort the query.psf file according to column
#	   in Ascending/Descending order
## Output: Results are written to query.psf
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 12-15-2003  Cre                                                          sjm
##-----------------------------------------------------------------------------
## Usage: PERL querysort.pl #COLUMNNO [0/1]
#	  #COLUMNNO = Column to be sorted
#	  [0/1] = Argument for sorting in Ascending or Descending order
#		  0 = Descending order
#		  1 = Ascending order
##-----------------------------------------------------------------------------
my $Column=$ARGV[0];
my $SortOrder=$ARGV[1];
my @logData=();
my $cramplogdir=".";

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

##-----------------------------------------------------------------------------
## CustomCompare
##	Checks sorting order and sorts the column accordingly
## 	SortOrder = 0 sorts in Descending order, ascending order o/w
##-----------------------------------------------------------------------------

##-----------------------------------------------------------------------------
## Error Trapping Sub...should things go pear shaped!
##-----------------------------------------------------------------------------
sub dienice{
    my($msg) = @_;
    print STDERR $msg;
    exit -1;
}

##-----------------------------------------------------------------------------
## CustomCompare
##-----------------------------------------------------------------------------
sub CustomCompare{
    my @aa=();
    my @bb=();

    if($SortOrder){
        @aa=split(/\|/,$a);
        @bb=split(/\|/,$b);
    }else{
        @aa=split(/\|/,$b);
        @bb=split(/\|/,$a);
    }

    ## Check for numeric or string context
    if($aa[$Column]=~/^[0-9]+$/){
        if($aa[$Column] < $bb[$Column]){
            return -1;
        }elsif($aa[$Column] > $bb[$Column]){
            return 1;
        }
    }else{
        if($aa[$Column] lt $bb[$Column]){
            return -1;
        }elsif($aa[$Column] gt $bb[$Column]){
            return 1;
        }
    }
    return 0;
}

## Read the input query.psf file
open(FILE,"$cramplogdir/query.psf") or dienice("Cannot open query.psf: $!");
my @logData=();
while(<FILE>){
    chomp();
    push(@logData,$_);
}
close(FILE);

## Call the sort method.
## CustomCompare is sub which checks for sorting order & WriteResults
open(fileOUT,">$cramplogdir/query.psf")
    or dienice("Cannot open query.psf: $!");
foreach(sort CustomCompare @logData){
    chomp();
    print fileOUT "$_\n";
}
close(fileOUT);
