#!perl
## Time-stamp: <2004-02-27 18:58:50 dky>
##-----------------------------------------------------------------------------
## File  : profilefilter.pl
## Desc  : PERL script to apply filter to profile log files
## Usage : perl -S profilefilter.pl PID
## Output: Results are written to file names of PID with '.fo' extension
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 02-27-2004  Cre                                                          dky
##-----------------------------------------------------------------------------
if (!exists($ENV{'CRAMP_LOGPATH'})) {
  print STDERR "Error: CRAMP_LOGPATH environmental variable not set\n";
  print STDERR "Usage: perl -S profilefilter.pl PID\n";
  exit 1;
}

if ($#ARGV < 0) {
  print STDERR "Error: Missing PID\n";
  print STDERR "Usage: perl -S profilefilter.pl PID\n";
  exit 1;
}

if (!($ARGV[0]=~/^[0-9]+$/)) {
  print STDERR "Error: PID has to be a number\n";
  print STDERR "Usage: perl -S profilefilter.pl PID\n";
  exit 1;
}

##-----------------------------------------------------------------------------
## Global variables used with in the script
##-----------------------------------------------------------------------------
my $g_pid=$ARGV[0];
my $g_logpath=$ENV{'CRAMP_LOGPATH'};
my $g_filterstring;
my %g_filteredhash=();
my $g_exclude=exists($ENV{'CRAMP_PROFILE_EXCLUSION'});
my $f_filter="$g_logpath/cramp_profile.flt";
my $f_statinfo="$g_logpath/cramp_stat#$g_pid.log";
my $f_profinfo="$g_logpath/cramp_profile#$g_pid.log";
my $f_funcinfo="$g_logpath/cramp_funcinfo#$g_pid.log";

if (! -f $f_filter ||
    ! -f $f_statinfo ||
    ! -f $f_funcinfo ||
    ! -f $f_profinfo) {
  print STDERR "Error: Some profile files are missing under $g_logpath\n";
  print STDERR "Usage: perl -S profilefilter.pl PID\n";
  exit 1;
}

##-----------------------------------------------------------------------------
## MakeFilterString
##-----------------------------------------------------------------------------
sub MakeFilterString{
  open(FILTER,"<$f_filter") ||
    die("Failed in opening \"$f_filter\"");

  my %filterhash=();
  while (<FILTER>) {
    chomp();
    if (length($_)) {
      s/\s//g;
      $filterhash{$_}=1;
    }
  }
  close(FILTER);

  foreach (keys %filterhash) {
    $g_filterstring="$_|".$g_filterstring;
  }

  return 0;
}

##-----------------------------------------------------------------------------
## ApplyFilterOnFuncInfo
##-----------------------------------------------------------------------------
sub ApplyFilterOnFuncInfo{
  open(I_FUNC,"<$f_funcinfo")
    || return 1;
  open(O_FUNC,">$f_funcinfo.fo")
    || return 1;

  my $addr;
  while (<I_FUNC>) {
    chomp();
    if (/$g_filterstring/o) {
      $addr=$_;
      $addr=~s/\|.+//g;
      print O_FUNC "$_\n";
      $g_filteredhash{$addr}=1;
    }
  }
  close(O_FUNC);
  close(I_FUNC);

  return 0;
}

##-----------------------------------------------------------------------------
## ApplyFilterOnProfile
##-----------------------------------------------------------------------------
sub ApplyFilterOnProfile{
  open(I_PROF,"<$f_profinfo")
    || return 1;
  open(O_PROF,">$f_profinfo.fo")
    || return 1;

  my $addr;
  my $filtered;
  while (<I_PROF>) {
    chomp();
    $_=~/^([0-9]+)(\|)([0-9a-fA-F]+)/;
    $addr=$3;
    $filtered=exists($g_filteredhash{$addr});

    if ($g_exclude && !$filtered) {
      print O_PROF "$_\n";
    } elsif (!$g_exclude && $filtered) {
      print O_PROF "$_\n";
    }
  }
  close(O_PROF);
  close(I_PROF);

  return 0;
}

##-----------------------------------------------------------------------------
## ApplyFilterOnStat
##-----------------------------------------------------------------------------
sub ApplyFilterOnStat{
  open(I_STAT,"<$f_statinfo")
    || return 1;
  open(O_STAT,">$f_statinfo.fo")
    || return 1;

  my $addr;
  my $filtered;
  while (<I_STAT>) {
    chomp();
    $_=~/^([0-9a-fA-F]+)/;
    $addr=$1;
    $filtered=exists($g_filteredhash{$addr});

    if ($g_exclude && !$filtered) {
      print O_STAT "$_\n";
    } elsif (!$g_exclude && $filtered) {
      print O_STAT "$_\n";
    }
  }
  close(O_STAT);
  close(I_STAT);

  return 0;
}

##-----------------------------------------------------------------------------
##                             Main Execution Begins Here
##-----------------------------------------------------------------------------
if (MakeFilterString()) {
  exit 1;
}
if (ApplyFilterOnFuncInfo()) {
  exit 1;
}
if (ApplyFilterOnProfile()) {
  exit 1;
}
if (ApplyFilterOnStat()) {
  exit 1;
}

# If all goes well, overwrite the files
if (!exists($ENV{'CRAMP_DEBUG'})) {
  unlink($f_statinfo);
  unlink($f_funcinfo);
  unlink($f_profinfo);
  rename("$f_statinfo.fo",$f_statinfo);
  rename("$f_profinfo.fo",$f_profinfo);
  rename("$f_funcinfo.fo",$f_funcinfo);
}

exit 0;
