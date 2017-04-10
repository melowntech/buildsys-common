# run all targets sequentially
.NOTPARALLEL:

# this variable marks this file has been included
BUILDYS_COMMON_INCLUDED=1

# find out current directory
BUILDSYS_COMMON_ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# include debian stuff
include $(BUILDSYS_COMMON_ROOT)deb.mk
