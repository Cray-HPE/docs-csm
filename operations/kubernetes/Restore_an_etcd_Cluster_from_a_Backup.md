## Restore an etcd Cluster from a Backup

Use an existing backup of a healthy etcd cluster to restore an unhealthy cluster to a healthy state.

The commands in this procedure can be run on any master node \(`ncn-mXXX`\) or worker node \(`ncn-wXXX`\) on the system.

---
**NOTE**

Etcd Clusters can be restored using the automation script or the manual procedure below. The automation script follows the same steps as the manual procedure. 
If the automation script fails to get the date from backups, follow the manual procedure. 

---

### Prerequisites

A backup of a healthy etcd cluster has been created.

### Restore with Automation Script

The automated script will restore the cluster from the most recent backup if it finds a backup created within the last 7 days. 
If it does not discover a backup within the last 7 days, it will ask the user if they would like to rebuild the cluster.

```
ncn-w001# cd /opt/cray/platform-utils/etcd_restore_rebuild_util

# rebuild/restore a single cluster
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -s cray-bos-etcd

# rebuild/restore multiple clusters
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -m cray-bos-etcd,cray-uas-mgr-etcd

# rebuild/restore all clusters
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -a
```

An example using the automation script is below.
```
ncn-m001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -s cray-externaldns-etcd
The following etcd clusters will be restored/rebuilt:
cray-externaldns-etcd
You will be accepting responsibility for any missing data if there is a restore/rebuild over a running etcd k/v. HPE assumes no responsibility.
Proceed restoring/rebuilding? (yes/no)
yes
Proceeding: restoring/rebuilding etcd clusters.

 ----- Restoring from cray-externaldns/etcd.backup_v8362_2021-08-18-20:00:09
etcdrestore.etcd.database.coreos.com/cray-externaldns-etcd created
- 3/3  Running
Successfully restored cray-externaldns-etcd
etcdrestore.etcd.database.coreos.com "cray-externaldns-etcd" deleted
```

### Restore with Manual Procedure

1.  List the backups for the desired etcd cluster.

    The example below uses the Boot Orchestration Service \(BOS\).

    ```bash
    ncn-w001# kubectl exec -it -n operators \
    $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') \
    -c boto3 -- list_backups cray-bos
    ```

    Example output:

    ```
    cray-bos/etcd.backup_v108497_2020-03-20-23:42:37
    cray-bos/etcd.backup_v125815_2020-03-21-23:42:37
    cray-bos/etcd.backup_v143095_2020-03-22-23:42:38
    cray-bos/etcd.backup_v160489_2020-03-23-23:42:37
    cray-bos/etcd.backup_v176621_2020-03-24-23:42:37
    cray-bos/etcd.backup_v277935_2020-03-30-23:52:54
    cray-bos/etcd.backup_v86767_2020-03-19-18:00:05
    ```

2.  Restore the cluster using a backup.

    Replace etcd.backup\_v277935\_2020-03-30-23:52:54 in the command below with the name of the backup being used.

    ```bash
    ncn-w001# kubectl exec -it -n operators \
    $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') \
    -c util -- restore_from_backup cray-bos etcd.backup_v277935_2020-03-30-23:52:54
    ```

    Example output:

    ```
    etcdrestore.etcd.database.coreos.com/cray-bos-etcd created
    ```

3.  Restart the pods for the etcd cluster.

    1.  Watch the pods come back online.

        This may take a couple minutes.

        ```bash
        ncn-w001# kubectl -n services get pod | grep SERVICE_NAME
        ```

        Example output:
        
        ```
        cray-bos-etcd-498jn7th6p             1/1     Running              0          4h1m
        cray-bos-etcd-dj7d894227             1/1     Running              0          3h59m
        cray-bos-etcd-tk4pr4kgqk             1/1     Running              0          4
        ```

    2.  Delete the EtcdRestore custom resource.

        This step will make it possible for future restores to occur. Replace the etcdrestore.etcd.database.coreos.com/cray-bos-etcd value with the name returned in step 2.

        ```bash
        ncn-w001# kubectl -n services delete etcdrestore.etcd.database.coreos.com/cray-bos-etcd
        ```

        Example output:

        ```
        etcdrestore.etcd.database.coreos.com "cray-bos-etcd" deleted
        ```



