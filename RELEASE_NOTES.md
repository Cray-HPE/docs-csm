# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.7 contains many changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

### Monitoring

### Networking

### Miscellaneous functionality

* Console logs and interaction is now available and tenant aware through the `cray` CLI, see [console](operations/conman/ConMan.md#console) for more information.

### New hardware support

### New software support

### Automation improvements

### Base platform component upgrades

### Security improvements

* Spire node attestation can now be setup to use TPM chips on supported platforms, see [Enable TPM node attestation with Spire](operations/spire/Enable_TPM_node_attestation.md) for more information.
* The old version of the Spire server was removed to fully transition to the newer version of Spire.

### Customer-requested enhancements

### Documentation enhancements

## Noteworthy changes

## Test

* Modified `adjust k8s_nodes_ready_check.sh` to not fail when a node is in `Ready,SchedulingDisabled` state
* Modified `velero_backups_check.sh` to not fail if a newer, successful backup exists
* Modified `run_hms_ct_tests.sh` to handle concurrency better
* Fixed intermittent failures sometimes seen when running `check_key_id_in_jwks.sh`
* Added retry logic to `goss-postgresql-syncfailed.yaml` to prevent intermittent false positives
* Added retry logic to `postgres_clusters_running.sh to prevent` intermittent false positives

## Bug fixes

* The [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos)
  [`session-setup` operator](operations/boot_orchestration/BOS_Services.md#session-setup) now ignores invalid
  [xnames](glossary.md#xname) referenced by [session templates](operations/boot_orchestration/Session_Templates.md),
  fixing a bug that caused BOS [sessions](operations/boot_orchestration/Sessions.md) to be stuck in `pending` state.
* BOS logging is significantly more memory efficient, fixing a problem where logging on large scale systems
  could cause [BOS operator](operations/boot_orchestration/BOS_Services.md#bos-operators) Kubernetes pods to be `OOMKilled`.
* When using the API or CLI to [Modify a BOS session template](operations/boot_orchestration/Manage_a_Session_Template.md#modify-a-session-template),
  it is no longer required to specify `boot_sets` in the update data (this fixes a regression bug present in CSM 1.6).

## Deprecations

For more details and a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* The [Content Projection Service (CPS)](glossary.md#content-projection-service-cps) and the
  [Data Virtualization Service (DVS)](glossary.md#data-virtualization-service-dvs)
* Support for projecting root filesystems and PE images using the [Content Projection Service (CPS)](glossary.md#content-projection-service-cps) and the
  [Data Virtualization Service (DVS)](glossary.md#data-virtualization-service-dvs)
    * This projection is now done using the [Scalable Boot Projection Service](glossary.md#scalable-boot-projection-service-sbps)

For more details and a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

For a full list of known issues, see [Known issues](troubleshooting/README.md#known-issues).

### Security vulnerability exceptions in CSM 1.7
