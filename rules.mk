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
LDFLAGS+=               $(LDFLAGS_PKGCONFIG) $(LDFLAGS_$(BUILDENV))  $(LDFLAGS_$(TARGET))        $(CFLAGS_EXTRA) $(LDFLAGS_EXTRA)

ifndef DIR
FULLDIR:=       $(abspath .)/
DIR:=           $(subst $(TOP),,$(FULLDIR))
PRETTY_DIR:=    $(subst $(TOP),[top],$(FULLDIR)$(VARIANT:%=[%]))
BUILD_DATE:=    $(shell /bin/date '+%Y%m%d-%H%M%S')
OBJROOT:=       $(OBJFILES)$(BUILDENV)/$(CROSS_COMPILE:%=%-)$(TARGET)$(BASE_EXTRA_DEPTH)
BUILD_LOG:=     $(LOGS)build-$(BUILDENV)-$(CROSS_COMPILE:%=%-)$(TARGET)-$(BUILD_DATE).log
endif

# Configuration variables
OBJDIR:=	$(OBJROOT)/$(DIR)
OBJECTS=	$(SOURCES:%=$(OBJDIR)%$(OBJ_EXT))
PRODUCTS_EXE=	$(patsubst %.exe,%$(EXE_EXT),$(filter %.exe,$(PRODUCTS)))
PRODUCTS_LIB=	$(patsubst %.lib,%$(LIB_EXT),$(filter %.lib,$(PRODUCTS)))
PRODUCTS_DLL=	$(patsubst %.dll,%$(DLL_EXT),$(filter %.dll,$(PRODUCTS)))
PRODUCTS_OTHER= $(filter-out %.exe %.lib %.dll %$(EXE_EXT) %$(LIB_EXT) %$(DLL_EXT), $(PRODUCTS))
PRODUCTS_LIBS=	$(filter %.lib %.dll,$(PRODUCTS))
OUTPUT_EXE=	$(PRODUCTS_EXE:%=$(OUTPUT)$(EXE_PFX)%)
OUTPUT_LIB=	$(PRODUCTS_LIB:%=$(OUTPUT)$(LIB_PFX)%)
OUTPUT_DLL=	$(PRODUCTS_DLL:%=$(OUTPUT)$(DLL_PFX)%)
OUTPUT_OTHER=	$(PRODUCTS_OTHER:%=$(OUTPUT)%)
OBJPRODUCTS=	$(OUTPUT_EXE) $(OUTPUT_LIB) $(OUTPUT_DLL) $(OUTPUT_OTHER)

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

ALL_LIBS=	$(LIBRARIES) $(LINK_LIBS)
LIBNAMES=       $(filter %.lib, $(notdir $(ALL_LIBS)))
DLLNAMES=       $(filter %.dll, $(notdir $(ALL_LIBS)))
OBJLIBS= 	$(LIBNAMES:%.lib=$(OUTPUT)$(LIB_PFX)%$(LIB_EXT))
OBJDLLS=        $(DLLNAMES:%.dll=$(OUTPUT)$(DLL_PFX)%$(DLL_EXT))
LINK_PATHS:=	$(OUTPUT:%=$(LINK_DIR_OPT)%)
LINK_XLIBS=	$(LIBNAMES:%.lib=$(LINK_LIB_OPT)%)	\
		$(DLLNAMES:%.dll=$(LINK_DLL_OPT)%)
LINK_INPUTS=    $(OBJECTS) $(OBJLIBS) $(OBJDLLS)
LINK_CMDLINE= 	$(OBJECTS) $(LINK_PATHS) $(LINK_XLIBS)
ifneq ($(words $(LINK_INPUTS)),0)
LINK_WINPUTS=   $(patsubst %,"%", $(shell cygpath -aw $(LINK_INPUTS)))
endif
PRINT_DIR=              --no-print-directory
RECURSE_BUILDENV=$(BUILDENV)
RECURSE_CMD=    $(MAKE) $(PRINT_DIR) TARGET=$(TARGET) BUILDENV=$(RECURSE_BUILDENV) BUILD="$(abspath $(BUILD))/" TOP="$(abspath $(TOP))/" $(RECURSE) COLOR_FILTER=
MAKEFILE_DEPS:= $(MAKEFILE_LIST)
NOT_PARALLEL?=  .NOTPARALLEL
BUILD_LOW?=     0
BUILD_HIGH?=    100
BUILD_INDEX:=   1
BUILD_COUNT:=   $(words $(SOURCES))
GIT_REVISION:=  $(shell git rev-parse --short HEAD 2> /dev/null || echo "unknown")
PROFILE_OUTPUT:=$(subst $(EXE_EXT),,$(OUTPUT_EXE))_prof_$(GIT_REVISION).vsp

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
install: install-all

