# Restore an etcd Cluster from a Backup

Use an existing backup of a healthy etcd cluster to restore an unhealthy cluster to a healthy state.

The commands in this procedure can be run on any master node \(`ncn-mXXX`\) or worker node \(`ncn-wXXX`\) on the system.

---
> **`NOTE`**

Etcd Clusters can be restored using the automation script or the manual procedure below. The automation script follows the same steps as the manual procedure.
If the automation script fails to get the date from backups, follow the manual procedure.

---

## Prerequisites

A backup of a healthy etcd cluster has been created.

## Restore with Automation Script

The automated script will restore the cluster from the most recent backup if it finds a backup created within the last 7 days.
If it does not discover a backup within the last 7 days, it will ask the user if they would like to rebuild the cluster.

```text
cd /opt/cray/platform-utils/etcd_restore_rebuild_util

# rebuild/restore a single cluster
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -s cray-bos-etcd

# rebuild/restore multiple clusters
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -m cray-bos-etcd,cray-uas-mgr-etcd

# rebuild/restore all clusters
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -a
```

An example using the automation script is below for `ncn-w001`. Can also
be executed on any master NCN.

```bash
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -s cray-bss-etcd
```

Example output:

```text
The following etcd clusters will be restored/rebuilt:
cray-bss-etcd
You will be accepting responsibility for any missing data if there is a restore/rebuild over a running etcd k/v. HPE assumes no responsibility.
Proceed restoring/rebuilding? (yes/no)
yes
Proceeding: restoring/rebuilding etcd clusters.

 ----- Restoring from cray-bss/etcd.backup_v5702_2022-07-30-19:00:02 -----
etcdrestore.etcd.database.coreos.com/cray-bss-etcd created
- Any existing cray-bss-etcd pods no longer in "Running" state.
- Waiting for 3 cray-bss-etcd pods to be running:
- 0/3  Running
- 1/3  Running
- 2/3  Running
- 3/3  Running
etcdrestore.etcd.database.coreos.com "cray-bss-etcd" deleted
2022-07-31-04:23:23
The cray-bss-etcd cluster has successfully been restored from cray-bss/etcd.backup_v5702_2022-07-30-19:00:02.

ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util #
```

## Restore with Manual Procedure

1.  List the backups for the desired etcd cluster.

    The example below uses the Boot Orchestration Service \(BOS\).

    ```bash
    kubectl exec -it -n operators \
    $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') \
    -c boto3 -- list_backups cray-bos
    ```

    Example output:

    ```text
    cray-bos/etcd.backup_v108497_2020-03-20-23:42:37
    cray-bos/etcd.backup_v125815_2020-03-21-23:42:37
    cray-bos/etcd.backup_v143095_2020-03-22-23:42:38
    cray-bos/etcd.backup_v160489_2020-03-23-23:42:37
    cray-bos/etcd.backup_v176621_2020-03-24-23:42:37
    cray-bos/etcd.backup_v277935_2020-03-30-23:52:54
    cray-bos/etcd.backup_v86767_2020-03-19-18:00:05
    ```

2.  Restore the cluster using a backup.

    Replace `etcd.backup\_v277935\_2020-03-30-23:52:54` in the command below with the name of the backup being used.

    ```bash
    kubectl exec -it -n operators \
    $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') \
    -c util -- restore_from_backup cray-bos etcd.backup_v277935_2020-03-30-23:52:54
    ```

    Example output:

    ```text
    etcdrestore.etcd.database.coreos.com/cray-bos-etcd created
    ```

3.  Restart the pods for the etcd cluster.

    1.  Watch the pods come back online.

        This may take a couple minutes.

        ```bash
        kubectl -n services get pod | grep SERVICE_NAME
        ```

        Example output:
        
        ```text
        cray-bos-etcd-498jn7th6p             1/1     Running              0          4h1m
        cray-bos-etcd-dj7d894227             1/1     Running              0          3h59m
        cray-bos-etcd-tk4pr4kgqk             1/1     Running              0          4
        ```

    2.  Delete the EtcdRestore custom resource.

        This step will make it possible for future restores to occur. Replace the etcdrestore.etcd.database.coreos.com/cray-bos-etcd value with the name returned in step 2.

        ```bash
        kubectl -n services delete etcdrestore.etcd.database.coreos.com/cray-bos-etcd
        ```

        Example output:

        ```text
        etcdrestore.etcd.database.coreos.com "cray-bos-etcd" deleted
        ```
