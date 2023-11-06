# SAT Command Authentication

Some SAT subcommands make requests to the HPE Cray EX services through the API
gateway and thus require authentication to the API gateway in order to function.
Other SAT subcommands use the Kubernetes API. Some `sat` commands require S3 to
be configured. In order to use the SAT S3 bucket, the System Administrator must
generate the S3 access key and secret keys and write them to a local file. This
must be done on every Kubernetes control plane node where SAT commands are run.

For more information on authentication to the API gateway, see
[System Security and Authentication](../../security_and_authentication/System_Security_and_Authentication.md).

The following is a table describing SAT commands and the types of authentication
they require.

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
|`sat swap`|Requires authentication to the API gateway.|`sat-swap`|Prepare HSN switch or cable for replacement and bring HSN switch or cable into service.|
|`sat xname2nid`|Requires authentication to the API gateway.|`sat-xname2nid`|Translate node and node BMC XNames to node IDs.|
|`sat switch`|**This command has been deprecated.** It has been replaced by `sat swap`.|

In order to authenticate to the API gateway, run the `sat auth`
command. This command will prompt for a password on the command line. The
username value is obtained from the following locations, in order of higher
precedence to lower precedence:

- The `--username` global command-line option.
- The `username` option in the `api_gateway` section of the configuration file
  at `~/.config/sat/sat.toml`.
- The name of currently logged in user running the `sat` command.

If credentials are entered correctly when prompted by `sat auth`, a token file
will be obtained and saved to `~/.config/sat/tokens`. Subsequent sat commands
will determine the username the same way as `sat auth` described above and will
use the token for that username if it has been obtained and saved by `sat auth`.