clean: $(SUBDIRS:%=%.clean) $(VARIANTS:%=%.variant-clean)
	-$(PRINT_CLEAN) rm -f $(TO_CLEAN) $(OBJECTS) $(DEPENDENCIES) $(OBJPRODUCTS) $(LINK_INPUTS) config.h
%.clean:
	$(PRINT_COMMAND) cd $* && $(RECURSE_CMD) clean $(COLORIZE)
%.variant-clean:
	$(PRINT_COMMAND) $(RECURSE_CMD) VARIANT=$* VARIANTS= clean $(COLORIZE)

distclean nuke: clean
	-$(PRINT_CLEAN) rm -rf $(OBJPRODUCTS) $(OBJFILES) $(LOGS)


help:
	@$(ECHO) "Available targets:"
	@$(ECHO) "  make                : Build default target (TARGET=$(TARGET))"
	@$(ECHO) "  make all            : Same"
	@$(ECHO) "  make debug          : Debug build"
	@$(ECHO) "  make opt            : Optimized build with debug info"
	@$(ECHO) "  make release        : Release build without debug info"
	@$(ECHO) "  make profile        : Profile build"
	@$(ECHO) "  make clean          : Clean build results (only BUILDENV=$(BUILDENV))"
	@$(ECHO) "  make rebuild        : Clean before building"
	@$(ECHO) "  make nuke           : Clean build directory"
	@$(ECHO) "  make test           : Run sanity tests (run only tests)"
	@$(ECHO) "  make check          : Build product, then run tests"
	@$(ECHO) "  make benchmark      : Build product, then run benchmarks"
	@$(ECHO) "  make install        : Build and install result"
	@$(ECHO) "  make clang-format   : Reformat sources using clang-format"
	@$(ECHO) "  make v-[target]     : Build target in 'verbose' mode"
	@$(ECHO) "  make d-[target]     : Deep-checking of library dependencies"
	@$(ECHO) "  make top-[target]   : Rebuild from top-level directory"


#------------------------------------------------------------------------------
#   Internal targets
#------------------------------------------------------------------------------

build: hello config libraries prebuild recurse objects product postbuild goodbye

hello:
	@$(INFO) "[BEGIN]" $(TARGET) $(BUILDENV) in "$(PRETTY_DIR)"
goodbye:
	@$(INFO) "[END]" $(TARGET) $(BUILDENV) in "$(PRETTY_DIR)"

# Sequencing build steps and build step hooks
config: hello
config: $(VARIANTS:%=%.variant)
ifeq ($(VARIANTS),)
config: $(CONFIG:%=config.h)
config: $(NORM_CONFIG:%=$(OBJDIR)CFG_HAVE_%.mk)
endif
libraries: config
libraries: $(OBJLIBS) $(OBJDLLS)
prebuild: config
objects: prebuild
objects:$(OBJDIR:%=%.mkdir) $(OBJECTS)
product:$(OBJPRODUCTS)
postbuild: product $(DO_INSTALL)
do_install: $(TO_INSTALL)
goodbye: postbuild

# Run the test (in the object directory)
product.test: product .ALWAYS
	$(PRINT_TEST) $(TEST_ENV) $(OUTPUT_EXE) $(PRODUCTS_OPTS)

# Run a test from a C or C++ file to link against current library
%.c.test: $(OUTPUT_LIB) .ALWAYS
	$(PRINT_BUILD) $(MAKE) SOURCES=$*.c LINK_LIBS="$(PRODUCTS_LIBS)" PRODUCTS=$*.exe $(TARGET)
	$(PRINT_TEST) $(TEST_ENV) $(TEST_CMD_$*) $(OUTPUT)$*$(EXE_EXT) $(TEST_ARGS_$*)
%.cpp.test: $(OUTPUT_LIB) .ALWAYS
	$(PRINT_BUILD) $(MAKE) SOURCES=$*.cpp LINK_LIBS="$(PRODUCTS_LIBS)" PRODUCTS=$*.exe $(TARGET)
	$(PRINT_TEST) $(TEST_ENV) $(TEST_CMD_$*) $(OUTPUT)$*$(EXE_EXT) $(TEST_ARGS_$*)

