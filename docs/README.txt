-------------------------------------------------------------------------------
                              CRAMP Installation
                   Time-stamp: <2003-12-15 09:57:34 dhruva>
       Please read this document before installing CRAMP on your system.
-------------------------------------------------------------------------------
mm-dd-yyyy  History                                                        user
12-14-2003  Cre                                                             sjm
-------------------------------------------------------------------------------

        CRAMP installation CD contains thee files, 'README.txt', 'autorun.inf'
and 'CRAMP-Setup.exe'.

    Double click on the CRAMP-Setup.exe and Installation wizard will guide you
through the installation procedure.

By default four components are installed, they are:
	CRAMP Engine - CRAMP Win32 test engine
	CRAMP Profiler - CRAMP Win32 profiler
	STAF - Software Test Automation Framework
	PERL - PERL 5.9.0 (+extra modules)

    If you already have STAF and PERL installed on your system you need not
install them again here. But it is recommended that you install all the four
components provided with this setup. If you are not installing STAF provided
with this setup then set a system environment variable STAF_PATH to folder
containing TOP level STAF installation (folder containing STAF's "bin" folder).

Select the destination folder and press Install. After installing the selected
components the setup will ask for rebooting the system. It is recommended that
you reboot your system after installing CRAMP since it will automatically set
the CRAMP specific environment variables and will start the STAFProc.exe.

After installation following environment system variables are set:
	CRAMP_LOGPATH=C:\DOCUME~1\username\LOCALS~1\Temp
	CRAMP_PATH=installation_folder\CRAMP
	CRAMP_PROFILE_CALLDEPTH=0
	CRAMP_PROFILE_EXCLUSION=1
	CRAMP_PROFILE_LOGSIZE=500
	CRAMP_PROFILE_MAXCALLLIMIT=0
	STAF_PATH=installation_folder\CRAMP\TOOLS\STAF

    To understand more about all of the above system environment variables
please read the CRAMP documentation. You can change the CRAMP_LOGPATH to your
custom choice.

-------------------------------------------------------------------------------
For further details, please contact:
1. dhruva_KRISHNAMURTHY@delmia.com (dky)
2. pragnesh_MISTRY@delmia.com (pie)
3. shrish_SABNIS@delmia.com (sjm)
-------------------------------------------------------------------------------
