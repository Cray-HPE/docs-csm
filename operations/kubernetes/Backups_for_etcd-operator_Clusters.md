# Backups for etcd-operator Clusters

Backups are periodically created for etcd clusters. These backups are stored in the Ceph Rados Gateway \(S3\). Not all services are backed up automatically. Services that are not backed up automatically will need to be manually rediscovered if the cluster is unhealthy.

### Clusters with Automated Backups

The following services are backed up \(daily, one week's worth of backups retained\) as part of the automated solution:

-   Boot Orchestration Service \(BOS\)
-   Boot Script Service \(BSS\)
-   Compute Rolling Upgrade Service \(CRUS\)
-   External DNS
-   Firmware Action Service \(FAS\)

Run the following command on any master node \(`ncn-mXXX`\) or the first worker node \(`ncn-w001`\) to list the backups for a specific project. In the example below, the backups for BSS are listed.

```bash
ncn-w001# kubectl exec -it -n operators $(kubectl get pod -n operators \
| grep etcd-backup-restore | head -1 | awk '{print $1}') -c boto3 -- list_backups cray-bss
cray-bss/etcd.backup_v1450_2020-01-30-20:44:41
cray-bss/etcd.backup_v4183_2020-02-01-20:45:48
cray-bss/etcd.backup_v5771_2020-02-02-20:45:48
cray-bss/etcd.backup_v7210_2020-02-03-20:45:48
```

To view all available backups across all projects:

```bash
ncn-w001# kubectl exec -it -n operators $(kubectl get pod -n operators \
| grep etcd-backup-restore | head -1 | awk '{print $1}') -c boto3 -- list_backups ""
bare-metal/etcd-backup-2020-02-03-14-40-07.tar.gz
bare-metal/etcd-backup-2020-02-03-14-50-03.tar.gz
bare-metal/etcd-backup-2020-02-03-15-00-10.tar.gz
bare-metal/etcd-backup-2020-02-03-15-10-06.tar.gz
bare-metal/etcd-backup-2020-02-03-15-30-05.tar.gz
bare-metal/etcd-backup-2020-02-03-15-40-01.tar.gz
bare-metal/etcd-backup-2020-02-03-15-50-08.tar.gz
cray-bos/etcd.backup_v1200_2020-02-03-20:45:48
cray-bos/etcd.backup_v240_2020-01-30-20:44:34
cray-bos/etcd.backup_v480_2020-01-31-20:44:34
cray-bos/etcd.backup_v720_2020-02-01-20:45:48
cray-bos/etcd.backup_v960_2020-02-02-20:45:48
cray-bss/etcd.backup_v1450_2020-01-30-20:44:41
cray-bss/etcd.backup_v4183_2020-02-01-20:45:48
cray-bss/etcd.backup_v5771_2020-02-02-20:45:48
cray-bss/etcd.backup_v7210_2020-02-03-20:45:48
cray-crus/etcd.backup_v1_2020-01-30-20:44:48
cray-crus/etcd.backup_v1_2020-02-01-20:45:48
cray-crus/etcd.backup_v1_2020-02-02-20:45:48
cray-crus/etcd.backup_v1_2020-02-03-20:45:48
cray-externaldns/etcd.backup_v2_2020-01-30-20:44:55
cray-externaldns/etcd.backup_v2_2020-02-01-20:45:48
cray-externaldns/etcd.backup_v2_2020-02-02-20:45:48
cray-fas/etcd.backup_v60303_2020-02-03-20:45:48
cray-fas/etcd.backup_v63195_2020-01-30-20:44:55
cray-fas/etcd.backup_v66092_2020-02-01-20:45:48
cray-fas/etcd.backup_v68972_2020-02-02-20:45:48
cray-fas/etcd.backup_v71858_2020-02-03-20:45:48
```

The returned output includes the date and time of the latest backup for each service. If a recent backup for any service is not included, it is an indication that the service is not backed up automatically. Create a manual backup for that service by following the [Create a Manual Backup of a Healthy etcd Cluster](Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md) procedure.

### Clusters without Automated Backups

The following projects are not backed up as part of the automated solution:

-   Heartbeat Tracking Daemon \(HBTD\)
-   HMS Notification Fanout Daemon \(HMNFD\)
-   River Endpoint Discovery Service \(REDS\)
-   User Access Service \(UAS\) Manager
-   Content Projection Service \(CPS\)

If these clusters become unhealthy, the process for rediscovering their data should be followed. See [Repopulate Data in etcd Clusters When Rebuilding Them](Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md).

