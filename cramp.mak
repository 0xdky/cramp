#-*-mode:makefile;indent-tabs-mode:nil-*-
## Time-stamp: <2003-10-01 19:09:55 dhruva>
##-----------------------------------------------------------------------------
## File : cramp.mak
## Desc : Microsoft make file
## Usage: nmake /f cramp.mak
##-----------------------------------------------------------------------------
## mm-dd-yyyy  History                                                      tri
## 09-23-2003  Cre                                                          dky
##-----------------------------------------------------------------------------

# Modify to point to XML base folder
XMLBASE=F:/Applications/xerces
XMLBASE1=E:/Applications/xerces
XML_LIB=xerces-c_2D.lib

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
CPP_DEBUG=/ZI
LINK_DEBUG=/DEBUG

INCLUDE=./src;$(INCLUDE)

# For engine
E_CFLAGS=$(CFLAGS) $(NOLOGO) /I$(XMLBASE)/include /I$(XMLBASE1)/include
E_CCFLAGS=$(E_CFLAGS) $(CPP_DEBUG) /MT /GX
E_LDFLAGS=$(LDFLAGS) $(NOLOGO) $(LINK_DEBUG)
E_LDFLAGS=$(E_LDFLAGS) /LIBPATH:$(XMLBASE)/lib /LIBPATH:$(XMLBASE1)/lib

# For profiler
P_CCFLAGS=$(CFLAGS) $(NOLOGO) $(CPP_DEBUG) /GX
P_LDFLAGS=$(LDFLAGS) $(NOLOGO) $(LINK_DEBUG)

# Add new files here
COBJS=$(OBJDIR)/cramp.obj $(OBJDIR)/TestCaseInfo.obj $(OBJDIR)/XMLParse.obj
POBJS=$(OBJDIR)/CallMon.obj $(OBJDIR)/CallMonLOG.obj $(OBJDIR)/DllMain.obj
OBJS=$(COBJS) $(POBJS) $(XOBJS)

all: cramp
cramp: dirs engine library baseclass test
remake: clean cramp

# Dependancy to force a re-build
DEPS=$(MAKEFILE)

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
$(OBJDIR)/cramp.obj: $(SRCDIR)/cramp.cpp
    @$(CPP)  /c $(CPP_DEBUG) $(E_CCFLAGS) $(SRCDIR)/cramp.cpp \
             /Fo$(OBJDIR)/cramp.obj
$(OBJDIR)/TestCaseInfo.obj: $(SRCDIR)/TestCaseInfo.cpp
    @$(CPP)  /c $(CPP_DEBUG) $(E_CCFLAGS) $(SRCDIR)/TestCaseInfo.cpp \
             /Fo$(OBJDIR)/TestCaseInfo.obj
$(OBJDIR)/XMLParse.obj: $(SRCDIR)/XMLParse.cpp
    @$(CPP)  /c $(CPP_DEBUG) $(E_CCFLAGS) $(SRCDIR)/XMLParse.cpp \
             /Fo$(OBJDIR)/XMLParse.obj
$(SRCDIR)/cramp.cpp: $(SRCDIR)/cramp.h
$(SRCDIR)/TestCaseInfo.cpp: $(SRCDIR)/TestCaseInfo.h
$(SRCDIR)/XMLParse.cpp: $(SRCDIR)/XMLParse.h
$(SRCDIR)/cramp.h: $(DEPS)
$(SRCDIR)/TestCaseInfo.h: $(DEPS)
$(SRCDIR)/XMLParse.h: $(DEPS)

# Profiling DLL
library: dirs $(PROFLIB).dll
$(PROFLIB).dll: $(POBJS)
    @$(LINK) /DLL $(LINK_DEBUG) $(P_LDFLAGS) $(POBJS) imagehlp.lib \
             /OUT:$(BINDIR)/$(PROFLIB).dll
$(OBJDIR)/CallMon.obj: $(SRCDIR)/CallMon.cpp
    @$(CPP)  /c $(CPP_DEBUG) $(P_CCFLAGS) $(SRCDIR)/CallMon.cpp \
             /Fo$(OBJDIR)/CallMon.obj
$(OBJDIR)/CallMonLOG.obj: $(SRCDIR)/CallMonLOG.cpp
    @$(CPP)  /c $(CPP_DEBUG) $(P_CCFLAGS) $(SRCDIR)/CallMonLOG.cpp \
             /Fo$(OBJDIR)/CallMonLOG.obj
$(OBJDIR)/DllMain.obj: $(SRCDIR)/DllMain.cpp $(SRCDIR)/CallMonLOG.h
    @$(CPP)  /c $(CPP_DEBUG) $(P_CCFLAGS) $(SRCDIR)/DllMain.cpp \
             /Fo$(OBJDIR)/DllMain.obj
$(SRCDIR)/CallMon.cpp: $(SRCDIR)/CallMon.h $(DEPS)
$(SRCDIR)/CallMonLOG.cpp: $(SRCDIR)/CallMonLOG.h $(DEPS)
$(SRCDIR)/CallMon.h: $(DEPS)
$(SRCDIR)/CallMonLOG.h: $(SRCDIR)/CallMon.h $(DEPS)

# Base class for test cases
baseclass: $(OBJDIR)/DPEBaseClass.obj
$(OBJDIR)/DPEBaseClass.obj: $(SRCDIR)/DPEBaseClass.cpp $(SRCDIR)/DPEBaseClass.h
    @$(CPP)  /c $(CPP_DEBUG) /I$(DPE_COMINC) $(SRCDIR)/DPEBaseClass.cpp \
             /Fo$(OBJDIR)/DPEBaseClass.obj
$(SRCDIR)/DPEBaseClass.cpp:
$(SRCDIR)/DPEBaseClass.h:

# Build the test cases: Profiler, XML
test: dirs $(BINDIR)/TestProf.exe $(BINDIR)/XMLtest.exe \
           $(BINDIR)/DPEBaseClassTest.exe
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
