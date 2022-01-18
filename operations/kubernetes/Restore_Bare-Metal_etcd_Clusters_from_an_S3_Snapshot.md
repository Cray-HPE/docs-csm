## Restore Bare-Metal etcd Clusters from an S3 Snapshot

The etcd cluster that serves Kubernetes on master nodes is backed up every 10 minutes. These backups are pushed to Ceph Rados Gateway \(S3\).

Restoring the etcd cluster from backup is only meant to be used in a catastrophic scenario, whereby the Kubernetes cluster and master nodes are being rebuilt. This procedure shows how to restore the bare-metal etcd cluster from an Simple Storage Service \(S3\) snapshot.

The etcd cluster needs to be restored from a backup when the Kubernetes cluster and master nodes are being rebuilt.


### Prerequisites

The Kubernetes cluster on master nodes is being rebuilt.

### Procedure

1.  Select a snapshot to restore a backup.

    The following command lists the available backups. It must be run from the /opt/cray/platform-utils/s3 directory.

    ```bash
    ncn# ./list-objects.py --bucket-name etcd-backup
    ```

    Example output:

    ```
    bare-metal/etcd-backup-2020-02-04-18-00-10.tar.gz
    bare-metal/etcd-backup-2020-02-04-18-10-06.tar.gz
    bare-metal/etcd-backup-2020-02-04-18-20-02.tar.gz
    bare-metal/etcd-backup-2020-02-04-18-30-10.tar.gz
    bare-metal/etcd-backup-2020-02-04-18-40-06.tar.gz
    bare-metal/etcd-backup-2020-02-04-18-50-03.tar.gz
    ```

    Note the file name for the desired snapshot/backup.

1.  Download the snapshot and copy it to all NCN master nodes.

    1.  Retrieve the backup from S3 and uncompress it.

        ```bash
        ncn# mkdir /tmp/etcd_restore
        ncn# cd /opt/cray/platform-utils/s3
        ncn# ./download-file.py --bucket-name etcd-backup \
        --key-name bare-metal/etcd-backup-2020-02-04-18-50-03.tar.gz \
        --file-name /tmp/etcd_restore/etcd-backup-2020-02-04-18-50-03.tar.gz
        ncn# cd /tmp/etcd_restore
        ncn# gunzip etcd-backup-2020-02-04-18-50-03.tar.gz
        ncn# tar -xvf etcd-backup-2020-02-04-18-50-03.tar
        ncn# mv etcd-backup-2020-02-04-18-50-03/etcd-dump.bin /tmp
        ```

    2.  Push the file to the other NCN master nodes.

        ```bash
        ncn# scp /tmp/etcd-dump.bin ncn-m002:/tmp
        ncn# scp /tmp/etcd-dump.bin ncn-m003:/tmp
        ```

1.  Prepare to restore the member directory for `ncn-m001`.

    1.  Log in as root to `ncn-m001`.

    2.  Create a new temporary /tmp/etcd\_restore directory.

        ```screen
        ncn-m001# mkdir /tmp/etcd_restore
        ```

    3.  Change to the /tmp/etcd_restore directory.

        ```screen
        ncn-m001# cd /tmp/etcd_restore
        ```

    4.  Retrieve the 'initial-cluster' and 'initial-advertise-peer-urls' values from the `kubeadmcfg.yaml` file.

        The returned values will be used in the next step.

        ```bash
        ncn-m001# grep -e initial-cluster: -e initial-advertise-peer-urls: \
        /etc/kubernetes/kubeadmcfg.yaml
        ```

        Example output:

        ```
        initial-cluster: ncn-m001=https://10.252.1.7:2380,ncn-m002=https://10.252.1.8:2380,ncn-m003=https://10.252.1.9:2380
        initial-advertise-peer-urls: https://10.252.1.7:2380
        ```

    5.  Restore the member directory.

        ```bash
        ncn-m001# ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt \
          --cert /etc/kubernetes/pki/etcd/server.crt \
          --key /etc/kubernetes/pki/etcd/server.key \
          --name ncn-m001 \
          --initial-cluster ncn-m001=https://10.252.1.7:2380,ncn-m002=https://10.252.1.8:2380,ncn-m003=https://10.252.1.9:2380 \
          --initial-cluster-token tkn \
          --initial-advertise-peer-urls https://10.252.1.7:2380 \
          snapshot restore /tmp/etcd-dump.bin
        ```

