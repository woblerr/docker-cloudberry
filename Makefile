CBDB_VERSION = 2.1.0-incubating-rc2
TAG_CBDB ?= 2.1.0-incubating-rc2
UBUNTU_OS_VERSION = ubuntu22.04
ROCKY_OS_VERSION = rockylinux9
UID := $(shell id -u)
GID := $(shell id -g)

all: $(CBDB_VERSION)

.PHONY: $(CBDB_VERSION)
$(CBDB_VERSION):
	$(call build_cbdb_image,$@,$(UBUNTU_OS_VERSION))

.PHONY: build_cbdb_ubuntu
build_cbdb_ubuntu:
	$(call build_cbdb_image_with_tag,$(TAG_CBDB),$(UBUNTU_OS_VERSION))

.PHONY: build_cbdb_rockylinux
build_cbdb_rockylinux:
	$(call build_cbdb_image_with_tag,$(TAG_CBDB),$(ROCKY_OS_VERSION))

.PHONY: test-e2e
test-e2e:
	$(MAKE) -C e2e-tests test-e2e

.PHONY: test-e2e-walg
test-e2e-walg:
	$(MAKE) -C e2e-tests test-e2e-walg

define build_cbdb_image
	@echo "Build Cloudberry $(1) $(2) docker image"
	docker buildx build -f docker/cloudberry/$(2)/Dockerfile --build-arg CBDB_VERSION=$(1) -t cloudberry:$(1) .
endef

define build_cbdb_image_with_tag
	@echo "Build Cloudberry $(1) $(2) docker image"
	docker buildx build -f docker/cloudberry/$(2)/Dockerfile --build-arg CBDB_VERSION=$(1) -t cloudberry:$(1)-$(2) .
endef
