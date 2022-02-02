# Troubleshoot Pods Failing to Restart on Other Worker Nodes

Troubleshoot an issue where pods cannot restart on another worker node because of the "Volume is already exclusively attached to one node and can't be attached to another" error. Kubernetes does not currently support "readwritemany" access mode for Rados Block Device \(RBD\) devices, which causes an issue where devices fail to unmap correctly.

The issue occurs when unmounting the mounts tied to the RBD devices, which causes the rbd-task \(watcher\) to not stop for the RBD device.

**WARNING:** If this process is followed and there are mount points that cannot be unmounted without using the force option, then a process may still be writing to them. If mount points are forcefully unmounted, there is a high probability of data loss or corruption.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. Force delete the pod.

    This may not be successful, but it is important to try before proceeding.

    ```bash
    ncn-w001# kubectl delete pod -n NAMESPACE POD_NAME --force --grace-period=0
    ```

1. Log in to a manager node and proceed if the previous step did not fix the issue.

1. Describe the pod experiencing issues.

    The returned Persistent Volume Claim \(PVC\) information will be needed in future steps.

    ```bash
    ncn-m001# kubectl -n services describe pod POD_ID
    ```

    Example output:

    ```
    [...]

    Events:
      Type     Reason              Age   From                     Message
      ----     ------              ----  ----                     -------
      Normal   Scheduled           23s   default-scheduler        Successfully assigned services/cray-ims-6578bf7874-twwp7 to ncn-w002
      Warning  FailedAttachVolume  23s   attachdetach-controller  Multi-Attach error for volume "**pvc-6ac68e32-de91-4e21-ac9f-c743b3ecb776**" Volume is already exclusively attached to one node and can't be attached to another

    ```

    In this example, pvc-6ac68e32-de91-4e21-ac9f-c743b3ecb776 is the PVC information required for the next step.

1. Retrieve the Ceph volume.

    ```bash
    ncn-m001# kubectl describe -n NAMESPACE pv PVC_NAME
    ```

    Example output:

    ```
    Name:            pvc-6ac68e32-de91-4e21-ac9f-c743b3ecb776
    Labels:          <none>
    Annotations:     pv.kubernetes.io/provisioned-by: ceph.com/rbd
                     rbdProvisionerIdentity: ceph.com/rbd
    Finalizers:      [kubernetes.io/pv-protection]
    StorageClass:    ceph-rbd-external
    Status:          Bound
    Claim:           services/cray-ims-data-claim
    Reclaim Policy:  Delete
    Access Modes:    RWO
    VolumeMode:      Filesystem
    Capacity:        10Gi
    Node Affinity:   <none>
    Message:
    Source:
        Type:          RBD (a Rados Block Device mount on the host that shares a pod's lifetime)
        CephMonitors:  [10.252.0.10 10.252.0.11 10.252.0.12]
        RBDImage:      kubernetes-dynamic-pvc-3ce9ec37-846b-11ea-acae-86f521872f4c  <<-- Ceph image name
        FSType:
        RBDPool:       kube                                                         <<-- Ceph pool
        RadosUser:     kube
        Keyring:       /etc/ceph/keyring
        SecretRef:     &SecretReference{Name:ceph-rbd-kube,Namespace:ceph-rbd,}
        ReadOnly:      false
    Events:            <none>
    ```

1. Find the worker node that has the RBD locked.

    1. Find the RBD status.

        Take a note of the returned IP address.

        ```bash
        ncn-m001# rbd status CEPH_POOL_NAME/CEPH_IMAGE_NAME
        ```

        For example:

        ```bash
        ncn-m001# rbd status kube/kubernetes-dynamic-pvc-3ce9ec37-846b-11ea-acae-86f521872f4c
        Watchers:
            watcher=**10.252.0.4**:0/3520479722 client.689192 cookie=18446462598732840976
        ```

    1. Use the returned IP address to get the host name attached to it.

        Take note of the returned host name.

        ```bash
        ncn-m001# grep IP_ADDRESS /etc/hosts
        ```

        Example output:

        ```
        10.252.0.4      ncn-w001.local ncn-w001 ncn-w001-nmn.local x3000c0s7b0n0 ncn-w001-nmn sms01-nmn.local sms04-nmn sms.local sms-nmn sms-nmn.local mgmt-plane-cmn mgmt-plane-cmn.local mgmt-plane-nmn.local bis.local bis time-nmn time-nmn.local #-label-10.252.0.4
        ```

1. SSH to the host name returned in the previous step.

    ```bash
    ncn-m001# ssh HOST_NAME
    ```

1. Unmap the device.

    1. Find the RBD number.

        Use the CEPH\_IMAGE\_NAME value returned in step 4.

        ```bash
        ncn-m001# rbd showmapped|grep CEPH_IMAGE_NAME
        ```

        Example output:

        ```
        16 kube           kubernetes-dynamic-pvc-3ce9ec37-846b-11ea-acae-86f521872f4c -    /dev/**rbd16**
        ```

        Take note of the returned RBD number, which will be used in the next step.

    1. Verify it is not in use by an unstopped container.

        ```bash
        ncn-m001# mount|grep RBD_NUMBER
        ```

        If no mount points are returned, proceed to the next step. If mount points are returned, run the following command:

        ```bash
        ncn-m001# unmount MOUNT_POINT
        ```

        **Troubleshooting:** If that still does not succeed, use the unmount `-f` option.

        **WARNING:** If mount points are forcefully unmounted, there is a chance for data loss or corruption.

    1. Unmap the device.

        ```bash
        ncn-m001# rbd unmap -o force /dev/RBD_NUMBER
        ```

1. Check the status of the pod.

    ```bash
    ncn-m001# kubectl get pod -n NAMESPACE POD_NAME
    ```

    **Troubleshooting:** If the pod status has not changes, try deleting the pod to restart it.

    ```bash
    ncn-m001# kubectl delete pod -n NAMESPACE POD_NAME
    ```
