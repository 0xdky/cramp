#!perl
## Time-stamp: <2003-10-20 19:40:00 dhruva>
##-----------------------------------------------------------------------------
## File  : dumpdb.pl
## Desc  : PERL script to dump contents of a DB hash
## Usage : perl dumpdb.pl CRAMP_PROFILE.db
## TODO  : Dump dupicate values for a key
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-30-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
use DB_File;

my $f_logdb;
if($#ARGV>=0){
    $f_logdb=$ARGV[0];
    $f_logdb=~tr/\\/\//;
}else{
    print(STDERR "Error: Please specify CRAMP log db file");
    exit 1;
}

my %h_profile;
my $hh;
$hh=tie(%h_profile, "DB_File",$f_logdb,O_RDONLY,undef,$DB_HASH) ||
    die("Cannot open \"$f_logdb\" file for read");
$h_profile->{'flags'}=R_DUP;
foreach(keys %h_profile){
    print "$_<=>$h_profile{$_}\n";
}
untie(%r_eid);
