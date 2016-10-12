# run all targets sequentially
.NOTPARALLEL:

# this variable marks this file has been included
BUILDYS_COMMON_INCLUDED=1

BUILDSYS_COMMON_ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# use given customer's debian directory and release
DEB_CUSTOMER ?= internal
DEB_RELEASE ?= $(call deb_release)

# dput configuration
DPUT_DISTRIBUTION := citationtech
DPUT_CONFIG := dput.cf

deb: deb_prepare
	@(dpkg-buildpackage -b -j`grep -c ^processor /proc/cpuinfo`)

debclean: deb_prepare
	@(unset MAKELEVEL; unset MAKEFLAGS;	fakeroot ./debian/rules clean)

dput: deb_prepare
	dput -c $(join $(BUILDSYS_COMMON_ROOT),dput.cf) $(DPUT_DISTRIBUTION) $(call deb_changes_file)

dversion: deb_prepare
	@echo $(call deb_version)

dch: deb_prepare
	@dch -i --release-heuristic log --no-auto-nmu

# notice no quotes around deb_tag -> we get package name and package version as
# separates args
dtag: deb_prepare
	@$(BUILDSYS_COMMON_ROOT)/dtag.sh $(call deb_tag)

.PHONY: deb debclean dput dtag deb_prepare deb_show_config

deb_prepare:
	@$(BUILDSYS_COMMON_ROOT)/deblink.sh $(DEB_CUSTOMER) $(DEB_RELEASE)

# supporting macros
define deb_changes_file
$(shell (dpkg-parsechangelog; \
	echo -n "Architecture: "; dpkg-architecture -qDEB_BUILD_ARCH) \
	| gawk '/^Version:/ { version=$$2; } /^Source:/ { source=$$2; } /^Architecture:/ { arch=$$2; } END { printf("../%s_%s_%s.changes\n", source, version, arch); }')
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
	$(shell lsb_release -a 2>/dev/null | gawk '/Codename:/ { print $$2 }')
endef

deb_show_config:
	@echo DEB_CUSTOMER = $(DEB_CUSTOMER)
	@echo DEB_RELEASE = $(DEB_RELEASE)

tar:
	@($(BUILDSYS_COMMON_ROOT)/make-tarball.sh -j`grep -c ^processor /proc/cpuinfo`)
