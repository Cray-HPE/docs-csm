# Rebalance Healthy etcd Clusters

Rebalance the etcd clusters. The clusters need to be in a healthy state, and there needs to be the same number of pods running on each worker node for the etcd clusters to be balanced.

Restoring the balance of etcd clusters will help with the storage of Kubernetes cluster data.

## Prerequisites

- etcd clusters are in a healthy state.
- etcd clusters do not have the same number of pods on each worker node.

## Procedure

1. Check to see if clusters have two or more pods on the same worker node.

    The following is an example of an unhealthy cluster. Two of the pods are on `ncn-w001` and only one pod is on `ncn-w003`.

    ```bash
    ncn-w001# kubectl get pods -o wide -A -l app=etcd
    ```

    Example output:

    ```text
    NAMESPACE  NAME                       READY  STATUS    RESTARTS   AGE     IP           NODE      NOMINATED NODE  READINESS GATES
    services   cray-bos-etcd-cqjr66ldlr   1/1    Running   0          5d10h   10.39.1.55   ncn-w001  <none>          <none>
    services   cray-bos-etcd-hsb2zfzxqv   1/1    Running   0          5d10h   10.36.0.13   ncn-w003  <none>          <none>
    services   cray-bos-etcd-v9sfkxcpzc   1/1    Running   0          3d      10.39.2.58   ncn-w001  <none>          <none>
    ```

1. Confirm that the clusters are healthy.

    Refer to [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md).

1. Delete one of the pods that is on the same node as another in the cluster.

    ```bash
    ncn-w001# kubectl -A delete pod POD_NAME
    ```

1. Check the health of the pods.

    Refer to [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md).
