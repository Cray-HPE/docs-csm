# Kubernetes pods failing to mount PVCs

- [Introduction](#introduction)
- [Example errors](#example-errors)
- [Resolution](#resolution)

## Introduction

Pods may fail because they are unable to mount PVCs. The root cause of this problem can be the Ceph MDS server daemon.
The symptoms of a Ceph MDS problem are generally Kubernetes issues.
Ceph MDS issues can be caused by clock skew on storage nodes currently or if there was clock skew previously.

## Example errors

The following are errors that may be observed due to this issue:

- Pods failing because they are unable to mount PVCs. A pod description could contain the following errors.

    ```bash
    Warning  FailedMount      98s (x11 over 24m)  kubelet            (combined from similar events): Unable to attach or mount volumes: unmounted volumes=[snapshot-volume], unattached volumes=[snapshot-volume istio-podinfo istiod-ca-cert istio-data istio-envoy istio-token kube-api-access-w9sjw etcd-jwt-token etcd-config data]: timed out waiting for the condition
    ```

    ```bash
    Mar 27 18:04:26 ncn-w001 kubelet[63627]: E0327 23:04:26.085783   63627 kubelet_pods.go:226] failed to prepare subPath for volumeMount "slurm-data" of container "slurmctld": error resolving symlinks in "/var/lib/kubelet/pods/8c006150-1473-4299-a2c5-429d6bd145ed/volumes/kubernetes.io~cephfs/pvc-1a2bd4b7-1fee-4175-9f53-ff5b7ef8dea2": lstat /var/lib/kubelet/pods/8c006150-1473-4299-a2c5-429d6bd145ed/volumes/kubernetes.io~cephfs/pvc-1a2bd4b7-1fee-4175-9f53-ff5b7ef8dea2: permission denied
    Mar 27 18:04:26 ncn-w001 kubelet[63627]: E0327 23:04:26.085818   63627 kuberuntime_manager.go:803] container start failed: CreateContainerConfigError: failed to prepare subPath for volumeMount "slurm-data" of container "slurmctld"
    Mar 27 18:04:26 ncn-w001 kubelet[63627]: E0327 23:04:26.085852   63627 pod_workers.go:191] Error syncing pod 8c006150-1473-4299-a2c5-429d6bd145ed ("slurmctld-6cb8c4fd66-h4wx6_user(8c006150-1473-4299-a2c5-429d6bd145ed)"), skipping: failed to "StartContainer" for "slurmctld" with CreateContainerConfigError: "failed to prepare subPath for volumeMount \"slurm-data\" of container \"slurmctld\""
    ```

- The PVC mounts on worker nodes may have permission denied error.
The problem can exist even if not all files have a permission denied error.

    Example error:

    ```bash
    ncn-w003:~ # ls -al /var/lib/kubelet/pods/4ff6d8ee-e9ab-4516-87d4-a94567f28ded/volumes/kubernetes.io~csi/pvc-419ef8b3-e7ba-4a82-8d0b-e35a819336cc
    ls: cannot access '/var/lib/kubelet/pods/4ff6d8ee-e9ab-4516-87d4-a94567f28ded/volumes/kubernetes.io~csi/pvc-419ef8b3-e7ba-4a82-8d0b-e35a819336cc/mount': Permission denied
    total 4
    drwxr-x--- 3 root root  40 Nov 16 05:52 .
    drwxr-x--- 4 root root 102 Nov 16 05:52 ..
    d????????? ? ?    ?      ?            ? mount
    -rw-r--r-- 1 root root 353 Nov 16 05:52 vol_data.json
    ```

    Expected output when not experiencing this problem:

    ```bash
    ncn-w003:~ # ls -al /var/lib/kubelet/pods/05c2b44e-2a8b-4015-bf5d-4c472fc772c6/volumes/kubernetes.io~csi/pvc-d43ac606-4302-4682-a195-13aeb2bc34fb
    total 8
    drwxr-x--- 3 root root   40 Nov 16 05:53 .
    drwxr-x--- 3 root root   54 Nov 16 05:53 ..
    drwxrwsr-x 4 root  103 4096 Nov 15 19:36 mount
    -rw-r--r-- 1 root root  350 Nov 16 05:53 vol_data.json
    ```

## Resolution

Failover the active Ceph MDS server to a standby daemon.
Running `ceph -s` will show that there are MDS daemons in standby.
Ceph MDS coordinates access to the Ceph cluster.
Failing the active MDS server should allow clients to successfully mount PVCs.

(`ncn-m/s`#) Fail the active MDS server. In the command below, `0` refers to the MDS server rank and `0` is the primary MDS.

```bash
ceph mds fail 0
```

If necessary, refer to other [MDS troubleshooting documentation](../../operations/utility_storage/Utility_Storage.md#storage-troubleshooting-references).
