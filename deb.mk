# Debian packaging related stuff

include $(BUILDSYS_COMMON_ROOT)deb-releases.mk

_DEFAULT_CUSTOMER:=internal

# use given customer's debian directory and release
DEB_CUSTOMER ?= $(_DEFAULT_CUSTOMER)
DEB_RELEASE ?= $(call deb_release)
DEB_RELEASE_VENDOR ?= $(call deb_release_vendor)
DEB_CHANGES_RELEASE ?= $(DEB_TRANSLATE_RELEASE_$(DEB_RELEASE))
DEB_RELEASE_HAS_BACKPORTS ?= $(DEB_RELEASE_HAS_BACKPORTS_$(DEB_RELEASE_VENDOR))
DEB_CHANGES_RELEASE_OPTION ?= --changes-option=-DDistribution="$(DEB_CHANGES_RELEASE)"
DEB_RELEASE_VERSION ?= $(call deb_release_version)

# default dput configuration
DPUT_DISTRIBUTION ?= melown
DPUT_CONFIG ?= $(BUILDSYS_COMMON_ROOT)dput.cf

# where is tar?
TAR_BINARY=$(shell (which tar))

# Default settings
BUILD_BINARY_PACKAGE ?= YES
BUILD_SOURCE_PACKAGE ?= NO
USE_DEBIAN_RELEASE_IN_VERSION ?= NO
USE_CUSTOMER_IN_VERSION ?= NO

# default customer is never added in version
ifeq ($(DEB_CUSTOMER),$(_DEFAULT_CUSTOMER))
USE_CUSTOMER_IN_VERSION = NO
endif

ifeq ("","$(wildcard /proc/cpuinfo)")
	CPU_COUNT = 1
else
	CPU_COUNT = $(shell grep -c ^processor /proc/cpuinfo)
endif

DPKG_SOURCE_OPTIONS=$(shell $(BUILDSYS_COMMON_ROOT)/generate-exludes.sh \
							$(notdir $(BUILDSYS_SRC_ROOT)))

# export some variables that can be used in dpkg-buildpackage
export USE_DEBIAN_RELEASE_IN_VERSION
export USE_CUSTOMER_IN_VERSION
export DEB_RELEASE
export DEB_CHANGES_RELEASE
export DEB_RELEASE_HAS_BACKPORTS
export DEB_RELEASE_VERSION

HAS_BUILDINFO=$(shell which dpkg-genbuildinfo)
DPKG_BUILDPACKAGE_EXTRA=

ifeq ($(USE_DEBIAN_RELEASE_IN_VERSION),YES)

#export version suffix
ifeq ($(USE_CUSTOMER_IN_VERSION),NO)
# use release
export DEBIAN_VERSION_SUFFIX = -0$(DEB_RELEASE)
else
# use release with customer
export DEBIAN_VERSION_SUFFIX = -0$(DEB_RELEASE).$(DEB_CUSTOMER)
endif

#do not sign control files, we'll sign it manually
ifneq ($(HAS_BUILDINFO),)
DPKG_BUILDPACKAGE_EXTRA=-uc --buildinfo-option=-O$(call deb_file,buildinfo)
endif
endif

debbin: deb_prepare
	@(echo "*** Building debian binary package for $(DEB_CHANGES_RELEASE) using configuration for $(DEB_RELEASE).")
	(export PATH=$(BUILDSYS_COMMON_ROOT)deb.bin:$$PATH; \
		dpkg-buildpackage $(DEB_CHANGES_RELEASE_OPTION) -b -j$(CPU_COUNT) $(DEB_OVERRIDE) $(DPKG_BUILDPACKAGE_EXTRA))
ifeq ($(USE_DEBIAN_RELEASE_IN_VERSION),YES)
	$(call deb_move_file,changes)
ifneq ($(HAS_BUILDINFO),)
	@(debsign $(call deb_file,changes))
endif
endif

debsrc: deb_prepare
	@(echo "*** Building debian source package for $(DEB_CHANGES_RELEASE) using configuration for $(DEB_RELEASE).")
	@(export PATH=$(BUILDSYS_COMMON_ROOT)src.bin:$$PATH TAR_BINARY=$(TAR_BINARY); \
		dpkg-buildpackage $(DEB_CHANGES_RELEASE_OPTION) -S $(DEB_OVERRIDE) $(DPKG_SOURCE_OPTIONS))

# deb target (conditionally) depends on debbin and debsrc
ifeq ($(BUILD_BINARY_PACKAGE),YES)
deb: debbin
endif
ifeq ($(BUILD_SOURCE_PACKAGE),YES)
deb: debsrc
endif

debclean: deb_prepare
	@(unset MAKELEVEL; unset MAKEFLAGS;	fakeroot ./debian/rules clean debclean_extra)

dput: deb_prepare
	dput -u -c $(DPUT_CONFIG) $(DPUT_DISTRIBUTION) $(call deb_file,changes)

dversion: deb_prepare
	@echo $(call deb_version)

