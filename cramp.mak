#-*-mode:makefile;indent-tabs-mode:nil-*-
## Time-stamp: <2003-10-30 17:59:14 dhruva>
##-----------------------------------------------------------------------------
## File : cramp.mak
## Desc : Microsoft make file
## Usage: nmake /f cramp.mak
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-23-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
VERSION="0.1.1"

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
ENGINE=$(PROJ)
PROFLIB=lib$(ENGINE)

CPP=CL
LINK=LINK
DEL=DEL /F /Q
ERASE=ERASE /F /Q
MD=MKDIR

# Existing folders
SRCDIR=src
INCDIR=inc
LIBSRCDIR=lib-src
UTILDIR=utils
TSTDIR=test

# Folders created
BINDIR=bin
OBJDIR=obj
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

INCLUDE=./src;./inc;$(INCLUDE)

# Version info
CFLAGS=$(CFLAGS) /V$(VERSION)
LDFLAGS=$(LDFLAGS) /VERSION:$(VERSION)

# For engine
E_CFLAGS=$(CFLAGS) $(NOLOGO) /I$(XMLBASE)/include /I$(BDBBASE)/include
E_CFLAGS=$(E_CFLAGS) /I$(STLBASE) /I$(BDBBASE)/include/dbinc
E_CCFLAGS=$(E_CFLAGS) $(CPP_DEBUG) $(MT_DEBUG) /GX
E_LDFLAGS=$(LDFLAGS) $(NOLOGO) $(LINK_DEBUG)
E_LDFLAGS=$(E_LDFLAGS) /LIBPATH:$(XMLBASE)/lib /LIBPATH:$(BDBBASE)/lib

# Add new files here
COBJS=$(OBJDIR)/main.obj $(OBJDIR)/engine.obj $(OBJDIR)/TestCaseInfo.obj \
      $(OBJDIR)/XMLParse.obj $(OBJDIR)/ipc.obj $(OBJDIR)/ipcmsg.obj
POBJS=$(OBJDIR)/CallMon.obj $(OBJDIR)/CallMonLOG.obj $(OBJDIR)/DllMain.obj \
      $(OBJDIR)/ProfileLimit.obj
UOBJS=$(OBJDIR)/profileDB.obj
OBJS=$(COBJS) $(POBJS) $(UOBJS)

# Add all query tools here
UTILITIES=$(BINDIR)/profileDB.exe

# Currently disabled base class build: Problem with SDK
all: cramp
cramp: dirs engine library utils test
remake: clean cramp

# Dependancy to force a re-build
DEPS=$(MAKEFILE) $(INCDIR)/cramp.h

# Rebuild on changes to makefile
$(MAKEFILE):

dirs: $(MAKEFILE)
    @IF NOT EXIST $(OBJDIR) $(MD) $(OBJDIR)
    @IF NOT EXIST $(BINDIR) $(MD) $(BINDIR)

# For CRAMP engine
engine: dirs $(COBJS)
    @$(LINK) $(LINK_DEBUG) $(E_LDFLAGS) $(COBJS) psapi.lib shell32.lib \
             $(XML_LIB) /OUT:$(BINDIR)/$(ENGINE).exe
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
$(SRCDIR)/TestCaseInfo.cpp: $(SRCDIR)/TestCaseInfo.h
$(SRCDIR)/XMLParse.cpp: $(SRCDIR)/XMLParse.h

$(INCDIR)/cramp.h:
$(SRCDIR)/ipc.h: $(DEPS)
$(SRCDIR)/ipcmsg.h: $(DEPS)
$(SRCDIR)/engine.h: $(DEPS)
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
$(OBJDIR)/ProfileLimit.obj: $(LIBSRCDIR)/ProfileLimit.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(LIBSRCDIR)/ProfileLimit.cpp \
             /Fo$(OBJDIR)/ProfileLimit.obj
$(OBJDIR)/DllMain.obj: $(LIBSRCDIR)/DllMain.cpp $(LIBSRCDIR)/CallMonLOG.h
    @$(CPP)  /c $(E_CCFLAGS) $(LIBSRCDIR)/DllMain.cpp \
             /Fo$(OBJDIR)/DllMain.obj

$(LIBSRCDIR)/CallMon.cpp: $(LIBSRCDIR)/CallMon.h
$(LIBSRCDIR)/CallMonLOG.cpp: $(LIBSRCDIR)/CallMonLOG.h
$(LIBSRCDIR)/ProfileLimit.cpp: $(LIBSRCDIR)/ProfileLimit.h

