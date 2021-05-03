# Upgrade Recovery and Troubleshooting

This document has recommendations for recovering from a failed upgrade.  The ability to recover from failures may be impacted by the stage in which the failure occurred.  There may be known issues and/or work-arounds that are already documented in other locations (which this document may reference).  Non-recoverable upgrade failures are more likely with irreversible data loss encountered in the Ceph/Storage upgrade steps.  Should this occur, the recommended recovery method will be to ensure that data exported in the 'Prereq' steps has been safely stored external to the shasta system, execute a Shasta 1.4 Fresh install, and follow steps documented below to "import" critical data back on top of the fresh install.  At that point, an upgrade attempt can be re-tried.

## Determine If Your Upgrade Failure if Recoverable

<Steps TBD to determine what consititues an Unrecoverable Upgrade failure.>

### Procedure for Restoring Nexus PVC

<Enter procedure here or link to script>


## Recovering from Unrecoverable Upgrade Failures

### Ensure Exported Data is Externally Saved
Ensure that the data that you collected to [export critical site data] (../prereqs/export-critical-data.md) has been safely stored in a location external to the system.


### Fresh Install Shasta 1.4 and Patches
Follow the steps in the [14 Fresh Install Documentation](../../../docs-csm-install) to fresh install your shasta system.

<Open Question:  In this process will we also require that all 14 patches are installed before upgrading - particularly if the data export was done from a particular version of shasta.  It may be advisable to ensure that the same version that data was exported from, be restored, in order to procedure with getting exported data configured on the fresh installed system.


### Copy or Mount Saved Data Back Onto System

Get exported data back onto the freshly installed 1.4 Shasta System. This may be done by restoring a mount or transferring files back onto the system.


### Get Saved Data Reconfigured On System

Use the following procedures to get critical data re-configured on the running 14 system.

TO DO:  Determine if the ordering if the below items matters and re-order accordingly!!!

#### Reconfigure Saved Hardware State Manager Group Info

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import Gitea-vcs Config Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import IMS Recipe Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import BOS Session Template Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import IMS Image Customization Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import SLS Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import Vault Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >


#### Import Keycloak Data

<Enter procedure here and if a script is included it should be placed [here] (data_export/<scriptname>) >



[Back to Main Page](../../README.md)
