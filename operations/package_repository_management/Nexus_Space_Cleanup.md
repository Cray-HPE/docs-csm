# Nexus Space Cleanup

Nexus stores all data in a PVC called `nexus-data`. If this PVC fills up it will turn to a read only state and cause issues for Nexus
as well as all the services that rely on Nexus. During the install of any CSM version there is a large amount data that is added to Nexus,
which at this point is only cleaned by hand. If there has not been a cleanup of old files in Nexus there is likely to not be enough space
for the next version of CSM to be installed. There are a few steps to take in order to clean up Nexus to allow for an upgrade.

## Cleanup of Data Not Being Used

Any data in Nexus that is not currently being used can be deleted to make space for the upgrade. This can include data added after the
previous install, or data that was added during an install that is no longer needed. If there is anything in Nexus that is no longer
needed then it is recommended to delete that first before taking any further steps.

## Cleanup of Old Installs

Currently there is not a documented list of files that are known to be older versions. If the system has been installed and around for
an extended period of time, or been put through two or more upgrades then submit a help request to determine what is best deleted. Before
sending a help request in, please gather data about the system by running a troubleshooting script. This script will give an output of all
the blob stores in nexus and how much space they use, it will also give a list of all the repositories and how much space they use.

(`ncn-m#`) To get troubleshooting information, run the nexus space script on any master node where the latest CSM documentation is installed. See
[Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

(`ncn-m#`) To gather trouble shooting information run:

```bash
/usr/share/doc/csm/scripts/nexus-space-usage.sh
```

## Increase PVC size

If no other methods of cleaning work then submit a help request to expand the `nexus-data` PVC. Expanding the PVC will allow the upgrade
to proceed. Expanding the PVC will also require future work to allow for further upgrades.

**CAUTION:** This is an irreversible step and is not recommended.