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

CC=             $(CROSS_COMPILE:%=%-)gcc
CXX=            $(CROSS_COMPILE:%=%-)g++
ifeq ($(filter %.cpp,$(SOURCES)),)
LD=		$(CC)
else
LD=             $(CXX)
endif
CPP=            $(CC) -E
PYTHON=         python
AR=             $(CROSS_COMPILE:%=%-)ar -rcs
RANLIB=         $(CROSS_COMPILE:%=%-)ranlib
LIBTOOL=        libtool -no_warning_for_no_symbols
INSTALL=	install


#------------------------------------------------------------------------------
#  Compilation flags
#------------------------------------------------------------------------------

CFLAGS_STD=$(CC_STD:%=-std=%)
CXXFLAGS_STD=$(CXX_STD:%=-std=%)

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

EXE_PFX=
LIB_PFX=	lib
DLL_PFX=	lib

#------------------------------------------------------------------------------
#  Build rules
#------------------------------------------------------------------------------

MAKE_CC=        $(CC)   $(CFLAGS)   $(CPPFLAGS_$*) $(CFLAGS_$*)   -c $< -o $@ $(DEPFLAGS)
MAKE_CXX=       $(CXX)  $(CXXFLAGS) $(CPPFLAGS_$*) $(CXXFLAGS_$*) -c $< -o $@ $(DEPFLAGS)
MAKE_AS=        $(CC)   $(CFLAGS)   $(CPPFLAGS_$*) $(CFLAGS_$*)   -c $< -o $@ $(DEPFLAGS)
MAKE_OBJDIR=    mkdir -p $*                                       && touch $@
MAKE_LIB=       $(AR) $@         $(LDFLAGS_$*)  $(LINK_INPUTS)&& $(RANLIB) $@
MAKE_DLL=       $(LD) -shared    $(LDFLAGS_$*)  $(LINK_CMDLINE)         -o $@
MAKE_EXE=       $(LD)            $(LDFLAGS_$*)  $(LINK_CMDLINE)         -o $@

LINK_DIR_OPT=	-L
LINK_LIB_OPT=	-l
LINK_DLL_OPT=	-l


#------------------------------------------------------------------------------
#   Dependencies
#------------------------------------------------------------------------------

CC_DEPEND=      $(CC)  $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MP -MF $@ -MT $(@:.d=) $<
CXX_DEPEND=     $(CXX) $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MP -MF $@ -MT $(@:.d=) $<
AS_DEPEND=      $(CC)  $(CPPFLAGS) $(CPPFLAGS_$*) -MM -MP -MF $@ -MT $(@:.d=) $<


#------------------------------------------------------------------------------
#  Test environment
#------------------------------------------------------------------------------

TEST_ENV=	LD_LIBRARY_PATH=$(OBJROOT)


#------------------------------------------------------------------------------
#  Configuration checks
#------------------------------------------------------------------------------

CONFIG_UPPER=$(shell echo -n "$(ORIG_TARGET)" | tr '[:lower:]' '[:upper:]' | tr -c '[:alnum:]' '_')
CONFIG_FLAGS=$(shell grep '// [A-Z]*FLAGS=' "$<" | sed -e 's|// [A-Z]*FLAGS=||g')

CC_CONFIG=	echo '\#define' HAVE_$(CONFIG_UPPER)_H $(shell $(CC) $(CFLAGS) $(CFLAGS_CONFIG_$*) $(CONFIG_FLAGS) "$<" -o "$<".exe > "$<".err 2>&1 && "$<".exe > "$<".out && echo 1 || echo 0) | sed -e 's|^\#define \(.*\) 0$$|/* \#undef \1 */|g' > "$@"; [ -f "$<".out ] && cat >> "$@" "$<".out; true
CXX_CONFIG=	echo '\#define' HAVE_$(CONFIG_UPPER) $(shell $(CXX) $(CXXFLAGS) $(CXXFLAGS_CONFIG_$*) $(CONFIG_FLAGS) "$<" -o "$<".exe > "$<".err 2>&1 && "$<".exe > "$<".out && echo 1 || echo 0) | sed -e 's|^\#define \(.*\) 0$$|/* \#undef \1 */|g' > "$@"; [ -f "$<".out ] && cat >> "$@" "$<".out; true
LIB_CONFIG=	echo '\#define HAVE_LIB'$(CONFIG_UPPER) $$($(CC) $(CCFLAGS) $(CFLAGS_CONFIG_$*) -l$* "$<" -o "$<".exe > "$<".err 2>&1 && "$<".exe && echo 1 || echo 0) | sed -e 's|^\#define \(.*\) 0$$|/* \#undef \1 */|g' > "$@"
FN_CONFIG=	echo '\#define HAVE_'$(CONFIG_UPPER) $$($(CC) $(CCFLAGS) $(CFLAGS_CONFIG_$*) "$<" -o "$<".exe > "$<".err 2>&1 && "$<".exe > "$<".out && echo 1 || echo 0) | sed -e 's|^\#define \(.*\) 0$$|/* \#undef \1 */|g' > "$@"; [ -f "$<".out ] && cat >> "$@" "$<".out; true