# we need to use some magic to mimic old simple behaviour:
#     * plain version increment: --increment + --no-auto-nmu
#     * grab info from previous entries: --release-heuristic log
#     * no addition stuff in version (like ubuntu on ubuntu): use fake vendor
dch: deb_prepare
	@(if [ -f debian/changelog ]; then \
		dch --increment --release-heuristic log --no-auto-nmu --vendor Melown; \
	else \
		dch --create --package $$(gawk '/^Source:/ {print $$2}' debian/control) \
			--vendor Melown -v 0.1 -D mlwn; \
	fi)

debsign: deb_prepare
ifeq ($(USE_DEBIAN_RELEASE_IN_VERSION),YES)
	$(call deb_move_file,changes)
endif
	@(debsign $(call deb_file,changes))

deb_prepare:
	@$(BUILDSYS_COMMON_ROOT)deb-prepare.sh $(DEB_CUSTOMER) $(DEB_RELEASE)

.PHONY: deb debbin debsrc debclean dput dtag deb_prepare deb_show_config

# supporting macros
define deb_basefile_pristine
$(shell (dpkg-parsechangelog; \
	echo -n "Architecture: "; dpkg-architecture -qDEB_BUILD_ARCH) \
	| gawk '/^Version:/ { version=$$2; } /^Source:/ { source=$$2; } /^Architecture:/ { arch=$$2; } END { printf("../%s_%s_%s\n", source, version, arch); }')
endef

define deb_basefile
$(shell (dpkg-parsechangelog; \
	echo -n "Architecture: "; dpkg-architecture -qDEB_BUILD_ARCH) \
	| gawk '/^Version:/ { version=$$2; } /^Source:/ { source=$$2; } /^Architecture:/ { arch=$$2; } END { printf("../%s_%s$(DEBIAN_VERSION_SUFFIX)_%s\n", source, version, arch); }')
endef

define deb_file_pristine
$(call deb_basefile_pristine).$(1)
endef

define deb_file
$(call deb_basefile).$(1)
endef

define deb_tag
$(shell dpkg-parsechangelog | \
	gawk '/^Version:/ { version=$$2; } /^Source:/ { source=$$2; } END { printf("%s %s\n", source, version); }')
endef

define deb_version
$(shell dpkg-parsechangelog | \
	gawk '/^Version:/ { print $$2; }')
endef

define deb_release
$(shell lsb_release -c 2>/dev/null | gawk '/Codename:/ { print $$2 }')
endef

define deb_release_vendor
$(shell dpkg-vendor --query Vendor 2>/dev/null)
endef

define deb_move_file
@if test -f $(call deb_basefile_pristine).$(1); then \
	mv -f $(call deb_basefile_pristine).$(1) $(call deb_basefile).$(1); \
fi
endef

define deb_release_version
$(shell dpkg-parsechangelog 2>/dev/null | \
	gawk 'match($$0, /RELEASE:([^[:space:]]+)/, out) { release = out[1]; } END { print release }')
endef

# override changed-by if asked to steal package
# however, if DEB_OVERRIDE_CHANGED_BY is set, nothing happens
ifdef DEB_STEAL
DEB_OVERRIDE_CHANGED_BY:=${DEBFULLNAME} <${DEBEMAIL}>
endif

# compose DEB_OVERRIDE from DEB_OVERRIDE_* variables
ifdef DEB_OVERRIDE_RELEASE
override DEB_OVERRIDE:=$(DEB_OVERRIDE)--changes-option=-DDistribution="$(DEB_OVERRIDE_RELEASE)"
endif
ifdef DEB_OVERRIDE_CHANGED_BY
override DEB_OVERRIDE:=$(DEB_OVERRIDE)--changes-option=-DChanged-By="$(DEB_OVERRIDE_CHANGED_BY)" -k"${DEBFULLNAME}"
endif

deb_show_config: deb_prepare
	$(info DEB_CUSTOMER = $(DEB_CUSTOMER)) @true
	$(info DEB_RELEASE = $(DEB_RELEASE)) @true
	$(info DEB_CHANGES_RELEASE = $(DEB_CHANGES_RELEASE)) @true
	$(info DEB_RELEASE_HAS_BACKPORTS = $(DEB_RELEASE_HAS_BACKPORTS)) @true
	$(info BUILD_BINARY_PACKAGE = $(BUILD_BINARY_PACKAGE)) @true
	$(info BUILD_SOURCE_PACKAGE = $(BUILD_SOURCE_PACKAGE)) @true
	$(info USE_DEBIAN_RELEASE_IN_VERSION = $(USE_DEBIAN_RELEASE_IN_VERSION)) @true
	$(info DPUT_DISTRIBUTION = $(DPUT_DISTRIBUTION)) @true
	$(info DPUT_CONFIG = $(DPUT_CONFIG)) @true
	$(info DEB_OVERRIDE = $(DEB_OVERRIDE)) @true
	$(info DEB_RELEASE_VERSION = $(DEB_RELEASE_VERSION)) @true

help-deb:
	@(cat $(BUILDSYS_COMMON_ROOT)/help-deb.txt)
.PHONY: help-deb

help-dput:
	@(cat $(BUILDSYS_COMMON_ROOT)/dput.cf)
.PHONY: help-dput
