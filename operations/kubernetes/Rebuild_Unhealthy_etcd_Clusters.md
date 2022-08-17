# Rebuild Unhealthy etcd Clusters

Rebuild any cluster that does not have healthy pods by deleting and redeploying unhealthy pods.
This procedure includes examples for rebuilding etcd clusters in the services namespace.
This procedure must be used for each unhealthy cluster, not just the services used in the following examples.

This process also applies when etcd is not visible when running the `kubectl get pods` command.

A special use case is also included for the Content Projection Service \(CPS\) as the process for rebuilding the cluster is slightly different.

---
> **`NOTE`**

Etcd Clusters other than the Content Projection Service \(CPS\) can be rebuilt using the automation script or the manual procedure below.
The automation script follows the same steps as the manual procedure.
If the automation script fails at any step, continue rebuilding the cluster using the manual procedure.

---

## Prerequisites

An etcd cluster has pods that are not healthy, or the etcd cluster has no pods. See [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md) for more information.

## Automation Script for Clusters in the Services Namespace

The automated script will restore the cluster from a backup if it finds a backup created within the last 7 days. If it does not discover a backup within the last 7 days, it will ask the user if they would like to rebuild the cluster.

```text
ncn-w001 # cd /opt/cray/platform-utils/etcd_restore_rebuild_util

# rebuild/restore a single cluster
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -s cray-bos-etcd

# rebuild/restore multiple clusters
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -m cray-bos-etcd,cray-uas-mgr-etcd

# rebuild/restore all clusters
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -a
```

An example using the automation script is below for `ncn-w001`. Can also
be executed on any master NCN.

```bash
ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util # ./etcd_restore_rebuild.sh -s cray-bss-etcd
```

Example output:

```text
The following etcd clusters will be restored/rebuilt:
cray-bss-etcd
You will be accepting responsibility for any missing data if there is a restore/rebuild over a running etcd k/v. HPE assumes no responsibility.
Proceed restoring/rebuilding? (yes/no)
yes
Proceeding: restoring/rebuilding etcd clusters.
The following etcd clusters did not have backups so they will need to be rebuilt:
cray-bss-etcd
Would you like to proceed rebuilding all of these etcd clusters? (yes/no)
yes

 ----- Rebuilding cray-bss-etcd -----
Deployment and etcd cluster objects captured in yaml file
yaml files edited
deployment.apps "cray-bss" deleted
etcdcluster.etcd.database.coreos.com "cray-bss-etcd" deleted
Waiting for pods to terminate.
etcdcluster.etcd.database.coreos.com/cray-bss-etcd created
Waiting for pods to be 'Running'.
- Waiting for 3 cray-bss-etcd pods to be running:
No resources found in services namespace.
- 0/3  Running
- 1/3  Running
- 2/3  Running
- 3/3  Running
Checking endpoint health.
cray-bss-etcd-qj4ds8j9k6 - Endpoint reached successfully
cray-bss-etcd-s8ck74hf96 - Endpoint reached successfully
cray-bss-etcd-vc2xznnbpj - Endpoint reached successfully
deployment.apps/cray-bss created
2022-07-31-05:04:27
SUCCESSFUL REBUILD of the cray-bss-etcd cluster completed.

etcdbackup.etcd.database.coreos.com "cray-bss-etcd-cluster-periodic-backup" deleted

ncn-w001:/opt/cray/platform-utils/etcd_restore_rebuild_util #
```

Check if rebuilt cluster's data needs to be repopulated [Repopulate Data in etcd Clusters When Rebuilding Them](Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md).
Rerun the etcd cluster health check \(see [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md)\) after recovering one or more clusters. Ensure that the clusters are healthy and have the correct number of pods.

## Manual Procedure for Clusters in the Services Namespace

The following examples use the `cray-bos` etcd cluster, but these steps must be repeated for every unhealthy service.

