# Backups for etcd-operator Clusters

Backups are periodically created for etcd clusters. These backups are stored in the Ceph Rados Gateway \(S3\). Not all services are backed up automatically.
Services that are not backed up automatically will need to be manually rediscovered if the cluster is unhealthy.

- [Clusters with automated backups](#clusters-with-automated-backups)
- [Clusters without automated backups](#clusters-without-automated-backups)
- [Check status of etcd cluster backups](#check-status-of-etcd-cluster-backups)
- [Check backup status for a specific etcd cluster](#check-backup-status-for-a-specific-etcd-cluster)

## Clusters with automated backups

The following services are backed up daily \(one week of backups retained\) as part of the automated solution:

- Boot Orchestration Service \(BOS\)
- Boot Script Service \(BSS\)
- Compute Rolling Upgrade Service \(CRUS\)
- Firmware Action Service \(FAS\)
- User Access Service \(UAS\)

If these clusters are lacking a recent backup, create a manual backup for that service by following the
[Create a Manual Backup of a Healthy etcd Cluster](Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md) procedure.

## Clusters without automated backups

The following projects are not backed up as part of the automated solution:

- Content Projection Service \(CPS\)
- Heartbeat Tracking Daemon \(HBTD\)
- HMS Notification Fanout Daemon \(HMNFD\)
- River Endpoint Discovery Service \(REDS\)

If these clusters become unhealthy, the process for rediscovering their data should be followed.
See [Repopulate Data in etcd Clusters When Rebuilding Them](Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md).

## Check status of etcd cluster backups

(`ncn-mw#`) To view all available etcd backups across all clusters

```bash
/opt/cray/platform-utils/ncnHealthChecks.sh -s etcd_backups_check
```

Example output:

```text
**************************************************************************

=== List automated etcd backups on system. ===
=== Etcd Clusters with Automatic Etcd Back-ups Configured: ===
=== BOS, BSS, CRUS, and FAS ===
=== May want to ensure that automated back-ups are up to-date ===
=== and that automated back-ups continue after NCN worker reboot. ===
=== Clusters without Automated Backups: ===
=== HBTD, HMNFD, REDS, UAS & CPS ===
=== Automatic backups generated after cluster has been running 24 hours. ===
=== date; kubectl exec -it -n operators $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') -c boto3 -- list_backups <cluster> ; ===
Fri 07 Jun 2024 08:22:48 PM UTC

-- cray-bos -- backups
cray-bos/etcd.backup_v1906358_2024-06-01-18:40:10
cray-bos/etcd.backup_v1911014_2024-06-02-18:40:10
cray-bos/etcd.backup_v1915722_2024-06-03-18:40:10
cray-bos/etcd.backup_v1920319_2024-06-04-18:40:10
cray-bos/etcd.backup_v1924894_2024-06-05-18:40:10
cray-bos/etcd.backup_v1929230_2024-06-06-18:40:10
cray-bos/etcd.backup_v1933567_2024-06-07-18:40:10
cray-bos/post_install.backup_2023-01-09-12:01:35
cray-bos/post_upgrade.backup_2023-09-06-19:58:11
PASS: backup found less than 24 hours old.

-- cray-bss -- backups
cray-bss/etcd.backup_v3365197_2024-06-01-18:03:17
cray-bss/etcd.backup_v3369567_2024-06-02-18:03:17
cray-bss/etcd.backup_v3374611_2024-06-03-18:03:17
cray-bss/etcd.backup_v3382276_2024-06-04-18:03:17
cray-bss/etcd.backup_v3389117_2024-06-05-18:03:17
cray-bss/etcd.backup_v3395127_2024-06-06-18:03:17
cray-bss/etcd.backup_v3401174_2024-06-07-18:03:17
cray-bss/post_install.backup_2023-01-09-12:01:36
cray-bss/post_upgrade.backup_2023-09-06-19:58:12
PASS: backup found less than 24 hours old.

[...]

 --- PASSED --- 

```

The returned output includes the date and time of the latest backup for each service. If a recent backup for any service is not included, it is an indication
that the service is not backed up automatically. Create a manual backup for that service by following the
[Create a Manual Backup of a Healthy etcd Cluster](Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md) procedure.

## Check backup status for a specific etcd cluster 

(`ncn-mw#`) Run the following command to list the backups for a specific project.
In the example below, the backups for BSS are listed.

```bash
kubectl exec -it -n operators \
    $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') \
    -c boto3 -- list_backups cray-bss
```

Example output:

```text
cray-bss/etcd.backup_v1450_2020-01-30-20:44:41
cray-bss/etcd.backup_v4183_2020-02-01-20:45:48
cray-bss/etcd.backup_v5771_2020-02-02-20:45:48
cray-bss/etcd.backup_v7210_2020-02-03-20:45:48
```

The returned output includes the date and time of the latest backup for this etcd cluster. If a recent backup is not included, it is an indication
that the service is not backed up automatically. Create a manual backup for that service by following the
[Create a Manual Backup of a Healthy etcd Cluster](Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md) procedure.

