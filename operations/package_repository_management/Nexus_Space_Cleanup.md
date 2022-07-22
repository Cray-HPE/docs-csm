# Nexus Space Cleanup

Nexus stores all data in a PVC called `nexus-data`. If this PVC fills up, then it will enter a read-only state. This read-only state causes
issues for Nexus as well as all the services that rely on Nexus. There is no automatic cleanup of old data from Nexus.

During the install of any CSM version, a large amount data is added to Nexus. If there has not been a manual cleanup of old files in Nexus,
then there is likely to be insufficient space for the next version of CSM to be installed.

**NOTE:** The HPE Cray EX System Software 22.07 release has around 130 Gigabytes of space needed in Nexus

This page outlines the procedure to manually cleanup Nexus, in order to ensure that there is sufficient free space for a CSM upgrade.

- [Cleanup of data not being used](#cleanup-of-data-not-being-used)
- [Cleanup of old installs](#cleanup-of-old-installs)
- [Increase PVC size](#increase-pvc-size)

## Cleanup of data not being used

Any data in Nexus that is not currently being used can be deleted to make space for the upgrade. This can include data added after the
previous install, or data that was added during an install that is no longer needed. If there is anything in Nexus that is no longer
needed, then it is recommended to delete that first, before taking any further steps.

## Cleanup of old installs

There is no documented list of files that are known to be older versions. If the system has been installed and around for
an extended period of time, or been put through multiple upgrades, then submit a help request in order to determine what can be safely deleted from Nexus.
Before submitting the help request, run a script to gather data about the system. This script outputs all of the blob stores and repositories in
Nexus, and how much space they use.

The script can be run on any master NCN where the latest CSM documentation is installed. See
[Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

(`ncn-m#`) Run the script as follows:

```bash
/usr/share/doc/csm/scripts/nexus-space-usage.sh
```

## Increase PVC size

If no other methods of cleaning work, then submit a help request to expand the `nexus-data` PVC. Expanding the PVC will allow the upgrade
to proceed. Expanding the PVC will also require future work to allow for further upgrades.

**CAUTION:** This is an irreversible step and is not recommended.
