# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.6 contains many changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

* v1 of Power Control Service (PCS) is active.

### Monitoring

### Networking

### Miscellaneous functionality

* The [System Admin Toolkit (SAT)](glossary.md#system-admin-toolkit-sat) is fully included
in CSM. There is no longer a separate SAT product stream to install. SAT 2.6 releases,
which accompanied CSM 1.5, are the last releases of SAT as a separate product. For more
information, see [SAT in CSM](operations/system_admin_toolkit/about_sat/SAT_in_CSM.md).

### New hardware support

* CSM 1.6.1 supports systems with NVIDIA CPUs and GPUs. CSM 1.6.0 does not support NVIDIA hardware.

### New software support

* Bump `iuf-cli` version to 1.6.15
* Bump `cray-nls` version to 4.0.15
* Added support to upgrade CSM through IUF
* Added support for iSCSI based boot content projection for `rootfs` and `PE` images

### Automation improvements

### Base platform component upgrades

| Platform Component           | Version        |
|------------------------------|----------------|
| `Kubernetes`                 | 1.24.17        |
| `istio`                      | 1.19.10        |
| `kiali`                      | 1.75.0         |
| `Strimzi Kafka`              | 0.41.0         |
| `Kyverno`                    | 1.10.7         |

### Security improvements

* `Kyverno` is upgraded from 1.9.5 version to 1.10.7 version to address CVEs.

### Customer-requested enhancements

* iSCSI based boot content projection for `rootfs` and `PE` images.

### Documentation enhancements

* Upgrade documentation modified to support CSM upgrade only through IUF
* Diagram and procedures for `Upgrade CSM and additional products with IUF` updated
* Updated `Kyverno` documentation
* Added documentation about iSCSI based boot content projection for `rootfs` and `PE` images
* The SAT documentation moved to be fully included within the [System Admin Toolkit (SAT)](https://cray-hpe.github.io/docs-csm/en-16/operations/system_admin_toolkit/) section of the [CSM Administration Guide](https://cray-hpe.github.io/docs-csm/en-16/operations/).

## Noteworthy changes

* CSM can now be upgraded with IUF. See [Upgrade CSM](upgrade/README.md) for more details.
* The [BOS](glossary.md#boot-orchestration-service-bos) API now enforces limits that previously had
  only been recommended. When updating to CSM 1.6, BOS data is migrated to be in compliance with the
  API specification. See [BOS data notice](upgrade/README.md#bos-data-notice) for more details.
* Please see [iSCSI SBPS](https://github.com/Cray-HPE/docs-csm/blob/release/1.6/operations/iscsi_sbps/iscsi_sbps.md) for
  details on iSCSI based boot content projection for `rootfs` and `PE` images.

## Bug fixes

* Fix for scheduling the execution of `management-nodes-rollout` stage for `ncn-m001` in `ncn-m002`
* Fix for `iuf cli` failure when `abort` command is executed with no arguments
* Fix for `iuf cli` failure when `media_dir` is not passed in command line

## Deprecations

* `sat swap cable` and `sat swap switch` commands
* [Data Virtualization Service (DVS)](glossary.md#data-virtualization-service-dvs)

For more details and a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* [BOS](glossary.md#boot-orchestration-service-bos) v1
* User Access Service
* User Access Instance

For more details and a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

* CSM 1.6.0 does not support servers with NVIDIA CPUs and GPUs. Systems with these servers should not be upgraded to CSM 1.6.0.
* CSM 1.6.1 and later supports servers with NVIDIA CPUs and GPUs.
* After updating Paradise BMC firmware, the `hmcollector-poll` service will lose event subscriptions and must be restarted
    * See [Updating Foxconn Paradise Nodes with FAS](operations/firmware/FAS_Paradise.md) for details on how to do this
* `cfs-api` pods in CLBO state during CSM install.
    * When installing CSM 1.6, `cray-shared-kafka-kafka-` pods in the services namespace fail to come up which results in `cfs-api` pods in CLBO state.
    * A workaround is presented in [CFS API pods in CLBO](troubleshooting/known_issues/cfs-api_pods_in_CLBO_state.md).
* `istio-proxy` containers fail with too many open files.
    * This may happen when any pod with `istio injection` enabled is started.
    * A workaround is presented in [Istio-Proxy failing with too many open files](troubleshooting/known_issues/Istio-Proxy_failing_with_too_many_open_files.md)
* IUF does not run the next stage for an activity
    * During CSM upgrade, IUF reports that multiple sessions are in progress for an activity.
    * A workaround is presented in [IUF does not run the next stage for an activity](troubleshooting/known_issues/iuf_unable_to_run_next_stage.md)
* iSCSI based boot content projection may fail
    * If the image to be projected does not have an `etag`
    * A workaround is presented in [iSCSI SBPS boot failure](https://github.com/Cray-HPE/docs-csm/blob/release/1.6/troubleshooting/known_issues/SBPS_boot_fail.md)

### Security vulnerability exceptions in CSM 1.6
