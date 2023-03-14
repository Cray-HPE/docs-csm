# Create a Manual Backup of a Healthy etcd Cluster

Manually create a backup of a healthy etcd cluster and check to see if the backup was created successfully.

Backups of healthy etcd clusters can be used to restore the cluster if it becomes unhealthy at any point.

The commands in this procedure can be run on any master node \(`ncn-mXXX`\) or worker node \(`ncn-wXXX`\) on the system.

## Prerequisites

A healthy etcd cluster is available on the system. See [Check the Health of etcd Clusters](Check_the_Health_of_etcd_Clusters.md).

## Procedure

1. Create a backup for the desired etcd cluster.

    The example below is backing up the etcd cluster for the Boot Orchestration Service \(BOS\) named `wednesday-manual-backup`.

    ```bash
    /opt/cray/platform-utils/etcd/etcd-util.sh create_backup cray-bos wednesday-manual-backup
    ```

    Example output:

    ```text
    Taking snapshot from cray-bos-bitnami-etcd-0...
    Pushing newly created snapshot /snapshots/cray-bos-bitnami-etcd/db-2023-03-10_23-38 to S3 as wednesday-manual-backup for cray-bos
    upload: snapshots/cray-bos-bitnami-etcd/db-2023-03-10_23-38 to s3://etcd-backup/cray-bos/wednesday-manual-backup
    ```

1. Verify the newly created backup is available in S3:

    ```bash
    /opt/cray/platform-utils/etcd/etcd-util.sh list_backups cray-bos
    ```

    Example output:

    ```text
    cray-bos/db-2023-03-10_21-00
    cray-bos/db-2023-03-10_22-00
    cray-bos/db-2023-03-10_23-00
    cray-bos/wednesday-manual-backup
    ```
