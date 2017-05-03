#******************************************************************************
# Makefile<build>                                             'build' project 
#******************************************************************************
#
#  File Description:
#
#    A sample maefile for 'build'
#
#
#
#
#
#
#
#
#******************************************************************************
# (C) 2017 Christophe de Dinechin <christophe@dinechin.org>
#  This software is licensed under the GNU General Public License v3
#  See file COPYING for details.
#******************************************************************************

# Define the path to 'build' (can be a git submodule in your project)
BUILD=./

# Define the source code
SOURCES=hello.cpp

# Define the product of the build (.exe will be removed for Unix builds)
PRODUCTS=hello.exe

# Define configuration options
CONFIG=	HAVE_<stdio.h>		\
	HAVE_<unistd.h>		\
	HAVE_<nonexistent.h>	\
	HAVE_<sys/time.h>	\
	HAVE_<sys/improbable.h> \
	HAVE_<iostream>		\
	HAVE_clearenv		\
	HAVE_libm		\
	HAVE_liboony		\
	HAVE_sbrk

# Define what to test
TESTS=product count-characters

# Define what to benchmark
BENCHMARKS=product

# Include the makefile rules
include $(BUILD)rules.mk

count-characters.runtest:
	@echo Output has `$(OBJPRODUCTS) | wc -c` characters, should be 35

