#-*-mode:makefile;indent-tabs-mode:nil-*-
## Time-stamp: <2003-10-20 10:27:59 dhruva>
##-----------------------------------------------------------------------------
## File : cramp.mak
## Desc : Microsoft make file
## Usage: nmake /f cramp.mak
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-23-2003  Cre                                                          dky
##-----------------------------------------------------------------------------
VERSION="0.1.1"

# Modify to point to XML base folder
XMLBASE=F:/Applications/xerces
XMLBASE1=E:/Applications/xerces

# Berkeley Database
DBBASE=F:/Applications/db
DBBASE1=E:/Applications/db

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
TSTDIR=test

# Folders created
BINDIR=bin
OBJDIR=obj
NOLOGO=/nologo

!IF ("$(NODEBUG)" == "1")
!MESSAGE Compiling with NO debug symbols, only for release
MT_DEBUG=/MT
XML_LIB=xerces-c_2.lib
!ELSE
!MESSAGE Compiling with debug options
CPP_DEBUG=/ZI /DCRAMP_DEBUG
MT_DEBUG=/MTd
LINK_DEBUG=/DEBUG
XML_LIB=xerces-c_2D.lib
!ENDIF

INCLUDE=./src;$(INCLUDE)

# Version info
CFLAGS=$(CFLAGS) /V$(VERSION)
LDFLAGS=$(LDFLAGS) /VERSION:$(VERSION)

# For engine
E_CFLAGS=$(CFLAGS) $(NOLOGO) /I$(XMLBASE)/include /I$(XMLBASE1)/include
E_CFLAGS=$(E_CFLAGS) /I$(DBBASE)/include /I$(DBBASE1)/include
E_CFLAGS=$(E_CFLAGS) /I$(DBBASE)/include/dbinc /I$(DBBASE1)/include/dbinc
E_CCFLAGS=$(E_CFLAGS) $(CPP_DEBUG) $(MT_DEBUG) /GX
E_LDFLAGS=$(LDFLAGS) $(NOLOGO) $(LINK_DEBUG)
E_LDFLAGS=$(E_LDFLAGS) /LIBPATH:$(XMLBASE)/lib /LIBPATH:$(XMLBASE1)/lib
E_LDFLAGS=$(E_LDFLAGS) /LIBPATH:$(DBBASE)/lib /LIBPATH:$(DBBASE1)/lib

# Add new files here
COBJS=$(OBJDIR)/main.obj $(OBJDIR)/engine.obj $(OBJDIR)/TestCaseInfo.obj \
      $(OBJDIR)/XMLParse.obj $(OBJDIR)/ipc.obj $(OBJDIR)/ipcmsg.obj
POBJS=$(OBJDIR)/CallMon.obj $(OBJDIR)/CallMonLOG.obj $(OBJDIR)/DllMain.obj \
      $(OBJDIR)/ProfileLimit.obj
OBJS=$(COBJS) $(POBJS) $(XOBJS)

# Currently disabled base class build: Problem with SDK
all: cramp
cramp: dirs engine library test
remake: clean cramp

# Dependancy to force a re-build
DEPS=$(MAKEFILE) $(SRCDIR)/cramp.h

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

$(SRCDIR)/cramp.h:
$(SRCDIR)/ipc.h: $(DEPS)
$(SRCDIR)/ipcmsg.h: $(DEPS)
$(SRCDIR)/engine.h: $(DEPS)
$(SRCDIR)/TestCaseInfo.h: $(DEPS)
$(SRCDIR)/XMLParse.h: $(DEPS)

# Profiling DLL
library: dirs $(PROFLIB).dll
$(PROFLIB).dll: $(POBJS)
    @$(LINK) /DLL $(LINK_DEBUG) $(E_LDFLAGS) $(POBJS) imagehlp.lib \
             libdb41s.lib /OUT:$(BINDIR)/$(PROFLIB).dll
$(OBJDIR)/CallMon.obj: $(SRCDIR)/CallMon.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/CallMon.cpp \
             /Fo$(OBJDIR)/CallMon.obj
$(OBJDIR)/CallMonLOG.obj: $(SRCDIR)/CallMonLOG.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/CallMonLOG.cpp \
             /Fo$(OBJDIR)/CallMonLOG.obj
$(OBJDIR)/ProfileLimit.obj: $(SRCDIR)/ProfileLimit.cpp
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/ProfileLimit.cpp \
             /Fo$(OBJDIR)/ProfileLimit.obj
$(OBJDIR)/DllMain.obj: $(SRCDIR)/DllMain.cpp $(SRCDIR)/CallMonLOG.h
    @$(CPP)  /c $(E_CCFLAGS) $(SRCDIR)/DllMain.cpp \
             /Fo$(OBJDIR)/DllMain.obj

$(SRCDIR)/CallMon.cpp: $(SRCDIR)/CallMon.h
$(SRCDIR)/CallMonLOG.cpp: $(SRCDIR)/CallMonLOG.h $(SRCDIR)/ProfileLimit.h
$(SRCDIR)/ProfileLimit.cpp: $(SRCDIR)/ProfileLimit.h

$(SRCDIR)/CallMon.h: $(DEPS)
$(SRCDIR)/CallMonLOG.h: $(SRCDIR)/CallMon.h $(DEPS)
$(SRCDIR)/ProfileLimit.h: $(DEPS)

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
             /Fo$(OBJDIR)/XMLtest.obj
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
