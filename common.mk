# run all targets sequentially
.NOTPARALLEL:

# this variable marks this file has been included
BUILDYS_COMMON_INCLUDED=1

# find the source root (i.e. pwd)
export BUILDSYS_SRC_ROOT := $(abspath .)

ifneq ($(BUILDSYS_SRC_ROOT)/,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))
$(error "make must be run from $(BUILDSYS_SRC_ROOT) directory")
endif

# find out current directory (where this script resides)
export BUILDSYS_COMMON_ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# include user's common configuration if present
common.mk:
-include common.mk

# include debian stuff
include $(BUILDSYS_COMMON_ROOT)deb.mk
