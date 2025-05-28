# Restore an etcd Cluster from a Backup

Use an existing backup of a healthy etcd cluster to restore an unhealthy cluster to a healthy state.

The commands in this procedure can be run on any Kubernetes master or worker node on the system.

* [Prerequisites](#prerequisites)
* [Restore procedure](#restore-procedure)

## Prerequisites

A backup of a healthy etcd cluster has been created.

## Restore procedure

Etcd clusters can be restored using an automated script.

The automated script will restore the cluster from the most recent backup if it finds a backup created within the last 7 days.
If it does not discover a backup within the last 7 days, it will ask the user if they would like to rebuild the cluster.

* (`ncn-mw#`) Rebuild/restore a single cluster

    ```bash
    /opt/cray/platform-utils/etcd/etcd_restore_rebuild.sh -s cray-bss
    ```

* (`ncn-mw#`) Rebuild/restore multiple clusters

    ```bash
    /opt/cray/platform-utils/etcd/etcd_restore_rebuild.sh -m cray-bss,cray-fas
    ```

* (`ncn-mw#`) Rebuild/restore all clusters

   ```bash
   /opt/cray/platform-utils/etcd/etcd_restore_rebuild.sh -a
   ```

### Example command and output

```bash
/opt/cray/platform-utils/etcd/etcd_restore_rebuild.sh -s cray-bss
```

Example output:

```text
The following etcd clusters will be restored/rebuilt:

cray-bss

You will be accepting responsibility for any missing data if there is a
restore/rebuild over a running etcd k/v. HPE assumes no responsibility.
Proceed restoring/rebuilding? (yes/no)
yes

Proceeding: restoring/rebuilding etcd clusters.

 ----- Restoring from cray-bss/db-2025-05-28_20-00 -----
Scaling etcd statefulset down to zero...
statefulset.apps/cray-bss-bitnami-etcd scaled
statefulset rolling update complete 0 pods at revision cray-bss-bitnami-etcd-7ccc4dd5cc...
Setting cluster state for cray-bss to 'new' and to start from snapshot
statefulset.apps/cray-bss-bitnami-etcd env updated
Deleting existing PVC's...
persistentvolumeclaim "data-cray-bss-bitnami-etcd-0" deleted
persistentvolumeclaim "data-cray-bss-bitnami-etcd-1" deleted
persistentvolumeclaim "data-cray-bss-bitnami-etcd-2" deleted
Scaling etcd statefulset back up to three members...
statefulset.apps/cray-bss-bitnami-etcd scaled
waiting for statefulset rolling update to complete 0 pods at revision cray-bss-bitnami-etcd-c766d98bf...
Waiting for 1 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 3 pods to be ready...
Waiting for 3 pods to be ready...
Waiting for 3 pods to be ready...
Waiting for 3 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 1 pods to be ready...
statefulset rolling update complete 3 pods at revision cray-bss-bitnami-etcd-c766d98bf...
Setting cluster state for cray-bss to back to 'existing'
statefulset.apps/cray-bss-bitnami-etcd env updated

Checking endpoint health.
cray-bss etcd cluster health verified from cray-bss-bitnami-etcd-1
```
