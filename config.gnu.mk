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

CFLAGS_STD=	$(CC_STD:%=-std=%)	-fPIC
CXXFLAGS_STD=	$(CXX_STD:%=-std=%)	-fPIC

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

MAKE_CC=	$(CC)	$(CFLAGS)   $(CPPFLAGS_$*) $(CFLAGS_$*)	  -c $< -o $@ $(DEPFLAGS)
MAKE_CXX=	$(CXX)	$(CXXFLAGS) $(CPPFLAGS_$*) $(CXXFLAGS_$*) -c $< -o $@ $(DEPFLAGS)
MAKE_AS=	$(CC)	$(CFLAGS)   $(CPPFLAGS_$*) $(CFLAGS_$*)	  -c $< -o $@ $(DEPFLAGS)
MAKE_DIR=	mkdir -p $*
MAKE_OBJDIR=	$(MAKE_DIR)					  && touch $@
MAKE_LIB=	$(AR) $@	 $(LINK_INPUTS)&& $(RANLIB) $@
MAKE_DLL=	$(LD) -shared	 $(LDFLAGS) $(LDFLAGS_$*)  $(LINK_CMDLINE)	   -o $@
MAKE_EXE=	$(LD)		 $(LDFLAGS) $(LDFLAGS_$*)  $(LINK_CMDLINE)	   -o $@

LINK_DIR_OPT=	-L
LINK_LIB_OPT=	-l
LINK_DLL_OPT=	-l
LINK_CFG_OPT=	-l


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

CFG_UPPER=$(shell echo -n "$(ORIG_TARGET)" | tr '[:lower:]' '[:upper:]' | tr -c '[:alnum:]' '_')
CFG_FLAGS=$(shell grep '// [A-Z]*FLAGS=' "$<" | sed -e 's|// [A-Z]*FLAGS=||g')

CFG_DEF=	echo '\#define'
CFG_TEST=								\
	$(CFG_FLAGS) "$<" -o "$<".exe > "$<".err 2>&1 &&		\
	"$<".exe > "$<".out && echo 1 || echo 0
CFG_UNDEF0=								\
	| sed -e 's|^\#define \(.*\) 0$$|/* \#undef \1 */|g' > "$@";	\
	[ -f "$<".out ] && cat >> "$@" "$<".out; true
CFG_CFLAGS=	$(CFLAGS)   $(shell cat $(PKG_CFLAGS) $(PKG_LDFLAGS) /dev/null)
CFG_CXXFLAGS=	$(CXXFLAGS) $(shell cat $(PKG_CFLAGS) $(PKG_LDFLAGS) /dev/null)

CFG_CC_CMD=	`$(CC)  $(CFG_CFLAGS)   $(CFLAGS_CONFIG_$*)        $(CFG_TEST)`
CFG_CXX_CMD=	`$(CXX) $(CFG_CXXFLAGS) $(CXXFLAGS_CONFIG_$*)      $(CFG_TEST)`
CFG_LIB_CMD=	`$(CC)  $(CFG_CFLAGS)   $(CFLAGS_CONFIG_$*)   -l$* $(CFG_TEST)`
CFG_FN_CMD=	`$(CC)  $(CFG_CFLAGS)   $(CFLAGS_CONFIG_$*)        $(CFG_TEST)`

CC_CONFIG=	$(CFG_DEF) HAVE_$(CFG_UPPER)_H  $(CFG_CC_CMD)  $(CFG_UNDEF0)
CXX_CONFIG=	$(CFG_DEF) HAVE_$(CFG_UPPER)    $(CFG_CXX_CMD) $(CFG_UNDEF0)
LIB_CONFIG=	$(CFG_DEF) HAVE_LIB$(CFG_UPPER) $(CFG_LIB_CMD) $(CFG_UNDEF0)
FN_CONFIG=	$(CFG_DEF) HAVE_$(CFG_UPPER) 	$(CFG_FN_CMD)  $(CFG_UNDEF0)

MAKE_CONFIG=	sed	-e 's|^\#define \([^ ]*\) \(.*\)$$|\1=\2|g' 	\
			-e 's|.*undef.*||g' < "$<" > "$@"
