# CSM 1.1.0 or later to 1.2.0 Upgrade Process (WIP)
#NOTE: this is a WIP doc

## Introduction

This document is intended to guide an administrator through the upgrade process going from Cray Systems Management v1.1 to v1.2. When upgrading a system, this top-level README.md file should be followed top to bottom, and the content on this top level page is meant to be terse. See the additional files in the various directories under the resource_material directory for additional reference material in support of the process/scripts mentioned explicitly on this page.

## Terminology

Throughout the guide the terms "stable" and "upgrade" are used in the context of the management nodes (NCNs). The
"stable" NCN is the master node from which all of these commands will be run and therefore cannot have its power state
affected. Then the "upgrade" node is the node to next be upgraded.

When doing a rolling upgrade of the entire cluster, at some point you will need to transfer the
responsibility of the "stable" NCN to another master node. However, you do not need to do this before you are ready to
upgrade that node.

>**`IMPORTANT:`**
>
> For TDS systems with only three worker nodes, see [TDS Lower CPU Requests](../../operations/kubernetes/TDS_Lower_CPU_Requests.md) for information on how to lower CPU requests on several services which can improve pod scheduling on smaller systems during this upgrade.  Independently, the `customizations.yaml` file will be edited automatically during upgrade for TDS systems prior to deploying new CSM services. See the file: `/usr/share/doc/csm/upgrade/1.2/scripts/upgrade/tds_cpu_requests.yaml` for these settings. If desired, this file can be modified (prior to proceeding with this upgrade) with different values if other settings are desired in the `customizations.yaml` file for this system. For more information about modifying `customizations.yaml` and tuning based on specific systems, see [Post Install Customizations](https://github.com/Cray-HPE/docs-csm/blob/release/1.2/operations/CSM_product_management/Post_Install_Customizations.md).
>

## Upgrade Stages

- [Stage 0 - Prerequisites](Stage_0_Prerequisites.md)
- [Stage 1 - Kubernetes Upgrade](Stage_1.md)
- [Stage 2 - Ceph Node Image Upgrade](Stage_2.md)
- [Stage 3 - CSM Services Upgrade](Stage_3.md)
- [Stage 4 - Apply Known Workarounds](Stage_4.md)
- [Stage 5 - Return to Main Page and Proceed to *Validate CSM Health*](../index.md#validate_csm_health)

**`Important:`** Please take note of the below content for troubleshooting purposes in the case that you encounter issues.

## Relevant Troubleshooting Links for Upgrade Related Issues

### General Kubernetes Commands for Troubleshooting

Please see [Kubernetes_Troubleshooting_Information](../../troubleshooting/kubernetes/Kubernetes_Troubleshooting_Information.md).

### Troubleshooting PXE Boot Issues

If execution of the upgrade procedures results in NCNs that have errors booting, please refer to these troubleshooting procedures:
[PXE Booting Runbook](../../troubleshooting/pxe_runbook.md)

### Troubleshooting NTP

During execution of the upgrade procedure, if it is noted that there is clock skew on one or more NCNs, the following procedure can be used to troubleshoot NTP config or to sync time:
[Configure NTP on NCNs](../../operations/node_management/Configure_NTP_on_NCNs.md)

### Bare-Metal Etcd Recovery

If in the upgrade process of the master nodes, it is found that the bare-metal etcd cluster (that houses values for the Kubernetes cluster) has a failure,
it may be necessary to restore that cluster from back-up. Please see
[Restore Bare-Metal etcd Clusters from an S3 Snapshot](../../operations/kubernetes/Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md) for that procedure.

### Back-ups for Etcd-Operator Clusters

After upgrading, if health checks indicate that etcd pods are not in a healthy/running state, recovery procedures may be needed. Please see
[Backups for etcd-operator Clusters](../../operations/kubernetes/Backups_for_etcd-operator_Clusters.md) for these procedures.

### Recovering from Postgres Dbase Issues

After upgrading, if health checks indicate the Postgres pods are not in a healthy/running state, recovery procedures may be needed.
Please see [Troubleshoot Postgres Database](../../operations/kubernetes/Troubleshoot_Postgres_Database.md) for troubleshooting and recovery procedures.

### Troubleshooting Spire Pods Not Staring on NCNs

Please see [Troubleshoot SPIRE Failing to Start on NCNs](../../operations/security_and_authentication/Troubleshoot_SPIRE_Failing_to_Start_on_NCNs.md).
`
### Rerun a step/script

When running upgrade scripts, each script record what has been done successfully on a node. This `state` file is stored at `/ect/cray/upgrade/csm/{CSM_VERSION}/{NAME_OF_NODE}/state`. If a rerun is required, you will need to remove the recorded steps from this file.

Here is an example of state file of `ncn-m001`:

```bash
ncn-m001:~ # cat /etc/cray/upgrade/csm/{CSM_VERSION}/ncn-m001/state
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

* See the inline comment above on how to rerun a single step
* If you need to rerun the whole upgrade of a node, you can just delete the state file
