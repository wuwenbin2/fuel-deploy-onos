##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# stefan.k.berg@ericsson.com
# jonas.bjurel@ericsson.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

SHELL = /bin/bash

# This file will be created if needed by runcontext to contain proxy
# settings.
-include environment.mk

############################################################################
# BEGIN of variables to customize
#
#Input args
export ISOSRC = file:$(shell pwd)/fuel-7.0.iso
export ISOCACHE = $(shell pwd)/$(shell basename $(ISOSRC))
export PRODNO = "OPNFV_BGS"
export REVSTATE = "P0000"

ifdef BUILD_FUEL_PLUGINS
$(warning Overriding plugin build selection to $(BUILD_FUEL_PLUGINS))
export NEWISO = $(shell pwd)/release/unofficial-opnfv-${REVSTATE}.iso
else
export NEWISO = $(shell pwd)/release/opnfv-${REVSTATE}.iso
endif

# Note! Invoke with "make REVSTATE=RXXXX all" to make release build!
# Invoke with ICOCACHE=/full/path/to/iso if cached ISO is in non-standard location.

# Build variables
export BUILD_BASE := $(shell pwd)
export DEB_DEST := $(BUILD_BASE)/release/packages/ubuntu/pool/main
export UDEB_DEST := $(BUILD_BASE)/release/packages/ubuntu/pool/debian-installer
export PUPPET_DEST := $(BUILD_BASE)/release/puppet/modules
export VERSION_FILE := $(BUILD_BASE)/.versions
export DOCKERIMG = opnfv.org/ubuntu-builder:14.04
export TOPDIR := $(shell pwd)
export REPOINFO  := $(BUILD_BASE)/repo_info.sh

#Build subclasses

SUBDIRS := f_isoroot

# f_example is only an example of how to generate a .deb package and
# should not be enabled in official builds.
#SUBDIRS += f_example

ORIGDIR := $(TOPDIR)/origiso
#
# END of variables to customize
#############################################################################

SUBCLEAN = $(addsuffix .clean,$(SUBDIRS))

.PHONY: all
all:
	@docker version >/dev/null 2>&1 || (echo 'No Docker installation available'; exit 1)
	@make -C docker
	@docker/runcontext $(DOCKERIMG) $(MAKE) $(MAKEFLAGS) iso


############################################################################
# BEGIN of Include definitions
#
include config.mk
include cache.mk
#
# END Include definitions
#############################################################################

$(ISOCACHE):
	# Clone Fuel to non-persistent location and build
	if [ ! -d /tmp/fuel-main ]; then \
		cd /tmp && git clone $(FUEL_MAIN_REPO); \
	fi
	cd /tmp/fuel-main && git checkout $(FUEL_MAIN_TAG)
	@echo "fuel" `git -C /tmp/fuel-main show | grep commit | head -1 | cut -d " " -f2` >> $(VERSION_FILE)
	# Setup cgroups for docker-in-docker
	sudo /root/enable_dockerx2
	# Patch for adding dosfstools, as Fuel 6.1 is running mkfs.vfat
	cd /tmp/fuel-main && patch -p0 < $(TOPDIR)/fuel-main_5.patch
	# Patch for changing the second layer Docker --bip address
	cd /tmp/fuel-main && patch -p0 < $(TOPDIR)/fuel-main_6.patch
	# Remove Docker optimizations, otherwise multistrap will fail during
	# Fuel build.
	sudo rm -f /etc/apt/apt.conf.d/docker*
	#
	# Need to replace the old Docker v. 1.5.0 with a later version to be
	# able to access the Docker remote repository!
	cd /tmp/fuel-main && patch -p0 < $(TOPDIR)/fuel-main_docker_version.patch
	#
	cd /tmp/fuel-main && ./prepare-build-env.sh
	cd /tmp/fuel-main && make repos
	$(REPOINFO) -r /tmp/fuel-main > gitinfo_fuel.txt
	#
	cd /tmp/fuel-main && sudo make iso
	cp /tmp/fuel-main/build/artifacts/fuel*.iso .

