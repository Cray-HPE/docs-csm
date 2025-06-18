# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.7 contains many changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

### Monitoring

### Networking

### Miscellaneous functionality

* Console logs and interaction is now available and tenant aware through the `cray` CLI, see [console](operations/conman/ConMan.md#console) for more information.
* cfs components can be updated in bulk through `cray` CLI using the `cfs components updatemany` command,
  see [Managing many components](operations/configuration_management/CFS_Commands_Cheat_Sheet.md#managing-many-components) for more information.
  Support is added for `v2` and `v3` API versions.

### New hardware support

### New software support

### Automation improvements

### Base platform component upgrades

* Kata upgraded to version 3.17.0.

### Security improvements

* Spire node attestation can now be setup to use TPM chips on supported platforms, see [Enable TPM node attestation with Spire](operations/spire/Enable_TPM_node_attestation.md) for more information.
* The old version of the Spire server was removed to fully transition to the newer version of Spire.

### Customer-requested enhancements

* CSM now provides the `csm.ssh_config` Ansible role to automatically restore the root user's SSH configuration file during
  [Management Node Personalization](operations/configuration_management/Management_Node_Personalization.md).
  For more details, see [SSH configuration files](operations/CSM_product_management/Set_Up_Passwordless_SSH.md#ssh-configuration-files).
* CFS import tool now checks for running sessions before importing data.
  For more details, see [Import](operations/configuration_management/Exporting_and_Importing_CFS_Data.md#import) for more information.
* BOS import tool now checks for running sessions before importing data. For more details,
  see [Import BOS session templates](operations/boot_orchestration/Exporting_and_Importing_BOS_Data.md#exporting-and-importing-bos-data) for more information.

### Documentation enhancements

## Noteworthy changes

## Test

* Modified `adjust k8s_nodes_ready_check.sh` to not fail when a node is in `Ready,SchedulingDisabled` state
* Modified `velero_backups_check.sh` to not fail if a newer, successful backup exists
* Modified `run_hms_ct_tests.sh` to handle concurrency better
* Fixed intermittent failures sometimes seen when running `check_key_id_in_jwks.sh`
* Added retry logic to `goss-postgresql-syncfailed.yaml` to prevent intermittent false positives
* Added retry logic to `postgres_clusters_running.sh to prevent` intermittent false positives
* Added BOS CRUD tests for `sessiontemplates` and `sessions`. `sessions` tests include `staged` and `non staged`.
  These tests are included as part of SMS health checks. Please refer to 
  [Software Management Services health checks](troubleshooting/known_issues/sms_health_check.md#software-management-services-health-checks) for more information.
* Added CFS CRUD tests for `configurations` and `sources`. These tests are included as part of SMS health checks. Please refer to 
  [Software Management Services health checks](troubleshooting/known_issues/sms_health_check.md#software-management-services-health-checks) for more information.

## Bug fixes

* The [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos)
  [`session-setup` operator](operations/boot_orchestration/BOS_Services.md#session-setup) now ignores invalid
  [xnames](glossary.md#xname) referenced by [session templates](operations/boot_orchestration/Session_Templates.md),
  fixing a bug that caused BOS [sessions](operations/boot_orchestration/Sessions.md) to be stuck in `pending` state.
* BOS logging is significantly more memory efficient, fixing a problem where logging on large scale systems
  could cause [BOS operator](operations/boot_orchestration/BOS_Services.md#bos-operators) Kubernetes pods to be `OOMKilled`.
* When using the API or CLI to [Modify a BOS session template](operations/boot_orchestration/Manage_a_Session_Template.md#modify-a-session-template),
  it is no longer required to specify `boot_sets` in the update data (this fixes a regression bug present in CSM 1.6).
* Previously, the CSM 1.5.3 and CSM 1.6.1 releases included changes
  to resolve resource leaks found in the
  [PCS](glossary.md#power-control-service-pcs),
  [SMD](glossary.md#hardware-state-manager-smd),
  `hmcollector`, and [FAS](glossary.md#firmware-action-service-fas)
  services.  This reduced instances of pods being restarted due to
  `OOMKilled` and failed liveness and/or readiness probes.  These
  changes also improved the responsiveness and scalability of these
  services.
    * In the CSM 1.7.0 release, additional resource leaks in these same services were found and resolved.
    * Additionally, similar resource leaks were found and resolved in the following HMS services:
      [BSS](glossary.md#boot-script-service-bss),
      [CAPMC](glossary.md#cray-advanced-platform-monitoring-and-control-capmc),
      River Discovery,
      [HBTD](glossary.md#heartbeat-tracker-daemon-hbtd),
      [MEDS](glossary.md#mountain-endpoint-discovery-service-meds),
      [RTS](glossary.md#redfish-translation-service-rts),
      [HMNFD](glossary.md#hardware-management-notification-fanout-daemon-hmnfd),
      [SCSD](glossary.md#system-configuration-service-scsd),
      [SLS](glossary.md#system-layout-service-sls)
* A bug was fixed in the `hmcollector-poll` service so that event subscriptions are no longer lost after updating Paradise BMC firmware.  The service no longer needs to be restarted after performing firmware updates.
* Fixed an issue where a soft deleted recipe was always assigned the arch `x86_64` regardless of the architecture of the recipe that was deleted.
* Soft deleted recipe was always assigned `require_dkms=true` regardless of the value of the recipe that was deleted.
* Incorrect metadata was stored for newly created IMS images.
* IMS image tags were removed by soft delete.
* Updating CFS session fails causing the session to be stuck in pending state.
* `cfs-debugger` crashes when `cfs-state-reporter` service status does not include `since` timestamp.

## Deprecations

For more details and a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* Support for projecting root filesystems and PE images using the [Content Projection Service (CPS)](glossary.md#content-projection-service-cps) and the
  [Data Virtualization Service (DVS)](glossary.md#data-virtualization-service-dvs)
    * This projection is now done using the [Scalable Boot Projection Service](glossary.md#scalable-boot-projection-service-sbps)
* Top-level Ansible playbooks `ncn-master.yaml`, `ncn-storage.yaml`, and `ncn-worker.yaml` in `csm-config-management` repository in the
  [Version Control Service (VCS)](glossary.md#version-control-service-vcs).
    * These have been replaced by the unified `ncn_nodes.yaml` top-level playbook.

For more details and a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

For a full list of known issues, see [Known issues](troubleshooting/README.md#known-issues).

### Security vulnerability exceptions in CSM 1.7
