#!perl
# Time-stamp: <2003-11-14 11:36:14 dhruva>
##-----------------------------------------------------------------------------
## File: crampbackup.pl
## Desc: Perl script to backup the CRAMP repository
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                     user
## 10-07-2003  Cre                                                          dky
## 11-14-2003  Mod  Use BZIP2 and TAR                                       dky
##-----------------------------------------------------------------------------
my $BASEDRIVE='d';
if(exists($ENV{'BASEDRIVE'})){
    $BASEDRIVE=$ENV{'BASEDRIVE'};
}
$source="$BASEDRIVE:/CRAMP/CVSREPOSITORY";
$target="$BASEDRIVE:/BACKUPS/cramp";

die("Unable to find source or target") unless(-d $source && -d $target);
my @curr=localtime();
$year=$curr[5]+1900;
$curr[4]++;
$name="$target/CRAMP_$curr[2]_$curr[1]#$curr[4]_$curr[3]_$year.tar";

while(-f $name){
    sleep(60-$curr[0]);
    @curr=localtime();
    $year=$curr[5]+1900;
    $name="$target/CRAMP_$curr[2]_$curr[1]#$curr[4]_$curr[3]_$year.tar";
}

system("tar.exe --force-local -cf $name -C $source cramp")==0
    || die("Failed in TAR");
system("bzip2.exe --force $name")==0
    || die("Failed in BZIP2");
print("BZIP file: $name.bz2\n");
