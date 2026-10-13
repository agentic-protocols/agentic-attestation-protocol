LIBDIR := lib

# i-d-template assumes npm when package.json is present. Standardize on the
# pinned pnpm version, bootstrapping it through npx/corepack when necessary so
# `make` remains the only command contributors need to run.
PNPM_VERSION := 10.28.0
PNPM ?= $(if $(shell command -v pnpm 2>/dev/null),pnpm,$(if $(shell command -v npx 2>/dev/null),npx --yes pnpm@$(PNPM_VERSION),corepack pnpm))
NO_NODEJS := true
DEPS_FILES := node_modules/.pnpm-install
export PATH := $(abspath node_modules/.bin):$(PATH)

include $(LIBDIR)/main.mk

node_modules/.pnpm-install: package.json pnpm-lock.yaml
	$(PNPM) install --frozen-lockfile
	@touch $@

update-deps::
	$(PNPM) update
	@touch node_modules/.pnpm-install

.PHONY: clean-node-deps
clean-node-deps:
	-rm -rf node_modules package-lock.json

clean:: clean-node-deps
clean-deps:: clean-node-deps

$(LIBDIR)/main.mk:
ifneq (,$(wildcard $(LIBDIR)))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b main https://github.com/martinthomson/i-d-template $(LIBDIR)
endif
