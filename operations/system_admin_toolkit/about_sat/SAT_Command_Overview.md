# SAT Command Overview

The SAT command-line utility, `sat`, is organized into multiple subcommands
that perform different administrative tasks. For example, `sat status` provides
a summary of the status of the components in the system while `sat bootprep`
provides a way to create CFS configurations, IMS images, and session templates
to prepare for booting the system.

Some SAT subcommands make requests to the HPE Cray EX services through the API
gateway and thus require authentication to the API gateway in order to function.
Other SAT subcommands use the Kubernetes API. Some `sat` subcommands require S3
to be configured. In order to use the SAT S3 bucket, the System Administrator
must generate the S3 access key and secret keys and write them to a local file.
This must be done on every Kubernetes control plane node where SAT commands are
run.

See the following procedures to set up SAT authentication and S3 credentials:

* [Authenticate SAT Commands](../configuration/Authenticate_SAT_Commands.md)
* [Generate SAT S3 Credentials](../configuration/Generate_SAT_S3_Credentials.md)

## Summary of SAT Subcommands

The following table summarizes the various subcommands provided by the `sat`
CLI. It includes information about the types of authentication required by the
command, the name of the associated man page, and a short description of the
command.

|SAT Subcommand|Authentication/Credentials Required|Man Page|Description|
|--------------|-----------------------------------|--------|-----------|
|`sat auth`|Responsible for authenticating to the API gateway and storing a token.|`sat-auth`|Authenticate to the API gateway and save the token.|
|`sat bmccreds`|Requires authentication to the API gateway.|`sat-bmccreds`|Set BMC passwords.|
|`sat bootprep`|Requires authentication to the API gateway. Requires Kubernetes configuration and authentication, which is done on `ncn-m001` during the install.|`sat-bootprep`|Prepare to boot nodes with images and configurations.|
|`sat bootsys`|Requires authentication to the API gateway. Requires Kubernetes configuration and authentication, which is configured on `ncn-m001` during the install. Some stages require passwordless SSH to be configured to all other NCNs. Requires S3 to be configured for some stages.|`sat-bootsys`|Boot or shutdown the system, including compute nodes, application nodes, and non-compute nodes (NCNs) running the management software.|
|`sat diag`|Requires authentication to the API gateway.|`sat-diag`|Launch diagnostics on the HSN switches and generate a report.|
|`sat firmware`|Requires authentication to the API gateway.|`sat-firmware`|Report firmware version.|
|`sat hwhist`|Requires authentication to the API gateway.|`sat-hwhist`|Report hardware component history.|
|`sat hwinv`|Requires authentication to the API gateway.|`sat-hwinv`|Give a listing of the hardware of the HPE Cray EX system.|
|`sat hwmatch`|Requires authentication to the API gateway.|`sat-hwmatch`|Report hardware mismatches.|
|`sat init`|None|`sat-init`|Create a default SAT configuration file.|
|`sat jobstat`|Requires authentication to the API gateway.|`sat-jobstat`|Check the status of jobs and applications.|
|`sat k8s`|Requires Kubernetes configuration and authentication, which is automatically configured on `ncn-m001` during the install.|`sat-k8s`|Report on Kubernetes replica sets that have co-located \(on the same node\) replicas.|
|`sat linkhealth`|**This command has been deprecated.**|
|`sat nid2xname`|Requires authentication to the API gateway.|`sat-nid2xname`|Translate node IDs to node XNames.|
|`sat sensors`|Requires authentication to the API gateway.|`sat-sensors`|Report current sensor data.|
|`sat setrev`|Requires S3 to be configured for site information such as system name, serial number, install date, and site name.|`sat-setrev`|Set HPE Cray EX system revision information.|
|`sat showrev`|Requires API gateway authentication in order to query the Interconnect from HSM. Requires S3 to be configured for site information such as system name, serial number, install date, and site name.|`sat-showrev`|Print revision information for the HPE Cray EX system.|
|`sat slscheck`|Requires authentication to the API gateway.|`sat-slscheck`|Perform a cross-check between SLS and HSM.|
|`sat status`|Requires authentication to the API gateway.|`sat-status`|Report node status across the HPE Cray EX system.|
|`sat swap`|Requires authentication to the API gateway.|`sat-swap`|Prepare compute blade, HSN switch, or HSN cable for replacement and bring those components into service after replacement.|
|`sat xname2nid`|Requires authentication to the API gateway.|`sat-xname2nid`|Translate node and node BMC XNames to node IDs.|
|`sat switch`|**This command has been deprecated.** It has been replaced by `sat swap`.|
