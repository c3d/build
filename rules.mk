#******************************************************************************
# rules.mk                                                    Recorder project
#******************************************************************************
#
#  File Description:
#
#   Common rules for building the targets
#
#
#
#
#
#
#
#******************************************************************************
# (C) 1992-2017 Christophe de Dinechin <christophe@dinechin.org>
# This software is licensed under the GNU General Public License v3
# See file COPYING for details.
#******************************************************************************

# Include the Makefile configuration and local variables
include $(BUILD)config.mk

# Default build settings (definitions in specific config..mkXYZ)
XINCLUDES=  $(INCLUDES) $(INCLUDES_$(BUILDENV)) $(INCLUDES_$(TARGET))       $(INCLUDES_EXTRA)
XDEFINES=   $(DEFINES)  $(DEFINES_$(BUILDENV))  $(DEFINES_$(TARGET))        $(DEFINES_EXTRA)
CPPFLAGS+=              $(CPPFLAGS_$(BUILDENV)) $(CPPFLAGS_$(TARGET))       $(CPPFLAGS_EXTRA)                   $(XDEFINES:%=-D%) $(XINCLUDES:%=-I%)
CFLAGS+=    $(CPPFLAGS) $(CFLAGS_STD)   $(CFLAGS_PKGCONFIG) $(CFLAGS_$(BUILDENV))   $(CFLAGS_$(TARGET))         $(CFLAGS_EXTRA)
CXXFLAGS+=  $(CPPFLAGS) $(CXXFLAGS_STD) $(CFLAGS_PKGCONFIG) $(CXXFLAGS_$(BUILDENV)) $(CXXFLAGS_$(TARGET))       $(CFLAGS_EXTRA) $(CXXFLAGS_EXTRA)
LDFLAGS+=               $(CFLAGS_STD) $(CXXFLAGS_STD) $(LDFLAGS_PKGCONFIG) $(LDFLAGS_$(BUILDENV))  $(LDFLAGS_$(TARGET))        $(CFLAGS_EXTRA) $(LDFLAGS_EXTRA)

ifndef DIR
# The cd ./ in FULLDIR is for a corner case where . is a symbolic link
# At least with bash (not sure with other shells), pwd returns me
# the symbolic link path (as for BASEDIR), rather than the physical path

# So this is necessary for the substitution to happen correctly. Ugh!
BASEDIR:=       $(realpath $(BUILD)..)
FULLDIR:=       $(abspath .)
DIR:=           $(subst $(BASEDIR),,$(FULLDIR))
PRETTY_DIR:=    $(subst $(BASEDIR),[top],$(FULLDIR))
BUILD_DATE:=    $(shell /bin/date '+%Y%m%d-%H%M%S')
OBJROOT:=       $(OUTPUT)$(BUILDENV)/$(CROSS_COMPILE:%=%-)$(TARGET)$(BASE_EXTRA_DEPTH)
BUILD_LOG:=     $(LOGS)build-$(BUILDENV)-$(CROSS_COMPILE:%=%-)$(TARGET)-$(BUILD_DATE).log
endif

# Configuration variables
OBJDIR:=        $(OBJROOT)$(DIR)
OBJECTS=        $(SOURCES:%=$(OBJDIR)/%$(OBJ_EXT))
PRODUCTS_EXE:=  $(patsubst %.exe,%$(EXE_EXT),$(filter %.exe,$(PRODUCTS)))
PRODUCTS_LIB:=  $(patsubst %.lib,%$(LIB_EXT),$(filter %.lib,$(PRODUCTS)))
PRODUCTS_DLL:=  $(patsubst %.dll,%$(DLL_EXT),$(filter %.dll,$(PRODUCTS)))
PRODUCTS_OTHER:=$(filter-out %.exe %.lib %.dll %$(EXE_EXT) %$(LIB_EXT) %$(DLL_EXT), $(PRODUCTS))
OBJROOT_EXE:=   $(PRODUCTS_EXE:%=$(OBJROOT)/$(EXE_PFX)%)
OBJROOT_LIB:=   $(PRODUCTS_LIB:%=$(OBJROOT)/$(LIB_PFX)%)
OBJROOT_DLL:=   $(PRODUCTS_DLL:%=$(OBJROOT)/$(DLL_PFX)%)
OBJROOT_OTHER:= $(PRODUCTS_OTHER:%=$(OBJROOT)/%)
OBJPRODUCTS:=   $(OBJROOT_EXE) $(OBJROOT_LIB) $(OBJROOT_DLL) $(OBJROOT_OTHER)

