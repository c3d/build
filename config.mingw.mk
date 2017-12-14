#******************************************************************************
# config.mingw.mk                                             Recorder project
#******************************************************************************
#
#  File Description:
#
#    Configuration file when building with MinGW
#
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

DEFINES_mingw=CONFIG_MINGW UNICODE _WIN32 WIN32
OS_NAME_mingw=windows

include $(BUILD)config.gnu.mk

# On Windows, DLLs have to go with the .exe
PREFIX_DLL:=$(PREFIX_DLL:$(PREFIX_LIB)=$(PREFIX_BIN))

# Windows overrides for extensions
EXE_EXT=        .exe
LIB_EXT=        .a
DLL_EXT=        .dll

# MinGW has no 'install' program
INSTALL=	cp