1.  Prepare to restore the member directory for `ncn-m002`.

    1.  Log in as root to `ncn-m002`.

    2.  Create a new temporary /tmp/etcd\_restore directory.

        ```bash
        ncn-m002# mkdir /tmp/etcd_restore
        ```

    3.  Change to the `/tmp/etcd_restore` directory.

        ```bash
        ncn-m002# cd /tmp/etcd_restore
        ```

    4.  Retrieve the 'initial-cluster' and 'initial-advertise-peer-urls' values from the `kubeadmcfg.yaml` file.

        The returned values will be used in the next step.

        ```bash
        ncn-m002# grep -e initial-cluster: -e initial-advertise-peer-urls: \
        /etc/kubernetes/kubeadmcfg.yaml
        ```

        Example output:

        ```
        initial-cluster: ncn-m001=https://10.252.1.7:2380,ncn-m002=https://10.252.1.8:2380,ncn-m003=https://10.252.1.9:2380
        initial-advertise-peer-urls: https://10.252.1.8:2380
        ```

    5.  Restore the member directory.

        ```bash
        ncn-m002# ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt \
        --cert /etc/kubernetes/pki/etcd/server.crt \
        --key /etc/kubernetes/pki/etcd/server.key \
        --name ncn-m002 \
        --initial-cluster ncn-m001=https://10.252.1.7:2380,ncn-m002=https://10.252.1.8:2380,ncn-m003=https://10.252.1.9:2380 \
        --initial-cluster-token tkn \
        --initial-advertise-peer-urls https://10.252.1.8:2380 \
        snapshot restore /tmp/etcd-dump.bin
        ```

1.  Prepare to restore the member directory for `ncn-m003`.

    1.  Log in as root to `ncn-m003`.

    2.  Create a new temporary /tmp/etcd\_restore directory.

        ```bash
        ncn-m003# mkdir /tmp/etcd_restore
        ```

    3.  Change to the `/tmp/etcd_restore` directory.

        ```bash
        ncn-m003# cd /tmp/etcd_restore
        ```

    4.  Retrieve the 'initial-cluster' and 'initial-advertise-peer-urls' values from the `kubeadmcfg.yaml` file.

        The returned values will be used in the next step.

        ```bash
        ncn-m003# grep -e initial-cluster: -e initial-advertise-peer-urls: \
        /etc/kubernetes/kubeadmcfg.yaml
        ```

        Example output:

        ```
        initial-cluster: ncn-m001=https://10.252.1.7:2380,ncn-m002=https://10.252.1.8:2380,ncn-m003=https://10.252.1.9:2380
        initial-advertise-peer-urls: https://10.252.1.9:2380
        ```

    5.  Restore the member directory.

        ```bash
        ncn-m003# ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt \
        --cert /etc/kubernetes/pki/etcd/server.crt \
        --key /etc/kubernetes/pki/etcd/server.key \
        --name ncn-m003 \
        --initial-cluster ncn-m001=https://10.252.1.7:2380,ncn-m002=https://10.252.1.8:2380,ncn-m003=https://10.252.1.9:2380 \
        --initial-cluster-token tkn \
        --initial-advertise-peer-urls https://10.252.1.9:2380 \
        snapshot restore /tmp/etcd-dump.bin
        ```

1.  Stop the current running cluster.

    If the cluster is currently running, run the following command on all three master nodes \(`ncn-m001`, `ncn-m002`, `ncn-m003`\).

    1.  Stop the cluster on `ncn-m001`.

        ```bash
        ncn-m001# systemctl stop etcd
        ```

    2.  Stop the cluster on `ncn-m002`.

        ```bash
        ncn-m002# systemctl stop etcd
        ```

    3.  Stop the cluster on `ncn-m003`.

        ```bash
        ncn-m003# systemctl stop etcd
        ```

1.  Start the restored cluster on each master node.

    Run the following commands on all three master nodes \(`ncn-m001`, `ncn-m002`, `ncn-m003`\) to start the restored cluster.

    1.  Start the cluster on `ncn-m001`.

        ```bash
        ncn-m001# rm -rf /var/lib/etcd/member
        ncn-m001# mv ncn-m001.etcd/member/ /var/lib/etcd/
        ncn-m001# systemctl start etcd
        ```

    2.  Start the cluster on `ncn-m002`.

        ```bash
        ncn-m002# rm -rf /var/lib/etcd/member
        ncn-m002# mv ncn-m002.etcd/member/ /var/lib/etcd/
        ncn-m002# systemctl start etcd
        ```

    3.  Start the cluster on `ncn-m003`.

        ```bash
        ncn-m003# rm -rf /var/lib/etcd/member
        ncn-m003# mv ncn-m003.etcd/member/ /var/lib/etcd/
        ncn-m003# systemctl start etcd
        ```

1. Confirm the membership of the cluster.

    ```bash
    ncn-m001# ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt \
    --cert /etc/kubernetes/pki/etcd/server.crt \
    --key /etc/kubernetes/pki/etcd/server.key member list
    ```

    Example output:

    ```
    448a8d056377359a, started, ncn-m001, https://10.252.1.7:2380, https://10.252.1.7:2379,https://127.0.0.1:2379
    986f6ff2a30b01cb, started, ncn-m002, https://10.252.1.8:2380, https://10.252.1.8:2379,https://127.0.0.1:2379
    d5a8e497e2788510, started, ncn-m003, https://10.252.1.9:2380, https://10.252.1.9:2379,https://127.0.0.1:2379
    ```




