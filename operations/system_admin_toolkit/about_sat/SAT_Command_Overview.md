# SAT Command Overview

The `sat` command-line utility is organized into multiple subcommands that
perform different administrative tasks. Most `sat` subcommands depend on services
or components from other products in the HPE Cray EX software stack. For more
information, see [SAT Dependencies](SAT_Dependencies.md).

While some `sat` subcommands use the Kubernetes API, others require another form
of authentication in order to function. For example, commands that make requests
through the API gateway to the HPE Cray EX services must first authenticate to the
API gateway. A handful of `sat` commands require S3 to be configured in order to
function. To use the SAT S3 bucket, the system administrator must generate both
the S3 access key and secret keys before writing them to a local file. This must
be done on every Kubernetes control plane node where SAT commands are run. To
configure SAT authentication and S3 credentials, see
[Authenticate SAT Commands](../configuration/Authenticate_SAT_Commands.md) and
[Generate SAT S3 Credentials](../configuration/Generate_SAT_S3_Credentials.md).

The following table summarizes the various subcommands provided by the `sat`
CLI. It includes information about the types of authentication required by the
command, the name of the associated man page, and a short description of the
command.

|SAT Subcommand|Authentication/Credentials Required|Man Page|Description|
|--------------|-----------------------------------|--------|-----------|
|`sat auth`|None|`sat-auth`|Authenticate to the API gateway and save the token.|
|`sat bmccreds`|Requires authentication to the API gateway.|`sat-bmccreds`|Set BMC passwords.|
|`sat bootprep`|Requires authentication to the API gateway. Requires Kubernetes configuration and authentication, which is done on `ncn-m001` during installation.|`sat-bootprep`|Prepare to boot nodes with images and configurations.|
|`sat bootsys`|Requires authentication to the API gateway. Requires Kubernetes configuration and authentication, which is done on `ncn-m001` during installation. Some stages require passwordless SSH to be configured to all other NCNs. Some stages require S3 to be configured.|`sat-bootsys`|Boot or shutdown the system, including compute nodes, application nodes, and non-compute nodes (NCNs) running the management software.|
|`sat diag`|Requires authentication to the API gateway.|`sat-diag`|Launch diagnostics on the HSN switches and generate a report.|
|`sat firmware`|Requires authentication to the API gateway.|`sat-firmware`|Report firmware version.|
|`sat hwhist`|Requires authentication to the API gateway.|`sat-hwhist`|Report hardware component history.|
|`sat hwinv`|Requires authentication to the API gateway.|`sat-hwinv`|Give a hardware list of the HPE Cray EX system.|
|`sat hwmatch`|Requires authentication to the API gateway.|`sat-hwmatch`|Report hardware mismatches.|
|`sat init`|None|`sat-init`|Create a default SAT configuration file.|
|`sat jobstat`|Requires authentication to the API gateway.|`sat-jobstat`|Check the status of jobs and applications.|
|`sat k8s`|Requires Kubernetes configuration and authentication, which is done on `ncn-m001` during installation.|`sat-k8s`|Report on Kubernetes replica sets that have co-located \(on the same node\) replicas.|
|`sat linkhealth`|**This command has been deprecated.**|
|`sat nid2xname`|Requires authentication to the API gateway.|`sat-nid2xname`|Translate node IDs to node XNames.|
|`sat sensors`|Requires authentication to the API gateway.|`sat-sensors`|Report current sensor data.|
|`sat setrev`|Requires S3 to be configured for site information such as system name, serial number, install date, and site name.|`sat-setrev`|Set HPE Cray EX system revision information.|
|`sat showrev`|Requires authentication to the API gateway to query the Interconnect from HSM. Requires S3 to be configured for site information such as system name, serial number, install date, and site name.|`sat-showrev`|Print HPE Cray EX system revision information.|
|`sat slscheck`|Requires authentication to the API gateway.|`sat-slscheck`|Perform a cross-check between SLS and HSM.|
|`sat status`|Requires authentication to the API gateway.|`sat-status`|Report node status across the HPE Cray EX system.|
|`sat swap`|Requires authentication to the API gateway.|`sat-swap`|Prepare a compute blade, HSN switch, or HSN cable for replacement and bring those components into service after replacement.|
|`sat switch`|**This command has been deprecated.** It has been replaced by `sat swap`.|
|`sat xname2nid`|Requires authentication to the API gateway.|`sat-xname2nid`|Translate node and node BMC XNames to node IDs.|
