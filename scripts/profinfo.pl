#!perl
## Time-stamp: <2003-10-16 11:18:50 dhruva>
##-----------------------------------------------------------------------------
## File: profinfo.pl
## Desc: PERL script to extract useful information from function profiler
##       output.
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-30-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
# Profiler log file: profile.log
my $f_logfile;
if($#ARGV>=0){
    $f_logfile=$ARGV[0];
    $f_logfile=~tr/\\/\//;
}else{
    print(STDERR "Error: Please specify CRAMP profile log file");
    exit 1;
}

# Make xml file name
my $f_xmlfile=$f_logfile;
$f_xmlfile=~s/\..+$//g;
$f_xmlfile.=".xml";

die("Log File \"$f_logfile\" not found...") unless(-f $f_logfile);

open(LOG,"<$f_logfile") || die("Could not open \"$f_logfile\" for read");
my @f_loglines=();
while(<LOG>){
    chomp();
    push(@f_loglines,$_);
}
close(LOG);

@f_loglines=sort(@f_loglines);
my %f_hash;
foreach(@f_loglines){
    my @arr=split(/\|/,$_);
    # Thread, module, time, tick, return
    my @larr=
        (
         [$arr[0],$arr[1],$arr[4],$arr[5],$arr[6]]
        );
    if(exists($f_hash{$arr[2]})){
        my @oarr=@{$f_hash{$arr[2]}};
        push(@oarr,@larr);
        $f_hash{$arr[2]}=\@oarr;
    }else{
        $f_hash{$arr[2]}=\@larr;
    }
}

open(XML,">$f_xmlfile") || die("Cannot open \"$f_xmlfile\" for write");
select(XML);
print("<?xml version=\"1.0\"?>\n");
print("<SCENARIO>\n");
foreach(keys %f_hash){
    my @larr=@{$f_hash{$_}};
    my $func=$_;
    $func=~s/</&lt;/g;
    $func=~s/>/&gt;/g;
    print("<FUNCTION NAME=\"$func\" CALLS=\"",$#larr+1,"\">\n");
    my $cc=1;
    # Thread, module, time, tick, return
    foreach(@larr){
        print("<CALL\n ");
        print("ID=\"$cc\" ");
        print("MODULE=\"@{$_}[1]\" ");
        print("THREAD=\"@{$_}[0]\" ");
        print("TIME=\"@{$_}[3]\" ");
        print("TICKS=\"@{$_}[4]\" ");
        print("RETURN=\"@{$_}[2]\" ");
        print("/>\n");
        $cc++;
    }
    print("</FUNCTION>\n");
}
print("</SCENARIO>");
select(STDOUT);
close(XML);
