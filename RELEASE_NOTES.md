# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.4 contains approximately 500 changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

* v1 of Power Control Service (PCS) is active.
* Cray CLI will default to version 2 (v2) for BOS, if a version is not specified.

### Monitoring

### Networking

### Management Nodes (Ceph, Kubernetes Workers, and Kubernetes Managers)

### User Application Nodes (UAN)

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

* Added documentation for 
  * `IUF` workflows for fresh and upgrade install 
  * how to increase helm chart deploy timeout
  
* Updated documentation for
  * CSM upgrade `UPGRADE_KYVERNO_POLICY` step failed due to missing "dvs" namespace
  * Automated sat bootprep usage instead of manual steps for NCN customization and personalization
  * System recovery procedure for keycloak
  * Steps to configure SNMP credentials 
  * Use BOS v2 in prepare-images stage
  * Keycloak to use CMN LB for administrative tasks
  * Add cray product catalog module`scripts/operations/configuration/python_lib`
  * Add NCN squashfs IMS ID/version/name to cray product catalog
  * Keycloak API upgrade
  * new name for management NCN CFS configuration
  * `docs/pit-init` to include arch when referring to artifacts
  * Master node disk reboot test defaulted to PXE
  * New protected S3 NCN images
  * Stage 4 upgrade to include info on automation
  * Procedure to find Argo logs in S3
  * CFS usability changes
  * "NCN Node Personalization" step that modifies CPE/Analytics layers
  * Ceph troubleshooting page 
  * User to know cronjobs may need to be restarted after Bare-Metal etcd cluster restore
  * `hms_verification/verify_hsm_discovery.py` failure to reference SNMP configuration doc
  * `write_root_secrets_to_vault.py`
  
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
* Documented known issue with Antero node NIDs

### Security vulnerability exceptions in CSM 1.4
