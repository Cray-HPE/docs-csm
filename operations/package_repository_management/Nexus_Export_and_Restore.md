# Nexus Export and Restore

The current process for ensuring the safety of the nexus-data PVC is a one time, space intensive, manual process and is only recommended to be done while Nexus is in a known good state.
An export is recommended to be done before an upgrade to enable the ability of rollback. Taking an export can also be used to improve Nexus resiliency by allowing easy fixes for data corruption.
**CAUTION:** This process may be risky and is not recommended for all use cases.

## Export

**Note:** Only one export should be taken.  Each time the script is run, it will overwrite the old export.

Prior to making an export, check the size of the exported tar file on the cluster (for example, three times the size of just the export) and the amount of storage the cluster has left.

Run the following command on a master node (`ncn-m#`):

```bash
kubectl exec -n nexus deploy/nexus -c nexus -- df -P /nexus-data | grep '/nexus-data' | awk '{print "Amount of space the Nexus export will take up on cluster: "(($3 * 3)/1048576)" GiB";}' && ceph df | grep 'zone1.rgw.buckets.data' | awk '{ print "Currently used: " $7 $8 ", Max Available " $10 $11;}'
```

The above command will return the following information:

 - The amount of space the Nexus export will take on the cluster.
 - The amount of space currently used in the Ceph pool that the export will be stored.
 - The max amount of space available in that Ceph pool.
 - If the size of the Nexus export plus the size of the currently used space is larger than the max available size, submit a help request to figure out a solution.

Taking the export can take multiple hours and Nexus will be unavailable for the entire time. For a fresh install of Nexus the export takes around
1 hour for every 60 GiB stored in the nexus-data PVC. For example, if the nexus-data PVC is 120 GiB (meaning the first step showed the export will take 360 GiB on cluster)
Nexus would be unavailable for around 2 hours while the export was taking place.

To get an export, run the export script on a master node (`ncn-m#`):

```bash
/usr/share/doc/csm/scripts/nexus-export.sh
```

## Restore

The restore will delete any changes made to Nexus after the backup was taken. The restore takes around half the time that the export took
(for example, if the export took two hours the restore would take around one hour) and during the time to restore Nexus is unavailable.

To restore Nexus to the state of the backup, run the restore script on any master node (`ncn-m#`):

```bash
/usr/share/doc/csm/scripts/nexus-restore.sh
```

## Cleanup

To clean up all the jobs and data that the export or restore creates there are a few different commands that can be used.

To clean up the job that the export created:

```bash
kubectl delete job -n nexus nexus-backup
```

To clean up the job that the restore created:

```bash
kubectl delete job -n nexus nexus-restore
```

If a new export is being created, it is recommended to first delete the old export to ensure everything exported correctly. If the old export is not deleted the new
job will overwrite the old export. This is expected behavior as only one export should be used at a time.

To delete an export:

```bash
kubectl delete pvc -n nexus nexus-bak
```
