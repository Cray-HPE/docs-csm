# Validate Added Master Node

Validate the master node added successfully.

1. Verify the new node is in the cluster.

    Run the following command from any master or worker node that is already in the cluster. It is helpful to run this command several times to watch for the newly rebuilt node to join the cluster. This should occur within 10 to 20 minutes.

    ```bash
    ncn-mw# kubectl get nodes
    NAME       STATUS   ROLES    AGE    VERSION
    ncn-m001   Ready    master   113m   v1.19.9
    ncn-m002   Ready    master   113m   v1.19.9
    ncn-m003   Ready    master   112m   v1.19.9
    ncn-w001   Ready    <none>   112m   v1.19.9
    ncn-w002   Ready    <none>   112m   v1.19.9
    ncn-w003   Ready    <none>   112m   v1.19.9
    ```

1. Confirm the `sdc` disk has the correct lvm on the rebuilt node.

    ```bash
    ncn-m# lsblk | grep -A2 ^sdc
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
