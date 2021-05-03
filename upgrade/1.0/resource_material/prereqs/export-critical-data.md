# Determine Data Export Location (External to Shasta System)

Configure a mount point or select a location external to the Shasta system where critical data can be exported.  

For example, on ncn-m001, create a local directory for the mount point and run `mount -t nfs <external-host>:/<mount_point> /local/directory`.  Other mechanisms can be used to ensure that the data collected is stored external to the system in the event that it is needed in a later stage. 

# Collect Data

Follow the instructions, below, to collect data for the specified components.  If unexpected errors are encountered during the upgrade procedure, the exported data can aid in system recovery or re-configuration if a reinstall becomes necessary.

## General System Information

The following will collect general credential, switch, firmware, and node status information:

Either execute a script here

   ```bash
   ncn-m001# /usr/share/doc/metal/upgrade/1.0/resource_material/prereqs/data_export/<script_name.sh>
   ```

or

See Steps 1- 19 in the `Collect Data From Healthy Shasta System for EX Installation` section of the `HPE Cray EX System Installation and Configuration Guide`.


## Export Nexus PVC Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export Hardware State Manager Group Info

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export Critical Gitea-vcs Config Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export IMS Recipe Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export BOS Session Template Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export IMS Image Customization Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export SLS Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export Vault Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >


## Export Keyloak Data

<Enter procedure here and if a script is included it should be placed [here](data_export/<scriptname>) >




[Back to Main Page](../../README.md)
