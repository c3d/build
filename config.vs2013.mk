#******************************************************************************
# config.vs2013.mk                                            Recorder project 
#******************************************************************************
#
#  File Description:
#
#    Makefile configuration file for Visual Studio 2013
#
#    Compiler options:
#    https://msdn.microsoft.com/en-us/library/fwkeyyhe%28v=vs.120%29.aspx
#
#
#
#
#
#******************************************************************************
# (C) 1992-2017 Christophe de Dinechin <christophe@dinechin.org>
#This software is licensed under the GNU General Public License v3
#See file COPYING for details.
#******************************************************************************

#------------------------------------------------------------------------------
#  Tools
#------------------------------------------------------------------------------

# -nologo: suppresses display of sign-on banner
# -TC: C mode
# -TP: C++ mode
CC=    cl -nologo -TC
CC99=  cl -nologo -TC
CXX=   cl -nologo -TP -EHsc
CXX11= cl -nologo -TP -EHsc
CPP=   cl -nologo -E
LD=    link -nologo
MSLIB= lib -nologo
PYTHON= python
AR=     no-ar-on-windows
RANLIB= no-ranlib-on-windows
INSTALL=install


#------------------------------------------------------------------------------
#  Compilation flags
#------------------------------------------------------------------------------
#
# Options in Visual Studio are an anti-poem: no rhyme, no reason.
#
# For example, debug options are: -Z7, -ZI and -Zi.
# But don't think -Z is for debugging. -Za and -Ze disable extensions,
# whereas -Zc controls language conformance,
# and -Zg generates function prototypes. All this is perfectly normal.
#
# For a good introduction to the logic of of Microsoft options,
# watch the neuralyzer scenes in Men In Black. Swamp gas, Venus.
#
# For a true (and truly shocking) reference about the options,
# see https://msdn.microsoft.com/en-us/library/958x11bc.aspx
#
# For now, -Wall is hopeless on Visual Studio 2013

# -TP=C++ mode
# -EHa=Exception model catching both structured and unstructured exceptions
CFLAGS_cxx=	 -TP -EHa -EHsc

# -Z7=Put debug information in .obj files (don't laugh)
# -Zi=Set debug information format to Program Database
# -O2=Optimise for speed (-O1 is for size, -Ob for inline functions, and so on)
CFLAGS_debug=	    -Zi -DEBUG
CFLAGS_opt=	    -O2 -Zi -DEBUG
CFLAGS_release= -O2

# Curiously, the C++ compiler takes the same options as the C compiler. Bug?
CXXFLAGS_debug=      -Zi -EHa -EHsc -DEBUG
CXXFLAGS_opt=	 -O2 -Zi -EHa -EHsc -DEBUG
CXXFLAGS_release=-O2     -EHa -EHsc

DEFINES_vs2013= WIN32
OS_NAME_vs2013= windows

# Some default build libraries that are typically used for Python
LDFLAGS_vs2013=	shell32.lib Advapi32.lib User32.lib -libpath:$(OBJROOT)

# Options specific to profiling
# OBJ_PDB is the .pdb file (profile database) associated to a Windows
# binary (.exe, .lib), containing profile and debug information
OBJ_PDB:=       $(OBJROOT)/$(PRODUCTS)
OBJ_PDB:=       $(subst .exe,.pdb,$(OBJ_PDB))
CFLAGS_profile=	   -Fd$(OBJ_PDB)	-O2 -Zi            -DEBUG
CXXFLAGS_profile=  -Fd$(OBJ_PDB)	-O2 -Zi -EHa -EHsc -DEBUG
LDFLAGS_profile=   -pdb:$(OBJ_PDB) -debug


#------------------------------------------------------------------------------
#  File extensions
#------------------------------------------------------------------------------

OBJ_EXT=.obj
LIB_EXT=.lib
EXE_EXT=.exe
DLL_EXT=.dll


#------------------------------------------------------------------------------
#  Build rules
#------------------------------------------------------------------------------
# Visual C++ really goes out of its way now to have incompatible options
# For example, -o was recently 'deprecated' in favor of -Fo (!!!!)
#
# For debugging and profiling, we specify the -Fd and -pdb option.
# In order to merge all .pdb information for an executable, we need to pass the -debug
# option to the linker.

MAKE_CC=       $(CC)  $(CFLAGS)   $(CPPFLAGS_$*) $(CFLAGS_$*)   -c -Fo$@ $<
MAKE_CXX=      $(CXX) $(CXXFLAGS) $(CPPFLAGS_$*) $(CXXFLAGS_$*) -c -Fo$@ $<
MAKE_OBJDIR=   mkdir -p $* && touch $@
MAKE_LIB=      $(MSLIB) $(LINK_INPUTS)                                -out:$@
MAKE_DLL=      $(LD) $(LDFLAGS) $(LDFLAGS_$*)   $(LINK_INPUTS) -dll   -out:$@
MAKE_EXE=      $(LD) $(LDFLAGS) $(LDFLAGS_$*)   $(LINK_INPUTS)        -out:$@


#------------------------------------------------------------------------------
#  Dependencies
#------------------------------------------------------------------------------

GNU_CC=         gcc
GNU_CXX=        g++
GNU_AS=         gcc -x assembler-with-cpp
CC_DEPEND=	$(GNU_CC)  -D_WIN32=1 $(GFLAGS) $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MF $@ -MT $(@:.d=) $<
CXX_DEPEND=	$(GNU_CXX) -D_WIN32=1 $(GFLAGS) $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MF $@ -MT $(@:.d=) $<
AS_DEPEND=	$(GNU_AS)  -D_WIN32=1 $(GFLAGS) $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MF $@ -MT $(@:.d=) $<
