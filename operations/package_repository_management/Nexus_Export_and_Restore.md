# Nexus Export and Restore

The current process for ensuring the safety of the `nexus-data` PVC is a one time, space intensive, manual process, and is only recommended to be done while Nexus is
in a known good state. An export is recommended to be done before an upgrade, in order to enable the ability to roll back. Taking an export can also be used to improve
Nexus resiliency by allowing easy fixes for data corruption.

**CAUTION:** This process may be risky and is not recommended for all use cases.

## Export

**Note:** Only one export should be taken. Each time the script is run, it will overwrite the old export.

Prior to making an export, check the size of the exported tar file on the cluster (for example, three times the size of just the export) and the amount of storage
that the cluster has left.

Run the following command on a master node:

```bash
ncn-m# kubectl exec -n nexus deploy/nexus -c nexus -- df -P /nexus-data | grep '/nexus-data' |
           awk '{print "Amount of space the Nexus export will take up on cluster: "(($3 * 3)/1048576)" GiB";}' &&
       ceph df | grep 'zone1.rgw.buckets.data' | awk '{ print "Currently used: " $7 $8 ", Max Available " $10 $11;}'
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

(`ncn-m#`) If an export has been taken previously, then it should be deleted before a new export is taken.

Check for existing `nexus-bak` PVC. If found, it needs to be removed.

```bash
kubectl get pvc -n nexus nexus-bak
```

Example output:

```text
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
nexus-bak   Bound    pvc-7551d342-f976-48e1-bb91-1957b75dbc53   1000Gi     RWO            k8s-block-replicated   42d
```

Check for existing `nexus-backup` job. If found, it needs to be removed.

```bash
kubectl get jobs -n nexus nexus-backup
```

Example output:

```text
NAME           COMPLETIONS   DURATION   AGE
nexus-backup   1/1           6h22m      42d
```

> See [Cleanup previous export](#cleanup-previous-export).

To take an export of nexus, run the export script on any master node where the latest CSM documentation is installed. See
[Check for latest documentation](../../update_product_stream/index.md#check-for-latest-documentation).

```bash
ncn-m# /usr/share/doc/csm/scripts/nexus-export.sh
```

Example output:

```text
Gibibytes available in cluster: 52418
Gibibytes used in nexus-data: 434
Gibibytes available in nexus-data: 566
Space to be used from backup:  1302
Creating PVC for Nexus backup, if needed
Error from server (NotFound): persistentvolumeclaims "nexus-bak" not found
persistentvolumeclaim/nexus-bak created
Scaling Nexus deployment to 0
deployment.apps/nexus scaled
Starting backup, do not exit this script.
Should be done around Fri 22 Mar 2024 06:29:03 PM UTC (7:14 from now)
job.batch/nexus-backup created
Waiting for the backup to finish.
..............................
```

> A single "." will be output every 30 seconds until the export reports "Done".

## Restore

The restore will delete any changes made to Nexus after the backup was taken. The restore takes around half the time that the export took
(for example, if the export took two hours then the restore would take around one hour). While the restore is underway, Nexus is unavailable.

To restore Nexus to the state of the backup, run the restore script on any master node where the latest CSM documentation is installed. See
[Check for latest documentation](../../update_product_stream/index.md#check-for-latest-documentation).

```bash
ncn-m# /usr/share/doc/csm/scripts/nexus-restore.sh
```

## Cleanup

To cleanup all the jobs and data that the export or restore creates, there are a few different commands that can be used.

### Cleanup export job

```bash
ncn-mw# kubectl delete job -n nexus nexus-backup
```

### Cleanup restore job

```bash
ncn-mw# kubectl delete job -n nexus nexus-restore
```

### Cleanup previous export

If a new export is being created, then it is recommended to first delete the old export, in order to ensure that everything exported correctly.
If the old export is not deleted, then the new job will overwrite the old export. This is expected behavior, because only one export should be used at a time.

To delete an export:

```bash
ncn-mw# kubectl delete pvc -n nexus nexus-bak
```

### Cleanup failed or stopped export

If an export is stopped prematurely or fails to complete, there are a few steps that need to be taken to bring Nexus back into a working state.

1. Delete the failed or stopped job.

    See [Cleanup export job](#cleanup-export-job).

1. Delete the partially filled export PVC.

    See [Cleanup previous export](#cleanup-previous-export).

1. Restart Nexus if it is still stopped.

    Depending on where the job failed the Nexus pods may still be down.

    1. Check if the Nexus pods are down.

        ```bash
        ncn-mw# kubectl get pods -n nexus | grep nexus
        ```

    1. If the Nexus pod is not found, then scale it back up.

        ```bash
        ncn-mw# kubectl -n nexus scale deployment nexus --replicas=1
        ```
