# build
A simple makefile-based build system for C / C++ programs

## Features

Build is a simple build system destined to make it easy to build C or
C++ programs without having to write lengthy makefiles or going
through the complexity of tools such as `automake` or `cmake`. It is
well suited for relatively small programs, although it has been used
for at least one much larger program.

* Compact size (about 500 lines of active makefile code for a typical build)
* Fast, since short makefiles with few rules are quickly parsed
* Automatic generation of header-file dependencies
* Automatic logging of detailed build commands in log files
* Compact, colorized progress report
* Summary of errors and warnings at end of build
* Colorization of error and warning messages
* Rules to build various targets (optimized, debug, release, profile)
* Rule modifiers for common build options, e.g. `v-debug` for verbose debug
* Personal preferences easily defined with environment variables
* Built-in help (`make help`)
* Pure `make`, allowing you to use standard `Makefile` syntax and features
* Supports parallel builds
* Supports separate libraries with accelerated build


## Using build

To use `build`, you create a `Makefile`. A minimal makefile only needs
to specify the name of the `SOURCES`, the name of the build `PRODUCTS`,
and include the `rules.mk` file, which contains the makefile rules:

    BUILD=build/
    SOURCES=my-super-tool.cpp helper.c
    PRODUCTS=my-super-tool.exe
    include $(BUILD)rules.mk

That's all you need to get started. There is a small sample `Makefile`
in this distribution.

Note that the `BUILD` variable requires a trailing `/`. This is a
general convention in `build` for variables that denote directories
(Rationale: You can leave these variables empty for the current
directory).

For consistency across projects, it is recommended to leave `build`
in the `build` subdirectory. You can typically add `build` as a
submodule in your project using:

    git submodule add https://github.com/c3d/build.git

In order to get a summary of the available build targets, use `make help`.

## Building the products

If you simply type `make`, a default build is launched. This is what
you should see if you do that in the `build` directory itself:

    build> make
    [BEGIN]              opt macosx-clang in [top]/build
    [DEPEND]             hello.cpp
    [BEGIN]              opt macosx-clang in [top]/build
    [COMPILE  1/1]       hello.cpp
    [BUILD]              hello
    0 Errors, 0 Warnings in ./logs/build-macosx-clang-opt-20170325-144013.log

    real    0m3.263s
    user    0m0.456s
    sys     0m0.133s
    
The output of the build will be located by default in `build/objects`.
There are subdirectories corresponding to the build environment and
the build target, so the final product could be for instance under
`build/objects/macosx-clang/opt/hello`. This is explained below.

The log files will be located by default in `build/logs`, the latest
one being called `make.log`.

You can clean the build products with `make clean` and force a clean
build with `make rebuild`.


## Testing the products

Use `make test` to test the product. The simplest possible test is to
simply run the generated program. You can do this by adding a `TESTS`
variable to your `Makefile`:

    BUILD=build/
    SOURCES=hello.cpp
    PRODUCTS=hello.exe
    TESTS=product
    include $(BUILD)rules.mk

If you run `make test` (or `make check`) on the sample makefile found in the
distribution directory, you will run the `hello` program, after
building it if necessary:

     build> make test
     [BEGIN]              opt macosx-clang in [top]/build
     [COMPILE  1/1]       hello.cpp
     [BUILD]              hello
     [TEST]               product
     You successfully built using build
     Output has 35 characters, should be 35

As you can see in the sample `Makefile`, it is easy to add tests,
simply by adding a rule that ends in `.runtest`. In the sample file,
it is called `count-characters.runtest`.


## Building for debugging, release or profiling

The default build is an optimized build similar to what you would
achieve by running `make opt`. It is well optimized, but still retains
some debugging capabilities.

If you need more debugging capabilities, you can create a debug build
by using `make debug`. This disables most optimizations, making it
easier for the debugger to relate machine code to source code.

If you want to remove all debugging symbols, you can generate a
release build by using `make release`.

Finally, you can build for profiling using `make profile` and
benchmark the result using `make benchmark`. This is still only
partially tested and supported.

This list is likely to evolve over time, most notably with support for
Valgrind and other debug / analysis tools.


## Installing the product 

To install the product, use `make install`. This often requires
super-user privileges.

    build> make install
    [INSTALL]            opt macosx-clang in [top]/build
    [INSTALL]            hello in /usr/local/bin


## Build modifiers

Several built target modifiers can be used to modify the meaning of a
following target. For example, the `v-` prefix disables output
filtering, so that you can see the complete build commands:

     build> make v-debug
     [...]
     [BEGIN]              debug macosx-clang in [top]/build
     g++ -std=gnu++0x                             -DCONFIG_MACOSX -DDEBUG   -g -Wall -fno-inline           -c hello.cpp -o objects/macosx-clang/debug/build/hello.cpp.o
     g++ -o objects/macosx-clang/debug/hello ./objects/macosx-clang/debug/build/hello.cpp.o   -framework CoreFoundation -framework CoreServices  -g
     [END]                debug macosx-clang in [top]/build


Note that this is not normally necessary, since the build commands are
preserved automatically in the build log every time you use `make`.

The build targets can be used also as build modifiers. For example, if
you do `make clean`, you only clean `opt` objects since this is the
default target. If you want to clean debug objects, use `make debug-clean`.
Similarly, you can do a release install with `make release-install`.

(Note that you can make `debug` your default target, see below).



## Environment variables

Several environment variables control the behavior of `build`. The
variables that can be configured are found at the beginning of `config.mk`.
Some of the most useful include:

* `BUILDENV` specifies the build environment, for example
  `macosx-clang` when building on MacOSX with Clang. Parameters for
  this build environment are defined in `config.$(BUILDENV).mk`, for
  example `config.macosx-clang.mk`. If not set, heuristics defined in
  `config.auto.mk` are used to try and determine the correct
  `BUILDENV`.

* `TARGET` specifies the default build target, which can be `opt`,
  `debug`, `release` or `profile` at the moment. If you often build
  debug targets, you only need to `export BUILDENV=debug`, and
  the default `make` will become equivalent to `make debug`.

* `PREFIX` specifies the installation location. You can also specify
  the installation location for executables (`PREFIX_BIN`), libraries
  (`PREFIX_LIB`) or shared libraries (`PREFIX_DLL`).
  

## Hierarchical projects

Often, a project is made of several directories or libraries. In
`build`, this is supported with two makefile variables:

* `SUBDIRS` lists subdirectories of the top-level directory that
  must be built every time.
  
* `LIBRARIES` lists libraries, which can be subdirectories or not,
  which the products depends on.
  
Subdirectories are re-built everytime a top-level build is started,
whereas libraries are re-built only if they are missing. It is
possible to force a re-build of libraries using the `d-` or `deep-`
prefix for builds, for example `make deep-debug`.
