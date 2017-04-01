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
CFLAGS+=    $(CPPFLAGS) $(CFLAGS_$(BUILDENV))   $(CFLAGS_$(TARGET))         $(CFLAGS_EXTRA) $(C99FLAGS_EXTRA)
CXXFLAGS+=  $(CPPFLAGS) $(CXXFLAGS_$(BUILDENV)) $(CXXFLAGS_$(TARGET))       $(CFLAGS_EXTRA) $(CXXFLAGS_EXTRA)
LDFLAGS+=               $(LDFLAGS_$(BUILDENV))  $(LDFLAGS_$(TARGET))        $(CFLAGS_EXTRA) $(LDFLAGS_EXTRA)


# Get BUILDOBJ from the BUILD_OBJECTS environment variable if set
BUILDOBJ=	$(BUILD_OBJECTS)

ifndef DIR
# The cd ./ in FULLDIR is for a corner case where . is a symbolic link
# At least with bash (not sure with other shells), pwd returns me
# the symbolic link path (as for BASEDIR), rather than the physical path

# So this is necessary for the substitution to happen correctly. Ugh!
BASEDIR:=       $(shell cd ./$(BUILD)/..; pwd)
FULLDIR:=       $(shell cd ./; pwd)
DIR:=           $(subst $(BASEDIR),,$(FULLDIR))
PRETTY_DIR:=    $(subst $(BASEDIR),[top],$(FULLDIR))
BASENAME_DIR:=  $(shell basename $(FULLDIR))
BUILD_DATE:=    $(shell /bin/date '+%Y%m%d-%H%M%S')
OBJROOT:=       $(BUILDOBJ)/$(BUILDENV)/$(TARGET)$(BASE_EXTRA_DEPTH)
BUILD_LOG:=     $(BUILD_LOGS)build-$(BUILDENV)-$(TARGET)-$(BUILD_DATE).log
endif

# Configuration variables
OBJDIR:=        $(OBJROOT)$(DIR)
OBJECTS:=       $(SOURCES:%=$(OBJDIR)/%$(OBJ_EXT))
PRODUCTS_EXE:=  $(patsubst %.exe,%$(EXE_EXT),$(filter %.exe,$(PRODUCTS)))
PRODUCTS_LIB:=  $(patsubst %.lib,%$(LIB_EXT),$(filter %.lib,$(PRODUCTS)))
PRODUCTS_DLL:=  $(patsubst %.dll,%$(DLL_EXT),$(filter %.dll,$(PRODUCTS)))
PRODUCTS_OTHER:=$(filter-out %.exe %.lib %.dll %$(EXE_EXT) %$(LIB_EXT) %$(DLL_EXT), $(PRODUCTS))
OBJROOT_EXE:=   $(PRODUCTS_EXE:%=$(OBJROOT)/%)
OBJROOT_LIB:=   $(PRODUCTS_LIB:%=$(OBJROOT)/%)
OBJROOT_DLL:=   $(PRODUCTS_DLL:%=$(OBJROOT)/%)
OBJROOT_OTHER:= $(PRODUCTS_OTHER:%=$(OBJROOT)/%)
OBJPRODUCTS:=   $(OBJROOT_EXE) $(OBJROOT_LIB) $(OBJROOT_DLL) $(OBJROOT_OTHER)

# Check a common mistake with PRODUCTS= not being set or set without extension
# Even on Linux / Unix, the PRODUCTS variable must end in .exe for executables,
# in .lib for static libraries, and in .dll for dynamic libraries.
# This is to help executable build rules be more robust and not catch
# unknown extensions by mistake. The extension is replaced with the
# correct platform extension, i.e. .a for static libraries on Linux
ifeq ($(PRODUCTS_EXE)$(PRODUCTS_LIB)$(PRODUCTS_DLL),)
$(error Error: Variable PRODUCTS must end in .exe, .lib or .dll)
endif

LIBNAMES:=      $(notdir $(LIBRARIES))
OBJLIBRARIES:=  $(LIBNAMES:%=$(OBJROOT)/%$(LIB_EXT))
LINK_INPUTS:=   $(OBJECTS) $(LINK_LIBS) $(OBJLIBRARIES)
ifneq ($(words $(LINK_INPUTS)),0)
LINK_WINPUTS=   $(patsubst %,"%", $(shell cygpath -aw $(LINK_INPUTS)))
endif
PRINT_DIR=              --no-print-directory
RECURSE_BUILDENV=$(BUILDENV)
RECURSE_CMD=    $(MAKE) $(PRINT_DIR) TARGET=$(TARGET) BUILDENV=$(RECURSE_BUILDENV) $(RECURSE) COLORIZE=
MAKEFILE_DEPS:= Makefile                             \
                $(BUILD)rules.mk                     \
                $(BUILD)config.mk                    \
                $(BUILD)config.$(BUILDENV).mk