# Check a common mistake with PRODUCTS= not being set or set without extension
# Even on Linux / Unix, the PRODUCTS variable must end in .exe for executables,
# in .lib for static libraries, and in .dll for dynamic libraries.
# This is to help executable build rules be more robust and not catch
# unknown extensions by mistake. The extension is replaced with the
# correct platform extension, i.e. .a for static libraries on Linux
ifneq ($(PRODUCTS),)
ifeq ($(PRODUCTS_EXE)$(PRODUCTS_LIB)$(PRODUCTS_DLL),)
$(error Error: Variable PRODUCTS must end in .exe, .lib or .dll)
endif
endif

LIBNAMES:=      $(filter %.lib, $(notdir $(LIBRARIES)))
DLLNAMES:=      $(filter %.dll, $(notdir $(LIBRARIES)))
OBJLIBS:=	$(LIBNAMES:%.lib=$(OBJROOT)/$(LIB_PFX)%$(LIB_EXT))
OBJDLLS:=       $(DLLNAMES:%.dll=$(OBJROOT)/$(DLL_PFX)%$(DLL_EXT))
LINK_PATHS:=	$(OBJROOT:%=$(LINK_DIR_OPT)%)
LINK_LIBS:=	$(LINK_LIBS)				\
		$(LIBNAMES:%.lib=$(LINK_LIB_OPT)%)	\
		$(DLLNAMES:%.dll=$(LINK_DLL_OPT)%)
LINK_INPUTS:=   $(OBJECTS) $(OBJLIBS) $(OBJDLLS)
LINK_CMDLINE:=	$(OBJECTS) $(LINK_PATHS) $(LINK_LIBS)
ifneq ($(words $(LINK_INPUTS)),0)
LINK_WINPUTS=   $(patsubst %,"%", $(shell cygpath -aw $(LINK_INPUTS)))
endif
PRINT_DIR=              --no-print-directory
RECURSE_BUILDENV=$(BUILDENV)
RECURSE_CMD=    $(MAKE) $(PRINT_DIR) TARGET=$(TARGET) BUILDENV=$(RECURSE_BUILDENV) BUILD="$(abspath $(BUILD))/" $(RECURSE) COLORIZE=
MAKEFILE_DEPS:= $(MAKEFILE_LIST)
NOT_PARALLEL?=  .NOTPARALLEL
BUILD_LOW?=     0
BUILD_HIGH?=    100
BUILD_INDEX:=   1
BUILD_COUNT:=   $(words $(SOURCES))
GIT_REVISION:=  $(shell git rev-parse --short HEAD 2> /dev/null || echo "unknown")
PROFILE_OUTPUT:=$(subst $(EXE_EXT),,$(OBJROOT_EXE))_prof_$(GIT_REVISION).vsp

-include $(PKGCONFIGS:%=$(OBJROOT)/%.pkg-config.mk)


#------------------------------------------------------------------------------
#   User targets
#------------------------------------------------------------------------------

all: $(TARGET)

debug opt release profile: logs.mkdir
	$(PRINT_COMMAND) $(TIME) $(MAKE) TARGET=$@ RECURSE=build LOG_COMMANDS= build $(LOG_COMMANDS)

# Testing
test tests check: $(TARGET)
	$(PRINT_COMMAND) $(MAKE) RECURSE=test $(TESTS:%=%.test) LOG_COMMANDS= TIME= $(LOG_COMMANDS)

# Clean builds
startup restart rebuild: clean all

# Installation
install: all
	$(PRINT_COMMAND) $(MAKE) RECURSE=install install-internal recurse LOG_COMMANDS= TIME= $(LOG_COMMANDS)
