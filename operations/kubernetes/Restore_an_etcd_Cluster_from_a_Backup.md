# Restore an etcd Cluster from a Backup

Use an existing backup of a healthy etcd cluster to restore an unhealthy cluster to a healthy state.

The commands in this procedure can be run on any master node \(`ncn-mXXX`\) or worker node \(`ncn-wXXX`\) on the system.

### Prerequisites

A backup of a healthy etcd cluster has been created.


### Procedure

1. List the backups for the desired etcd cluster.

    The example below uses the Boot Orchestration Service \(BOS\).

    ```bash
    ncn-w001# kubectl exec -it -n operators \
    $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') \
    -c boto3 -- list_backups cray-bos
    cray-bos/etcd.backup_v108497_2020-03-20-23:42:37
    cray-bos/etcd.backup_v125815_2020-03-21-23:42:37
    cray-bos/etcd.backup_v143095_2020-03-22-23:42:38
    cray-bos/etcd.backup_v160489_2020-03-23-23:42:37
    cray-bos/etcd.backup_v176621_2020-03-24-23:42:37
    cray-bos/etcd.backup_v277935_2020-03-30-23:52:54
    cray-bos/etcd.backup_v86767_2020-03-19-18:00:05
    ```

2. Restore the cluster using a backup.

    Replace etcd.backup\_v277935\_2020-03-30-23:52:54 in the command below with the name of the backup being used.

    ```bash
    ncn-w001# kubectl exec -it -n operators \
    $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') \
    -c util -- restore_from_backup cray-bos etcd.backup_v277935_2020-03-30-23:52:54


    etcdrestore.etcd.database.coreos.com/cray-bos-etcd created
    ```

3. Restart the pods for the etcd cluster.

    1.  Watch the pods come back online.

        This may take a couple minutes.

        ```bash
        ncn-w001# kubectl -n services get pod | grep SERVICE_NAME
        cray-bos-etcd-498jn7th6p             1/1     Running              0          4h1m
        cray-bos-etcd-dj7d894227             1/1     Running              0          3h59m
        cray-bos-etcd-tk4pr4kgqk             1/1     Running              0          4
        ```

    2.  Delete the EtcdRestore custom resource.

        This step will make it possible for future restores to occur. Replace the etcdrestore.etcd.database.coreos.com/cray-bos-etcd value with the name returned in step 2.

        ```bash
        ncn-w001# kubectl -n services delete etcdrestore.etcd.database.coreos.com/cray-bos-etcd
        etcdrestore.etcd.database.coreos.com "cray-bos-etcd" deleted
        ```
        
4. Verify that the `cray-bos-etcd-client` service was created.

       ```bash
       ncn# kubectl get service -n services cray-bos-etcd-client
       ```

       Example of output showing that the service was created:    

       ```text
       NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
       cray-bos-etcd-client   ClusterIP   10.28.248.232   <none>        2379/TCP   2m
       ```
   
      1. If service was not created repeat steps 1 to 3 for a new backup restore.
   
