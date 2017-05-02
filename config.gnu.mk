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
CXX11=          g++ -std=gnu++11
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
CFLAGS_opt=     -g -O3 -Wall
CFLAGS_release= -O3 -Wall
CFLAGS_profile=	-pg
CFLAGS_cxx=     -x c++
LDFLAGS_debug=  -g
LDFLAGS_profile=-pg
DEPFLAGS=	-MD -MP -MF $(@).d -MT $@

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

MAKE_CC=        $(CC)   $(CFLAGS)   $(CPPFLAGS_$*) $(CFLAGS_$*)   -c $< -o $@ $(DEPFLAGS)
MAKE_CXX=       $(CXX)  $(CXXFLAGS) $(CPPFLAGS_$*) $(CXXFLAGS_$*) -c $< -o $@ $(DEPFLAGS)
MAKE_AS=        $(CC)   $(CFLAGS)   $(CPPFLAGS_$*) $(CFLAGS_$*)   -c $< -o $@ $(DEPFLAGS)
MAKE_OBJDIR=    mkdir -p $*                                       && touch $@
MAKE_LIB=       $(AR) $@                        $(LINK_INPUTS)&& $(RANLIB) $@
MAKE_DLL=       $(LIBTOOL) -shared              $(LINK_INPUTS)          -o $@
MAKE_EXE=       $(LD) -o $@ $(LINK_INPUTS) $(LDFLAGS) $(LDFLAGS_$*)


#------------------------------------------------------------------------------
#   Dependencies
#------------------------------------------------------------------------------

CC_DEPEND=      $(CC)  $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MP -MF $@ -MT $(@:.d=) $<
CXX_DEPEND=     $(CXX) $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MP -MF $@ -MT $(@:.d=) $<
AS_DEPEND=      $(CC)  $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MP -MF $@ -MT $(@:.d=) $<


#------------------------------------------------------------------------------
#  Configuration checks
#------------------------------------------------------------------------------

CC_CONFIG=	mkdir -p "$$(dirname "$@")" ; echo '\#define HAVE_$*_H' $$($(CC) $(CFLAGS) -Werror -c "$<" -o "$<".o > "$<".err 2>&1 && echo 1 || echo 0) | tr '[:lower:]' '[:upper:]' | sed -e 's|[^[:alnum:]]|_|g' -e 's|_DEFINE_\(.*\)_0|/* \#undef \1 */|g' -e 's|_DEFINE_\(.*\)_1|\#define \1 1|g' > "$@"
CXX_CONFIG=	mkdir -p "$$(dirname "$@")" ; echo '\#define HAVE_$*' $$($(CXX) $(CXXFLAGS) -Werror -c "$<" -o "$<".o > "$<".err 2>&1 && echo 1 || echo 0) | tr '[:lower:]' '[:upper:]' | sed -e 's|[^[:alnum:]]|_|g' -e 's|_DEFINE_\(.*\)_0|/* \#undef \1 */|g' -e 's|_DEFINE_\(.*\)_1|\#define \1 1|g' > "$@"