install-internal:				\
        $(OBJROOT_EXE:%=%.install_exe)          \
        $(OBJROOT_LIB:%=%.install_lib)          \
        $(OBJROOT_DLL:%=%.install_dll)          \
        $(EXE_INSTALL:%=%.install_exe)          \
        $(LIB_INSTALL:%=%.install_lib)          \
        $(DLL_INSTALL:%=%.install_dll)		\
	$(HDR_INSTALL:%=%.install_hdr)

clean: hello.clean
	-$(PRINT_COMMAND) rm -f $(GARBAGE) $(TOCLEAN) $(OBJECTS) $(DEPENDENCIES) $(OBJPRODUCTS) config.h

distclean: nuke clean
nuke:
	-$(PRINT_COMMAND) rm -rf $(OUTPUT) $(LOGS)build-*.log


help:
	@$(ECHO) "Available targets:"
	@$(ECHO) "  make                : Build default target (TARGET=$(TARGET))"
	@$(ECHO) "  make all            : Same"
	@$(ECHO) "  make debug          : Force debug build"
	@$(ECHO) "  make opt            : Force optimized build"
	@$(ECHO) "  make release        : Force release build"
	@$(ECHO) "  make profile        : Force profile build"
	@$(ECHO) "  make clean          : Clean build results (only BUILDENV=$(BUILDENV))"
	@$(ECHO) "  make rebuild        : Clean before building"
	@$(ECHO) "  make nuke           : Clean build directory"
	@$(ECHO) "  make test           : Run sanity tests (run only tests)"
	@$(ECHO) "  make check          : Build product, then run tests"
	@$(ECHO) "  make benchmark      : Build product, then run benchmarks"
	@$(ECHO) "  make install        : Build and install result"
	@$(ECHO) "  make v-[target]     : Build target in 'verbose' mode"
	@$(ECHO) "  make d-[target]     : Deep-checking of library dependencies"
	@$(ECHO) "  make top-[target]   : Rebuild from top-level directory"


#------------------------------------------------------------------------------
#   Internal targets
#------------------------------------------------------------------------------

build: hello config libraries recurse prebuild objects product postbuild goodbye

ifndef V
hello:
	@$(INFO) "[BEGIN]" $(TARGET) $(BUILDENV) in $(PRETTY_DIR)
goodbye:
	@$(INFO) "[END]" $(TARGET) $(BUILDENV) in $(PRETTY_DIR)

hello.install:
	@$(INFO) "[INSTALL]"	$(TARGET) $(BUILDENV) in $(PRETTY_DIR)
hello.clean:
	@$(INFO) "[CLEAN]" $(TARGET) $(BUILDENV) in $(PRETTY_DIR)
else
hello:
goodbye:
hello.install:
hello.clean:
endif

libraries: $(OBJLIBS) $(OBJDLLS)
product:$(OBJPRODUCTS)
objects:$(OBJDIR:%=%/.mkdir) $(OBJECTS)

# "Hooks" for pre and post build steps
config: $(VARIANTS:%=%.variant)
config: $(CONFIG:%=config.h) $(PKGCONFIGS:%=$(OBJROOT)/%.pkg-config.mk)
prebuild:
postbuild:

# Run the test (in the object directory)
product.test: product .ALWAYS
	$(PRINT_TEST) $(TEST_ENV) $(OBJROOT_EXE) $(PRODUCTS_OPTS)

# Run a test from a C or C++ file to link against current library
%.c.test: $(OBJROOT_LIB) .ALWAYS
	$(PRINT_BUILD) $(MAKE) SOURCES=$*.c LINK_LIBS=$(OBJROOT_LIB) PRODUCTS=$*.exe $(TARGET)
	$(PRINT_TEST) $(TEST_ENV) $(TEST_CMD_$*) $(OBJROOT)/$*$(EXE_EXT) $(TEST_ARGS_$*)
%.cpp.test: $(OBJROOT_LIB) .ALWAYS
	$(PRINT_BUILD) $(MAKE) SOURCES=$*.cpp LINK_LIBS=$(OBJROOT_LIB) PRODUCTS=$*.exe $(TARGET)
	$(PRINT_TEST) $(TEST_ENV) $(TEST_CMD_$*) $(OBJROOT)/$*$(EXE_EXT) $(TEST_ARGS_$*)

