#!perl
## Time-stamp: <2003-11-19 10:59:59 dhruva>
##-----------------------------------------------------------------------------
## File  : cramp_staf.pl
## Desc  : PERL script to run testcases on a pool of computers using STAF
## Usage : perl -S cramp_staf.pl scenario.list
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 11-18-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
use Config;
use Sys::Hostname;

my $STAF_EXEC;
my $STAF_PATH;
my $STAF_POOL;

my $STAF_WL;
my $complete=0;
my %h_staf_pool;
my %h_cramp_path;

if($Config{useithreads} || $Config{usethreads}){
    use threads;
    use threads::shared;
    share(%STAF_WL);
    share($complete);
    share(%h_staf_pool);
    share(%h_cramp_path);
}else{
    print(STDERR "PERL $] NOT built with Thread support\n");
    exit -1;
}

if(exists($ENV{'STAF_PATH'})){
    $STAF_PATH=$ENV{'STAF_PATH'};
    $STAF_PATH=~s/\/+$//g;
    if(! -d $STAF_PATH){
        exit -1;
    }
    $STAF_EXEC="$STAF_PATH/bin/cstaf.exe";
    $STAF_POOL="$STAF_PATH/bin/stafpool.cfg";
}else{
    exit -1;
}

if(!(-f $STAF_EXEC && -f $STAF_POOL)){
    exit -1;
}

##-----------------------------------------------------------------------------
## Init
##-----------------------------------------------------------------------------
sub Init{
    $STAF_WL="CRAMP_".hostname()."#".$$;
    return 0;
}

##-----------------------------------------------------------------------------
## GetSTAFLoad
##  Get the number of STAF processes in CRAMP running
##-----------------------------------------------------------------------------
sub GetSTAFLoad{
    my $comp=shift(@_);
    open(STAF_PROC,
         "$STAF_EXEC $comp PROCESS QUERY WORKLOAD $STAF_WL 2>&1 |")
        || return -1;
    my $cc=0;
    while(<STAF_PROC>){
        chomp();
        if(/Running/i){
            $cc++;
        }
    }
    close(STAF_PROC);
    return $cc;
}

##-----------------------------------------------------------------------------
## STAFPing
##  Check if alive
##-----------------------------------------------------------------------------
sub STAFPing{
    open(STAF_PROC,
         "$STAF_EXEC @_[0] PING PING 2>&1 |")
        || return -1;
    my $resp;
    while(<STAF_PROC>){
        chomp();
        if(!length($_)){
            next;
        }
        s/\\/\//g;
        $resp=$_;
    }
    close(STAF_PROC);
    if($resp=~/PONG/i){
        return 0;
    }
    return 1;
}

##-----------------------------------------------------------------------------
## GetSTAFPool
##  Get STAF computer pool
##-----------------------------------------------------------------------------
sub GetSTAFPool{
    open(POOL,"<$STAF_POOL") || return -1;
    my $cc=0;
    my $staf_cmd;
    while(<POOL>){
        chomp();
        my $comp=$_;
        if(STAFPing($comp)){
            next;
        }

        # Clean up the STAF log for WORKLOAD (WL)
        open(STAF_PROC,
             "$STAF_EXEC $comp PROCESS FREE WORKLOAD $STAF_WL 2>&1 |")
            || next;
        close(STAF_PROC);

        # Get the CRAMPEngine.exe's location on remote computer
        open(STAF_PROC,
             "$STAF_EXEC $comp VAR GLOBAL GET STAF/ENV/CRAMP_PATH 2>&1 |")
            || next;
        my $path;
        while(<STAF_PROC>){
            chomp();
            if(!length($_)){
                next;
            }
            s/\\/\//g;
            $path=$_;
        }
        close(STAF_PROC);
        if($path=~/^Error/i){
            next;
        }
        $path=~s/\/+$//g;

        # Get the CRAMP's logpath on remote computer
        open(STAF_PROC,
             "$STAF_EXEC $comp VAR GLOBAL GET STAF/ENV/CRAMP_LOGPATH 2>&1 |")
            || next;
        my $logpath;
        while(<STAF_PROC>){
            chomp();
            if(!length($_)){
                next;
            }
            s/\\/\//g;
            $logpath=$_;
        }
        close(STAF_PROC);
        if($logpath=~/^Error/i){
            next;
        }
        $logpath=~s/\/+$//g;
        $logpath.="/$STAF_WL";

        # Delete remote logs if exists
        $staf_cmd="$STAF_EXEC $comp FS DELETE ENTRY $logpath ";
        $staf_cmd.="RECURSE CONFIRM";
        open(STAF_PROC,"$staf_cmd 2>&1 |") || next;

        # Create a new log dir for uniqueness
        $staf_cmd="$STAF_EXEC $comp FS CREATE DIRECTORY $logpath";
        open(STAF_PROC,"$staf_cmd 2>&1 |") || next;
        my $err=0;
        while(<STAF_PROC>){
            if(/^Error/i){
                $err=1;
                last;
            }
        }
        close(STAF_PROC);
        if($err){
            next;
        }

        $h_staf_pool{$comp}=GetSTAFLoad($comp);
        $h_cramp_path{$comp}="$path/bin|$logpath";
        $cc++;
    }
    close(POOL);

    return !$cc;
}

