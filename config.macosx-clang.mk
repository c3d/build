#******************************************************************************
# config.macosx-clang.mk                                      Recorder project
#******************************************************************************
#
#  File Description:
#
#    This is the shared makefile configuration when building with Clang on OSX
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
#  Configuration definitions
#------------------------------------------------------------------------------

DEFINES_macosx-clang=CONFIG_MACOSX
OS_NAME_macosx-clang=macosx

include $(BUILD)config.gnu.mk

CFLAGS_ssev4=	-msse4
DLL_EXT=	.dylib
MAKE_DLL=	$(LD) -shared	$(LDFLAGS) $(LDFLAGS_$*)  	$(LINK_INPUTS)	-o $@	-rpath $(PREFIX_LIB)

# On MacOSX, we will use basic frameworks e.g. for string and filesystem functions
LDFLAGS_macosx-clang=	-framework CoreFoundation 			\
			-framework CoreServices
