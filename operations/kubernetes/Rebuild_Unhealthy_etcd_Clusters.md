# Rebuild Unhealthy etcd Clusters

Rebuild any cluster that does not have healthy pods by deleting and redeploying unhealthy pods.
This procedure includes examples for rebuilding etcd clusters in the `services` namespace.
This procedure must be used for each unhealthy cluster, and not just those used in the following examples.

This process also applies when etcd is not visible when running the `kubectl get pods` command.

The commands in this procedure can be run on any Kubernetes master or worker node on the system.

A special procedure is also included for the Content Projection Service \(CPS\), because the process for rebuilding its cluster is slightly different.

1. [Prerequisites](#prerequisites)
1. [Rebuild procedure](#rebuild-procedure)
    * [Automated script for clusters in the `services` namespace](#automated-script-for-clusters-in-the-services-namespace)
      * [Example command and output](#example-command-and-output)
      * [Next step](#next-step)
    * [Manual procedure for clusters in the `services` namespace](#manual-procedure-for-clusters-in-the-services-namespace)
      * [Post-rebuild steps](#post-rebuild-steps)
1. [Final checks](#final-checks)

## Prerequisites

An etcd cluster has pods that are not healthy, or the etcd cluster has no pods. See [Check the Health and Balance of etcd Clusters](Check_the_Health_and_Balance_of_etcd_Clusters.md) for more information.

## Rebuild procedure

Etcd clusters other than the Content Projection Service \(CPS\) are rebuilt using an automated script or a manual procedure.
The Content Projection Service \(CPS\) cluster can only be rebuilt using the manual procedure.

* [Automated script for clusters in the `services` namespace](#automated-script-for-clusters-in-the-services-namespace)
* [Manual procedure for clusters in the `services` namespace](#manual-procedure-for-clusters-in-the-services-namespace)

Regardless of which method is chosen, after completing the rebuild, the last step is to perform the [Final checks](#final-checks).

### Automated script for clusters in the `services` namespace

The automated script will restore the cluster from a backup if it finds a backup created within the last 7 days. If it does not discover a backup within the last 7 days, it will ask the user if they would like to rebuild the cluster.

The automated script follows the same steps as the manual procedure.
If the automated script fails at any step, then continue rebuilding the cluster using the manual procedure.

* Rebuild/restore a single cluster

    ```bash
    ncn-mw# /opt/cray/platform-utils/etcd_restore_rebuild_util/etcd_restore_rebuild.sh -s cray-bos-etcd
    ```

* Rebuild/restore multiple clusters

    ```bash
    ncn-mw# /opt/cray/platform-utils/etcd_restore_rebuild_util/etcd_restore_rebuild.sh -m cray-bos-etcd,cray-uas-mgr-etcd
    ```

* Rebuild/restore all clusters

   ```bash
   ncn-mw# /opt/cray/platform-utils/etcd_restore_rebuild_util/etcd_restore_rebuild.sh -a
   ```

#### Example command and output

```bash
ncn-mw# /opt/cray/platform-utils/etcd_restore_rebuild_util/etcd_restore_rebuild.sh -s cray-bss-etcd
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
```

#### Next step

After the script completes, perform the [Final checks](#final-checks).

### Manual procedure for clusters in the `services` namespace

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

#### Post-rebuild steps

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
