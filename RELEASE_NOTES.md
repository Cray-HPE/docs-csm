# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.6 contains many changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

v1 of Power Control Service (PCS) is active.  

### Monitoring

### Networking

### Miscellaneous functionality

### New hardware support

### Automation improvements

### Base platform component upgrades

| Platform Component           | Version        |
|------------------------------|----------------|

### Security improvements

### Customer-requested enhancements

### Documentation enhancements

## Bug fixes

## Deprecations

The following features are now deprecated and will be removed from CSM in a future release.

* CAPMC v1 partial deprecation.  CAPMC enters final lifecycle before deletion.  CAPMC will be accessible until 2024 when it will be completely deleted from the system. Users should begin to migrate to PCS.
* HSM v1 interface
* [BOS](glossary.md#boot-orchestration-service-bos) v1 is now deprecated, in favor of BOS v2. BOS v1 will be removed from CSM in the CSM 1.9 release.
  * It is likely that even prior to BOS v1 being removed from CSM, the [Cray CLI](glossary.md#cray-cli-cray) will change its behavior when no
    version is explicitly specified in BOS commands. Currently it defaults to BOS v1, but it may change to default to BOS v2 even before BOS v1
    is removed from CSM.

For a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* [CRUS](glossary.md#compute-rolling-upgrade-service-crus)

For a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

### Security vulnerability exceptions in CSM 1.6
