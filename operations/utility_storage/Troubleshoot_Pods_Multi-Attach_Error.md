# Troubleshoot Pods Multi-Attach Error

Troubleshoot an issue where pods cannot restart on another worker node because of the
"Volume is already exclusively attached to one node and can't be attached to another" error.
Kubernetes does not currently support `readwritemany` access mode for
Rados Block Device \(RBD\) devices, which causes an issue where devices fail to unmap correctly.

The issue occurs when unmounting the mounts tied to the RBD devices, which causes the`rbd-task`
\(watcher\) to not stop for the RBD device.

**WARNING:** If this process is followed and there are mount points that cannot be unmounted
without using the force option, then a process may still be writing to them. If mount points
are forcefully unmounted, there is a high probability of data loss or corruption.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. (`ncn-mw#`) Force delete the pod.

    This may not be successful, but it is important to try before proceeding.

    ```bash
    NAMESPACE=vault
    POD_NAME=cray-vault-0
    kubectl delete pod -n $NAMESPACE $POD_NAME --force --grace-period=0
    ```

    If this does not resolve the issue, then continue following this procedure.

1. (`ncn-mw#`) Describe the pod experiencing issues.

    The returned Persistent Volume Claim \(PVC\) information will be needed in future steps.

    ```bash
    kubectl -n services describe pod $POD_NAME
    ```

    Excerpt of example output:

    ```text
    Events:
      Type     Reason              Age   From                     Message
      ----     ------              ----  ----                     -------
      Normal   Scheduled           23s   default-scheduler        Successfully assigned services/cray-vault-0 to ncn-w003
      Warning  FailedAttachVolume  23s   attachdetach-controller  Multi-Attach error for volume "**pvc-186dc7a5-9c9a-450b-b856-4308c331b37**" Volume is already exclusively attached to one node and can't be attached to another
    ```

    In this example, `pvc-186dc7a5-9c9a-450b-b856-4308c331b37` is the PVC information required for the next step.

1. (`ncn-mw#`) Retrieve the Ceph volume.

    ```bash
    PVC_NAME=pvc-186dc7a5-9c9a-450b-b856-4308c331b37
    kubectl describe -n $NAMESPACE pv $PVC_NAME
    ```

    Example output:

    ```text
    Name:            pvc-186dc7a5-9c9a-450b-b856-4308c331b373
    Labels:          <none>
    Annotations:     pv.kubernetes.io/provisioned-by: rbd.csi.ceph.com
    Finalizers:      [kubernetes.io/pv-protection external-provisioner.volume.kubernetes.io/finalizer]
    StorageClass:    k8s-block-replicated
    Status:          Bound
    Claim:           vault/vault-raft-cray-vault-0
    Reclaim Policy:  Delete
    Access Modes:    RWO
    VolumeMode:      Filesystem
    Capacity:        2Gi
    Node Affinity:   <none>
    Message:
    Source:
        Type:              CSI (a Container Storage Interface (CSI) volume source)
        Driver:            rbd.csi.ceph.com
        FSType:            ext4
        VolumeHandle:      0001-0024-f17091d2-31a2-11f0-b30a-42010afc0104-000000000000000b-10f31479-31a7-11f0-9092-ea5ff752cdc5
        ReadOnly:          false
        VolumeAttributes:      clusterID=f17091d2-31a2-11f0-b30a-42010afc0104
                               imageFeatures=layering
                               imageName=csi-vol-10f31479-31a7-11f0-9092-ea5ff752cdc5
                               journalPool=kube
                               pool=kube
                               storage.kubernetes.io/csiProvisionerIdentity=1747325223051-8081-rbd.csi.ceph.com
    Events:                <none>
    ```

1. Save the RBD name.

    ```bash
    CEPH_IMAGE_NAME=$(kubectl get pv -n vault $PVC_NAME -o json | \
    jq -r '.spec.csi.volumeAttributes.imageName')
    RBD_NAME=$(kubectl get pv -n vault $PVC_NAME -o json | \
    jq -r '"\(.spec.csi.volumeAttributes.pool)/\(.spec.csi.volumeAttributes.imageName)"')
    ```

1. (`ncn-m#`) Find the worker node that has the RBD locked.

    1. Find the RBD status.

        Take a note of the returned IP address.

        ```bash
        rbd status $RBD_NAME
        ```

        For example:

        ```bash
        rbd status kube/kubernetes-dynamic-pvc-3ce9ec37-846b-11ea-acae-86f521872f4c
        ```

        Example output:

        ```text
        Watchers:
                watcher=10.252.1.11:0/3628969487 client.74826 cookie=18446462598732840963
        ```

    1. Use the returned IP address to get the host name attached to it.

        Take note of the returned host name.

        ```bash
        IP_ADDRESS=10.252.1.11
        grep $IP_ADDRESS /etc/hosts
        ```

        Example output:

        ```text
        10.252.1.11     ncn-w005.nmn ncn-w005
        ```

1. Save the host name returned in the previous step.

    ```bash
    HOST_NAME=ncn-w005
    ```

1. (`ncn#`) Unmap the device.

    1. Find the RBD number.

        Use the `CEPH_IMAGE_NAME` value identified earlier.

        ```bash
        ssh "${HOST_NAME}" rbd showmapped | grep "${CEPH_IMAGE_NAME}"
        ```

        Example output:

        ```text
        2   kube             csi-vol-5a91ee3d-4539-11ef-a44c-2629c446168b  -     /dev/rbd2
        ```

        Take note of the returned RBD number, which will be used in the next step.

    1. SSH to the host and set varibles needed

        ```bash
        ssh $HOST_NAME
        RBD_NUMBER=rbd2
        ```

    1. Verify it is not in use by an unstopped container.

        ```bash
        mount | grep "${RBD_NUMBER}"
        ```

        If no mount points are returned, proceed to the next step. If mount points are returned, then run the following command for each mount point:

        ```bash
        unmount MOUNT_POINT
        ```

        **Troubleshooting:** If that still does not succeed, use the unmount `-f` option.

        **WARNING:** If mount points are forcefully unmounted, there is a chance for data loss or corruption.

    1. Unmap the device.

        ```bash
        rbd unmap -o force /dev/$RBD_NUMBER
        ```

    1. Disconnect from the host

        ```bash
        exit
        ```

1. (`ncn-mw#`) Check the status of the pod.

    ```bash
    kubectl get pod -n $NAMESPACE $POD_NAME
    ```

    **Troubleshooting:** If the pod status has not changed, try deleting the pod to restart it.

    ```bash
    kubectl delete pod -n $NAMESPACE $POD_NAME
    ```
