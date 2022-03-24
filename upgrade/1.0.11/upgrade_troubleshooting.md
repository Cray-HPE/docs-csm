# Relevant Troubleshooting Links for Upgrade Related Issues

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

### Recovering from Postgres Database Issues

After upgrading, if health checks indicate the Postgres pods are not in a healthy/running state, recovery procedures may be needed.
Please see [Troubleshoot Postgres Database](../../operations/kubernetes/Troubleshoot_Postgres_Database.md) for troubleshooting and recovery procedures.

### Troubleshooting Spire Pods Not Starting on NCNs

Please see [Troubleshoot Spire Failing to Start on NCNs](../../operations/spire/Troubleshoot_Spire_Failing_to_Start_on_NCNs.md).

### Troubleshooting CFS Sessions That Can't Find Playbooks

Due to an issue with the Ansible content import logic, the git commit ids for some
release branches may have changed, making old CFS configurations invalid.  If CFS
fails to find the specified playbook, or fails to checkout the appropriate commit
in the `git-clone` containers, check that the commit still exists by manually
cloning the git repo and attempting to checkout the commit.  If it no longer exists,
find the most recent commit id for the desired branch and update the configuration
as usual for CFS.  This will be fixed in a future version.

### Rerun a step or script

When running upgrade scripts, each script records what has been done successfully on a node. This `state` file is stored at `/etc/cray/upgrade/csm/{CSM_VERSION}/{NAME_OF_NODE}/state`. If a rerun is required, you will need to remove the recorded steps from this file.

Here is an example of the state file for `ncn-m001`:

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

* See the inline comment above on how to rerun a single step.
* If you need to rerun the whole upgrade of a node, delete the state file.
