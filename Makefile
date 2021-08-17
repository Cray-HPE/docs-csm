SPEC_NAME = docs-csm-install
RPM_NAME ?= docs-csm-install
RPM_VERSION := $(shell cat .version)
SPEC_FILE := ${SPEC_NAME}.spec
BUILD_METADATA ?= "1~development~$(shell git rev-parse --short HEAD)"
RPM_SOURCE_NAME := ${RPM_NAME}-${RPM_VERSION}
RPM_BUILD_DIR := $(PWD)/dist/rpmbuild
RPM_SOURCE_PATH := ${RPM_BUILD_DIR}/SOURCES/${RPM_SOURCE_NAME}.tar.bz2


all : prepare rpm
rpm: rpm_package_source rpm_build_source rpm_build

prepare:
		rm -rf dist
		mkdir -p $(RPM_BUILD_DIR)/SPECS $(RPM_BUILD_DIR)/SOURCES
		cp $(SPEC_FILE) $(RPM_BUILD_DIR)/SPECS/

rpm_package_source:
		tar --transform 'flags=r;s,^,/$(RPM_SOURCE_NAME)/,' --exclude .git --exclude dist -cvjf $(RPM_SOURCE_PATH) .

rpm_build_source:
		BUILD_METADATA=$(BUILD_METADATA) rpmbuild -ts $(RPM_SOURCE_PATH) --define "_topdir $(RPM_BUILD_DIR)"

rpm_build:
		BUILD_METADATA=$(BUILD_METADATA) rpmbuild -ba $(SPEC_FILE) --define "_topdir $(RPM_BUILD_DIR)"
