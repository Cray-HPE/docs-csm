# CSM 1.0.0 or later to 1.2.0 Upgrade Process

## Introduction

This document is intended to guide an administrator through the upgrade process going from Cray Systems Management v1.0 to v1.2. When upgrading a system, this top-level `README.md`
file should be followed top to bottom, and the content on this top level page is meant to be terse. See the additional files in the various directories under the
[`resource_material` directory](resource_material/README.md)
for additional reference material in support of the processes and scripts mentioned explicitly on this page.

## Notes

- **`Important:`** The SMA Grafana service is temporarily inaccessible during the upgrade.
During stage 3 of the CSM 1.2 upgrade, SMA's Grafana service will become inaccessible at the previous DNS location until the upgrade to SMA 1.6.x is applied. This is due to a change in DNS names for the service.

- Service request adjustments made for small systems.
For systems with only three worker nodes (typically Testing and  Development Systems (TDS)), prior to proceeding with this upgrade, CPU limits **MUST** be lowered on several
services in order for this upgrade to succeed. This step is
executed automatically as part of [Stage 0.4](Stage_0_Prerequisites.md#stage-04---prerequisites-check). See [TDS Lower CPU Requests](../../operations/kubernetes/TDS_Lower_CPU_Requests.md) for more
information.

Independently, the `customizations.yaml` file will be edited automatically during upgrade for three worker systems prior to deploying new CSM services. See the file
`/usr/share/doc/csm/upgrade/1.2/scripts/upgrade/tds_cpu_requests.yaml` for these settings. This file can be modified (prior to proceeding with this upgrade), if other settings
are desired in the `customizations.yaml` file for this system.

For more information about modifying `customizations.yaml` and tuning for specific systems, see
[Post Install Customizations](../../operations/CSM_product_management/Post_Install_Customizations.md).

## Plan and coordinate network upgrade

Prior to CSM 1.2, the single Customer Access Network (CAN) carried both the administrative network traffic and the user network
traffic. CSM 1.2 introduces bifurcated CAN (BICAN), which is designed to separate administrative network traffic and user network traffic.

[Plan and coordinate network upgrade](plan_and_coordinate_network_upgrade.md) shows the steps that need to be taken in order to prepare
for this network upgrade. Follow these steps in order to plan and coordinate the network upgrade with your users, as well as to ensure
undisrupted access to UANs during the upgrade.

## Upgrade stages

- [Stage 0 - Prerequisites](Stage_0_Prerequisites.md)
- [Stage 1 - Ceph Node Image Upgrade](Stage_1.md)
- [Stage 2 - Kubernetes Upgrade](Stage_2.md)
- [Stage 3 - CSM Services Upgrade](Stage_3.md)
- [Stage 4 - Ceph Upgrade](Stage_4.md)
- [Stage 5 - Perform NCN Personalization](Stage_5.md)
- [Return to Main Page and Proceed to *Validate CSM Health*](../README.md#6-validate-csm-health)

**`Important:`** Take note of the below content for troubleshooting purposes, in the event that issues are encountered during the upgrade process.

## Relevant troubleshooting links for upgrade-related issues

- General upgrade troubleshooting

  If the execution of the upgrade procedure fails, it is safe to rerun the failed script. If a rerun still fails, wait for 10 seconds and then run it again. If the issue persists, then refer to the below troubleshooting procedures.

- General Kubernetes troubleshooting

   For general Kubernetes commands for troubleshooting, see [Kubernetes Troubleshooting Information](../../troubleshooting/kubernetes/Kubernetes_Troubleshooting_Information.md).

- Troubleshooting PXE Boot Issues

   If execution of the upgrade procedures results in NCNs that have errors booting, then refer to the troubleshooting procedures in the
   [PXE Booting Runbook](../../troubleshooting/pxe_runbook.md).

- Troubleshooting NTP

   During upgrades, clock skew may occur when rebooting nodes. If one node is rebooted and its clock differs significantly from those that have **not** been rebooted, it can
   cause contention among the other nodes. Waiting for `chronyd` to slowly adjust the clocks can resolve intermittent clock skew issues. This can take up to 15 minutes or
   longer. If it does not resolve on its own, then follow the [Configure NTP on NCNs](../../operations/node_management/Configure_NTP_on_NCNs.md) procedure to troubleshoot it further.

- Bare-metal Etcd recovery

   During the upgrade process of the master nodes, if it is found that the bare-metal Etcd cluster (that houses values for the Kubernetes cluster) has a failure,
   it may be necessary to restore that cluster from backup. See
   [Restore Bare-Metal etcd Clusters from an S3 Snapshot](../../operations/kubernetes/Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md) for that procedure.

- Back-ups for `etcd-operator` Clusters

   After upgrading, if health checks indicate that Etcd pods are not in a healthy/running state, recovery procedures may be needed. See
   [Backups for `etcd-operator` Clusters](../../operations/kubernetes/Backups_for_etcd-operator_Clusters.md) for these procedures.

- Recovering from Postgres database issues

   After upgrading, if health checks indicate the Postgres pods are not in a healthy/running state, recovery procedures may be needed.
   See [Troubleshoot Postgres Database](../../operations/kubernetes/Troubleshoot_Postgres_Database.md) for troubleshooting and recovery procedures.

- Troubleshooting Spire pods not starting on NCNs

   See [Troubleshoot Spire Failing to Start on NCNs](../../operations/spire/Troubleshoot_Spire_Failing_to_Start_on_NCNs.md).

- Troubleshoot SLS not working

    See [SLS Not Working During Node Rebuild](../../troubleshooting/known_issues/SLS_Not_Working_During_Node_Rebuild.md).

- Rerun a step

   When running upgrade scripts, each script records what has been done successfully on a node. This is recorded in the
   `/etc/cray/upgrade/csm/{CSM_VERSION}/{NAME_OF_NODE}/state` file.
   If a rerun is required, the recorded steps to be re-run must be removed from this file.

   Here is an example of state file of `ncn-m001`:

   ```console
   cat /etc/cray/upgrade/csm/csm-{CSM_VERSION}/ncn-m001/state
   ```

   Example output:

   ```text
   [2021-07-22 20:05:27] UNTAR_CSM_TARBALL_FILE
   [2021-07-22 20:05:30] INSTALL_CSI
   [2021-07-22 20:05:30] INSTALL_WAR_DOC
   [2021-07-22 20:13:15] SETUP_NEXUS
   [2021-07-22 20:13:16] UPGRADE_BSS <=== Remove this line if you want to rerun this step
   [2021-07-22 20:16:30] CHECK_CLOUD_INIT_PREREQ
   [2021-07-22 20:19:17] APPLY_POD_PRIORITY
   [2021-07-22 20:19:38] UPDATE_BSS_CLOUD_INIT_RECORDS
   [2021-07-22 20:19:38] UPDATE_CRAY_DHCP_KEA_TRAFFIC_POLICY
   [2021-07-22 20:21:03] UPLOAD_NEW_NCN_IMAGE
   [2021-07-22 20:21:03] EXPORT_GLOBAL_ENV
   [2021-07-22 20:50:36] PREFLIGHT_CHECK
   [2021-07-22 20:50:38] UNINSTALL_CONMAN
   [2021-07-22 20:58:39] INSTALL_NEW_CONSOLE
   ```

  - See the inline comment above on how to rerun a single step.
  - In order to rerun the whole upgrade of a node, delete the state file.
