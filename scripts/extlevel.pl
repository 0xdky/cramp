#!perl.exe
# Time-stamp: <2004-06-23 12:11:47 dky>
#------------------------------------------------------------------------------
# File : extlevel.pl
# Usage: extlevel.pl PID LEVEL
# Desc : Perl script to extract the function calls at given level. This script
#        creates a file of same name as profile log file with '.out' extension.
#        Ex: for file cramp_profile#1234.log, cramp_profile#1234.log.out.
#------------------------------------------------------------------------------
# 06-22-2004  Cre                                                           dky
#------------------------------------------------------------------------------
my $prog=$0;
$prog=~tr/\\/\//;
my @arr=split('/',$prog);
$prog=$arr[-1];

sub usage{
  print STDERR "usage: $prog PID Level\n";
  exit 1;
}

if ($#ARGV<1) {
  usage();
}

my $pid,$level;
if ($ARGV[0]=~/^[0-9]+$/) {
  $pid=$ARGV[0];
} else {
  usage();
}

if ($ARGV[1]=~/^[0-9]+$/) {
  $level=$ARGV[1];
} else {
  usage();
}

my $logpath='.';
if (exists($ENV{'CRAMP_LOGPATH'})) {
  $logpath=$ENV{'CRAMP_LOGPATH'};
  $logpath=~s/\/+$//g;
}
my $logfile=$logpath.'/cramp_profile#'.$pid.'.log';
open(LOG,"<$logfile") || die("Unable to open \"$logfile\"");
open(OUT,">$logfile.out") || die("Unable to open \"$logfile.out\"");

while (<LOG>) {
  chomp();
  /([0-9]+\|)([0-9ABCDEFX]+\|)([0-9]+)/;
  if ($3==$level) {
    print OUT "$_\n";
  }
}
close(LOG);
close(OUT);
