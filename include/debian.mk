# This file can be included into debian/rules to include basic stuff and update
# package version to include debian release for which this package is built

include /usr/share/dpkg/default.mk

ifneq ("$(DEBIAN_VERSION_SUFFIX)","")
# add DEB_RELEASE variable to debian_revision part of package version to
# distinguish between packages of the same version for different distributions
override_dh_gencontrol:
	dh_gencontrol -- -v$(DEB_VERSION)$(DEBIAN_VERSION_SUFFIX)
endif

# extra cleaning, empty by default
.PHONY: debclean_extra
debclean_extra: ;
