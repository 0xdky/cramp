#!perl
## Time-stamp: <2003-10-17 14:05:41 dhruva>
##-----------------------------------------------------------------------------
## File  : profsort.pl
## Desc  : PERL script to sort the raw profile output.
## Usaga : perl profsort.pl CRAMP_PROFILE.log
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-30-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
sub sorter{
    my @a=$_[0];
    my @b=$_[1];
    my @aa=split(/:/,$a->[2]);
    my @ab=split(/:/,$b->[2]);
    if($aa[0] lt $ab[0]){
        return -1;
    }elsif($aa[0] gt $ab[0]){
        return 1;
    }
    if($aa[1] < $ab[1]){
        return -1;
    }elsif($aa[1] > $ab[1]){
        return 1;
    }
    if($a->[6] > $b->[6]){
        return -1;
    }
    if($a->[6] < $b->[6]){
        return 1;
    }
    return 0;
}

my $f_logfile;
if($#ARGV>=0){
    $f_logfile=$ARGV[0];
    $f_logfile=~tr/\\/\//;
}else{
    print(STDERR "Error: Please specify CRAMP profile log file");
    exit 1;
}

die("Log File \"$f_logfile\" not found...") unless(-f $f_logfile);
open(LOGIN,"<$f_logfile") || die("Could not open \"$f_logfile\" for read");

my $f_logsumm=$f_logfile.".summ";
open(LOGSUMM,">$f_logsumm") || die("Could not open \"$f_logsumm\" for write");

my @arr_arr=();
my @hsh_summ;

print("Reading log file \"$f_logfile\"...\n");
while(<LOGIN>){
    chomp();
    my @arr=split(/\|/,$_);
    push(@arr_arr,\@arr);
    if(exists($hsh_summ{$arr[2]})){
        $hsh_summ{$arr[2]}->[0]++;
        $hsh_summ{$arr[2]}->[1]+=$arr[6];
    }else{
        $hsh_summ{$arr[2]}=[1,$arr[6]];
    }
}
close(LOGIN);

print("Writing summary file \"$f_logsumm\"...\n");
foreach(keys %hsh_summ){
    print LOGSUMM "$_|$hsh_summ{$_}->[0]|$hsh_summ{$_}->[1]\n";
}
close(LOGSUMM);
print("Created summary file \"$f_logsumm\"\n");

# No sorting
if($#ARGV==0){
    exit 0;
}

my $f_logsort=$f_logfile.".sort";
open(LOGSORT,">$f_logsort") || die("Could not open \"$f_logsort\" for write");

print("Sorting log file...\n");
@arr_arr=sort sorter @arr_arr;

print("Writing out sorted log file to \"$f_logsort\"...\n");
foreach(@arr_arr){
    print LOGSORT join("|",@$_) . "\n";
}
close(LOGSORT);
print("Created sorted log file \"$f_logsort\"\n");
