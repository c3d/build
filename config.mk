#******************************************************************************
# config.mk                                                   Recorder project
#******************************************************************************
#
#  File Description:
#
#    This is the shared makefile configuration file for all Camera Controls
#    This where the location of specific directories should be specified
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

# Use /bin/sh as a basic shell, since it is faster than bash
# even when it's actually bash underneath, at least
# according to http://www.oreilly.com/openbook/make3/book/ch10.pdf
SHELL=      /bin/bash

#------------------------------------------------------------------------------
#   Default build target and options (can be overriden with env variables)
#------------------------------------------------------------------------------

# Default target
TARGET?=        opt

# Default build environment if not set
BUILDENV?=auto

# Default location for object files
BUILD_OBJECTS?= $(BUILD)objects

# Default location for build logs
BUILD_LOGS?=$(BUILD)logs/
BUILD_SAVED_LOG?=$(BUILD_LOGS)make.log

# Stuff to clean
GARBAGE=        *~ *.bak


#------------------------------------------------------------------------------
#   Installation paths
#------------------------------------------------------------------------------

PREFIX?=/usr/local/
PREFIX_BIN?=$(PREFIX)bin/
PREFIX_LIB?=$(PREFIX)lib/
PREFIX_DLL?=$(PREFIX_LIB)


#------------------------------------------------------------------------------
#   Compilation flags
#------------------------------------------------------------------------------

# Standard specification (use GCC standard names)
# For a compiler that is not GCC compatible, please state options corresponding
# to the relevant GNU option names as follows:
#   CCFLAGS_STD=$(CC_FLAGS_STD_$(CC_STD))
#   CCFLAGS_STD_gnu11=[whatever option is needed here]
CC_STD=gnu11
CXX_STD=gnu++14

# Compilation flags
DEFINES_debug=      DEBUG
DEFINES_opt=        DEBUG OPTIMIZED
DEFINES_release=    NDEBUG OPTIMIZED RELEASE

# Default for C++ flags is to use CFLAGS
CXXFLAGS_debug=     $(CFLAGS_debug)
CXXFLAGS_opt=       $(CFLAGS_opt)
CXXFLAGS_release=   $(CFLAGS_release)
CXXFLAGS_extra=     $(CFLAGS_extra)


#------------------------------------------------------------------------------
#   Toools we use
#------------------------------------------------------------------------------

ECHO=           /bin/echo
TIME=           time
RECURSE_MAKE=   $(MAKE) --no-print-directory COLORIZE=



#------------------------------------------------------------------------------
#   OS name for a given build environment
#------------------------------------------------------------------------------

OS_NAME=                $(OS_NAME_$(BUILDENV))


#------------------------------------------------------------------------------
#   Warning extraction (combines outputs from multiple compiler "races")
#------------------------------------------------------------------------------

# GCC and clang write something like:   "warning: GCC keeps it simple"
# Visual Studio writes something like:  "warning C2013: Don't use Visual Studio"

WARNING_MSG=    '[Ww]arning\( \?\[\?[A-Za-z]\+[0-9]\+\]\?\)\?:'
ERROR_MSG=  '[Ee]rror\( \?\[\?[A-Za-z]\+[0-9]\+\]\?\)\?:'


#------------------------------------------------------------------------------
# Colorization
#------------------------------------------------------------------------------
# These use ANSI code, but they work on Mac, Windows, Linux, BSD and VMS, which is good enough
# Change them if you want to work from an hpterm on HP-UX ;-)
INFO_STEP_COL=  \\033[37;44m
INFO_NAME_COL=  \\033[33;44m
INFO_LINE_COL=  \\033[36;49m
INFO_ERR_COL=   \\033[31m
INFO_WRN_COL=   \\033[33m
INFO_POS_COL=   \\033[32m
INFO_RST_COL=   \\033[39;49;27m
INFO_CLR_EOL=   \\033[K
INFO=           printf "%-20s %s %s %s %s %s %s %s\n"

# Color for build steps
STEP_COLOR:=    $(shell printf "$(INFO_STEP_COL)")
LINE_COLOR:=    $(shell printf "$(INFO_NAME_COL)")
NAME_COLOR:=    $(shell printf "$(INFO_LINE_COL)")
ERR_COLOR:=     $(shell printf "$(INFO_ERR_COL)")
WRN_COLOR:=     $(shell printf "$(INFO_WRN_COL)")
POS_COLOR:=     $(shell printf "$(INFO_POS_COL)")
DEF_COLOR:=     $(shell printf "$(INFO_RST_COL)")
CLR_EOLINE:=    $(shell printf "$(INFO_CLR_EOL)")

SEDOPT_windows=	-u

# Colorize warnings, errors and progress information
LINE_BUFFERED=--line-buffered
COLORIZE=   | grep $(LINE_BUFFERED) -v -e "^true &&" -e "^[A-Za-z0-9_-]\+\.\(c\|h\|cpp\|hpp\)$$"            \
            | sed $(SEDOPT_$(OS_NAME))                                                                      \
            -e 's/^\(.*[,:(]\{1,\}[0-9]*[ :)]*\)\([Ww]arning\)/$(POS_COLOR)\1$(WRN_COLOR)\2$(DEF_COLOR)/g'  \
            -e 's/^\(.*[,:(]\{1,\}[0-9]*[ :)]*\)\([Ee]rror\)/$(POS_COLOR)\1$(ERR_COLOR)\2$(DEF_COLOR)/g'    \
            -e 's/^\(\[BEGIN\]\)\(.*\)$$/$(STEP_COLOR)\1\2$(CLR_EOLINE)$(DEF_COLOR)/g'                      \
            -e 's/^\(\[END\]\)\(.*\)$$/$(STEP_COLOR)\1\2$(CLR_EOLINE)$(DEF_COLOR)/g'                        \
            -e 's/^\(\[[A-Z/ 0-9-]\{1,\}\]\)\(.*\)$$/$(LINE_COLOR)\1$(NAME_COLOR)\2$(DEF_COLOR)/g'


#------------------------------------------------------------------------------
#   Logging
#------------------------------------------------------------------------------

LOG_COMMANDS=       PRINT_COMMAND="true && " 2>&1              | \
                    tee $(BUILD_LOG)                             \
                    $(COLORIZE) ;                                \
                    RC=$${PIPESTATUS[0]} $${pipestatus[1]} ;     \
                    $(ECHO) `grep -v '^true &&' $(BUILD_LOG)   | \
                             grep -i $(ERROR_MSG) $(BUILD_LOG) | \
                             wc -l` Errors,                      \
                            `grep -v '^true &&' $(BUILD_LOG)   | \
                             grep -i $(WARNING_MSG)            | \
                             wc -l` Warnings in $(BUILD_LOG);    \
                    cp $(BUILD_LOG) $(BUILD_SAVED_LOG);          \
                    exit $$RC


#------------------------------------------------------------------------------
#   Progress reporting
#------------------------------------------------------------------------------

HELLO=          BEGIN
HELLO_clean=    CLEAN
HELLO_install=  INSTALL
HELLO_test=     TEST
HELLO_bench=    BENCH


#------------------------------------------------------------------------------
#   Build configuration and rules
#------------------------------------------------------------------------------

# Include actual configuration for specific BUILDENV - At end for overrides
include $(BUILD)config.$(BUILDENV).mk
