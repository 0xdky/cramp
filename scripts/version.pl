#!perl
## Time-stamp: <2004-02-25 18:35:04 dky>
##-----------------------------------------------------------------------------
## File  : version.pl
## Usage : version.pl version MAJOR|MINOR|TRIVIAL
## Desc  : PERL script to update version
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 02-25-2004  Cre  Script to automatically version and create installer    dky
##-----------------------------------------------------------------------------

open(VER,"<$ARGV[0]") || die("Cannot open \"$ARGV[0]\" version file");
my $p_ver=<VER>;
close(VER);

my @arr=split(/=/,$p_ver);
$p_ver=$arr[1];
$p_ver=~s/\"//g;

@arr=split(/\./,$p_ver);
if ($ARGV[1]=~/MAJOR/i) {
  $arr[0]++;
  $arr[1]=0;
  $arr[2]=0;
} elsif ($ARGV[1]=~/MINOR/i) {
  $arr[1]++;
  $arr[2]=0;
} elsif ($ARGV[1]=~/TRIVIAL/i) {
  $arr[2]++;
} else {
  exit 1;
}

my $n_ver=join('.',@arr);
open(VER,">$ARGV[0]") || die("Cannot open \"$ARGV[0]\" version file");
print VER "VERSION=\"$n_ver\"\n";
close(VER);

my $cmd="makensis.exe /V2 /DPRODUCT_VERSION=$n_ver CRAMP.nsi";
print "$cmd";
system($cmd);
