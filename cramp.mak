#-*-mode:makefile;indent-tabs-mode:nil-*-
## Time-stamp: <2004-02-29 13:32:00 dky>
##-----------------------------------------------------------------------------
## File : cramp.mak
## Desc : Microsoft make file
## Usage: nmake /f cramp.mak
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-23-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
# Specify the drive as an environment variable
BASEDRIVE=$(BASEDRIVE)

# Modify to point to XML base folder
XMLBASE=$(BASEDRIVE):/Applications/xerces
# Berkeley Database
BDBBASE=$(BASEDRIVE):/Applications/bdb
# SGI's STL
STLBASE=$(BASEDRIVE):/Applications/stl

# DPE Cominc folder for DPE server header files
DPE_COMINC=../../DPE/Cominc

PROJ=CRAMP
MAKEFILE=$(PROJ).mak
ENGINE=CRAMPEngine
PROFLIB=lib$(PROJ)

VB=VB6
CPP=CL
LINK=LINK
DEL=DEL /F /Q
ERASE=ERASE /F /Q
MD=MKDIR
COPY=XCOPY /y /q /r
ECHO=echo

# Existing folders
SRCDIR=src
INCDIR=inc
LIBSRCDIR=lib-src
UTILDIR=utils
VBDIR=vbsrc
TSTDIR=test

# Folders created
BINDIR=bin
OBJDIR=obj
RESDIR=res
NOLOGO=/nologo

!IF ("$(NODEBUG)" == "1")
!MESSAGE Compiling with NO debug symbols, only for release
MT_DEBUG=/MT
XML_LIB=xerces-c_2.lib
BDB_LIB=libdb41s.lib
!ELSE
!MESSAGE Compiling with debug options
CPP_DEBUG=/ZI /DCRAMP_DEBUG
MT_DEBUG=/MTd
LINK_DEBUG=/DEBUG
XML_LIB=xerces-c_2D.lib
BDB_LIB=libdb41sd.lib
!ENDIF

!IF ("$(CRAMP_STUB)" == "1")
!MESSAGE Building a STUBBED profile library
STUB=/DCRAMP_STUB
!ENDIF

INCLUDE=./src;./inc;$(INCLUDE)

# Version info
CFLAGS=$(CFLAGS)
LDFLAGS=$(LDFLAGS)

# For engine
E_CFLAGS=$(CFLAGS) $(NOLOGO) /I$(XMLBASE)/include /I$(BDBBASE)/include
E_CFLAGS=$(E_CFLAGS) $(STUB) /I$(STLBASE) /I$(BDBBASE)/include/dbinc
E_CCFLAGS=$(E_CFLAGS) $(CPP_DEBUG) $(MT_DEBUG) /GX
E_LDFLAGS=$(LDFLAGS) $(NOLOGO) $(LINK_DEBUG)
E_LDFLAGS=$(E_LDFLAGS) /LIBPATH:$(XMLBASE)/lib /LIBPATH:$(BDBBASE)/lib

# Add new files here
COBJS=$(OBJDIR)/main.obj $(OBJDIR)/engine.obj $(OBJDIR)/TestCaseInfo.obj \
      $(OBJDIR)/XMLParse.obj $(OBJDIR)/ipc.obj $(OBJDIR)/ipcmsg.obj \
      $(OBJDIR)/PerfCounters.obj
POBJS=$(OBJDIR)/CallMon.obj $(OBJDIR)/CallMonLOG.obj $(OBJDIR)/DllMain.obj
UOBJS=$(OBJDIR)/profileDB.obj
OBJS=$(COBJS) $(POBJS) $(UOBJS)

# Add all query tools here
UTILITIES=$(BINDIR)/ProfileControl.exe $(BINDIR)/profileDB.exe

# Currently disabled base class build: Problem with SDK
all: cramp
cramp: dirs res engine library gui utils test
remake: clean cramp

# Dependancy to force a re-build
DEPS=$(MAKEFILE) $(INCDIR)/cramp.h

# Rebuild on changes to makefile
$(MAKEFILE):

# Create folders
dirs: $(MAKEFILE)
    @IF NOT EXIST $(OBJDIR) $(MD) $(OBJDIR)
    @IF NOT EXIST $(BINDIR) $(MD) $(BINDIR)
    @IF NOT EXIST $(RESDIR) $(MD) $(RESDIR)

# Add res
res: $(RESDIR)/Attributes.txt $(RESDIR)/MostRecentFiles.txt
$(RESDIR)/Attributes.txt:
    @$(COPY) $(VBDIR)/mainui/Attributes.txt $(RESDIR)
$(RESDIR)/MostRecentFiles.txt:
    @$(COPY) $(VBDIR)/mainui/MostRecentFiles.txt $(RESDIR)

