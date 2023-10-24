# Rebuild Unhealthy etcd Clusters

Rebuild any cluster that does not have healthy pods by deleting and redeploying unhealthy pods.
This procedure includes examples for rebuilding etcd clusters in the `services` namespace.
This procedure must be used for each unhealthy cluster, and not just those used in the following examples.

This process also applies when etcd is not visible when running the `kubectl get pods` command.

The commands in this procedure can be run on any Kubernetes master or worker node on the system.

1. [Prerequisites](#prerequisites)
1. [Rebuild procedure](#rebuild-procedure)
1. [Post-rebuild steps](#post-rebuild-steps)
1. [Final checks](#final-checks)

## Prerequisites

An etcd cluster has pods that are not healthy, or the etcd cluster has no pods. See [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md) for more information.

## Rebuild procedure

The following examples use the `cray-bos` etcd cluster, but these steps must be repeated for every unhealthy service.

1. Create YAML files for the deployment and the etcd cluster objects.

    ```bash
    ncn-mw# kubectl -n services get deployment cray-bos -o yaml > /root/etcd/cray-bos.yaml
    ncn-mw# kubectl -n services get etcd cray-bos-etcd -o yaml > /root/etcd/cray-bos-etcd.yaml
    ```

    Only two files must be retrieved in most cases. There is a third file needed if rebuilding clusters for CPS. CPS must be unmounted before running the commands to rebuild its etcd cluster.

    ```bash
    ncn-mw# kubectl -n services get deployment cray-cps -o yaml > /root/etcd/cray-cps.yaml
    ncn-mw# kubectl -n services get daemonset cray-cps-cm-pm -o yaml > /root/etcd/cray-cps-cm-pm.yaml
    ncn-mw# kubectl -n services get etcd cray-cps-etcd -o yaml > /root/etcd/cray-cps-etcd.yaml
    ```

1. Edit each YAML file.

    * Remove the entire lines for `creationTimestamp`, generation, `resourceVersion`, and `uid`.
    * Remove the `status` line, as well as every line after it.

    For example:

    ```yaml
    creationTimestamp: "2019-11-26T16:54:23Z"
    generation: 1

    resourceVersion: "5340297"
    selfLink: /apis/extensions/v1beta1/namespaces/services/deployments/cray-bos
    uid: 65f4912e-106d-11ea-88b0-b42e993e060a

    status:
      availableReplicas: 1
      conditions:
      - lastTransitionTime: "2019-11-26T16:54:23Z"
        lastUpdateTime: "2019-11-26T16:57:36Z"
        message: ReplicaSet "cray-bos-6f4475d59b" has successfully progressed.
        reason: NewReplicaSetAvailable
        status: "True"
        type: Progressing
      - lastTransitionTime: "2019-11-29T03:25:29Z"
        lastUpdateTime: "2019-11-29T03:25:29Z"
        message: Deployment has minimum availability.
        reason: MinimumReplicasAvailable
        status: "True"
        type: Available
      observedGeneration: 1
      readyReplicas: 1
      replicas: 1
      updatedReplicas: 1
    ```

1. Delete the deployment and the etcd cluster objects.

    Wait for the pods to terminate before proceeding to the next step.

    ```bash
    ncn-mw# kubectl delete -f /root/etcd/cray-bos.yaml
    ncn-mw# kubectl delete -f /root/etcd/cray-bos-etcd.yaml
    ```

    If rebuilding CPS, the etcd cluster, deployment, and daemonset must be removed:

    ```bash
    ncn-mw# kubectl delete -f /root/etcd/cray-cps.yaml
    ncn-mw# kubectl delete -f /root/etcd/cray-cps-cm-pm.yaml
    ncn-mw# kubectl delete -f /root/etcd/cray-cps-etcd.yaml
    ```

1. Apply the etcd cluster file.

    ```bash
    ncn-mw# kubectl apply -f /root/etcd/cray-bos-etcd.yaml
    ```

    Wait for all three pods to go into the `Running` state before proceeding to the next step. Use the following command to monitor the status of the pods:

    ```bash
    ncn-mw# kubectl get pods -n services | grep bos-etcd
    ```

    Example output:

    ```text
    cray-bos-etcd-hwcw4429b9                  1/1     Running         1          7d18h
    cray-bos-etcd-mdnl28vq9c                  1/1     Running         0          36h
    cray-bos-etcd-w5vv7j4ghh                  1/1     Running         0          18h
    ```

1. Apply the deployment file.

    ```bash
    ncn-mw# kubectl apply -f /root/etcd/cray-bos.yaml
    ```

    If rebuilding CPS, the etcd cluster file, deployment file, and daemonset file must be reapplied:

    ```bash
    ncn-mw# kubectl apply -f /root/etcd/cray-cps.yaml
    ncn-mw# kubectl apply -f /root/etcd/cray-cps-cm-pm.yaml
    ncn-mw# kubectl apply -f /root/etcd/cray-cps-etcd.yaml
    ```

Proceed to [Post-rebuild steps](#post-rebuild-steps) in order to finish rebuilding the cluster.

## Post-rebuild steps

1. Update the IP address that interacts with the rebuilt cluster.

    After recreating the etcd cluster, the IP address needed to interact with the cluster changes, which requires recreating the etcd backup. The IP address is created automatically via a cronjob that runs at the top of each hour.

1. Determine the periodic backup name for the cluster.

    The following example is for the `bos` cluster:

    ```bash
    ncn-mw# kubectl get etcdbackup -n services | grep bos.*periodic
    ```

    Example output:

    ```text
    cray-bos-etcd-cluster-periodic-backup
    ```

1. Delete the etcd backup definition.

    A new backup will be created that points to the new IP address.

    In the following command, substitute the backup name obtained in the previous step.

    ```bash
    ncn-mw# kubectl delete etcdbackup -n services cray-bos-etcd-cluster-periodic-backup
    ```

Proceed to the next section and perform the [Final checks](#final-checks).

## Final checks

Whether the rebuild was done manually or with the automated script, after completing the procedure, perform the following checks.

1. Check if the rebuilt cluster's data needs to be repopulated.

    See [Repopulate Data in etcd Clusters When Rebuilding Them](Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md).

1. Run the etcd cluster health check.

    Ensure that the clusters are healthy and have the correct number of pods.
    See [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md).
