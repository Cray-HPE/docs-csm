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

## Bug fixes

## Deprecations

For a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* [BOS](glossary.md#boot-orchestration-service-bos) v1

For a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

* CSM 1.6.0 **does not support servers with NVIDIA CPUs and GPUs**. Systems with these servers should not be upgraded to CSM 1.6.0. Please stay on the supported CSM release of 1.5.x.
* After updating Paradise BMC firmware, the `hmcollector-poll` service will lose event subscriptions and must be restarted
    * See [Updating Foxconn Paradise Nodes with FAS](operations/firmware/FAS_Paradise.md) for details on how to do this

### Security vulnerability exceptions in CSM 1.6
