#******************************************************************************
# config.auto.mk                                              Recorder project 
#******************************************************************************
#
#  File Description:
#
#    Default configuration file invoked when the configuration is unknown
#    In that case, we pick one based on the uname.
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

# Identification of the default build environment
BUILDENV=$(BUILDENV_$(shell uname -s | sed s/CYGWIN.*/Cygwin/ | sed s/MINGW.*/MinGW/))
BUILDENV_Darwin=$(shell clang --version > /dev/null 2>&1 && echo macosx-clang || echo macosx)
BUILDENV_Linux=linux
BUILDENV_Cygwin=cygwin
BUILDENV_MinGW=mingw

# Just in case (leftovers from a former life ;-)
BUILDENV_HP-UX=hpux
BUILDENV_SunOS=sun

include $(BUILD)config.$(BUILDENV).mk

hello: warn-buildenv

warn-buildenv:
	@$(ECHO) "$(ERR_COLOR)"
	@$(ECHO) "****************************************************************"
	@$(ECHO) "* The BUILDENV environment variable is not set"
	@$(ECHO) "* You will accelerate builds by setting it as appropriate for"
	@$(ECHO) "* your system. The best guess is BUILDENV=$(BUILDENV)"
	@$(ECHO) "* Attempting to build $(TARGET) with $(BUILDENV)" DIR=$(DIR)
	@$(ECHO) "****************************************************************"
	@$(ECHO) "$(DEF_COLOR)"
