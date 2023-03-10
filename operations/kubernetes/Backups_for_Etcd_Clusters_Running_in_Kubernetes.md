# Backups for Etcd Clusters Running in Kubernetes

Backups are periodically created for etcd clusters. These backups are stored in the Ceph Rados Gateway \(S3\). Not all services are backed up automatically.
Services that are not backed up automatically will need to be manually rediscovered if the cluster is unhealthy.

- [Clusters with automated backups](#clusters-with-automated-backups)
- [Clusters without automated backups](#clusters-without-automated-backups)

## Clusters with automated backups

The following services are backed up daily \(one week of backups retained\) as part of the automated solution:

- Boot Orchestration Service \(BOS\)
- Boot Script Service \(BSS\)
- Firmware Action Service \(FAS\)
- User Access Service \(UAS\)

(`ncn-mw#`) Run the following command on any Kubernetes master or worker node in order to list the backups for a specific project.
In the example below, the backups for BSS are listed.

```bash
/opt/cray/platform-utils/etcd/etcd-util.sh list_backups cray-bss
```

Example output:

```text
cray-bss/db-2023-03-08_23-00
cray-bss/db-2023-03-09_00-00
cray-bss/db-2023-03-09_01-00
```

(`ncn-mw#`) To view all available backups across all projects:

```bash
/opt/cray/platform-utils/etcd/etcd-util.sh list_backups -
```

Example output:

```text
cray-bss/etcd.backup_v4508_2023-03-08-01:00:03
cray-crus/etcd.backup_v1_2023-03-08-01:00:03
cray-fas/etcd.backup_v2963_2023-03-08-01:00:04
cray-bss/etcd.backup_v8828_2023-03-09-01:00:03
cray-crus/etcd.backup_v1_2023-03-09-01:00:04
cray-bos/db-2023-03-09_18-00
bare-metal/etcd-backup-2023-03-09-18-10-02.tar.gz
bare-metal/etcd-backup-2023-03-09-18-20-02.tar.gz

[...]
```

The returned output includes the date and time of the latest backup for each service. If a recent backup for any service is not included, it is an indication
that the service is not backed up automatically. Create a manual backup for that service by following the
[Create a Manual Backup of a Healthy etcd Cluster](Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md) procedure.

## Clusters without automated backups

The following projects are not backed up as part of the automated solution:

- Content Projection Service \(CPS\)
- Heartbeat Tracking Daemon \(HBTD\)
- HMS Notification Fanout Daemon \(HMNFD\)
- River Endpoint Discovery Service \(REDS\)

If these clusters become unhealthy, the process for rediscovering their data should be followed.
See [Repopulate Data in etcd Clusters When Rebuilding Them](Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md).
