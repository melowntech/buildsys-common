define git-branch
$(shell $(BUILDSYS_COMMON_ROOT)/git/branch.sh)
endef

define git-hash
$(shell $(BUILDSYS_COMMON_ROOT)/git/hash.sh)
endef

GIT_BRANCH_CONFIG_DIR = common.mk.d/git-branch/$(git-branch)
GIT_BRANCH_CONFIG = ${GIT_BRANCH_CONFIG_DIR}/common.mk

# include git-based config
$(GIT_BRANCH_CONFIG):
-include $(GIT_BRANCH_CONFIG)

# edit git-branch config file
$(GIT_BRANCH_CONFIG_DIR):
	mkdir -p $(GIT_BRANCH_CONFIG_DIR)

edit-git-branch-config: $(GIT_BRANCH_CONFIG_DIR)
	sensible-editor $(GIT_BRANCH_CONFIG)
.PHONY: edit-git-branch-config

show-git-branch-config:
	@test -f $(GIT_BRANCH_CONFIG) && cat $(GIT_BRANCH_CONFIG) || exit 0
.PHONY: show-git-branch-config

remove-git-branch-config:
	@$(BUILDSYS_COMMON_ROOT)/git/remove-branch-config.sh $(GIT_BRANCH_CONFIG)
.PHONY: remove-git-branch-config
