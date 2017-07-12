# Debian packaging related stuff

# use given customer's debian directory and release
DEB_CUSTOMER ?= internal
DEB_RELEASE ?= $(call deb_release)

# default dput configuration
DPUT_DISTRIBUTION ?= melown
DPUT_CONFIG ?= $(BUILDSYS_COMMON_ROOT)dput.cf

deb: deb_prepare
	@(dpkg-buildpackage -b -j`grep -c ^processor /proc/cpuinfo` $(DEB_OVERRIDE))

debclean: deb_prepare
	@(unset MAKELEVEL; unset MAKEFLAGS;	fakeroot ./debian/rules clean)

dput: deb_prepare
	dput -c $(DPUT_CONFIG) $(DPUT_DISTRIBUTION) $(call deb_changes_file)

dversion: deb_prepare
	@echo $(call deb_version)

# we need to use some magic to mimic old simple behaviour:
#     * plain version increment: --increment + --no-auto-nmu
#     * grab info from previous entries: --release-heuristic log
#     * no addition stuff in version (like ubuntu on ubuntu): use fake vendor
dch: deb_prepare
	@dch --increment --release-heuristic log --no-auto-nmu --vendor Melown

debsign: deb_prepare
	@(debsign $(call deb_changes_file))

deb_prepare:
	@$(BUILDSYS_COMMON_ROOT)/deblink.sh $(DEB_CUSTOMER) $(DEB_RELEASE)

.PHONY: deb debclean dput dtag deb_prepare deb_show_config

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
	$(shell lsb_release -c 2>/dev/null | gawk '/Codename:/ { print $$2 }')
endef

# compose DEB_OVERRIDE from DEB_OVERRIDE_* variables
ifdef DEB_OVERRIDE_RELEASE
	DEB_OVERRIDE:="$(DEB_OVERRIDE) --changes-option=-DDistribution=\"$(DEB_OVERRIDE_RELEASE)\""
endif
ifdef DEB_OVERRIDE_CHANGED_BY
	DEB_OVERRIDE:="$(DEB_OVERRIDE) --changes-option=-DChanged-By=\"$(DEB_OVERRIDE_CHANGED_BY)\""
endif

deb_show_config:
	@echo DEB_CUSTOMER = $(DEB_CUSTOMER)
	@echo DEB_RELEASE = $(DEB_RELEASE)