# Installing the product: always need to build it first
%.install_exe: $(PREFIX_BIN).mkdir build
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_BIN)
%.install_lib: $(PREFIX_LIB).mkdir build
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_LIB)
%.install_dll: $(PREFIX_DLL).mkdir build
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_DLL)
%.install_hdr: $(PREFIX_HDR).mkdir
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_HDR)

# Check pkg-config
$(OBJROOT)/%.pkg-config.mk: $(MAKEFILE_DEPS) $(OBJROOT)/.mkdir
	$(PRINT_PKGCONFIG) pkg-config $*
	$(PRINT_GENERATE)  echo CFLAGS_PKGCONFIG+=`pkg-config --cflags $*` > $@ && echo LDFLAGS_PKGCONFIG+=`pkg-config --libs $*` >> $@

# Benchmarking (always done with profile target)
benchmark:	$(BENCHMARK:%=%.benchmark) $(BENCHMARKS:%=%.benchmark)
product.benchmark: product .ALWAYS
	$(PRINT_TEST) gprof

.PHONY: hello hello.install hello.clean goodbye
.PHONY: build libraries product objects prebuild postbuild test
.PHONY: .ALWAYS


#------------------------------------------------------------------------------
#  Build target modifiers
#------------------------------------------------------------------------------

# Make from the top-level directory (useful from child directories)
top-%:
	cd $(BUILD); $(MAKE) $*

# Verbose build (show all commands as executed)
v-% verbose-%:
	$(PRINT_COMMAND) $(MAKE) $* V=1

# Timed build (show the time for each step)
t-% time-%:
	$(PRINT_COMMAND) time $(MAKE) $*

# Deep build (re-check all libraries instead of just resulting .a)
d-% deep-%:
	$(PRINT_COMMAND) $(MAKE) $* DEEP_BUILD=deep_build

# Silent build (logs errors only to build.err)
s-% silent-%:
	$(PRINT_COMMAND) $(MAKE) -s --no-print-directory $* 2> build.err

# Logged build (show results and record them in build.log)
l-% log-%:
	$(PRINT_COMMAND) $(MAKE) $*
nolog-% nl-%:
	$(PRINT_COMMAND) $(MAKE) $* LOG_COMMANDS=

# No colorization
nocolor-% nocol-% bw-%:
	$(PRINT_COMMAND) $(MAKE) $* COLORIZE=

# For debug-install, run 'make TARGET=debug install'
debug-% opt-% release-% profile-%:
	@$(MAKE) TARGET=$(@:-$*=) $*


#------------------------------------------------------------------------------
#  Subdirectories and requirements
#------------------------------------------------------------------------------

recurse: $(SUBDIRS:%=%.recurse)
%.dll.recurse:      | hello prebuild
	+$(PRINT_COMMAND) $(MAKE) $*.recurse BUILD_DLL=dll
%.project.recurse:  | hello prebuild
	+$(PRINT_COMMAND) $(MAKE) PROJECT=$*
%.recurse:          | hello prebuild
	+$(PRINT_COMMAND) cd $* && $(RECURSE_CMD)

# If LIBRARIES=foo/bar, go to directory foo/bar, which should build bar.a
$(OBJROOT)/$(LIB_PFX)%$(LIB_EXT): $(DEEP_BUILD)
	+$(PRINT_COMMAND) cd $(filter %$*, $(LIBRARIES:.lib=) $(SUBDIRS)) && $(RECURSE_CMD)
$(OBJROOT)/$(DLL_PFX)%$(DLL_EXT): $(DEEP_BUILD)
	+$(PRINT_COMMAND) cd $(filter %$*, $(LIBRARIES:.dll=) $(SUBDIRS)) && $(RECURSE_CMD)
%/.test:
	+$(PRINT_TEST) cd $* && $(MAKE) TARGET=$(TARGET) test
deep_build:

%.variant:
	$(PRINT_VARIANT) $(MAKE) VARIANTS= VARIANT=$* RECURSE=build build


#------------------------------------------------------------------------------
#  Progress printout
#------------------------------------------------------------------------------