##-----------------------------------------------------------------------------
## STAFUpdateTH
##  Update STAF load status in a thread
##-----------------------------------------------------------------------------
sub STAFUpdateTH{
    while(1){
        threads->self()->yield();
        my $comp;
        my $jobload=0;
        lock %h_staf_pool;
        foreach(keys %h_staf_pool){
            $comp=$_;
            $h_staf_pool{$comp}=GetSTAFLoad($comp);
            if($complete && !$jobload){
                $jobload=$h_staf_pool{$comp};
            }
        }
        cond_signal %h_staf_pool;

        if($complete && !$jobload){
            return 0;
        }
    }
    return -1;
}

##-----------------------------------------------------------------------------
## STAFRunTH
##  Runs a STAF process on first available comp
##-----------------------------------------------------------------------------
sub STAFRunTH{
    while(1){
        lock %h_staf_pool;
        foreach(keys %h_staf_pool){
            my $comp=$_;
            if(!$h_staf_pool{$comp}){
                $h_staf_pool{$comp}=GetSTAFLoad($comp);
            }
            if($h_staf_pool{$comp}){
                next;
            }

            if(!exists($h_cramp_path{$comp})){
                next;
            }
            my @arr=split(/\|/,$h_cramp_path{$comp});
            $arr[0]="$arr[0]/CRAMPEngine.exe";

            my $staf_cmd="$STAF_EXEC $comp PROCESS START WORKLOAD $STAF_WL ";
            $staf_cmd.="ENV CRAMP_LOGPATH=$arr[1] COMMAND $arr[0] PARMS @_";

            if(STAFPing($comp)){
                next;
            }

            open(STAF_PROC,"$staf_cmd 2>&1 |") || return -1;
            close(STAF_PROC);

            $h_staf_pool{$comp}=1;
            cond_signal %h_staf_pool;

            return 0;
        }
        cond_signal %h_staf_pool;
    }

    return 1;
}

##-----------------------------------------------------------------------------
## STAFJobDispatcher
##  Runs a STAF jobs on remote computers
##-----------------------------------------------------------------------------
sub STAFJobDispatcher{
    my $los=@_[0];
    my @h_jobs=();
    if(! -f $los){
        return -1;
    }
    my @jobs;
    open(LOS,"<$los") || return -1;
    while(<LOS>){
        chomp();
        if(! -f $_){
            return -1;
        }
        push(@jobs,$_);
    }
    close(LOS);

    my $upth=threads->create("STAFUpdateTH");
    foreach(@jobs){
        push(@h_jobs,threads->create("STAFRunTH",$_));
    }
    foreach(@h_jobs){
        $_->join();
    }
    $complete=1;
    $upth->join();
    return 0;
}

##-----------------------------------------------------------------------------
## STAFCopyCRAMPLogs
##  Copies the remote CRAMP logs to local computer
##-----------------------------------------------------------------------------
sub STAFCopyCRAMPLogs{
    my $host=hostname();
    my $comp;
    my $logpath;
    my $llogpath;
    my $staf_cmd;
    my $retval=0;

    if(!exists($h_cramp_path{$host})){
        return -1;
    }

    $llogpath=$h_cramp_path{$host};
    $llogpath=~s/.+\|//g;

    foreach(keys %h_staf_pool){
        if($host eq $_){
            next;
        }
        my $err=0;
        $comp=$_;
        $logpath=$h_cramp_path{$comp};
        $logpath=~s/.+\|//g;

        # Copy the remote log files to local computer
        $staf_cmd="$STAF_EXEC $comp FS COPY DIRECTORY $logpath ";
        $staf_cmd.="TODIRECTORY $llogpath/$comp RECURSE";
        open(STAF_PROC,"$staf_cmd 2>&1 |") || eval{$retval++;next};
        while(<STAF_PROC>){
            if(/^Error/i){
                $err=1;
                last;
            }
        }
        close(STAF_PROC);
        if($err){
            $retval++;
            next;
        }

        # Delete remote logs if copied to local
        $staf_cmd="$STAF_EXEC $comp FS DELETE ENTRY $logpath ";
        $staf_cmd.="RECURSE CONFIRM";
        open(STAF_PROC,"$staf_cmd 2>&1 |") || next;
    }

    return $retval;
}

##---------------------------------------------------------------------------##
##                          BEGIN ACTUAL EXECUTION                           ##
##---------------------------------------------------------------------------##
my $retval=0;
Init();
GetSTAFPool()==0||exit $?;
$retval=STAFJobDispatcher($ARGV[0]);
foreach(keys %h_staf_pool){
    STAFPing($_)==0 || next;
    open(STAF_PROC,
         "$STAF_EXEC $comp PROCESS FREE WORKLOAD $STAF_WL 2>&1 |")
        || next;
    close(STAF_PROC);
}
if($retval){
    print STDERR "Error dispatching \"$ARGV[0]\" job\n";
}else{
    $retval=STAFCopyCRAMPLogs();
}

if($retval){
    print STDERR "Error copying remote logs\n";
}

exit $retval;
