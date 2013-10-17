# this variable marks this file has been included
BUILDYS_COMMON_INCLUDED=1

BUILDSYS_COMMON_ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# dput configuration
DPUT_DISTRIBUTION := citationtech
DPUT_CONFIG := dput.cf

deb:
	@(dpkg-buildpackage -b -j`grep -c ^processor /proc/cpuinfo`)

debclean:
	@(unset MAKELEVEL; unset MAKEFLAGS;	fakeroot ./debian/rules clean)

dput:
	dput -c $(join $(BUILDSYS_COMMON_ROOT),dput.cf) $(DPUT_DISTRIBUTION) $(call deb_changes_file)

# notice no quotes around deb_tag -> we get package name and package version as
# separates args
dtag:
	@$(BUILDSYS_COMMON_ROOT)/dtag.sh $(call deb_tag)

.PHONY: deb debclean dput dtag

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