# For CRAMP engine
engine: dirs res $(COBJS)
    @$(LINK) $(LINK_DEBUG) $(E_LDFLAGS) $(COBJS) psapi.lib shell32.lib \
             Pdh.lib AdvApi32.lib $(XML_LIB) /OUT:$(BINDIR)/$(ENGINE).exe
# Compiling
$(OBJDIR)/main.obj: $(SRCDIR)/main.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/main.cpp \
             /Fo$(OBJDIR)/main.obj
$(OBJDIR)/ipc.obj: $(SRCDIR)/ipc.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/ipc.cpp \
             /Fo$(OBJDIR)/ipc.obj
$(OBJDIR)/ipcmsg.obj: $(SRCDIR)/ipcmsg.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/ipcmsg.cpp \
             /Fo$(OBJDIR)/ipcmsg.obj
$(OBJDIR)/engine.obj: $(SRCDIR)/engine.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/engine.cpp \
             /Fo$(OBJDIR)/engine.obj
$(OBJDIR)/PerfCounters.obj: $(SRCDIR)/PerfCounters.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/PerfCounters.cpp \
             /Fo$(OBJDIR)/PerfCounters.obj
$(OBJDIR)/TestCaseInfo.obj: $(SRCDIR)/TestCaseInfo.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/TestCaseInfo.cpp \
             /Fo$(OBJDIR)/TestCaseInfo.obj
$(OBJDIR)/XMLParse.obj: $(SRCDIR)/XMLParse.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/XMLParse.cpp \
             /Fo$(OBJDIR)/XMLParse.obj

$(SRCDIR)/main.cpp: $(SRCDIR)/engine.h
$(SRCDIR)/ipc.cpp: $(SRCDIR)/ipc.h
$(SRCDIR)/ipcmsg.cpp: $(SRCDIR)/ipcmsg.h
$(SRCDIR)/engine.cpp: $(SRCDIR)/engine.h
$(SRCDIR)/PerfCounters.cpp: $(SRCDIR)/PerfCounters.h
$(SRCDIR)/TestCaseInfo.cpp: $(SRCDIR)/TestCaseInfo.h
$(SRCDIR)/XMLParse.cpp: $(SRCDIR)/XMLParse.h

$(INCDIR)/cramp.h:
$(SRCDIR)/ipc.h: $(DEPS)
$(SRCDIR)/ipcmsg.h: $(DEPS)
$(SRCDIR)/engine.h: $(DEPS)
$(SRCDIR)/PerfCounters.h: $(DEPS)
$(SRCDIR)/TestCaseInfo.h: $(DEPS)
$(SRCDIR)/XMLParse.h: $(DEPS)

# Profiling DLL
library: dirs $(PROFLIB).dll
$(PROFLIB).dll: $(POBJS)
    @$(LINK) /DLL $(LINK_DEBUG) $(E_LDFLAGS) $(POBJS) imagehlp.lib \
             /OUT:$(BINDIR)/$(PROFLIB).dll
$(OBJDIR)/CallMon.obj: $(LIBSRCDIR)/CallMon.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(LIBSRCDIR)/CallMon.cpp \
             /Fo$(OBJDIR)/CallMon.obj
$(OBJDIR)/CallMonLOG.obj: $(LIBSRCDIR)/CallMonLOG.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(LIBSRCDIR)/CallMonLOG.cpp \
             /Fo$(OBJDIR)/CallMonLOG.obj
$(OBJDIR)/DllMain.obj: $(LIBSRCDIR)/DllMain.cpp $(LIBSRCDIR)/CallMonLOG.h
    @$(CPP)  /c $(E_CCFLAGS) $(LIBSRCDIR)/DllMain.cpp \
             /Fo$(OBJDIR)/DllMain.obj

$(LIBSRCDIR)/CallMon.cpp: $(LIBSRCDIR)/CallMon.h
$(LIBSRCDIR)/CallMonLOG.cpp: $(LIBSRCDIR)/CallMonLOG.h

$(LIBSRCDIR)/CallMon.h: $(DEPS)
$(LIBSRCDIR)/CallMonLOG.h: $(LIBSRCDIR)/CallMon.h $(DEPS)

# Query utilities
utils: $(UTILITIES)
$(BINDIR)/profileDB.exe: $(OBJDIR)/profileDB.obj
    @$(LINK) $(LINK_DEBUG) $(E_LDFLAGS) $(OBJDIR)/profileDB.obj \
             $(BDB_LIB) /OUT:$(BINDIR)/profileDB.exe
$(OBJDIR)/profileDB.obj: $(UTILDIR)/profileDB.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(UTILDIR)/profileDB.cpp \
             /Fo$(OBJDIR)/profileDB.obj
$(UTILDIR)/profileDB.cpp: $(DEPS)