INCR_INDEX=	$(eval BUILD_INDEX:=$(shell echo $$(($(BUILD_INDEX)+1))))
PRINT_COUNT=	$(shell printf "%3d/%d" $(BUILD_INDEX) $(BUILD_COUNT))$(INCR_INDEX)
PRINT_PCT=	$(shell printf "%3d%%" $$(( ($(BUILD_HIGH) - $(BUILD_LOW)) * $(BUILD_INDEX) / $(BUILD_COUNT) + $(BUILD_LOW))))$(INCR_INDEX)

# Printing out various kinds of statements
ifndef V
PRINT_COMMAND= 	@
PRINT_COMPILE=	$(PRINT_COMMAND) $(INFO) "[COMPILE$(PRINT_COUNT)] " $<;
PRINT_BUILD= 	$(PRINT_COMMAND) $(INFO) "[BUILD]" $(shell basename $@);
PRINT_GENERATE= $(PRINT_COMMAND) $(INFO) "[GENERATE]" "$(shell basename "$@")";
PRINT_VARIANT=  $(PRINT_COMMAND) $(INFO) "[VARIANT]" "$*";
PRINT_INSTALL=  $(PRINT_COMMAND) $(INFO) "[INSTALL] " $(*F) in $(<D);
PRINT_COPY=     $(PRINT_COMMAND) $(INFO) "[COPY]" $< '=>' $@ ;
PRINT_DEPEND= 	$(PRINT_COMMAND) $(INFO) "[DEPEND] " $< ;
PRINT_TEST= 	$(PRINT_COMMAND) $(INFO) "[TEST]" $(@:.test=) ;
PRINT_CONFIG= 	$(PRINT_COMMAND) $(INFO) "[CONFIG]" "$*" ;
PRINT_PKGCONFIG=$(PRINT_COMMAND) $(INFO) "[PKGCONFIG]" "$*" ;
PRINT_LIBCONFIG=$(PRINT_COMMAND) $(INFO) "[LIBCONFIG]" "lib$*" ;
endif

logs.mkdir: $(LOGS).mkdir $(dir $(LAST_LOG))/.mkdir
%/.mkdir:
	$(PRINT_COMMAND) $(MAKE_OBJDIR)
.PRECIOUS: %/.mkdir


#------------------------------------------------------------------------------
#  Special for Fabien: make 'Directory'
#------------------------------------------------------------------------------

ifneq ($(filter $(MAKECMDGOALS:/=),$(SUBDIRS)),)
$(MAKECMDGOALS): deep_build
	$(PRINT_COMMAND)	cd $@ && make
endif


#------------------------------------------------------------------------------
# Dependencies generation
#------------------------------------------------------------------------------

ifdef TARGET

DEPENDENCIES=$(SOURCES:%=$(OBJDIR)/%$(OBJ_EXT).d)
OBJDIR_DEPS=$(OBJDIR)/%.deps/.mkdir

ifeq (3.80,$(firstword $(sort $(MAKE_VERSION) 3.80)))
OBJ_DEPS=$(OBJDIR_DEPS) $(MAKEFILE_DEPS) | hello prebuild
else
OBJ_DEPS=$(OBJDIR_DEPS) $(MAKEFILE_DEPS)  hello prebuild
endif

