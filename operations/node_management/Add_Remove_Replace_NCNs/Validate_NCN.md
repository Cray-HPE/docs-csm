# Validate Added NCN

Only follow the steps in the section for the node type that was added:

- [Master Node](#validate-master-node)
- [Worker Node](#validate-worker-node)
- [Storage Node](#validate-storage-node)

<a name="validate-master-node"></a>

## Validate: Master Node

Validate the master node added successfully.

1. Verify the new node is in the cluster.

    Run the following command from any master or worker node that is already in the cluster. It is helpful to run this command several times to watch for the newly rebuilt node to join the cluster. This should occur within 10 to 20 minutes.

    ```bash
    ncn-mw# kubectl get nodes
    ```

    Example output:

    ```text
    NAME       STATUS   ROLES    AGE    VERSION
    ncn-m001   Ready    master   113m   v1.19.9
    ncn-m002   Ready    master   113m   v1.19.9
    ncn-m003   Ready    master   112m   v1.19.9
    ncn-w001   Ready    <none>   112m   v1.19.9
    ncn-w002   Ready    <none>   112m   v1.19.9
    ncn-w003   Ready    <none>   112m   v1.19.9
    ```

1. Confirm the `sdc` disk has the correct `lvm` on the rebuilt node.

    ```bash
    ncn-m# lsblk `blkid -L ETCDLVM` 
    ```

    Example output:

    ```text
    sdc                   8:32   0 447.1G  0 disk
     └─ETCDLVM           254:0    0 447.1G  0 crypt
       └─etcdvg0-ETCDK8S 254:1    0    32G  0 lvm   /run/lib-etcd
    ```

1. Confirm `etcd` is running and shows the node as a member once again.

    The newly built master node should be in the returned list.

    ```bash
    ncn-m# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/ca.crt \
                   --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member list
    ```

<a name="validate-worker-node"></a>

## Validate: Worker Node

Validate the worker node added successfully.

1. Verify the new node is in the cluster.

    Run the following command from any master or worker node that is already in the cluster. It is helpful to run this command several times to watch for the newly added node to join the cluster. This should occur within 10 to 20 minutes.

    ```bash
    ncn-mw# kubectl get nodes
    ```

    Example output:

    ```text
    NAME       STATUS   ROLES    AGE    VERSION
    ncn-m001   Ready    master   113m   v1.19.9
    ncn-m002   Ready    master   113m   v1.19.9
    ncn-m003   Ready    master   112m   v1.19.9
    ncn-w001   Ready    <none>   112m   v1.19.9
    ncn-w002   Ready    <none>   112m   v1.19.9
    ncn-w003   Ready    <none>   112m   v1.19.9
    ```

1. Confirm `/var/lib/containerd` is on overlay on the node which was added.

    Run the following command on the added node.

    ```bash
    ncn-w# df -h /var/lib/containerd
    ```

    Example output:

    ```text
    Filesystem            Size  Used Avail Use% Mounted on
    containerd_overlayfs  378G  245G  133G  65% /var/lib/containerd
    ```

    After several minutes of the node joining the cluster, pods should be in a `Running` state for the worker node.

1. Confirm the pods are beginning to get scheduled and reach a `Running` state on the worker node.

    Run this command on any master or worker node. This command assumes you have set the variables from [the prerequisites section](../Add_Remove_Replace_NCNs.md#add-ncn-prerequisites).

    ```bash
    ncn# kubectl get po -A -o wide | grep $NODE
    ```

1. Confirm BGP is healthy.

    Follow the steps in the [Check BGP Status and Reset Sessions](../../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md#Prerequisites) to verify and fix BGP if needed.

<a name="validate-storage-node"></a>

## Validate: Storage Node

Validate the storage node added successfully. The following examples are based on a storage cluster that was expanded from three nodes to four.

1. Verify the Ceph status looks correct.
    1. Get the current Ceph status:

        ```bash
        ncn-m# ceph -s
        ```

        Example output:

        ```text
        cluster:
          id:     b13f1282-9b7d-11ec-98d9-b8599f2b2ed2
          health: HEALTH_OK

        services:
          mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 4h)
          mgr: ncn-s001.pdeosn(active, since 4h), standbys: ncn-s002.wjnqvu, ncn-s003.avkrzl
          mds: cephfs:1 {0=cephfs.ncn-s001.ldlvfj=up:active} 1 up:standby-replay 1 up:standby
          osd: 18 osds: 18 up (since 4h), 18 in (since 4h)
          rgw: 4 daemons active (site1.zone1.ncn-s001.ktslgl, site1.zone1.ncn-s002.inynsh, site1.zone1.ncn-s003.dvyhak, site1.zone1.ncn-s004.jnhqvt)

        task status:

          data:
            pools:   12 pools, 713 pgs
            objects: 37.20k objects, 72 GiB
            usage:   212 GiB used, 31 TiB / 31 TiB avail
            pgs:     713 active+clean

          io:
            client:   7.0 KiB/s rd, 300 KiB/s wr, 2 op/s rd, 49 op/s wr
          ```

    1. Verify that the status shows the following:
        - 3 `mon`s
        - 3 `mds`
        - 3 `mgr` processes
        - 1 `rgw` for each storage node (4 in this example)

1. Verify the added host contains OSDs and the OSDs are up.

    ```bash
    ncn-m# ceph osd tree
    ```

    Example output:

    ```text
    ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
    -1         31.43875  root default
    -7          6.98639      host ncn-s001
     0    ssd   1.74660          osd.0          up   1.00000  1.00000
    10    ssd   1.74660          osd.10         up   1.00000  1.00000
    11    ssd   1.74660          osd.11         up   1.00000  1.00000
    15    ssd   1.74660          osd.15         up   1.00000  1.00000
    -3          6.98639      host ncn-s002
     3    ssd   1.74660          osd.3          up   1.00000  1.00000
     5    ssd   1.74660          osd.5          up   1.00000  1.00000
     7    ssd   1.74660          osd.7          up   1.00000  1.00000
    12    ssd   1.74660          osd.12         up   1.00000  1.00000
    -5          6.98639      host ncn-s003
     1    ssd   1.74660          osd.1          up   1.00000  1.00000
     4    ssd   1.74660          osd.4          up   1.00000  1.00000
     8    ssd   1.74660          osd.8          up   1.00000  1.00000
    13    ssd   1.74660          osd.13         up   1.00000  1.00000
    -9         10.47958      host ncn-s004
     2    ssd   1.74660          osd.2          up   1.00000  1.00000
     6    ssd   1.74660          osd.6          up   1.00000  1.00000
     9    ssd   1.74660          osd.9          up   1.00000  1.00000
    14    ssd   1.74660          osd.14         up   1.00000  1.00000
    16    ssd   1.74660          osd.16         up   1.00000  1.00000
    17    ssd   1.74660          osd.17         up   1.00000  1.00000
    ```

1. Verify the `radosgw` and `haproxy` are correct.

    Run the following command on the added storage node.

    There will be an output \(without an error\) returned if `radosgw` and `haproxy` are correct.

    ```bash
    ncn-s# curl -k https://rgw-vip.nmn
    ```

    Example output:

    ```text
    <?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/ "><Owner><ID>anonymous</ID><DisplayName></DisplayName></Owner><Buckets></Buckets></ListAllMyBucketsResult
    ```

## Next Step

Proceed to the next step to [Validate Health](Validate_Health.md) or return to the main [Add, Remove, Replace, or Move NCNs](../Add_Remove_Replace_NCNs.md) page.
