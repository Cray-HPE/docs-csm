# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.7 contains many changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

### Monitoring

### Networking

### Miscellaneous functionality

* Console logs and interaction is now available and tenant aware through the `cray` CLI, see [console](operations/conman/ConMan.md#console) for more information.
* [Configuration Framework Service (CFS)](glossary.md#configuration-framework-service-cfs) components can now be updated in bulk through the [Cray CLI (`cray`)](glossary.md#cray-cli-cray).
  See [Managing many components](operations/configuration_management/CFS_Commands_Cheat_Sheet.md#managing-many-components) for more information.
  Support is added for `v2` and `v3` API versions.
* Recipe builds using kiwi-ng now include the signing keys contained in the `hpe-signing-key` secret, which allows for the verification of the recipe build artifacts.

### New hardware support

### New software support

### Automation improvements

### Base platform component upgrades

| Platform Component           | Version |
|------------------------------|---------|
| `Kubernetes`                 | 1.32.5  |
| `Kyverno`                    | 1.13.4  |
| `Strimzi Kafka`              | 0.45.0  |
| `argo-workflow-controller`   | 3.4.5   |
| `argo-workflows`             | 3.4.5   |
| `bitnami-etcd` for clusters  | 3.5.21  |
| `etcd` on `ncn-mxxx`         | 3.5.18  |
| `ceph`                       | 17.2.6  |
| `containerd`                 | 1.7.27  |
| `coredns`                    | 1.11.3  |
| `cray-certmanager`           | 1.17.0  |
| `cray-externaldns`           | 0.15.0  |
| `cray-metallb`               | 0.14.9  |
| `cray-node-problem-detector` | 0.8.20  |
| `cray-spire`                 | 1.5.5   |
| `cray-vault-operator`        | 1.22.5  |
| `cray-velero`                | 10.0.1  |
| `helm`                       | 3.18.3  |
| `istio`                      | 1.26.0  |
| `kata`                       | 3.17.0  |
| `keycloak`                   | 21.1.1  |
| `kiali`                      | 2.10.0  |
| `metrics-server`             | 0.6.3   |
| `nexus`                      | 3.70.4  |
| `pause`                      | 3.10    |
| `postgres-operator`          | 1.10.1  |
| `postgresql`                 | 15.2    |
| `sealed-secrets`             | 0.28.0  |
| `spire-intermediate`         | 1.0.1   |
| `tapms-operator`             | 1.9.1   |

### Security improvements

* Spire node attestation can now be setup to use TPM chips on supported platforms, see [Enable TPM node attestation with Spire](operations/spire/Enable_TPM_node_attestation.md) for more information.
* The old version of the Spire server was removed to fully transition to the newer version of Spire.

### Customer-requested enhancements

* CSM now provides the `csm.ssh_config` Ansible role to automatically restore the root user's SSH configuration file during
  [Management Node Personalization](operations/configuration_management/Management_Node_Personalization.md).
  For more details, see [SSH configuration files](operations/CSM_product_management/Set_Up_Passwordless_SSH.md#ssh-configuration-files).
* [CFS](glossary.md#configuration-framework-service-cfs) import tool now checks for running sessions before importing data.
  For more details, see [Import](operations/configuration_management/Exporting_and_Importing_CFS_Data.md#import).
* [BOS](glossary.md#boot-orchestration-service-bos) import tool now checks for running sessions before importing data. For more details,
  see [Import BOS session templates](operations/boot_orchestration/Exporting_and_Importing_BOS_Data.md#exporting-and-importing-bos-data).
* When a [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos) session starts,
  any nodes that are locked in the [Hardware State Manager (HSM)](glossary.md#hardware-state-manager-hsm) are removed from the session.
  For more information, see [BOS sessions and HSM locks](operations/boot_orchestration/Sessions.md#bos-sessions-and-hsm-locks).

### Documentation enhancements

## Noteworthy changes

## Test

* Modified `adjust k8s_nodes_ready_check.sh` to not fail when a node is in `Ready,SchedulingDisabled` state
* Modified `velero_backups_check.sh` to not fail if a newer, successful backup exists
* Modified `run_hms_ct_tests.sh` to handle concurrency better
* Fixed intermittent failures sometimes seen when running `check_key_id_in_jwks.sh`
* Added retry logic to `goss-postgresql-syncfailed.yaml` to prevent intermittent false positives
* Added retry logic to `postgres_clusters_running.sh to prevent` intermittent false positives
* Added tests to the Software Management Services (SMS) health checks:
    * Added [BOS](glossary.md#boot-orchestration-service-bos) create/update/delete (CRUD) tests for session templates and sessions.
    * Added [CFS](glossary.md#configuration-framework-service-cfs) CRUD tests for configurations and sources.
    * Added [IMS](glossary.md#image-management-service-ims) CRUD tests for images, recipes, and public keys.
    * These tests are part of the procedure to [Validate CSM Health](operations/validate_csm_health.md).
    * For more information on the SMS health checks, see
      [Software Management Services health checks](troubleshooting/known_issues/sms_health_check.md#software-management-services-health-checks).
* Added [CFS](glossary.md#configuration-framework-service-cfs) node personalization to the barebones image boot test.
    * This tests is part of the procedure to [Validate CSM Health](operations/validate_csm_health.md).
    * For more information, see [Barebones Image Boot Test](troubleshooting/cms_barebones_image_boot.md).

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
* Fixed an issue where a soft deleted IMS recipe was always assigned the architecture `x86_64`, regardless of the architecture of the recipe that was deleted.
* Fixed an issue where a soft deleted IMS recipe was always assigned `require_dkms=true`, regardless of the value of the recipe that was deleted.
* Fixed an issue where incorrect metadata was stored for newly created IMS images.
* Fixed an issue where IMS image tags were removed by a soft delete.
* Fixed an issue where updating a CFS session could fail and cause the session to be stuck in pending state.
* Fixed an issue where `cfs-debugger` crashed when `cfs-state-reporter` service status did not include a `since` timestamp.
* Fixed an issue where the post-upgrade job of `cms-ipxe` would fail if a previously failed `cms-ipxe` upgrade job entry existed.
* Fixed an issue where, when building an IMS image from a recipe, the job status would not update to `error` when the `zypper` repositories were not available.

## Deprecations

For more details and a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* Support for projecting root filesystems and PE images using the [Content Projection Service (CPS)](glossary.md#content-projection-service-cps) and the
  [Data Virtualization Service (DVS)](glossary.md#data-virtualization-service-dvs).
    * This projection is now done using the [Scalable Boot Projection Service](glossary.md#scalable-boot-projection-service-sbps).
* Top-level Ansible playbooks `ncn-master.yaml`, `ncn-storage.yaml`, and `ncn-worker.yaml` in `csm-config-management` repository in the
  [Version Control Service (VCS)](glossary.md#version-control-service-vcs).
    * These have been replaced by the unified `ncn_nodes.yaml` top-level playbook.
* Experimental `disable_components_on_completion` [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos)
  [option](operations/boot_orchestration/Options.md).

For more details and a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

For a full list of known issues, see [Known issues](troubleshooting/README.md#known-issues).

### Security vulnerability exceptions in CSM 1.7