NOT_PARALLEL?=  .NOTPARALLEL
BUILD_LOW?=     0
BUILD_HIGH?=    100
BUILD_INDEX:=   1
BUILD_COUNT:=   $(words $(SOURCES))
GIT_REVISION:=  $(shell git rev-parse --short HEAD 2> /dev/null || echo "unknown")
PROFILE_OUTPUT:=$(subst $(EXE_EXT),,$(OBJROOT_EXE))_prof_$(GIT_REVISION).vsp

#------------------------------------------------------------------------------
#   User targets
#------------------------------------------------------------------------------

all: $(TARGET)

debug opt release profile: logs.mkdir
	$(PRINT_COMMAND) $(TIME) $(MAKE) TARGET=$@ RECURSE=build LOG_COMMANDS= build $(LOG_COMMANDS)

# Testing
test tests check: $(TARGET)
	$(PRINT_COMMAND) $(MAKE) RECURSE=test $(TESTS:%=%.runtest) LOG_COMMANDS= $(LOG_COMMANDS)

# Clean builds
startup restart rebuild: clean all

# Installation
install: hello.install                          \
        $(OBJROOT_EXE:%=%.install_exe)          \
        $(OBJROOT_LIB:%=%.install_lib)          \
        $(OBJROOT_DLL:%=%.install_dll)          \
        $(EXE_INSTALL:%=%.install_exe)          \
        $(LIB_INSTALL:%=%.install_lib)          \
        $(DLL_INSTALL:%=%.install_dll)

clean: hello.clean
	-$(PRINT_COMMAND) rm -f $(GARBAGE) $(TOCLEAN) $(OBJECTS) $(DEPENDENCIES) $(OBJPRODUCTS)

distclean: nuke clean
nuke:
	-$(PRINT_COMMAND) rm -rf $(BUILDOBJ) $(BUILD_LOGS)build-*.log


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

build: hello libraries recurse prebuild objects product postbuild goodbye

hello:
	@$(INFO) "[BEGIN]" $(TARGET) $(BUILDENV) in $(PRETTY_DIR)
goodbye:
	@$(INFO) "[END]" $(TARGET) $(BUILDENV) in $(PRETTY_DIR)

hello.install:
	@$(INFO) "[INSTALL]"	$(TARGET) $(BUILDENV) in $(PRETTY_DIR)
hello.clean:
	@$(INFO) "[CLEAN]" $(TARGET) $(BUILDENV) in $(PRETTY_DIR)

libraries: $(OBJLIBRARIES)
product:$(OBJPRODUCTS)
objects:$(OBJDIR:%=%/.mkdir) $(OBJECTS)

# "Hooks" for pre and post build steps
prebuild:
postbuild:

# Run the test (in the object directory)
product.runtest: product .ALWAYS
	$(PRINT_TEST) $(OBJROOT_EXE) $(PRODUCTS_OPTS)

# Run a test from a C or C++ file to link against current library
%.c.runtest: $(OBJROOT_LIB) .ALWAYS
	$(PRINT_BUILD) $(MAKE) SOURCES=$*.c LINK_LIBS=$(OBJROOT_LIB) PRODUCTS=$*.exe $(TARGET)
	$(PRINT_TEST) $(TEST_CMD_$*) $(OBJROOT)/$* $(TEST_ARGS_$*)
%.cpp.runtest: $(OBJROOT_LIB) .ALWAYS
	$(PRINT_BUILD) $(MAKE) SOURCES=$*.cpp LINK_LIBS=$(OBJROOT_LIB) PRODUCTS=$*.exe $(TARGET)
	$(PRINT_TEST) $(TEST_CMD_$*) $(OBJROOT)/$* $(TEST_ARGS_$*)

# Installing the product: always need to build it first
%.install_exe: $(PREFIX_BIN).mkdir
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_BIN)
%.install_lib: $(PREFIX_LIB).mkdir
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_LIB)
%.install_dll: $(PREFIX_DLL).mkdir
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_DLL)

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
	cd ./$(BUILD); $(MAKE) $*

# Verbose build (show all commands as executed)
v-% verbose-%:
	$(PRINT_COMMAND) $(MAKE) $* PRINT_COMPILE= PRINT_BUILD= PRINT_DEPEND= PRINT_DEPALL= PRINT_COMMAND= PRINT_TEST=

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
ifeq ($(RECURSE),clean)
%.recurse:          | hello
	+$(PRINT_COMMAND) cd $* && $(RECURSE_CMD)
else
%.recurse:          | hello prebuild
	+$(PRINT_COMMAND) cd $* && $(RECURSE_CMD)
