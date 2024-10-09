# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.6 contains many changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

* v1 of Power Control Service (PCS) is active.

### Monitoring

### Networking

### Miscellaneous functionality

### New hardware support

* **IMPORTANT** Systems with NVIDIA CPUs and GPUs must see [Known issues](#known-issues)

### Automation improvements

### Base platform component upgrades

| Platform Component           | Version        |
|------------------------------|----------------|

### Security improvements

### Customer-requested enhancements

### Documentation enhancements

## Noteworthy changes

* The [BOS](glossary.md#boot-orchestration-service-bos) API now enforces limits that previously had
  only been recommended. When updating to CSM 1.6, BOS data is migrated to be in compliance with the
  API specification. See [BOS data notice](upgrade/README.md#bos-data-notice) for more details.

## Bug fixes

## Deprecations

For a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* [BOS](glossary.md#boot-orchestration-service-bos) v1

For a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

* CSM 1.6.0 **does not support servers with NVIDIA CPUs and GPUs**. Systems with these servers should not be upgraded to CSM 1.6.0.

  The January 2025 HPE HPC continuous software stack releases (CSM 1.6.0) are for HPE Cray EX systems without NVIDIA CPUs and GPUs.
  For HPE Cray EX systems with NVIDIA CPUs and GPUs, please use the August 2024 (CSM 1.5.x) HPE HPC continuous software stack.
  These software stacks were validated with NVIDIA HPC SDK 24.3.

  The March 2025 HPE HPC continuous and extended software stack releases will be validated with NVIDIA HPC SDK 24.11.
  The March 2025 (CSM 1.6.1) software stacks will support all HPE Cray EX systems.

* After updating Paradise BMC firmware, the `hmcollector-poll` service will lose event subscriptions and must be restarted
    * See [Updating Foxconn Paradise Nodes with FAS](operations/firmware/FAS_Paradise.md) for details on how to do this

### Security vulnerability exceptions in CSM 1.6
