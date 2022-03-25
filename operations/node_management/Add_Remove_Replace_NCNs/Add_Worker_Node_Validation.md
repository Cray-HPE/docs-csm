# Validate Added Worker Node

Validate the worker node added successfully.

1. Verify the new node is in the cluster.

      Run the following command from any master or worker node that is already in the cluster. It is helpful to run this command several times to watch for the newly added node to join the cluster. This should occur within 10 to 20 minutes.

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

1. Confirm /var/lib/containerd is on overlay on the node which was added.

    Run the following command on the added node.

    ```bash
    ncn-w# df -h /var/lib/containerd
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
