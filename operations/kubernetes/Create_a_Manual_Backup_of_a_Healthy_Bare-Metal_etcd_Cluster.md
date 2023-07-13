# Create a Manual Backup of Bare-Metal etcd Cluster

Manually create a backup of a healthy bare-metal etcd cluster.

bare-metal etcd cluster backups are automatically created every ten minutes and deleted after 24 hours.
When necessary, these procedures can be used to create an additional backup, and then save a separate copy of it, or one of the automated backups.
When needed, a bare-metal etcd cluster can be restored from a saved backup.

The commands in these procedures can be run on any master (control plane) node \(`ncn-m#`\) on the system.
These procedures assume a healthy bare-metal etcd cluster.

* [Check health of bare-metal etcd cluster](#check-health-of-bare-metal-etcd-cluster)
* [bare-metal etcd cluster backups overview](#bare-metal-etcd-cluster-backups-overview)
* [Create new bare-metal etcd cluster backup](#create-new-bare-metal-etcd-cluster-backup)
* [Save a copy of a bare-metal etcd cluster backup](#save-a-copy-of-a-bare-metal-etcd-cluster-backup)
* [Restore bare-metal etcd cluster from a saved backup file](#restore-bare-metal-etcd-cluster-from-a-saved-backup-file)

## Check health of bare-metal etcd cluster

1. Verify bare-metal etcd cluster health on each master (control plane) node \(`ncn-m#`\) on the system.

    ```bash
    ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt \
        --cert /etc/kubernetes/pki/etcd/server.crt \
        --key /etc/kubernetes/pki/etcd/server.key endpoint health
    ```

    Example output:

    ```text
    127.0.0.1:2379 is healthy: successfully committed proposal: took = 20.697187ms
     ```

## Bare-metal etcd cluster backups overview

1. (`ncn-mw#`) Verify that the bare-metal etcd cluster backups are initiated every ten minutes.

    ```bash
    kubectl get cronjob -n kube-system
    ```

    Example output:

    ```text
    NAME              SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    kube-etcdbackup   */10 * * * *   False     0        3m28s           7d10h
    ```

1. (`ncn-mw#`) View backup job.

    ```bash
    kubectl get jobs -n kube-system | grep -e NAME -e etcdbackup
    ```

    Example output:

    ```text
    NAME                       COMPLETIONS   DURATION   AGE
    kube-etcdbackup-27721380   1/1           8s         2m30s
    ```

1. (`ncn-mw#`) List the available bare-metal etcd cluster backups. Note the ten minute interval.

    ```bash
    cd /opt/cray/platform-utils/s3 && \
        ./list-objects.py --bucket-name etcd-backup | \
        grep bare-metal | tail -5; echo "Current": $(date +"%Y-%m-%d-%H-%M-%S")
    ```

    Example output:

    ```text
    bare-metal/etcd-backup-2022-09-15-19-50-02.tar.gz
    bare-metal/etcd-backup-2022-09-15-20-00-02.tar.gz
    bare-metal/etcd-backup-2022-09-15-20-10-02.tar.gz
    bare-metal/etcd-backup-2022-09-15-20-20-02.tar.gz
    bare-metal/etcd-backup-2022-09-15-20-30-03.tar.gz
    Current: 2022-09-15-20-32-54
    ```

## Create new bare-metal etcd cluster backup

1. Validate bare-metal etcd cluster's health.

    See [Check health of bare-metal etcd cluster](#check-health-of-bare-metal-etcd-cluster).

1. (`ncn-mw#`) Create backup job.

    ```bash
    kubectl create job tmp-bare-metal-etcd-backup --from=cronjob/kube-etcdbackup -n kube-system
    ```

    Example output:

    ```text
    job.batch/tmp-bare-metal-etcd-backup created
    ```

1. (`ncn-mw#`) Validate job creation.

    ```bash
    kubectl get jobs -n kube-system | grep -e NAME -e tmp-bare-metal-etcd-backup
    ```

    Example output:

    ```text
    NAME                       COMPLETIONS   DURATION   AGE
    tmp-bare-metal-etcd-backup   1/1           9s         16s
    ```

1. (`ncn-mw#`) Verify that the new bare-metal etcd cluster backup was created.

    In this example, `bare-metal/etcd-backup-2022-09-15-20-34-13.tar.gz` is created.

    ```bash
    cd /opt/cray/platform-utils/s3 && ./list-objects.py \
        --bucket-name etcd-backup | \
        grep bare-metal | tail -5; echo "Current": $(date +"%Y-%m-%d-%H-%M-%S")
    ```

    Example output:

    ```text
    bare-metal/etcd-backup-2022-09-15-20-00-02.tar.gz
    bare-metal/etcd-backup-2022-09-15-20-10-02.tar.gz
    bare-metal/etcd-backup-2022-09-15-20-20-02.tar.gz
    bare-metal/etcd-backup-2022-09-15-20-30-03.tar.gz
    bare-metal/etcd-backup-2022-09-15-20-34-13.tar.gz
    Current: 2022-09-15-20-36-14
    ```

1. (`ncn-mw#`) Delete the `tmp-bare-metal-etcd-backup` backup job.

    ```bash
    kubectl -n kube-system delete job tmp-bare-metal-etcd-backup
    ```

    Example output:

    ```text
    job.batch "tmp-bare-metal-etcd-backup" deleted
    ```

## Save a copy of a bare-metal etcd cluster backup

1. (`ncn-mw#`) Create a temporary directory.

    ```bash
    mkdir /tmp/etcd_backup
    ```

1. (`ncn-mw#`) Retrieve the backup from S3.

    In this example, the `bare-metal/etcd-backup-2022-09-15-20-34-13.tar.gz` backup created earlier is saved.
    Set the `BACKUP_NAME` variable to the file name, omitting the `bare-metal/` prefix and the `.tar.gz suffix`.

    ```bash
    BACKUP_NAME=etcd-backup-2022-09-15-20-34-13
    cd /opt/cray/platform-utils/s3
    ./download-file.py --bucket-name etcd-backup \
        --key-name "bare-metal/${BACKUP_NAME}.tar.gz" \
        --file-name "/tmp/etcd_backup/${BACKUP_NAME}.tar.gz"
    ls /tmp/etcd_backup/
    ```

    Example output:

    ```text
    etcd-backup-2022-09-15-20-34-13.tar.gz
    ```

## Restore bare-metal etcd cluster from a saved backup file

1. (`ncn-mw#`) Create a `/tmp/etcd_restore` directory.

    ```bash
    mkdir /tmp/etcd_restore
    ```

1. (`ncn-mw#`) Copy the saved bare-metal etcd cluster backup file into the directory.

    Set the `BACKUP_NAME` variable to the file name, omitting the `bare-metal/` prefix and the `.tar.gz suffix`.
    In the following example, the backup file is copied from `/tmp/etcd_backup`
    where a copy of the backup file `etcd-backup-2022-09-15-20-34-13.tar.gz` was saved above.

    ```bash
    cd /tmp/etcd_restore
    BACKUP_NAME=etcd-backup-2022-09-15-20-34-13
    cp /tmp/etcd_backup/${BACKUP_NAME}.tar.gz .
    ls /tmp/etcd_restore/
    ```

    Example output:

    ```text
    etcd-backup-2022-09-15-20-34-13.tar.gz
    ```

1. (`ncn-mw#`) Uncompress the backup file and extract the `etcd-dump.bin` file.

    ```bash
    gunzip "${BACKUP_NAME}.tar.gz"
    tar -xvf "${BACKUP_NAME}.tar"
    mv -v "${BACKUP_NAME}/etcd-dump.bin" /tmp
    ```

    Example output:

    ```text
    renamed 'etcd-backup-2022-09-15-20-34-13/etcd-dump.bin' -> '/tmp/etcd-dump.bin'
    ```

1. (`ncn-mw#`) Push the `etcd-dump.bin` file to the other NCN master nodes.

    If not running these steps on `ncn-m001`, adjust the NCN names in the following command accordingly.

    ```bash
    scp /tmp/etcd-dump.bin ncn-m002:/tmp
    scp /tmp/etcd-dump.bin ncn-m003:/tmp
    ```

1. Continue the bare-metal etcd cluster restore.

    Continue with the [Restore member directory](Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md#2-restore-member-directory) step.

1. Verify the restored bare-metal etcd cluster's health.

    See [Check health of bare-metal etcd cluster](#check-health-of-bare-metal-etcd-cluster).
