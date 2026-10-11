CBDB_VERSION_21 := 2.1.0-incubating
CBDB_VERSION_22 := 2.2.0-incubating-rc1
TAG_CBDB_21 ?= $(CBDB_VERSION_21)
TAG_CBDB_22 ?= $(CBDB_VERSION_22)
BUILD_JOBS ?= 2

.PHONY: all
all: build_cbdb_21_ubuntu22 build_cbdb_22_ubuntu22

.PHONY: build_cbdb_21_ubuntu22
build_cbdb_21_ubuntu22:
	$(call build_cbdb_image,$(TAG_CBDB_21),ubuntu22.04,2.1)

.PHONY: build_cbdb_21_rockylinux9
build_cbdb_21_rockylinux9:
	$(call build_cbdb_image,$(TAG_CBDB_21),rockylinux9,2.1)

.PHONY: build_cbdb_22_ubuntu22
build_cbdb_22_ubuntu22:
	$(call build_cbdb_image,$(TAG_CBDB_22),ubuntu22.04,2.2)

.PHONY: build_cbdb_22_ubuntu24
build_cbdb_22_ubuntu24:
	$(call build_cbdb_image,$(TAG_CBDB_22),ubuntu24.04,2.2)

.PHONY: build_cbdb_22_rockylinux9
build_cbdb_22_rockylinux9:
	$(call build_cbdb_image,$(TAG_CBDB_22),rockylinux9,2.2)

.PHONY: test-e2e
test-e2e:
	$(MAKE) -C e2e-tests test-e2e

.PHONY: test-e2e-walg
test-e2e-walg:
	$(MAKE) -C e2e-tests test-e2e-walg

.PHONY: test-e2e-standby-coordinator
test-e2e-standby-coordinator:
	$(MAKE) -C e2e-tests test-e2e-standby-coordinator

.PHONY: test-e2e-yezzey
test-e2e-yezzey:
	$(MAKE) -C e2e-tests test-e2e-yezzey

define build_cbdb_image
	@echo "Build Cloudberry $(1) $(2) image from the $(3) release line"
	docker buildx build \
		-f docker/cloudberry/$(2)/$(3)/Dockerfile \
		--build-arg CBDB_VERSION=$(1) \
		--build-arg BUILD_JOBS=$(BUILD_JOBS) \
		-t cloudberry:$(1)-$(2) .
endef