.PHONY: mount-origiso umount-origiso
mount-origiso: $(ISOCACHE)
	@echo "Mounting original ISO in $(ORIGDIR)"
	@mkdir -p $(ORIGDIR)
	@fuseiso $(ISOCACHE) $(ORIGDIR)

umount-origiso:
	@echo "Unmounting original ISO from $(ORIGDIR)"
	@fusermount -u $(ORIGDIR)
	@rmdir $(ORIGDIR)

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	@mkdir -p release/packages/ubuntu/pool/main release/packages/ubuntu/pool/debian-installer release/puppet/modules release/isoroot
	$(MAKE) -C $@ -f Makefile release

.PHONY: patch-packages
patch-packages:
	ORIGISO=$(ISOCACHE) REVSTATE=$(REVSTATE) $(MAKE) -C $@ -f Makefile release

.PHONY: clean $(SUBCLEAN)
clean:  $(SUBCLEAN)
	$(MAKE) -C patch-packages -f Makefile clean
	@rm -f *.iso
	@rm -Rf release
	@rm -Rf newiso
	@rm -Rf .versions
	@rm -f $(NEWISO)
	@rm -f $(BUILD_BASE)/gitinfo_*.txt

.PHONY: deepclean
deepclean: clean clean-cache
	make -C docker clean
	docker rmi opnfv.org/ubuntu-builder:14.04 &>/dev/null || exit 0
	docker rmi opnfv.org/ubuntu-builder:latest &>/dev/null || exit 0
	docker rmi ubuntu:14.04 &>/dev/null || exit 0
	@if docker images | grep -q "ubuntu *14.04"; then \
		echo "Error: ubuntu:14.04 still present!"; \
		exit 1; \
	fi
	@if docker images | grep -q "opnfv.org/ubuntu-builder"; then \
		echo "Error: opnfv.org/ubuntu-builder still present!"; \
		exit 1; \
	fi

$(SUBCLEAN): %.clean:
	$(MAKE) -C $* -f Makefile clean

.PHONY: setup-env
setup-env:
	@if [ -f environment.mk ]; then \
		sudo bash -c "cat environment.mk >> /etc/environment"; \
	fi

# Todo: Make things smarter - we shouldn't need to clean everything
# betwen make invocations.
.PHONY: iso
iso:	setup-env $(ISOCACHE) $(SUBDIRS) patch-packages
	$(REPOINFO) . > gitinfo_main.txt
	install/install.sh iso $(ISOCACHE) $(NEWISO) $(PRODNO) $(REVSTATE)
	@printf "\n\nProduct ISO is $(NEWISO)\n\n"

# Start a bash shell in docker for Makefile debugging
.PHONY: debug
debug:
	@docker version >/dev/null 2>&1 || (echo 'No Docker installation available'; exit 1)
	@make -C docker
	docker/runcontext $(DOCKERIMG) debug

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################

# Create a unique hash to be used for getting and putting cache, based on:
#   - The commit ID of the full Fuel repo structre
#   - The contents of all local Fuel patches
.cacheid:
	cd /tmp && git clone $(FUEL_MAIN_REPO)
	cd /tmp/fuel-main && git checkout $(FUEL_MAIN_TAG)
	cd /tmp/fuel-main && make repos
	$(REPOINFO) -r /tmp/fuel-main > .cachedata
	sha1sum fuel-main*.patch >> .cachedata
	cat .cachedata | $(CACHETOOL) getid > .cacheid
	# Not removing fuel-main as it is re-used in build

# Clean local data related to caching - called prior to ordinary build
.PHONY: clean-cache
clean-cache: $(SUBCLEANCACHE)
	rm -f .cachedata .cacheid

# Try to download cache - called prior to ordinary build
.PHONY: get-cache
get-cache: .cacheid
	@if $(CACHETOOL) check $(shell cat .cacheid); then \
		 $(CACHETOOL) get $(shell cat .cacheid) | tar xf -;\
	else \
		exit 0;\
	fi

# Store cache if not already stored - called after ordinary build
.PHONY: put-cache
put-cache: .cacheid
	@tar cf - fuel*.iso gitinfo_fuel.txt | $(CACHETOOL) put $(shell cat .cacheid)
