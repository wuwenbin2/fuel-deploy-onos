##############################################################################
# Copyright (c) 2015 Ericsson AB and others.
# mskalski@mirantis.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

TOP := $(shell pwd)
ODL_BRANCH=7.0
ODL_REPO="https://github.com/openstack/fuel-plugin-opendaylight.git"

.PHONY: all
all: .odlbuild

.PHONY: clean
clean:
	@rm -f .odlbuild ../release/opnfv/opendaylight*.rpm opendaylight*.rpm
	@rm -f $(BUILD_BASE)/gitinfo_odlplugin.txt gitinfo_odlplugin.txt

.PHONY: release
release:.odlbuild
	@rm -f ../release/opnfv/opendaylight*.rpm
	@mkdir -p ../release/opnfv
	@cp opendaylight*.rpm ../release/opnfv/
	cp gitinfo_odlplugin.txt $(BUILD_BASE)
	cd $(BUILD_BASE) && mkdir -p ../deploy/templates/plugins && cp -rf $(TOP)/config/* ../deploy/templates/plugins
.odlbuild:
	rm -rf fuel-plugin-opendaylight
	sudo apt-get -y install build-essential ruby-dev rubygems-integration python-pip git rpm createrepo dpkg-dev
	sudo gem install fpm
	sudo pip install fuel-plugin-builder
	git clone -b $(ODL_BRANCH) $(ODL_REPO)
	fpb --debug --build fuel-plugin-opendaylight/
	mv fuel-plugin-opendaylight/opendaylight*.rpm .
	$(REPOINFO) -r . > gitinfo_odlplugin.txt
	rm -rf fuel-plugin-opendaylight
	touch .odlbuild

#############################################################################
# Cache operations - only used when building through ci/build.sh
#############################################################################


# Create a unique hash to be used for getting and putting cache, based on:
#   - The SHA1 hash of the HEAD on the plugin repo's $(ODL_BRANCH)
#   - The contents of this Makefile
.cacheid:
	@$(CACHETOOL) getcommitid $(ODL_REPO) $(ODL_BRANCH) > .cachedata
	sha1sum Makefile >> .cachedata
	cat .cachedata | $(CACHETOOL) getid > .cacheid

# Clean local data related to caching - called prior to ordinary build
.PHONY: clean-cache
clean-cache: clean
	rm -f .cachedata .cacheid

# Try to download cache - called prior to ordinary build
.PHONY: get-cache
get-cache: .cacheid
	@if $(CACHETOOL) check $(shell cat .cacheid); then \
		 $(CACHETOOL) get $(shell cat .cacheid) | tar xf -;\
	else \
		echo "No cache item found for $(shell cat .cacheid)" ;\
		exit 0;\
	fi

# Store cache if not already stored - called after ordinary build
.PHONY: put-cache
put-cache: .cacheid
	@tar cf - .odlbuild opendaylight*.rpm gitinfo_odlplugin.txt | $(CACHETOOL) put $(shell cat .cacheid)
