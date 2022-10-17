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
        cd /opt/cray/platform-utils/s3 && ./list-objects.py \
        --bucket-name etcd-backup | grep bare-metal
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

1. (`ncn-m#`)  After a few minutes, if any cron jobs appear stuck, and/or pods have yet to reach the Running state, the cron jobs will need to be restarted and the associated pods deleted.

    For example, following a successful Bare-Metal etcd cluster restore it can be observed that the `kube-etcdbackup`,
    `cray-dns-unbound-manager` and `sonar-sync` cron jobs have not been scheduled for 18 minutes. The `hms-discovery` cron job at 20 minutes is in the same situation.

    ```bash
    kubectl get cronjobs.batch -A
    ```

    Example output:

    ```text
    NAMESPACE     NAME                                 SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    argo          cray-nls-postgresql-db-backup        10 23 * * *    False     0        21h             26h
    kube-system   kube-etcdbackup                      */10 * * * *   False     1        18m             33h
    operators     kube-etcd-defrag                     0 0 * * *      False     0        20h             33h
    operators     kube-etcd-defrag-cray-hbtd-etcd      0 */4 * * *    False     0        38m             33h
    operators     kube-etcd-periodic-backup-cron       0 * * * *      False     0        38m             33h
    services      cray-dns-unbound-manager             */2 * * * *    False     1        18m             33h
    services      cray-keycloak-postgresql-db-backup   10 2 * * *     False     0        18h             33h
    services      cray-sls-postgresql-db-backup        10 23 * * *    False     0        21h             33h
    services      cray-smd-postgresql-db-backup        10 0 * * *     False     0        20h             33h
    services      gitea-vcs-postgresql-db-backup       10 1 * * *     False     0        19h             33h
    services      hms-discovery                        */3 * * * *    False     0        20m             33h
    services      sonar-sync                           */1 * * * *    False     1        18m             34h
    spire         spire-postgresql-db-backup           10 3 * * *     False     0        17h             33h
    vault         spire-intermediate                   0 0 * * 1      False     0        <none>          23h
    ```

    The `kube-etcdbackup`, `cray-dns-unbound-manager`, `sonar-sync` and `hms-discovery` cron jobs need to be restarted.
    For example restarting the `kube-etcdbackup` cron job:

    ```bash
     kubectl get cronjobs.batch -n kube-system kube-etcdbackup -o json | \
     jq 'del(.spec.selector)' | \
     jq 'del(.spec.template.metadata.labels."controller-uid")' | \
     kubectl replace --force -f -
    ```

    Example output:

    ```text
    cronjob.batch "kube-etcdbackup" deleted
    cronjob.batch/kube-etcdbackup replaced
    ```

    and the stuck cron jobs are now running.

    ```bash
    kubectl get cronjobs.batch -A
    ```

    Example output:

    ```text
     NAMESPACE     NAME                                 SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
     argo          cray-nls-postgresql-db-backup        10 23 * * *    False     0        21h             26h
     kube-system   kube-etcdbackup                      */10 * * * *   False     0        41s             33h
     operators     kube-etcd-defrag                     0 0 * * *      False     0        20h             33h
     operators     kube-etcd-defrag-cray-hbtd-etcd      0 */4 * * *    False     0        30m             33h
     operators     kube-etcd-periodic-backup-cron       0 * * * *      False     0        30m             33h
     services      cray-dns-unbound-manager             */2 * * * *    False     0        41s             33h
     services      cray-keycloak-postgresql-db-backup   10 2 * * *     False     0        18h             33h
     services      cray-sls-postgresql-db-backup        10 23 * * *    False     0        21h             33h
     services      cray-smd-postgresql-db-backup        10 0 * * *     False     0        20h             33h
     services      gitea-vcs-postgresql-db-backup       10 1 * * *     False     0        19h             33h
     services      hms-discovery                        */3 * * * *    False     1        41s             33h
     services      sonar-sync                           */1 * * * *    False     1        41s             33h
     spire         spire-postgresql-db-backup           10 3 * * *     False     0        17h             33h
     vault         spire-intermediate                   0 0 * * 1      False     0        <none>          22h
     ```

    At the same time these associated pods had not yet reached the running state and needed to be deleted.

   ```bash
    kubectl get pods -A -o wide | grep -v "Completed\|Running"
    ```

    Example output:

    ```text
    NAMESPACE           NAME                                                              READY   STATUS              RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
    kube-system         kube-etcdbackup-27758660-xj9kb                                    0/1     ContainerCreating   0          23m   <none>        ncn-w002   <none>           <none>
    services            cray-dns-unbound-manager-27758660-d7d2l                           0/2     Init:0/1            0          23m   <none>        ncn-w003   <none>           <none>
    services            sonar-sync-27758660-75qxb                                         0/1     ContainerCreating   0          23m   <none>        ncn-w002   <none>           <none>
     ```