endif

# If LIBRARIES=foo/bar, go to directory foo/bar, which should build bar.a
$(OBJROOT)/%$(LIB_EXT): $(DEEP_BUILD)
	+$(PRINT_COMMAND) cd $(filter %$*, $(LIBRARIES) $(SUBDIRS)) && $(RECURSE_CMD)
%/.runtest:
	+$(PRINT_TEST) cd $* && $(MAKE) TARGET=$(TARGET) test
deep_build:

recursive:
ifdef SUBDIRS
	$(PRINT_COMMAND) $(MAKE) recurse RECURSE=$(MAKECMDGOALS) HELLO=$(HELLO_$(MAKECMDGOALS))
endif


#------------------------------------------------------------------------------
#  Progress printout
#------------------------------------------------------------------------------

INCR_INDEX=	$(eval BUILD_INDEX:=$(shell echo $$(($(BUILD_INDEX)+1))))
PRINT_COUNT=	$(shell printf "%3d/%d" $(BUILD_INDEX) $(BUILD_COUNT))$(INCR_INDEX)
PRINT_PCT=	$(shell printf "%3d%%" $$(( ($(BUILD_HIGH) - $(BUILD_LOW)) * $(BUILD_INDEX) / $(BUILD_COUNT) + $(BUILD_LOW))))$(INCR_INDEX)

# Printing out various kinds of statements
PRINT_COMMAND= 	@
PRINT_COMPILE=	$(PRINT_COMMAND) $(INFO) "[COMPILE$(PRINT_COUNT)] " $<;
PRINT_BUILD= 	$(PRINT_COMMAND) $(INFO) "[BUILD]" $(shell basename $@);
PRINT_GENERATE= $(PRINT_COMMAND) $(INFO) "[GENERATE]" $(shell basename $@);
PRINT_INSTALL=  $(PRINT_COMMAND) $(INFO) "[INSTALL] " $(*F) in $(<D);
PRINT_COPY=     $(PRINT_COMMAND) $(INFO) "[COPY]" $(*F) into $(@D) ;
PRINT_DEPEND= 	$(PRINT_COMMAND) $(INFO) "[DEPEND] " $< ;
PRINT_TEST= 	$(PRINT_COMMAND) $(INFO) "[TEST] " $(@:.runtest=) ;

logs.mkdir: $(dir $(BUILD_LOG))/.mkdir $(dir $(BUILD_SAVED_LOG))/.mkdir
%/.mkdir:
	$(PRINT_COMMAND) $(MAKE_OBJDIR)
.PRECIOUS: %/.mkdir


#------------------------------------------------------------------------------
#  Special for Fabien: make 'Directory'
#------------------------------------------------------------------------------

ifneq ($(filter $(MAKECMDGOALS:/=),$(SUBDIRS)),)
$(MAKECMDGOALS): deep_build
1	$(PRINT_COMMAND)	cd $@ && make
endif


#------------------------------------------------------------------------------
# Dependencies generation
#------------------------------------------------------------------------------

ifdef TARGET

DEPENDENCIES=$(SOURCES:%=$(OBJDIR)/%$(OBJ_EXT).d)
OBJDIR_DEPS=$(OBJDIR)/%.deps/.mkdir

OBJ_DEPS=$(OBJDIR_DEPS) $(MAKEFILE_DEPS) | hello prebuild

# The following is a trick to avoid errors if a header file appears in a
# generated dependency but no longer in the source code.
# The trick is quite ugly, but fortunately documented here:
# http://scottmcpeak.com/autodepend/autodepend.html
POSTPROCESS_DEPENDENCY=                             \
    ( sed -e 's/.*://' -e 's/\\$$//' < $@ |         \
      fmt -1 |                                      \
      sed -e 's/^ *//' -e 's/$$/:/' >> $@ )

$(OBJDIR)/%.c$(OBJ_EXT).d:		%.c		$(OBJ_DEPS)
	$(PRINT_DEPEND) ( $(CC_DEPEND)  && $(POSTPROCESS_DEPENDENCY) )
$(OBJDIR)/%.cpp$(OBJ_EXT).d:	%.cpp	$(OBJ_DEPS)
	$(PRINT_DEPEND) ( $(CXX_DEPEND) && $(POSTPROCESS_DEPENDENCY) )
$(OBJDIR)/%.s$(OBJ_EXT).d: 		%.s		$(OBJ_DEPS)
	$(PRINT_DEPEND) ( $(AS_DEPEND)  && $(POSTPROCESS_DEPENDENCY) )


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
#  Makefile optimization tricks
#------------------------------------------------------------------------------

# Disable all built-in rules for performance
.SUFFIXES:

# Build with a single shell for all commands
.ONESHELL:
