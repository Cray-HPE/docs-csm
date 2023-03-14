# Rebuild Unhealthy etcd Clusters

Rebuild any cluster that does not have healthy pods by deleting and redeploying unhealthy pods.
This process also applies when etcd is not visible when running the `kubectl get pods` command.
The commands in this procedure can be run on any Kubernetes master or worker node on the system.

1. [Prerequisites](#prerequisites)
1. [Rebuild procedure](#rebuild-procedure)
    * [Example command and output](#example-command-and-output)
1. [Final checks](#final-checks)

## Prerequisites

An etcd cluster has pods that are not healthy, or the etcd cluster has no pods. See [Check the Health of etcd Clusters](Check_the_Health_of_etcd_Clusters.md) for more information.

## Rebuild procedure

The automated script will restore the cluster from a backup if it finds a backup created within the last 7 days. If it does not discover a backup within the last 7 days, it will ask the user if they would like to rebuild the cluster.

* (`ncn-mw#`) Rebuild/restore a single cluster

    ```bash
    /opt/cray/platform-utils/etcd/etcd_restore_rebuild.sh -s cray-bos
    ```

* (`ncn-mw#`) Rebuild/restore multiple clusters

    ```bash
    /opt/cray/platform-utils/etcd/etcd_restore_rebuild.sh -m cray-bos,cray-uas-mgr
    ```

* (`ncn-mw#`) Rebuild/restore all clusters

   ```bash
   /opt/cray/platform-utils/etcd_/etcd_restore_rebuild.sh -a
   ```

### Example command and output

```bash
/opt/cray/platform-utils/etcd/etcd_restore_rebuild.sh -s cray-bos
```

Example output:

```text
The following etcd clusters will be restored/rebuilt:

cray-bos

You will be accepting responsibility for any missing data if there is a
restore/rebuild over a running etcd k/v. HPE assumes no responsibility.
Proceed restoring/rebuilding? (yes/no)
yes

Proceeding: restoring/rebuilding etcd clusters.
The following etcd clusters did not have backups so they will need to be rebuilt:
cray-bos
Would you like to proceed rebuilding all of these etcd clusters? (yes/no)
yes


 ----- Rebuilding cray-bos -----
statefulset.apps/cray-bos-bitnami-etcd scaled
Waiting for statefulset spec update to be observed...
statefulset rolling update complete 0 pods at revision cray-bos-bitnami-etcd-6977fdd4b7...
Deleting existing PVC's...
persistentvolumeclaim "data-cray-bos-bitnami-etcd-0" deleted
persistentvolumeclaim "data-cray-bos-bitnami-etcd-1" deleted
persistentvolumeclaim "data-cray-bos-bitnami-etcd-2" deleted
Setting cluster state for cray-bos to 'new'
statefulset.apps/cray-bos-bitnami-etcd env updated
statefulset.apps/cray-bos-bitnami-etcd scaled
waiting for statefulset rolling update to complete 0 pods at revision cray-bos-bitnami-etcd-747d7d97b4...
Waiting for 1 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 3 pods to be ready...
Waiting for 3 pods to be ready...
Waiting for 3 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 1 pods to be ready...
statefulset rolling update complete 3 pods at revision cray-bos-bitnami-etcd-747d7d97b4...
Setting cluster state for cray-bos to 'existing'
statefulset.apps/cray-bos-bitnami-etcd env updated
Checking endpoint health.
cray-bos etcd cluster health verified from cray-bos-bitnami-etcd-0
```

## Final checks

After completing the above procedure, perform the following checks.

1. Check if the rebuilt cluster's data needs to be repopulated.

    See [Repopulate Data in etcd Clusters When Rebuilding Them](Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md).

1. Run the etcd cluster health check.

    Ensure that the clusters are healthy and have the correct number of pods.
    See [Check the Health of etcd Clusters](Check_the_Health_of_etcd_Clusters.md).
