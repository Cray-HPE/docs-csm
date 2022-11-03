# 6.2. Validate Master Node

Validate the master node rebuilt successfully.

Skip this section if a worker or storage node was rebuilt.

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

1. Ensure there is proper routing set up for liquid-cooled hardware.

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

1. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig after rebooting the node.

    The following command will indicate if a CFS job is currently in progress for this node. This command assumes you have set the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites).

    ```bash
    ncn# cray cfs components describe $XNAME --format json
    {
      "configurationStatus": "configured",
      "desiredConfig": "ncn-personalization-full",
      "enabled": true,
      "errorCount": 0,
      "id": "x3000c0s7b0n0",
      "retryPolicy": 3,
    ```

    If the configurationStatus is `pending`, wait for the job to finish before continuing. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus should be addressed now for this node. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.
    If configurationStatus is `failed`, See [Troubleshoot Ansible Play Failures in CFS Sessions](../../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md#Prerequisites) for how to analyze the pod logs from `cray-cfs` to determine why the configuration may not have completed.

1. Collect data about the system management platform health \(can be run from a master or worker NCN\).

    ```bash
    ncn-mw# /opt/cray/platform-utils/ncnHealthChecks.sh
    ncn-mw# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
    ```

   [Return to Main Page](../Rebuild_NCNs.md#Validation)