$(LIBSRCDIR)/CallMon.h: $(DEPS)
$(LIBSRCDIR)/CallMonLOG.h: $(LIBSRCDIR)/CallMon.h $(DEPS)
$(LIBSRCDIR)/ProfileLimit.h: $(DEPS)

# Query utilities
utils: $(UTILITIES)
$(BINDIR)/profileDB.exe: $(OBJDIR)/profileDB.obj
    @$(LINK) $(LINK_DEBUG) $(E_LDFLAGS) $(OBJDIR)/profileDB.obj \
             $(BDB_LIB) /OUT:$(BINDIR)/profileDB.exe
$(OBJDIR)/profileDB.obj: $(UTILDIR)/profileDB.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(UTILDIR)/profileDB.cpp \
             /Fo$(OBJDIR)/profileDB.obj
$(UTILDIR)/profileDB.cpp: $(DEPS)

# Base class for test cases
baseclass: $(OBJDIR)/DPEBaseClass.obj
$(OBJDIR)/DPEBaseClass.obj: $(SRCDIR)/DPEBaseClass.cpp $(SRCDIR)/DPEBaseClass.h
    @$(CPP)  /c $(CPP_DEBUG) /I$(DPE_COMINC) $(SRCDIR)/DPEBaseClass.cpp \
             /Fo$(OBJDIR)/DPEBaseClass.obj
$(SRCDIR)/DPEBaseClass.cpp:
$(SRCDIR)/DPEBaseClass.h:

# Build the test cases: Profiler, XML
test: dirs $(BINDIR)/TestProf.exe $(BINDIR)/XMLtest.exe
basetest: baseclass $(BINDIR)/DPEBaseClassTest.exe

$(BINDIR)/TestProf.exe: library $(OBJDIR)/TestProf.obj
    @$(LINK) $(LINK_DEBUG) $(OBJDIR)/TestProf.obj $(BINDIR)/$(PROFLIB).lib \
             /OUT:$(BINDIR)/TestProf.exe
$(BINDIR)/XMLtest.exe: $(OBJDIR)/TestCaseInfo.obj $(OBJDIR)/XMLParse.obj \
                       $(OBJDIR)/XMLtest.obj
    @$(LINK) $(LINK_DEBUG) $(E_LDFLAGS) $(OBJDIR)/XMLtest.obj \
             $(OBJDIR)/TestCaseInfo.obj $(OBJDIR)/XMLParse.obj \
             psapi.lib $(XML_LIB) /OUT:$(BINDIR)/XMLtest.exe
$(BINDIR)/DPEBaseClassTest.exe: $(OBJDIR)/DPEBaseClass.obj \
                                $(OBJDIR)/DPEBaseClassTest.obj
    @$(LINK) $(LINK_DEBUG) $(OBJDIR)/DPEBaseClassTest.obj \
             $(OBJDIR)/DPEBaseClass.obj /OUT:$(BINDIR)/DPEBaseClassTest.exe
$(OBJDIR)/TestProf.obj: $(TSTDIR)/TestProf.cpp
    @$(CPP)  /c $(CPP_DEBUG) /GX /Gh $(TSTDIR)/TestProf.cpp \
             /Fo$(OBJDIR)/TestProf.obj
$(OBJDIR)/XMLtest.obj: $(TSTDIR)/XMLtest.cpp
    @$(CPP)  /c $(CPP_DEBUG) $(E_CCFLAGS) $(TSTDIR)/XMLtest.cpp \
             /Isrc /Fo$(OBJDIR)/XMLtest.obj
$(OBJDIR)/DPEBaseClassTest.obj: $(TSTDIR)/DPEBaseClassTest.cpp
    @$(CPP)  /c $(CPP_DEBUG) /GX /I$(DPE_COMINC) \
             $(TSTDIR)/DPEBaseClassTest.cpp /Fo$(OBJDIR)/DPEBaseClassTest.obj

$(TSTDIR)/TestProf.cpp: $(DEPS)
$(TSTDIR)/XMLtest.cpp: $(DEPS)
$(TSTDIR)/DPEBaseClassTest.cpp: $(DEPS)

# Cleaning
clean: mostly-clean clean-vc60
    @IF EXIST $(BINDIR) @$(ERASE) $(BINDIR)
    @IF EXIST $(BINDIR) @RMDIR $(BINDIR)
    @IF EXIST $(OBJDIR) @$(ERASE) $(OBJDIR)
    @IF EXIST $(OBJDIR) @RMDIR $(OBJDIR)

clean-vc60:
    @IF EXIST vc60.pdb @$(DEL) vc60.pdb
    @IF EXIST vc60.idb @$(DEL) vc60.idb

mostly-clean:
    @IF EXIST $(OBJDIR) @$(ERASE) $(OBJDIR)
