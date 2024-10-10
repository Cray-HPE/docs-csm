# Backups for Etcd Clusters Running in Kubernetes

Backups are periodically created for etcd clusters. These backups are stored in the Ceph Rados Gateway \(S3\). Not all services are backed up automatically.
Services that are not backed up automatically will need to be manually rediscovered if the cluster is unhealthy.

- [Clusters with automated backups](#clusters-with-automated-backups)
- [Clusters without automated backups](#clusters-without-automated-backups)
- [Test for recent etcd cluster backups](#test-for-recent-etcd-cluster-backups)
- [Check backup status for a specific etcd cluster](#check-backup-status-for-a-specific-etcd-cluster)
- [Check status of etcd cluster backups](#check-status-of-etcd-cluster-backups)

## Clusters with automated backups

The following services are backed up daily \(one week of backups retained\) as part of the automated solution:

- Boot Orchestration Service \(BOS\)
- Boot Script Service \(BSS\)
- Controller Diagnostics Orchestration (FOX)
- Firmware Action Service \(FAS\)
- Heartbeat Tracking Daemon \(HBTD\)
- HMS Notification Fanout Daemon \(HMNFD\)
- Power Control Service \(PCS\)
- User Access Service \(UAS\)

## Clusters without automated backups

The following projects are not backed up as part of the automated solution:

- Content Projection Service \(CPS\)

If these clusters become unhealthy, the process for rediscovering their data should be followed.
See [Repopulate Data in etcd Clusters When Rebuilding Them](Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md).

## Test for recent etcd cluster backups

This test will show PASS or FAIL for each of the etcd clusters as it verifies whether they had a backup in the last 24 hours.

(`ncn-mw#`) To view all available etcd backups across all clusters:

```bash
/opt/cray/platform-utils/ncnHealthChecks.sh -s etcd_backups_check
```

Example output:

```text
**************************************************************************

=== Verify etcd clusters have a backup in the last 24 hours. ===
=== The complete list of backups can be listed as follows:
=== % /opt/cray/platform-utils/etcd/etcd-util.sh list_backups -
Tue 08 Oct 2024 05:37:02 PM UTC

-- cray-bos -- backups
PASS: backup found less than 24 hours old.

-- cray-bss -- backups
PASS: backup found less than 24 hours old.

-- cray-fas -- backups
PASS: backup found less than 24 hours old.

-- cray-fox -- backups
PASS: backup found less than 24 hours old.

-- cray-hbtd -- backups
PASS: backup found less than 24 hours old.

-- cray-hmnfd -- backups
PASS: backup found less than 24 hours old.

-- cray-power-control -- backups
PASS: backup found less than 24 hours old.

-- cray-uas-mgr -- backups
PASS: backup found less than 24 hours old.
 --- PASSED --- 
```

If a particular service is not included, it is an indication
that the service was not backed up automatically or was not backed up with success. Create a manual backup for that service by following the
[Create a Manual Backup of a Healthy etcd Cluster](Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md) procedure.

## Check backup status for a specific etcd cluster

(`ncn-mw#`) Run the following command on any Kubernetes master or worker node in order to list the backups for a specific project.
In the example below, the backups for BSS are listed.

```bash
/opt/cray/platform-utils/etcd/etcd-util.sh list_backups cray-bss
```

Example output:

```text
cray-bss/db-2024-09-30_23-01
cray-bss/db-2024-10-01_23-00
cray-bss/db-2024-10-02_23-00
cray-bss/db-2024-10-03_23-00
cray-bss/db-2024-10-04_23-00
cray-bss/db-2024-10-05_23-00
cray-bss/db-2024-10-06_23-00
cray-bss/db-2024-10-07_00-01
cray-bss/db-2024-10-07_01-00
cray-bss/db-2024-10-07_02-00
cray-bss/db-2024-10-07_03-00
cray-bss/db-2024-10-07_04-01

[...]
```

## Check status of etcd cluster backups

(`ncn-mw#`) To view all available backups across all projects:

```bash
/opt/cray/platform-utils/etcd/etcd-util.sh list_backups -
```

Example output:

```text
cray-bos/db-2024-09-30_23-00
cray-bss/db-2024-09-30_23-01
cray-fas/db-2024-09-30_23-01
cray-fox/db-2024-09-30_23-00
cray-hbtd/db-2024-09-30_23-00
cray-hmnfd/db-2024-09-30_23-01
cray-power-control/db-2024-09-30_23-00
cray-uas-mgr/db-2024-09-30_23-00
cray-bos/db-2024-10-01_23-00
cray-bss/db-2024-10-01_23-00
cray-fas/db-2024-10-01_23-00
cray-fox/db-2024-10-01_23-00
cray-hbtd/db-2024-10-01_23-01

[...]
```

The returned output includes the date and time of the latest backup for each service. If a recent backup for any service is not included, it is an indication
that the service is not backed up automatically. Create a manual backup for that service by following the
[Create a Manual Backup of a Healthy etcd Cluster](Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md) procedure.
