#!perl
##-----------------------------------------------------------------------------
## File: crampbackup.pl
## Desc: Perl script to backup the CRAMP repository
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                     user
## 10-07-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
$source="E:/CRAMP/CVSREPOSITORY";
$target="E:/BACKUPS/cramp";
die("Unable to find source or target") unless(-d $source && -d $target);
my @curr=localtime();
$year=$curr[5]+1900;
$name="$target/CRAMP_$curr[2]_$curr[1]#$curr[4]_$curr[3]_$year.zip";
while(-f $name){
    sleep(60-$curr[0]);
    @curr=localtime();
    $year=$curr[5]+1900;
    $name="$target/CRAMP_$curr[2]_$curr[1]#$curr[4]_$curr[3]_$year.zip";
}

open(ZIP,"zip.exe -9 -r $name $source|")
    || die("Cannot ZIP $source to $name");
close(ZIP);
print("Zipped file: $name\n");