# Installing the product: always need to build it first
%.install_exe: $(PREFIX_BIN).mkdir-only product
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_BIN)
%.install_lib: $(PREFIX_LIB).mkdir-only product
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_LIB)
%.install_dll: $(PREFIX_DLL).mkdir-only product
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_DLL)
%.install_hdr: $(PREFIX_HDR).mkdir-only
	$(PRINT_INSTALL) $(INSTALL) $* $(PREFIX_HDR)

# Benchmarking (always done with profile target)
benchmark:	$(BENCHMARK:%=%.benchmark) $(BENCHMARKS:%=%.benchmark)
product.benchmark: product .ALWAYS
	$(PRINT_TEST) gprof

.PHONY: hello goodbye
.PHONY: all debug opt release profile build test install
.PHONY: config libraries recurse prebuild objects product postbuild
.PHONY: .ALWAYS


#------------------------------------------------------------------------------
#  Build target modifiers
#------------------------------------------------------------------------------

# Make from the top-level directory (useful from child directories)
top-%:
	cd $(TOP); $(MAKE) $*

# Verbose build (show all commands as executed)
v-% verbose-%:
	$(PRINT_COMMAND) $(MAKE) $* V=1

# Timed build (show the time for each step)
t-% time-%:
	$(PRINT_COMMAND) time $(MAKE) $*

# Timed build (show the time for each step)
notime-%:
	$(PRINT_COMMAND) $(MAKE) TIME= $*

# Installation build
install-%:
	$(PRINT_COMMAND) $(MAKE) DO_INSTALL=do_install

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
$(OUTPUT)$(LIB_PFX)%$(LIB_EXT): $(DEEP_BUILD)
	+$(PRINT_COMMAND) cd $(firstword $(dir $(filter %$*, $(LIBRARIES:.lib=) $(SUBDIRS))) .) && $(RECURSE_CMD)
$(OUTPUT)$(DLL_PFX)%$(DLL_EXT): $(DEEP_BUILD)
	+$(PRINT_COMMAND) cd $(firstword $(dir $(filter %$*, $(LIBRARIES:.dll=) $(SUBDIRS))) .) && $(RECURSE_CMD)
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
PRINT_INSTALL=  $(PRINT_COMMAND) $(INFO) "[INSTALL] " $(*F) in $(<D) $(COLORIZE);
PRINT_CLEAN=    $(PRINT_COMMAND) $(INFO) "[CLEAN] " $@ $(PRETTY_DIR) $(COLORIZE);
PRINT_COPY=     $(PRINT_COMMAND) $(INFO) "[COPY]" $< '=>' $@ ;
PRINT_DEPEND= 	$(PRINT_COMMAND) $(INFO) "[DEPEND] " $< ;
PRINT_TEST= 	$(PRINT_COMMAND) $(INFO) "[TEST]" $(@:.test=) ;
PRINT_CONFIG= 	$(PRINT_COMMAND) $(INFO) "[CONFIG]" "$(ORIG_TARGET)" ;
PRINT_PKGCONFIG=$(PRINT_COMMAND) $(INFO) "[PKGCONFIG]" "$*" ;
PRINT_LIBCONFIG=$(PRINT_COMMAND) $(INFO) "[LIBCONFIG]" "lib$*" ;
PRINT_REFORMAT= $(PRINT_COMMAND) $(INFO) "[REFORMAT]" "$*" $(COLORIZE);
endif

logs.mkdir: $(LOGS).mkdir $(dir $(LAST_LOG))/.mkdir
%/.mkdir-only:
	$(PRINT_COMMAND) $(MAKE_DIR)
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


ifdef RECURSE
#------------------------------------------------------------------------------
# Dependencies generation
#------------------------------------------------------------------------------


DEPENDENCIES=$(SOURCES:%=$(OBJDIR)%$(OBJ_EXT).d)
OBJDIR_DEPS=$(OBJDIR)%.deps/.mkdir

ifeq (3.80,$(firstword $(sort $(MAKE_VERSION) 3.80)))
OBJ_DEPS=$(OBJDIR_DEPS) $(MAKEFILE_DEPS) | prebuild
else
OBJ_DEPS=$(OBJDIR_DEPS) $(MAKEFILE_DEPS)  prebuild
endif