ifndef DEPFLAGS
$(OBJDIR)/%.c$(OBJ_EXT).d:		%.c		$(OBJ_DEPS)
	$(PRINT_DEPEND) ( $(CC_DEPEND)
$(OBJDIR)/%.cpp$(OBJ_EXT).d:	%.cpp	$(OBJ_DEPS)
	$(PRINT_DEPEND) ( $(CXX_DEPEND)
$(OBJDIR)/%.s$(OBJ_EXT).d: 		%.s		$(OBJ_DEPS)
	$(PRINT_DEPEND) ( $(AS_DEPEND)
else
$(OBJDIR)/%$(OBJ_EXT).d: $(OBJDIR)/%$(OBJ_EXT)
endif


#------------------------------------------------------------------------------
#  Inference rules
#------------------------------------------------------------------------------


$(OBJDIR)/%.c$(OBJ_EXT): %.c 			$(OBJ_DEPS)
	$(PRINT_COMPILE) $(MAKE_CC)
$(OBJDIR)/%.cpp$(OBJ_EXT): %.cpp 		$(OBJ_DEPS)
	$(PRINT_COMPILE) $(MAKE_CXX)
$(OBJDIR)/%.s$(OBJ_EXT): %.s 			$(OBJ_DEPS)
	$(PRINT_COMPILE) $(MAKE_AS)

$(OBJROOT_LIB): $(LINK_INPUTS)			 		$(MAKEFILE_DEPS)
	$(PRINT_BUILD) $(MAKE_LIB)
$(OBJROOT_DLL): $(LINK_INPUTS)					$(MAKEFILE_DEPS)
	$(PRINT_BUILD) $(MAKE_DLL)
$(OBJROOT_EXE): $(LINK_INPUTS)					$(MAKEFILE_DEPS)
	$(PRINT_BUILD) $(MAKE_EXE)

endif

# Only build the leaf projects in parallel,
# since we don't have proper dependency between independent
# libraries and we may otherwise end up building the same
# library multiple times "in parallel" (wasting energy)
ifdef SUBDIRS
$(NOT_PARALLEL):
endif

# Include dependencies from current directory
# We only build when the target is set to avoid dependencies on 'clean'
ifeq ($(MAKECMDGOALS),build)
-include $(DEPENDENCIES)
endif


#------------------------------------------------------------------------------
#   Configuration rules
#------------------------------------------------------------------------------

NORM_CONFIG=$(subst <,.lt.,$(subst >,.gt.,$(subst /,.sl.,$(CONFIG))))
ORIG_TARGET=$(subst .lt.,<,$(subst .gt.,>,$(subst .sl.,/,$*)))

config.h: $(NORM_CONFIG:%=$(OBJDIR)/HAVE_%)
	$(PRINT_GENERATE) cat $^ > $@

# C standard headers, e.g. HAVE_<stdio.h>
$(OBJDIR)/HAVE_.lt.%.h.gt.: $(OBJDIR)/CONFIG_HAVE_%.c
	$(PRINT_CONFIG) $(CC_CONFIG)
$(OBJDIR)/CONFIG_HAVE_%.c: $(OBJDIR)/.mkdir
	$(PRINT_GENERATE) echo '#include' "<$(ORIG_TARGET).h>" > "$@"; echo 'int main() { return 0; }' >> "$@"
.PRECIOUS: $(OBJDIR)/CONFIG_HAVE_%.c

# C++ Standard headers, e.g. HAVE_<iostream>
$(OBJDIR)/HAVE_.lt.%.gt.: $(OBJDIR)/CONFIG_HAVE_%.cpp
	$(PRINT_CONFIG) $(CXX_CONFIG)
$(OBJDIR)/CONFIG_HAVE_%.cpp: $(OBJDIR)/.mkdir
	$(PRINT_GENERATE) echo '#include' "<$(ORIG_TARGET)>" > "$@"; echo 'int main() { return 0; }' >> "$@"
.PRECIOUS: $(OBJDIR)/CONFIG_HAVE_%.cpp

# Library
$(OBJDIR)/HAVE_lib%: $(OBJDIR)/CONFIG_LIB%.c
	$(PRINT_LIBCONFIG) $(LIB_CONFIG)
$(OBJDIR)/CONFIG_LIB%.c: $(OBJDIR)/.mkdir
	$(PRINT_GENERATE) echo 'int main() { return 0; }' > "$@"
.PRECIOUS: $(OBJDIR)/CONFIG_LIB%.c

# Check if a function is present
$(OBJDIR)/HAVE_%: $(OBJDIR)/CONFIG_CHECK_%.c
	$(PRINT_CONFIG)	$(FN_CONFIG)
$(OBJDIR)/CONFIG_CHECK_%.c: $(BUILD)config/check_%.c $(OBJDIR)/.mkdir
	$(PRINT_COPY) cp $< $@
.PRECIOUS: $(OBJDIR)/CONFIG_CHECK_%.c


#------------------------------------------------------------------------------
#  Makefile optimization tricks
#------------------------------------------------------------------------------

# Disable all built-in rules for performance
.SUFFIXES:

# Build with a single shell for all commands
.ONESHELL:
