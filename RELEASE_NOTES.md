# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.4 contains approximately 500 changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

### Monitoring

### Networking

### Miscellaneous functionality

### New hardware support

### Automation improvements

### Base platform component upgrades

| Platform Component           | Version        |
|------------------------------|----------------|
| Ceph                         | `16.6.29`      |
| `containerd`                 | `1.5.10`       |

### Security improvements

* IPXE binary name randomization for added security

### Customer-requested enhancements

### Documentation enhancements

## Bug fixes

## Deprecations

No new deprecations. For a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* [SLS](glossary.md#system-layout-service-sls) support for downloading and uploading credentials in the `dumpstate` and `loadstate` REST APIs

The following previously deprecated features now have an announced CSM version when they will be removed:

* [BOS](glossary.md#boot-orchestration-service-bos) v1 was deprecated in CSM 1.3, and will be removed in CSM 1.9.
* [CRUS](glossary.md#compute-rolling-upgrade-service-crus) was deprecated in CSM 1.2, and will be removed in CSM 1.6.

For a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

### Security vulnerability exceptions in CSM 1.4
