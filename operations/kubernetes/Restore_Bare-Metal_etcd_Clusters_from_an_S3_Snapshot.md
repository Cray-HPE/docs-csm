# Restore Bare-Metal etcd Clusters from an S3 Snapshot

The etcd cluster that serves Kubernetes on master nodes is backed up every 10 minutes. These backups are pushed to `Ceph Rados Gateway` \(S3\).

Restoring the etcd cluster from backup is only meant to be used in a catastrophic scenario, in which the Kubernetes cluster and master nodes are being rebuilt.
This procedure shows how to restore the bare-metal etcd cluster from a `Simple Storage Service` \(S3\) snapshot.

The etcd cluster needs to be restored from a backup when the Kubernetes cluster and master nodes are being rebuilt.

## Prerequisites

The Kubernetes cluster on master nodes is being rebuilt.

## Procedure

1. [Preparation](#1-preparation)
1. [Restore member directory](#2-restore-member-directory)
1. [Restart the cluster](#3-restart-the-cluster)

### 1. Preparation

This procedure can be run on any master NCN.

1. (`ncn-m#`) Select a snapshot to restore a backup.

    1. List the available backups.

        ```bash
        cd /opt/cray/platform-utils/s3 && ./list-objects.py --bucket-name etcd-backup
        ```

        Example output:

        ```text
        bare-metal/etcd-backup-2020-02-04-18-00-10.tar.gz
        bare-metal/etcd-backup-2020-02-04-18-10-06.tar.gz
        bare-metal/etcd-backup-2020-02-04-18-20-02.tar.gz
        bare-metal/etcd-backup-2020-02-04-18-30-10.tar.gz
        bare-metal/etcd-backup-2020-02-04-18-40-06.tar.gz
        bare-metal/etcd-backup-2020-02-04-18-50-03.tar.gz
        ```

    1. Set the `BACKUP_NAME` variable to the file name of the desired backup from the list.

        Omit the `bare-metal/` prefix shown in the output of the previous command, as well as the `.tar.gz` suffix.

        For example:

        ```bash
        BACKUP_NAME=etcd-backup-2020-02-04-18-50-03
        ```

1. (`ncn-m#`) Download the snapshot and copy it to all NCN master nodes.

    1. Retrieve the backup from S3 and uncompress it.

        ```bash
        mkdir /tmp/etcd_restore
        cd /opt/cray/platform-utils/s3
        ./download-file.py --bucket-name etcd-backup \
            --key-name "bare-metal/${BACKUP_NAME}.tar.gz" \
            --file-name "/tmp/etcd_restore/${BACKUP_NAME}.tar.gz"
        cd /tmp/etcd_restore
        gunzip "${BACKUP_NAME}.tar.gz"
        tar -xvf "${BACKUP_NAME}.tar"
        mv -v "${BACKUP_NAME}/etcd-dump.bin" /tmp
        ```

    1. Push the file to the other NCN master nodes.

        If not running these steps on `ncn-m001`, adjust the NCN names in the following command accordingly.

        ```bash
        scp /tmp/etcd-dump.bin ncn-m002:/tmp
        scp /tmp/etcd-dump.bin ncn-m003:/tmp
        ```

### 2. Restore member directory

The following procedure must be performed on all master nodes, one at a time. The order does not matter.

1. (`ncn-m#`) Create a new temporary `/tmp/etcd_restore` directory, if it does not already exist.

    ```bash
    mkdir -pv /tmp/etcd_restore
    ```

1. (`ncn-m#`) Change to the `/tmp/etcd_restore` directory.

    ```bash
    cd /tmp/etcd_restore
    ```

1. (`ncn-m#`) Retrieve values from the `kubeadmcfg.yaml` file.

    These values will be saved in variables and used in the following step.

    1. Retrieve the node name.

        The value should be the name of the master node where this command is being run (for example, `ncn-m002`).

        ```bash
        NODE_NAME=$(yq r /etc/kubernetes/kubeadmcfg.yaml 'etcd.local.extraArgs.name') ; echo "${NODE_NAME}"
        ```

    1. Retrieve the initial cluster.

        ```bash
        INIT_CLUSTER=$(yq r /etc/kubernetes/kubeadmcfg.yaml 'etcd.local.extraArgs.initial-cluster'); echo "${INIT_CLUSTER}"
        ```

        Example output:

        ```text
        ncn-m001=https://10.252.1.10:2380,ncn-m002=https://10.252.1.9:2380,ncn-m003=https://10.252.1.8:2380
        ```

    1. Retrieve the initial advertise peer URLs.

        ```bash
        INIT_URLS=$(yq r /etc/kubernetes/kubeadmcfg.yaml 'etcd.local.extraArgs.initial-advertise-peer-urls'); echo "${INIT_URLS}"
        ```

        Example output:

        ```text
        https://10.252.1.10:2380
        ```

1. (`ncn-m#`) Restore the member directory.

    ```bash
    ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt \
      --cert /etc/kubernetes/pki/etcd/server.crt \
      --key /etc/kubernetes/pki/etcd/server.key \
      --name "${NODE_NAME}" \
      --initial-cluster "${INIT_CLUSTER}" \
      --initial-cluster-token tkn \
      --initial-advertise-peer-urls "${INIT_URLS}" \
      snapshot restore /tmp/etcd-dump.bin
    ```

Repeat the steps in this section on the next master node, until they have been performed on every master node.

### 3. Restart the cluster

1. (`ncn-m#`) Stop the cluster.

    Run the following command on **each master node**.

    > If the etcd cluster is not currently running, this step can be skipped.

    ```bash
    systemctl stop etcd
    ```

1. (`ncn-m#`) Start the restored etcd cluster on **every** master node.

    Do the following steps on **each master node**.

    1. Set a variable with the node name of the current master node.

        ```bash
        NODE_NAME=ncn-mxxx
        ```

    1. Run the following commands.

        ```bash
        rm -rvf /var/lib/etcd/member &&
        cd /tmp/etcd_restore &&
        mv -v ${NODE_NAME}.etcd/member/ /var/lib/etcd/ &&
        systemctl start etcd
        ```

1. (`ncn-m#`) Confirm the membership of the cluster.

    This command can be run on any master node.

    ```bash
    ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt \
        --cert /etc/kubernetes/pki/etcd/server.crt \
        --key /etc/kubernetes/pki/etcd/server.key member list
    ```

    Example output:

    ```text
    448a8d056377359a, started, ncn-m001, https://10.252.1.7:2380, https://10.252.1.7:2379,https://127.0.0.1:2379, false
    986f6ff2a30b01cb, started, ncn-m002, https://10.252.1.8:2380, https://10.252.1.8:2379,https://127.0.0.1:2379, false
    d5a8e497e2788510, started, ncn-m003, https://10.252.1.9:2380, https://10.252.1.9:2379,https://127.0.0.1:2379, false
    ```
