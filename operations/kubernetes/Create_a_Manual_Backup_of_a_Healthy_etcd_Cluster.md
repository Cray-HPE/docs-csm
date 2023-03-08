# Create a Manual Backup of a Healthy etcd Cluster

Manually create a backup of a healthy etcd cluster and check to see if the backup was created successfully.

Backups of healthy etcd clusters can be used to restore the cluster if it becomes unhealthy at any point.

The commands in this procedure can be run on any master node \(`ncn-mXXX`\) or worker node \(`ncn-wXXX`\) on the system.

## Prerequisites

A healthy etcd cluster is available on the system. See [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md).

## Procedure

1. Create a backup for the desired etcd cluster.

    Create variables which will be used throughout this procedure.  In this example we are making a backup of the Boot Orchestration Service \(BOS\) etcd cluster which will be named cray-bos-etcd-backup_DATE_TIME.  NOTE: backup name can be anything you would like.

    ```bash
    SERVICE=cray-bos
    BACKUP_NAME=$SERVICE-etcd-backup_`date '+%Y-%m-%d_%H-%M-%S'`
    ```

    ```bash
    JOB=$(kubectl exec -it -n operators \
          $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') \
          -c util -- create_backup $SERVICE $BACKUP_NAME | cut -d " " -f 1); echo $JOB
    ```

    Example output:

    ```text
    etcdbackup.etcd.database.coreos.com/cray-bos-etcd-cluster-manual-backup-25847
    ```

1. Check the status of the backup.

    ```bash
    kubectl -n services get $JOB -o json | jq '.spec.s3.path, .status'
    ```

    Example output:

    ```json
    "etcd-backup/cray-bos/cray-bos-etcd-backup_2023-03-08_20-08-07"
    {
      "etcdRevision": 405927,
      "etcdVersion": "3.3.22",
      "lastExecutionDate": "2023-03-08T19:57:42Z",
      "lastSuccessDate": "2023-03-08T19:57:42Z",
      "succeeded": true
    }
    ```

1. To retrieve the created backup use the following command:

    ```bash
    cray artifacts get etcd-backup $SERVICE/$BACKUP_NAME $BACKUP_NAME
    ```
