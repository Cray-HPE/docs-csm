# Create a Manual Backup of a Healthy etcd Cluster

Manually create a backup of a healthy etcd cluster and check to see if the backup was created successfully.

Backups of healthy etcd clusters can be used to restore the cluster if it becomes unhealthy at any point.

The commands in this procedure can be run on any master node \(`ncn-mXXX`\) or worker node \(`ncn-wXXX`\) on the system.

## Prerequisites

A healthy etcd cluster is available on the system. See [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md).

## Procedure

1. Create a backup for the desired etcd cluster.

    The example below is backing up the etcd cluster for the Boot Orchestration Service \(BOS\). The returned backup name (`cray-bos-etcd-cluster-manual-backup-25847`) will be used in the next step.

    ```bash
    ncn-w001# kubectl exec -it -n operators \
                $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') \
                -c util -- create_backup cray-bos wednesday-manual-backup
    ```

    Example output:

    ```text
    etcdbackup.etcd.database.coreos.com/cray-bos-etcd-cluster-manual-backup-25847 created
    ```

1. Check the status of the backup using the name returned in the output of the previous step.

    ```bash
    ncn-w001# kubectl -n services get BACKUP_NAME -o yaml
    ```

    Example output:

    ```yaml
      status:
        etcdRevision: 1
        etcdVersion: 3.3.8
        lastSuccessDate: "2020-01-13T21:38:47Z"
        succeeded: true
    ```
