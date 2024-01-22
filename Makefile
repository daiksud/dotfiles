DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
HOME := $(realpath $(dir $(DIR)))
$(info $(DIR))
FILES=$(shell find $(DIR) -maxdepth 1 -mindepth 1 -name ".*" ! -name ".git" ! -name ".gitignore" ! -name ".gitmodules" | sed 's!^.*/!!')
CONFIG_FILES=$(shell find $(DIR)/config -maxdepth 1 -mindepth 1 | sed 's!^.*/!!')

# Define the default target
install:

define TARGET
TARGET_LIST+=$(1)_TARGET
.PHONY: $(1)_TARGET
$(1)_TARGET:
	@rm -rf $(HOME)/$(1) 2>/dev/null
	@ln -fs $(DIR)/$(1) $(HOME)/$(1)
	@echo "make symbolic link: $(HOME)/$(1) -> $(DIR)/$(1)"
endef
$(foreach file, $(FILES), $(eval $(call TARGET,$(file))))

define TARGET2
TARGET_LIST2+=$(1)_TARGET2
.PHONY: $(1)_TARGET2
$(1)_TARGET2:
	@rm -rf $(HOME)/.config/$(1) 2>/dev/null
	@ln -fs $(DIR)/config/$(1) $(HOME)/.config/$(1)
	@echo "make symbolic link: $(HOME)/.config/$(1) -> $(DIR)/config/$(1)"
endef
$(foreach file2, $(CONFIG_FILES), $(eval $(call TARGET2,$(file2))))

install: mkconfig $(TARGET_LIST) $(TARGET_LIST2)
	cp -r .git_template/hooks .git/
	git config --global push.default current

mkconfig:
	if [ ! -d $(HOME)/.config ]; then rm -f $(HOME)/.config; fi
	mkdir -p $(HOME)/.config
