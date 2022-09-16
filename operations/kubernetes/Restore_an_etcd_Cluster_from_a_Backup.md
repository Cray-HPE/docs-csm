# Restore an etcd Cluster from a Backup

Use an existing backup of a healthy etcd cluster to restore an unhealthy cluster to a healthy state.

The commands in this procedure can be run on any Kubernetes master or worker node on the system.

* [Prerequisites](#prerequisites)
* [Restore procedure](#restore-procedure)
  * [Automated script](#restore-with-automated-script)
  * [Manual procedure](#restore-with-manual-procedure)

## Prerequisites

A backup of a healthy etcd cluster has been created.

## Restore procedure

Etcd clusters can be restored using an automated script or a manual procedure.

* [Restore with automated script](#restore-with-automated-script)
* [Restore with manual procedure](#restore-with-manual-procedure)

### Restore with automated script

The automated script will restore the cluster from the most recent backup if it finds a backup created within the last 7 days.
If it does not discover a backup within the last 7 days, it will ask the user if they would like to rebuild the cluster.

The automated script follows the same steps as the manual procedure.
If the automated script fails to get the date from backups, then follow the manual procedure.

* (`ncn-mw#`) Rebuild/restore a single cluster

    ```bash
    /opt/cray/platform-utils/etcd_restore_rebuild_util/etcd_restore_rebuild.sh -s cray-bos-etcd
    ```

* (`ncn-mw#`) Rebuild/restore multiple clusters

    ```bash
    /opt/cray/platform-utils/etcd_restore_rebuild_util/etcd_restore_rebuild.sh -m cray-bos-etcd,cray-uas-mgr-etcd
    ```

* (`ncn-mw#`) Rebuild/restore all clusters

   ```bash
   /opt/cray/platform-utils/etcd_restore_rebuild_util/etcd_restore_rebuild.sh -a
   ```

#### Example command and output

```bash
/opt/cray/platform-utils/etcd_restore_rebuild_util/etcd_restore_rebuild.sh -s cray-bss-etcd
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
```

### Restore with manual procedure

1. (`ncn-mw#`) List the backups for the desired etcd cluster.

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

1. (`ncn-mw#`) Restore the cluster using a backup.

    Replace `etcd.backup_v277935_2020-03-30-23:52:54` in the command below with the name of the chosen backup from the previous step.

    ```bash
    kubectl exec -it -n operators \
        $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') \
        -c util -- restore_from_backup cray-bos etcd.backup_v277935_2020-03-30-23:52:54
    ```

    Example output:

    ```text
    etcdrestore.etcd.database.coreos.com/cray-bos-etcd created
    ```

1. (`ncn-mw#`) Wait for the pods to restart and watch the pods come back online.

    This may take a few minutes.

    ```bash
    kubectl -n services get pod | grep SERVICE_NAME
    ```

    Example output:

    ```text
    cray-bos-etcd-498jn7th6p             1/1     Running              0          4h1m
    cray-bos-etcd-dj7d894227             1/1     Running              0          3h59m
    cray-bos-etcd-tk4pr4kgqk             1/1     Running              0          4
    ```

1. (`ncn-mw#`) Delete the `EtcdRestore` custom resource.

    This step will make it possible for future restores to occur. In the following command, replace
    `etcdrestore.etcd.database.coreos.com/cray-bos-etcd` value with the output of the earlier command used to
    initiate the restore.

    ```bash
    kubectl -n services delete etcdrestore.etcd.database.coreos.com/cray-bos-etcd
    ```

    Example output:

    ```text
    etcdrestore.etcd.database.coreos.com "cray-bos-etcd" deleted
    ```

1. (`ncn-mw#`) Verify that the `cray-bos-etcd-client` service was created.

    ```bash
    ncn# kubectl get service -n services cray-bos-etcd-client
    ```

    Example of output showing that the service was created:

    ```text
    NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    cray-bos-etcd-client   ClusterIP   10.28.248.232   <none>        2379/TCP   2m
    ```

    If the `etcd-client` service was not created, then repeat the procedure to restore the cluster again.
