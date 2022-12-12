# CSM 1.0.x to 1.2.x Upgrade Process

## Introduction

This document guides an administrator through the upgrade of Cray Systems Management from v1.0.x to v1.2.x. When upgrading a system, follow this top-level file
from top to bottom. The content on this top-level page is meant to be terse. For additional reference material on the upgrade processes and scripts
mentioned explicitly on this page, see [resource material](resource_material/README.md).

If upgrading from CSM 1.0.x to 1.2.0, then instead upgrade directly to the latest released version of CSM 1.2.x.

A major feature of CSM 1.2.x is the Bifurcated CAN (BICAN). The BICAN is designed to separate administrative network traffic from user network traffic.
For more information, see the [BICAN Summary](../../operations/network/management_network/bican_technical_summary.md).
Review the BICAN Summary before continuing with the CSM 1.2.x upgrade.

For detailed BICAN documentation, see the [BICAN Technical Details](../../operations/network/management_network/bican_technical_details.md) page.

## Important Notes

- The SMA Grafana service is temporarily inaccessible during the upgrade.

  During stage 3 of the CSM 1.2.x upgrade, the SMA Grafana service will become inaccessible at its previous DNS location. It will
  remain inaccessible until the upgrade to SMA 1.6.x is applied. This is because of a change in DNS names for the service.

- Service request adjustments are needed for small systems.

  - For systems with only three worker nodes (typically Testing and Development Systems (TDS)), prior to proceeding with this upgrade, CPU limits **MUST** be
    lowered on several services in order for this upgrade to succeed. This step is
    executed automatically as part of [Stage 0.4](Stage_0_Prerequisites.md#prerequisites-check) of the upgrade.
    See [TDS Lower CPU Requests](../../operations/kubernetes/TDS_Lower_CPU_Requests.md) for more information.

  - Independently, for three-worker systems the `customizations.yaml` file is edited automatically during the upgrade, prior to deploying new CSM services. These
    settings are contained in `/usr/share/doc/csm/upgrade/1.2/scripts/upgrade/tds_cpu_requests.yaml`. This file can be modified (prior to proceeding with this
    upgrade), if other settings are desired in the `customizations.yaml` file for this system.

    For more information about modifying `customizations.yaml` and tuning for specific systems, see
    [Post Install Customizations](../../operations/CSM_product_management/Post_Install_Customizations.md).

## Known issues

- `kdump` (kernel dump) may hang and fail on NCNs in CSM 1.2.x (HPE Cray EX System Software 22.07 release). During the upgrade, a workaround is applied to fix this.
- The boot order on NCNs may not be correctly set. Because of a bug, the disk entries may be listed ahead of the PXE entries. During the upgrade, a workaround is applied to fix this.

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
- [Return to Main Page and Proceed to *Validate CSM Health*](../index.md#validate_csm_health)

**Important:** Take note of the below content for troubleshooting purposes, in the event that issues are encountered during the upgrade process.

## Relevant troubleshooting links for upgrade-related issues

- General upgrade troubleshooting

  If the execution of the upgrade procedure fails, it is safe to rerun the failed script. If a rerun still fails, wait for 10 seconds and then run it again. If the issue persists, then refer to the below troubleshooting procedures.

- General Kubernetes troubleshooting

   For general Kubernetes commands for troubleshooting, see [Kubernetes Troubleshooting Information](../../troubleshooting/kubernetes/Kubernetes_Troubleshooting_Information.md).

- PXE boot troubleshooting

   If execution of the upgrade procedures results in NCNs that have errors booting, then refer to the troubleshooting procedures in the
   [PXE Booting Runbook](../../troubleshooting/pxe_runbook.md).

- NTP troubleshooting

   During upgrades, clock skew may occur when rebooting nodes. If one node is rebooted and its clock differs significantly from those that have **not** been rebooted, it can
   cause contention among the other nodes. Waiting for `chronyd` to slowly adjust the clocks can resolve intermittent clock skew issues. This can take up to 15 minutes or
   longer. If it does not resolve on its own, then follow the [Configure NTP on NCNs](../../operations/node_management/Configure_NTP_on_NCNs.md) procedure to troubleshoot it further.

- Bare-metal Etcd recovery

   During the upgrade process of the master nodes, if it is found that the bare-metal Etcd cluster (that houses values for the Kubernetes cluster) has a failure,
   it may be necessary to restore that cluster from backup. See
   [Restore Bare-Metal etcd Clusters from an S3 Snapshot](../../operations/kubernetes/Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md) for that procedure.

- Bare-metal Etcd certificate

   After upgrading, the `apiserver-etcd-client` certificate may need to been renewed. See [Kubernetes and Bare Metal EtcD Certificate Renewal](../../operations/kubernetes/Cert_Renewal_for_Kubernetes_and_Bare_Metal_EtcD.md#renew-etcd-certificate)
   for procedures to check and renew this certificate.

- Back-ups for `etcd-operator` Clusters

   After upgrading, if health checks indicate that Etcd pods are not in a healthy/running state, recovery procedures may be needed. See
   [Backups for `etcd-operator` Clusters](../../operations/kubernetes/Backups_for_etcd-operator_Clusters.md) for these procedures.

- Recovering from Postgres database issues

   After upgrading, if health checks indicate the Postgres pods are not in a healthy/running state, recovery procedures may be needed.
   See [Troubleshoot Postgres Database](../../operations/kubernetes/Troubleshoot_Postgres_Database.md) for troubleshooting and recovery procedures.

- Troubleshooting Spire pods not starting on NCNs

   See [Troubleshoot Spire Failing to Start on NCNs](../../operations/spire/Troubleshoot_Spire_Failing_to_Start_on_NCNs.md).

- Fixing `shared-kafka` `kafka` cluster after upgrade

   See [Kafka Failure after CSM 1.2 Upgrade](../../troubleshooting/known_issues/kafka_upgrade_failure.md)

- Troubleshoot SLS not working

    See [SLS Not Working During Node Rebuild](../../troubleshooting/known_issues/SLS_Not_Working_During_Node_Rebuild.md).

- Rerun a step

   When running upgrade scripts, each script records what has been done successfully on a node. This is recorded in the
   `/etc/cray/upgrade/csm/{CSM_VERSION}/{NAME_OF_NODE}/state` file.
   If a rerun is required, the recorded steps to be re-run must be removed from this file.

   Here is an example of state file of `ncn-m001`:

   ```bash
   ncn# cat /etc/cray/upgrade/csm/{CSM_VERSION}/ncn-m001/state
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
  - In order to rerun the whole upgrade of a node, delete its state file.