ifndef DEPFLAGS
$(OBJDIR)%.c$(OBJ_EXT).d:		%.c			$(OBJ_DEPS)
	$(PRINT_DEPEND) ( $(CC_DEPEND)
$(OBJDIR)%.cpp$(OBJ_EXT).d:		%.cpp			$(OBJ_DEPS)
	$(PRINT_DEPEND) ( $(CXX_DEPEND)
$(OBJDIR)%.s$(OBJ_EXT).d: 		%.s			$(OBJ_DEPS)
	$(PRINT_DEPEND) ( $(AS_DEPEND)
else
$(OBJDIR)%$(OBJ_EXT).d: $(OBJDIR)%$(OBJ_EXT)
endif


#------------------------------------------------------------------------------
#  Inference rules
#------------------------------------------------------------------------------

$(OBJDIR)%.c$(OBJ_EXT): %.c 					$(OBJ_DEPS)
	$(PRINT_COMPILE) $(MAKE_CC)
$(OBJDIR)%.cpp$(OBJ_EXT): %.cpp 				$(OBJ_DEPS)
	$(PRINT_COMPILE) $(MAKE_CXX)
$(OBJDIR)%.s$(OBJ_EXT): %.s 					$(OBJ_DEPS)
	$(PRINT_COMPILE) $(MAKE_AS)

.SECONDEXPANSION:
$(OUTPUT_LIB): $(LINK_INPUTS) $$(LINK_INPUTS)	 		$(MAKEFILE_DEPS)
	$(PRINT_BUILD) $(MAKE_LIB)
$(OUTPUT_DLL): $(LINK_INPUTS) $$(LINK_INPUTS)			$(MAKEFILE_DEPS)
	$(PRINT_BUILD) $(MAKE_DLL)
$(OUTPUT_EXE): $(LINK_INPUTS) $$(LINK_INPUTS)			$(MAKEFILE_DEPS)
	$(PRINT_BUILD) $(MAKE_EXE)

# Include dependencies from current directory
# We only build when the target is set to avoid dependencies on 'clean'
ifeq ($(MAKECMDGOALS),build)
-include $(DEPENDENCIES)
endif


#------------------------------------------------------------------------------
#   Package configuration
#------------------------------------------------------------------------------

# Package configuration file
PKG_CFLAGS= 	$(PKGCONFIGS:%=$(OBJDIR)%.pkg-config.cflags)
PKG_LDFLAGS=	$(PKGCONFIGS:%=$(OBJDIR)%.pkg-config.ldflags)
CONFIG_LIBS=
PKG_LIBS=	$(patsubst %,$(OBJDIR)%.cfg.ldflags,$(filter lib%,$(CONFIG)))

PKG_DEPS=	$(MAKEFILE_DEPS) $(OBJDIR).mkdir

$(OBJDIR)pkg-config.mk: $(PKG_CFLAGS) $(PKG_LDFLAGS) $(PKG_LIBS)
	$(PRINT_COMMAND) (echo CFLAGS_PKGCONFIG=`$(CAT) $(PKG_CFLAGS)`; echo LDFLAGS_PKGCONFIG=`$(CAT) $(PKG_LDFLAGS) $(PKG_LIBS)`) > $@
-include $(PKGCONFIGS:%=$(OBJDIR)pkg-config.mk)
-include $(PKG_LIBS:%=$(OBJDIR)pkg-config.mk)

$(OBJDIR)%?.pkg-config.cflags: 					$(PKG_DEPS)
	$(PRINT_PKGCONFIG)  (pkg-config --cflags $* --silence-errors || true) > $@
$(OBJDIR)%?.pkg-config.ldflags: 				$(PKG_DEPS)
	$(PRINT_COMMAND)  (pkg-config --libs $* --silence-errors || true) > $@

$(OBJDIR)%.pkg-config.cflags: 					$(PKG_DEPS)
	$(PRINT_PKGCONFIG)  pkg-config --cflags $* > $@
$(OBJDIR)%.pkg-config.ldflags: 					$(PKG_DEPS)
	$(PRINT_COMMAND)  pkg-config --libs $* > $@
$(OBJDIR)lib%.cfg.ldflags: $(OBJDIR)CFG_HAVE_lib%.h		$(PKG_DEPS)
	$(PRINT_COMMAND)  (grep -q 'define ' $< && echo $(LINK_CFG_OPT)$* || true) > $@


#------------------------------------------------------------------------------
#   Configuration rules
#------------------------------------------------------------------------------

NORM_CONFIG=$(subst <,.lt.,$(subst >,.gt.,$(subst /,.sl.,$(CONFIG))))
ORIG_TARGET=$(subst .lt.,<,$(subst .gt.,>,$(subst .sl.,/,$*)))
CONFIG_DEPS=	$(PKG_DEPS) 						\
		$(PKGCONFIGS:%=$(OBJDIR)pkg-config.mk)			\
		$(PKG_LIBS:%=$(OBJDIR)pkg-config.mk)

config.h: $(NORM_CONFIG:%=$(OBJDIR)CFG_HAVE_%.h)
	$(PRINT_GENERATE) cat $^ > $@

$(OBJDIR)CFG_HAVE_%.mk: $(OBJDIR)CFG_HAVE_%.h 			$(MAKEFILE_DEPS)
	$(PRINT_COMMAND) $(MAKE_CONFIG)
-include $(NORM_CONFIG:%=$(OBJDIR)CFG_HAVE_%.mk)

# C standard headers, e.g. HAVE_<stdio.h>
$(OBJDIR)CFG_HAVE_.lt.%.h.gt..h: $(OBJDIR)CFG-CH_HAVE_%.c	$(CONFIG_DEPS)
	$(PRINT_CONFIG) $(CC_CONFIG)
$(OBJDIR)CFG-CH_HAVE_%.c: $(OBJDIR).mkdir			$(CONFIG_DEPS)
	$(PRINT_COMMAND) (echo '#include' "<$(ORIG_TARGET).h>" && echo 'int main() { return 0; }') > "$@"
.PRECIOUS: $(OBJDIR)CFG-CH_HAVE_%.c

# C++ Standard headers, e.g. HAVE_<iostream>
$(OBJDIR)CFG_HAVE_.lt.%.gt..h: $(OBJDIR)CFG-C++H_HAVE_%.cpp	$(CONFIG_DEPS)
	$(PRINT_CONFIG) $(CXX_CONFIG)
$(OBJDIR)CFG-C++H_HAVE_%.cpp: $(OBJDIR).mkdir			$(CONFIG_DEPS)
	$(PRINT_COMMAND) (echo '#include' "<$(ORIG_TARGET)>" && echo 'int main() { return 0; }') > "$@"
.PRECIOUS: $(OBJDIR)CFG-C++H_HAVE_%.cpp

# Library
$(OBJDIR)CFG_HAVE_lib%.h: $(OBJDIR)CFG-LIB_HAVE_lib%.c		$(PKG_DEPS)
	$(PRINT_LIBCONFIG) $(LIB_CONFIG)
$(OBJDIR)CFG-LIB_HAVE_lib%.c: 					$(PKG_DEPS)
	$(PRINT_COMMAND) echo 'int main() { return 0; }' > "$@"
.PRECIOUS: $(OBJDIR)CFG-LIB_HAVE_lib%.c

# Check if a function is present
$(OBJDIR)CFG_HAVE_%.h: $(OBJDIR)CFG-FN_HAVE_%.c			$(CONFIG_DEPS)
	$(PRINT_CONFIG)	$(FN_CONFIG)
$(OBJDIR)CFG-FN_HAVE_%.c: $(BUILD)config/HAVE_%.c 		$(CONFIG_DEPS)
	$(PRINT_COMMAND) cp $< $@
$(OBJDIR)CFG-FN_HAVE_%.c: config/HAVE_%.c			$(CONFIG_DEPS)
	$(PRINT_COMMAND) cp $< $@
$(OBJDIR)CFG-FN_HAVE_%.c: $(BUILD)config/check_%.c 		$(CONFIG_DEPS)
	$(PRINT_COMMAND) cp $< $@
$(OBJDIR)CFG-FN_HAVE_%.c: config/check_%.c			$(CONFIG_DEPS)
	$(PRINT_COMMAND) cp $< $@
.PRECIOUS: $(OBJDIR)CFG-FN_HAVE_%.c

endif


#------------------------------------------------------------------------------
#  Clang format
#------------------------------------------------------------------------------

reformat clang-format:	$(CLANG_FORMAT_SOURCES:%=%.clang-format)
%.clang-format:
	$(PRINT_REFORMAT)	clang-format $* > $*.tmp && mv $*.tmp $*


#------------------------------------------------------------------------------
#  Makefile optimization tricks
#------------------------------------------------------------------------------

# Disable all built-in rules for performance
.SUFFIXES:

# Build with a single shell for all commands
.ONESHELL:

# Only build the leaf projects in parallel,
# since we don't have proper dependency between independent
# libraries and we may otherwise end up building the same
# library multiple times "in parallel" (wasting energy)
ifneq ($(SUBDIRS)$(VARIANTS),)
$(NOT_PARALLEL):
endif
