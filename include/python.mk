# This file can be included into debian/rules to include python info

python3_late_eval ?= $(or $(value PYTHON3_CACHE_$(1)),$(eval PYTHON3_CACHE_$(1) := $(shell $(2)))$(value PYTHON3_CACHE_$(1)))

PYTHON3_VERSION_FULL = $(wordlist 2,4,$(subst ., ,$(call python3_late_eval,PYTHON3_VERSION_FULL,python3 --version 2>&1)))
PYTHON3_VERSION_MAJOR_MINOR = $(word 1,${PYTHON3_VERSION_FULL}).$(word 2,${PYTHON3_VERSION_FULL})
