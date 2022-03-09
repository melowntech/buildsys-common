define git-branch
$(shell $(BUILDSYS_COMMON_ROOT)/git/branch.sh)
endef

define git-hash
$(shell $(BUILDSYS_COMMON_ROOT)/git/hash.sh)
endef

# include git-based config
common.mk.d/git-branch/$(git-branch)/common.mk:
-include common.mk.d/git-branch/$(git-branch)/common.mk