1.  Retrieve the `.yaml` file for the deployment and the etcd cluster objects.

    ```bash
    kubectl -n services get deployment cray-bos -o yaml > /root/etcd/cray-bos.yaml
    kubectl -n services get etcd cray-bos-etcd -o yaml > /root/etcd/cray-bos-etcd.yaml
    ```

    Only two files must be retrieved in most cases. There is a third file needed if rebuilding clusters for the CPS. CPS must be unmounted before running the commands to rebuild the etcd cluster.

    ```bash
    kubectl -n services get deployment cray-cps -o yaml > /root/etcd/cray-cps.yaml
    kubectl -n services get daemonset cray-cps-cm-pm -o yaml > /root/etcd/cray-cps-cm-pm.yaml
    kubectl -n services get etcd cray-cps-etcd -o yaml > /root/etcd/cray-cps-etcd.yaml
    ```

2.  Edit each `.yaml` file to remove the entire line for `creationTimestamp`, generation, `resourceVersion`, `uid`, and everything after status \(including status\).

    For example:

    ```text
    creationTimestamp: "2019-11-26T16:54:23Z"
    generation: 1

    resourceVersion: "5340297"
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

3.  Delete the deployment and the etcd cluster objects.

    Wait for the pods to terminate before proceeding to the next step.

    ```bash
    kubectl delete -f /root/etcd/cray-bos.yaml
    kubectl delete -f /root/etcd/cray-bos-etcd.yaml
    ```

    In the use case of CPS clusters being rebuilt, the following files must be deleted:

    ```bash
    kubectl delete -f /root/etcd/cray-cps.yaml
    kubectl delete -f /root/etcd/cray-cps-cm-pm.yaml
    kubectl delete -f /root/etcd/cray-cps-etcd.yaml
    ```

4.  Apply the etcd cluster file.

    ```bash
    kubectl apply -f /root/etcd/cray-bos-etcd.yaml
    ```

    Wait for all three pods to go into the Running state before proceeding to the next step. Use the following command to monitor the status of the pods:

    ```bash
    kubectl get pods -n services | grep bos-etcd
    ```

    Example output:

    ```text
    cray-bos-etcd-hwcw4429b9                  1/1     Running         1          7d18h
    cray-bos-etcd-mdnl28vq9c                  1/1     Running         0          36h
    cray-bos-etcd-w5vv7j4ghh                  1/1     Running         0          18h
    ```

5.  Apply the deployment file.

    ```bash
    kubectl apply -f /root/etcd/cray-bos.yaml
    ```

    If using CPS, the etcd cluster file, deployment file, and daemonset file must be reapplied:

    ```bash
    kubectl apply -f /root/etcd/cray-cps.yaml
    kubectl apply -f /root/etcd/cray-cps-cm-pm.yaml
    kubectl apply -f /root/etcd/cray-cps-etcd.yaml
    ```

    Proceed to the next step to finish rebuilding the cluster.

## Post-Rebuild

1.  Update the IP address needed to interact with the rebuilt cluster.

    After recreating the etcd cluster, the IP address needed to interact with the cluster changes, which requires recreating the etcd backup. The IP address is created automatically via a cronjob that runs at the top of each hour.

1.  Determine the periodic backup name for the cluster.

        The following example is for the `bos` cluster:

        ```bash
        kubectl get etcdbackup -n services | grep bos.*periodic
        cray-bos-etcd-cluster-periodic-backup
        ```

2.  Delete the etcd backup definition.

        A new backup will be created that points to the new IP address. Use the value returned in the previous substep.

        ```bash
        kubectl delete etcdbackup -n services \
        cray-bos-etcd-cluster-periodic-backup
        ```

Check if rebuilt cluster's data needs to be repopulated [Repopulate Data in etcd Clusters When Rebuilding Them](Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md).
Rerun the etcd cluster health check \(see [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md)\) after recovering one or more clusters. Ensure that the clusters are healthy and have the correct number of pods.
