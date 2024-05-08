# Increase the PVC size in an etcd Cluster Database

This procedure will detail how to increase the size of the Persistent Volume Claims (PVCs) that back an etcd cluster, in the event they have filled the database. Below are symptoms which may be caused by etcd running out of space:

- The etcd pods for a given cluster will not start and end up in CLBO (Crash Loop Back Off).
- The pod logs for one of the etcd members reports 'no space' errors.

## Prerequisites

- This procedure requires root privileges.

## Procedure

NOTE: The examples below use `cray-power-control` as the example etcd cluster. If inspecting another cluster, replace the cluster name with the appropriate cluster name (`cray-bos`, `cray-bss`, etc..).

1. (`ncn-mw#`) Check the current PVC usage in the running pods. Note that the following script will only report usage for pods that are running,
so it may be necessary to run this command multiple times in order to catch the pod(s) while they are briefly up and trying to start.

    ```bash
    /opt/cray/platform-utils/etcd/etcd-util.sh pvc_usage cray-power-control
    ```

    Example output:

    ```text
    ### cray-power-control-bitnami-etcd-2 PVC Usage: ###
    Filesystem   Size   Used   Avail   Use%   Mounted   on
    /dev/rbd13   2.9G   2.9G   21M   100%   /bitnami/etcd

    ### cray-power-control-bitnami-etcd-0 PVC Usage: ###
    Filesystem   Size   Used   Avail   Use%   Mounted   on
    /dev/rbd7   2.9G   2.9G   21M   100%   /bitnami/etcd

    ### cray-power-control-bitnami-etcd-1 PVC Usage: ###
    Filesystem   Size   Used   Avail   Use%   Mounted   on
    /dev/rbd10   2.9G   2.9G   21M   100%   /bitnami/etcd
    ```

1. (`ncn-mw#`) Scale the `statefulset` down to zero

    ```bash
    kubectl scale statefulset -n services cray-power-control-bitnami-etcd --replicas=0
    ```

1. (`ncn-mw#`) Edit each of the three PVCs, and increase the storage request size. Repeat for all three PVCs (0, 1 and 2):
    Navigate to the following section and increase the size

    ```bash
    resources:
      requests:
        storage: 3Gi  <---- Increase value here
    ```

    ```bash
    kubectl edit pvc -n services data-cray-power-control-bitnami-etcd-<n>
    ```

1. (`ncn-mw#`) Observe the PVC size by periodically executing the following command. After about a minute the size reported should increase to match the setting in the above step.

    ```bash
    kubectl get pvc -n services | grep data-cray-power-control
    ```

    ```text
    data-cray-power-control-bitnami-etcd-0 Bound pvc-29d140c6-2386-4949-a834-4c1aa53091c7 8Gi RWO k8s-block-replicated 18h
    data-cray-power-control-bitnami-etcd-1 Bound pvc-3ca8ab46-5dce-41c8-8aa6-2b30b8ca937d 8Gi RWO k8s-block-replicated 18h
    data-cray-power-control-bitnami-etcd-2 Bound pvc-2bd5f851-1a78-415b-8c3a-94c0e1751456 8Gi RWO k8s-block-replicated 18h
    ```

1. (`ncn-mw#`) Scale the `statefulset` back up to three.

    ```bash
    kubectl scale statefulset -n services cray-power-control-bitnami-etcd --replicas=3
    ```

1. (`ncn-mw#`) Verify all three pods start and have 2/2 running containers (these pods typically take about a minute to start).

    ```bash
    kubectl get po -n services | grep cray-power-control-bitnami-etcd-[0-3]
    ```

    Example output:

    ```text
    cray-power-control-bitnami-etcd-0 2/2 Running 0 55m
    cray-power-control-bitnami-etcd-1 2/2 Running 0 55m
    cray-power-control-bitnami-etcd-2 2/2 Running 0 55m
    ```

1. (`ncn-mw#`) Check the PVC usage in the running pods.

    ```bash
    /opt/cray/platform-utils/etcd/etcd-util.sh pvc_usage cray-power-control
    ```

    Example output:

    ```text
    ### cray-power-control-bitnami-etcd-2 PVC Usage: ###
    Filesystem   Size   Used   Avail   Use%   Mounted   on
    /dev/rbd13   7.8G   2.9G   5.0G   37%   /bitnami/etcd

    ### cray-power-control-bitnami-etcd-0 PVC Usage: ###
    Filesystem   Size   Used   Avail   Use%   Mounted   on
    /dev/rbd7   7.8G   2.9G   5.0G   37%   /bitnami/etcd

    ### cray-power-control-bitnami-etcd-1 PVC Usage: ###
    Filesystem   Size   Used   Avail   Use%   Mounted   on
    /dev/rbd10   7.8G   2.9G   5.0G   37%   /bitnami/etcd
    ```
