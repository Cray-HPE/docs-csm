# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.4 contains approximately 500 changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

* v1 of Power Control Service (PCS) is active.
* Cray CLI will default to version 2 (v2) for BOS, if a version is not specified.

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

* [CAPMC](glossary.md#cray-advanced-platform-monitoring-and-control-capmc)

For a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

The following previously deprecated features now have an announced CSM version when they will be removed:

* [BOS](glossary.md#boot-orchestration-service-bos) v1 was deprecated in CSM 1.3, and will be removed in CSM 1.9.
* [CRUS](glossary.md#compute-rolling-upgrade-service-crus) was deprecated in CSM 1.2, and will be removed in CSM 1.5.

For a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

* UAIs use a default route that sends outbound packets over the CMN, this will be addressed in a future release so that the default route uses the CAN/CHN.
* The Slurm installer released in CPE 23.03 (`cpe-slurm-23.03-sles15-1.2.10.tar.gz`) has an issue that causes failures when installed with the IUF. To work around the issue, run the following commands before the IUF `process-media` stage:

  ```bash
  tar -xf cpe-slurm-23.03-sles15-1.2.10.tar.gz
  sed -i -e 's_-cn$_-cn/_' wlm-slurm-1.2.10/iuf-product-manifest.yaml
  tar -zcf cpe-slurm-23.03-sles15-1.2.10.tar.gz wlm-slurm-1.2.10
  ```

  If a previous installation failed, apply the workaround and re-install with the `iuf run --force` option.

* The PBS installer released in CPE 23.03 (`cpe-pbs-23.03-sles15-1.2.10.tar.gz`) has an issue that causes failures when installed with the IUF. To work around the issue, run the following commands before the IUF `process-media` stage:

  ```bash
  tar -xf cpe-pbs-23.03-sles15-1.2.10.tar.gz
  sed -i -e 's_-cn$_-cn/_' wlm-pbs-1.2.10/iuf-product-manifest.yaml
  tar -zcf cpe-pbs-23.03-sles15-1.2.10.tar.gz wlm-pbs-1.2.10
  ```

  If a previous installation failed, apply the workaround and re-install with the `iuf run --force` option.

### Security vulnerability exceptions in CSM 1.4
