#******************************************************************************
# config.gnu.mk                                               Recorder project 
#******************************************************************************
#
#  File Description:
#
#    Makefile configuration file for GNU tools
#
#
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

CC=             gcc
CC99=           gcc -std=gnu99
CXX=            g++
CXX11=          g++ -std=c++11
LD=             g++
CPP=            gcc -E
PYTHON=         python
AR=             ar -rcs
RANLIB=         ranlib
LIBTOOL=        libtool -no_warning_for_no_symbols
INSTALL=	install


#------------------------------------------------------------------------------
#  Compilation flags
#------------------------------------------------------------------------------

CFLAGS_debug=   -g -Wall -fno-inline
CFLAGS_opt=     -O3 -Wall
CFLAGS_release= -O3 -Wall
CFLAGS_profile=	-pg
CFLAGS_cxx=     -x c++
LDFLAGS_debug=  -g
LDFLAGS_profile=-pg


#------------------------------------------------------------------------------
#  File extensions
#------------------------------------------------------------------------------

OBJ_EXT=        .o
LIB_EXT=        .a
EXE_EXT=        
DLL_EXT=        .so


#------------------------------------------------------------------------------
#  Build rules
#------------------------------------------------------------------------------

MAKE_CC=        $(CC)   $(CFLAGS)   $(CPPFLAGS_$*) $(CFLAGS_$*)   -c $< -o $@
MAKE_CXX=       $(CXX)  $(CXXFLAGS) $(CPPFLAGS_$*) $(CXXFLAGS_$*) -c $< -o $@
MAKE_OBJDIR=    mkdir -p $*                                       && touch $@
MAKE_LIB=       $(AR) $@                        $(LINK_INPUTS)&& $(RANLIB) $@
MAKE_DLL=       $(LIBTOOL) -shared              $(LINK_INPUTS)          -o $@
MAKE_EXE=       $(LD) -o $@ $(LINK_INPUTS) $(LDFLAGS) $(LDFLAGS_$*)


#------------------------------------------------------------------------------
#   Dependencies
#------------------------------------------------------------------------------

CC_DEPEND=      $(CC)  $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MF $@ -MT $(@:.d=) $<
CXX_DEPEND=     $(CXX) $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MF $@ -MT $(@:.d=) $<
AS_DEPEND=      $(CC)  $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MF $@ -MT $(@:.d=) $<