$(BINDIR)/ProfileControl.exe: $(OBJDIR)/ProfileControl.obj
    @$(LINK) $(LINK_DEBUG) $(E_LDFLAGS) $(OBJDIR)/ProfileControl.obj \
             Shell32.lib /OUT:$(BINDIR)/ProfileControl.exe
$(OBJDIR)/ProfileControl.obj: $(UTILDIR)/ProfileControl.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(UTILDIR)/ProfileControl.cpp \
             /Fo$(OBJDIR)/ProfileControl.obj
$(UTILDIR)/ProfileControl.cpp: $(DEPS)

# Base class for test cases
baseclass: $(OBJDIR)/DPEBaseClass.obj
$(OBJDIR)/DPEBaseClass.obj: $(SRCDIR)/DPEBaseClass.cpp $(SRCDIR)/DPEBaseClass.h
    @$(CPP)  /c $(CPP_DEBUG) /I$(DPE_COMINC) $(SRCDIR)/DPEBaseClass.cpp \
             /Fo$(OBJDIR)/DPEBaseClass.obj
$(SRCDIR)/DPEBaseClass.cpp:
$(SRCDIR)/DPEBaseClass.h:

# Build the test cases: Profiler, XML
test: dirs $(BINDIR)/TestProf.exe
basetest: baseclass $(BINDIR)/DPEBaseClassTest.exe

$(BINDIR)/TestProf.exe: library $(OBJDIR)/TestProf.obj
    @$(LINK) /DEBUG $(OBJDIR)/TestProf.obj $(BINDIR)/$(PROFLIB).lib \
             /OUT:$(BINDIR)/TestProf.exe
$(BINDIR)/DPEBaseClassTest.exe: $(OBJDIR)/DPEBaseClass.obj \
                                $(OBJDIR)/DPEBaseClassTest.obj
    @$(LINK) $(LINK_DEBUG) $(OBJDIR)/DPEBaseClassTest.obj \
             $(OBJDIR)/DPEBaseClass.obj /OUT:$(BINDIR)/DPEBaseClassTest.exe
$(OBJDIR)/TestProf.obj: $(TSTDIR)/TestProf.cpp
    @$(CPP)  /c /ZI /DCRAMP_DEBUG /GX /Gh $(TSTDIR)/TestProf.cpp \
             /Fo$(OBJDIR)/TestProf.obj
$(OBJDIR)/DPEBaseClassTest.obj: $(TSTDIR)/DPEBaseClassTest.cpp
    @$(CPP)  /c $(CPP_DEBUG) /GX /I$(DPE_COMINC) \
             $(TSTDIR)/DPEBaseClassTest.cpp /Fo$(OBJDIR)/DPEBaseClassTest.obj

$(TSTDIR)/TestProf.cpp: $(DEPS)
$(TSTDIR)/DPEBaseClassTest.cpp: $(DEPS)

# Compile CRAMP VB project
gui: $(BINDIR)/CRAMP.exe
$(BINDIR)/CRAMP.exe: $(VBDIR)/mainui/CRAMP.vbw
$(VBDIR)/mainui/CRAMP.vbw: $(VBDIR)/mainui/CRAMP.vbp
$(VBDIR)/mainui/CRAMP.vbp: $(MAKEFILE) $(VBDIR)/mainui/*.bas \
                           $(VBDIR)/mainui/*.frm $(VBDIR)/mainui/*.frx
    @$(ECHO) Compiling VB project $(VBDIR)/mainui/CRAMP.vbp
    @$(VB) /make /outdir $(BINDIR) $(VBDIR)/mainui/CRAMP.vbp

# Compile the installer
!IF ("$(LEVEL)"=="MAJOR" || "$(LEVEL)"=="MINOR" || "$(LEVEL)"=="TRIVIAL")
!MESSAGE Updating the CRAMP version number
installer: remake
    @cvs.exe -z3 edit ./version
    @perl.exe ./scripts/version.pl ./version $(LEVEL)
    @cvs.exe -z3 commit -m "$(LEVEL) modification" ./version
!ELSE
installer: remake
    @perl.exe ./scripts/version.pl ./version $(LEVEL)
!ENDIF

# Cleaning
clean: mostly-clean clean-vc60
    @IF EXIST $(BINDIR) @$(ERASE) $(BINDIR)
    @IF EXIST $(BINDIR) @RMDIR $(BINDIR)
    @IF EXIST $(OBJDIR) @$(ERASE) $(OBJDIR)
    @IF EXIST $(OBJDIR) @RMDIR $(OBJDIR)
    @IF EXIST $(RESDIR) @$(ERASE) $(RESDIR)
    @IF EXIST $(RESDIR) @RMDIR $(RESDIR)

clean-vc60:
    @IF EXIST vc60.pdb @$(DEL) vc60.pdb
    @IF EXIST vc60.idb @$(DEL) vc60.idb

mostly-clean:
    @IF EXIST $(OBJDIR) @$(ERASE) $(OBJDIR)
