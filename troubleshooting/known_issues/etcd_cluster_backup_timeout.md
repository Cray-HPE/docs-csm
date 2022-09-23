# Etcd Cluster Backup Fails Due to Timeout

## Description

There is a known issue where an Etcd cluster backup will fails if it takes longer than 1 minute to complete.

## Symptoms

* An Etcd cluster backup was not created in the last 24 hours.
* The `etcdbackup` status contains `MultipartUpload: upload multipart failed`.

1. (`ncn-mw#`) Check for recent Etcd cluster backups listed in the `etcd-backup` S3 bucket.

  ```bash
  /opt/cray/platform-utils/s3/list-objects.py --bucket-name etcd-backup | grep -v bare-metal
  ```

  Example output:

  ```text
  cray-bos/etcd.backup_v273436_2022-09-12-13:55:20
  cray-bos/etcd.backup_v273436_2022-09-13-13:55:20
  cray-bos/etcd.backup_v276316_2022-09-14-13:55:20
  cray-bos/etcd.backup_v279196_2022-09-15-13:55:20
  cray-bos/etcd.backup_v282076_2022-09-16-13:55:20
  cray-bos/etcd.backup_v545936_2022-09-17-13:55:20
  cray-bos/etcd.backup_v562933_2022-09-18-13:55:20  <---- Missing backups for 2022-09-19 and 2022-09-20
  cray-bss/etcd.backup_v452224_2022-09-20-13:54:09
  cray-bss/etcd.backup_v458007_2022-09-19-13:54:09
  .
  .
  .
  ```

1. (`ncn-mw#`) If the latest backup listed in the `etcd-backup` S3 bucket for a given Etcd cluster is older than 24 hours,
check the status of the `etcdbackup` resource. This example is checking `cray-bos etcdbackup` resource:

  ```bash
  kubectl describe etcdbackup cray-bos-etcd-cluster-periodic-backup -n services | grep -A8  "Status":
  ```

  Example output:

  ```text
  Status:
    Reason:  failed to save snapshot (failed to write snapshot (MultipartUpload: upload multipart failed
             upload id: 2~V6e_CehW2ULDNNmAgL01mkt2zObm4pg
  caused by: RequestCanceled: request context canceled
  caused by: context deadline exceeded))
    Last Execution Date:  2022-09-20T13:58:04Z
    Last Success Date:    2022-09-18-13:55:20Z
    Succeeded:            false
  Events:                 <none>
  ```

## Solution

Add a `backupPolicy.timeoutInSecond` of 600 to the `etcdbackup` resource to allow the backup to take up to 10 minutes to complete.

1. (`ncn-mw#`) Patch the `etcdbackup` resource. This example patches the `cray-bos etcdbackup` resource:

   ```bash
   kubectl patch etcdbackup cray-bos-etcd-cluster-periodic-backup -n services --type=merge -p '{"spec":{"backupPolicy":{"timeoutInSecond": 600}}}'
   ```

  Example output:

  ```text
  etcdbackup.etcd.database.coreos.com/cray-bos-etcd-cluster-periodic-backup patched
  ```

1. (`ncn-mw#`) To verify that backups can now be successfully created, temporarily set the `backupIntervalInSecond` to force a backup every minute. This example patches the `cray-bos etcdbackup` resource:

  ```bash
  INTERVAL=$(kubectl get etcdbackups cray-bos-etcd-cluster-periodic-backup -n services -o json | jq -r '.spec.backupPolicy.backupIntervalInSecond')
  TMPINTERVAL=60
  kubectl patch etcdbackup cray-bos-etcd-cluster-periodic-backup -n services --type=json  -p="[{'op' : 'replace', 'path':'/spec/backupPolicy/backupIntervalInSecond', 'value' : \"$TMPINTERVAL\" }]"
  ```

  Example output:

  ```text
  etcdbackup.etcd.database.coreos.com/cray-bos-etcd-cluster-periodic-backup patched
  ```

1. (`ncn-mw#`) Re-check the list of Etcd cluster backups. It will take a few minutes for the new backup to show in the list.

  ```bash
  /opt/cray/platform-utils/s3/list-objects.py --bucket-name etcd-backup | grep -v bare-metal
  ```

  Example output:

  ```text
  cray-bos/etcd.backup_v276316_2022-09-13-13:55:20
  cray-bos/etcd.backup_v276316_2022-09-14-13:55:20
  cray-bos/etcd.backup_v279196_2022-09-15-13:55:20
  cray-bos/etcd.backup_v282076_2022-09-16-13:55:20
  cray-bos/etcd.backup_v545936_2022-09-17-13:55:20
  cray-bos/etcd.backup_v562933_2022-09-18-13:55:20
  cray-bos/etcd.backup_v569459_2022-09-21-07:36:15  <---- A new backup exists for cray-bos Etcd cluster
  cray-bss/etcd.backup_v452224_2022-09-20-13:54:09
  cray-bss/etcd.backup_v458007_2022-09-19-13:54:09
  .
  .
  .
  ```

1. (`ncn-mw#`) Reset the `backupIntervalInSecond` to the original value so backups are not running every minute.

  ```bash
  kubectl patch etcdbackup cray-bos-etcd-cluster-periodic-backup -n services --type=json  -p="[{'op' : 'replace', 'path':'/spec/backupPolicy/backupIntervalInSecond', 'value' : \"$INTERVAL\" }]"
  ```
