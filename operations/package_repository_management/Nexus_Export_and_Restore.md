# Nexus Export and Restore

The current process for ensuring the safety of the `nexus-data` PVC is a one time, space intensive, manual process, and is only recommended to be done while Nexus is
in a known good state. An export is recommended to be done before an upgrade, in order to enable the ability to roll back. Taking an export can also be used to improve
Nexus resiliency by allowing easy fixes for data corruption.

**CAUTION:** This process may be risky and is not recommended for all use cases.

## Export

**Note:** Only one export should be taken. Each time the script is run, it will overwrite the old export.

Prior to making an export, check the size of the exported tar file on the cluster (for example, three times the size of just the export) and the amount of storage
that the cluster has left.

(`ncn-m#`) Run the following command on a master node:

```bash
kubectl exec -n nexus deploy/nexus -c nexus -- df -P /nexus-data | grep '/nexus-data' |
    awk '{print "Amount of space the Nexus export will take up on cluster: "(($3 * 3)/1048576)" GiB";}' &&
ceph df | grep 'TOTAL' | awk '{ print "Currently used: " $7 $8 ", Max Available " $10 $11;}'
```

The above commands will return the following information:

- The amount of space the Nexus export will take on the cluster.
- The amount of space currently used in the Ceph pool where the export will be stored.
- The maximum amount of space available in that Ceph pool.

If the size of the Nexus export plus the size of the currently used space is larger than the maximum available space,
then follow the steps on [Nexus Space Cleanup](Nexus_Space_Cleanup.md).

Taking the export can take multiple hours and Nexus will be unavailable for the entire time. For a fresh install of Nexus, the export takes around
1 hour for every 60 GiB stored in the `nexus-data` PVC. For example, if the `nexus-data` PVC is 120 GiB (meaning the first step showed the export will
use 360 GiB on cluster), then Nexus would be unavailable for around 2 hours while the export was taking place. If the time required to backup is too long
because of the size it will take follow the steps on [Nexus Space Cleanup](Nexus_Space_Cleanup.md).

(`ncn-m#`) To get an export, run the export script on any master node where the latest CSM documentation is installed. See
[Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

> If an export has been taken previously, then it should be deleted before a new export is taken. See [Cleanup previous export](#cleanup-previous-export).

```bash
/usr/share/doc/csm/scripts/nexus-export.sh
```

## Restore

The restore will delete any changes made to Nexus after the backup was taken. The restore takes around half the time that the export took
(for example, if the export took two hours then the restore would take around one hour). While the restore is underway, Nexus is unavailable.

(`ncn-m#`) To restore Nexus to the state of the backup, run the restore script on any master node where the latest CSM documentation is installed. See
[Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

```bash
/usr/share/doc/csm/scripts/nexus-restore.sh
```

## Cleanup

To cleanup all the jobs and data that the export or restore creates, there are a few different commands that can be used.

### Cleanup export job

(`ncn-mw#`) This can be run on any master or worker NCN.

```bash
kubectl delete job -n nexus nexus-backup
```

### Cleanup restore job

(`ncn-mw#`) This can be run on any master or worker NCN.

```bash
kubectl delete job -n nexus nexus-restore
```

### Cleanup previous export

If a new export is being created, then it is recommended to first delete the old export, in order to ensure that everything exported correctly.
If the old export is not deleted, then the new job will overwrite the old export. This is expected behavior, because only one export should be used at a time.

(`ncn-mw#`) To delete an export:

```bash
kubectl delete pvc -n nexus nexus-bak
```

### Cleanup failed or stopped export

If an export is stopped prematurely or fails to complete, there are a few steps that need to be taken to bring Nexus back into a working state.

1. Delete the failed or stopped job.

    See [Cleanup export job](#cleanup-export-job).

1. Delete the partially filled export PVC.

    See [Cleanup previous export](#cleanup-previous-export).

1. Restart Nexus if it is still stopped.

    Depending on where the job failed the Nexus pods may still be down.

    1. (`ncn-mw#`) Check if the Nexus pods are down.

        ```bash
        kubectl get pods -n nexus | grep nexus
        ```

    1. (`ncn-mw#`) If the Nexus pod is not found, then scale it back up.

        ```bash
        kubectl -n nexus scale deployment nexus --replicas=1
        ```
