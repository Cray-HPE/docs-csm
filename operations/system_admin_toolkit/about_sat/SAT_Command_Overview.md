# SAT Command Overview

The `sat` command-line utility is organized into multiple subcommands that
perform different administrative tasks. Most `sat` subcommands depend on services
or components from other products in the HPE Cray EX software stack. For more
information, see [SAT Dependencies][sat-deps].

While some `sat` subcommands use the Kubernetes API, others require another form
of authentication in order to function. For example, commands that make requests
through the API gateway to the HPE Cray EX services must first authenticate to the
API gateway. A handful of `sat` commands require S3 to be configured in order to
function. To use the [SAT][sat] [S3][s3] bucket, the system administrator must generate both
the S3 access key and secret keys before writing them to a local file. This must
be done on every Kubernetes control plane node where SAT commands are run. To
configure [SAT][sat] authentication and [S3][s3] credentials, see
[Authenticate SAT Commands][auth-sat] and
[Generate SAT S3 Credentials][gen-sat-s3-creds].

The following table summarizes the various subcommands provided by the `sat`
CLI. It includes information about the types of authentication required by the
command, the name of the associated man page, and a short description of the
command.

|SAT Subcommand|Authentication/Credentials Required|Man Page|Description|
|--------------|-----------------------------------|--------|-----------|
|`sat auth`|None|`sat-auth`|Authenticate to the API gateway and save the token.|
|`sat bmccreds`|Requires authentication to the API gateway.|`sat-bmccreds`|Set [BMC][bmc] passwords.|
|`sat bootprep`|Requires authentication to the API gateway. Requires Kubernetes configuration and authentication, which is done on `ncn-m001` during installation.|`sat-bootprep`|Prepare to boot nodes with [IMS][ims] images and [CFS][cfs] configurations.|
|`sat bootsys`|Requires authentication to the API gateway. Requires Kubernetes configuration and authentication, which is done on `ncn-m001` during installation. Some stages require passwordless SSH to be configured to all other [NCNs][ncn]. Some stages require [S3][s3] to be configured.|`sat-bootsys`|Boot or shutdown the system, including [compute nodes][cn], [application nodes][an], and [non-compute nodes (NCNs)][ncn] running the management software.|
|`sat diag`|Requires authentication to the API gateway.|`sat-diag`|Launch diagnostics on the [HSN][hsn] switches and generate a report.|
|`sat firmware`|Requires authentication to the API gateway.|`sat-firmware`|Report firmware version.|
|`sat hwhist`|Requires authentication to the API gateway.|`sat-hwhist`|Report hardware component history.|
|`sat hwinv`|Requires authentication to the API gateway.|`sat-hwinv`|Give a hardware list of the HPE Cray EX system.|
|`sat hwmatch`|Requires authentication to the API gateway.|`sat-hwmatch`|Report hardware mismatches.|
|`sat init`|None|`sat-init`|Create a default [SAT][sat] configuration file.|
|`sat jobstat`|Requires authentication to the API gateway.|`sat-jobstat`|Check the status of jobs and applications.|
|`sat k8s`|Requires Kubernetes configuration and authentication, which is done on `ncn-m001` during installation.|`sat-k8s`|Report on Kubernetes replica sets that have co-located (on the same node) replicas.|
|`sat linkhealth`|**This command has been deprecated.**|
|`sat nid2xname`|Requires authentication to the API gateway.|`sat-nid2xname`|Translate [node IDs][nid] to node [xnames][xname].|
|`sat sensors`|Requires authentication to the API gateway.|`sat-sensors`|Report current sensor data.|
|`sat setrev`|Requires S3 to be configured for site information such as system name, serial number, install date, and site name.|`sat-setrev`|Set HPE Cray EX system revision information.|
|`sat showrev`|Requires authentication to the API gateway to query the Interconnect from [HSM][hsm]. Requires [S3][s3] to be configured for site information such as system name, serial number, install date, and site name.|`sat-showrev`|Print HPE Cray EX system revision information.|
|`sat slscheck`|Requires authentication to the API gateway.|`sat-slscheck`|Perform a cross-check between [SLS][sls] and [HSM][hsm].|
|`sat status`|Requires authentication to the API gateway.|`sat-status`|Report node status across the HPE Cray EX system.|
|`sat swap`|Requires authentication to the API gateway.|`sat-swap`|Prepare a [compute][cn] blade, [HSN][hsn] switch, or HSN cable for replacement and bring those components into service after replacement.|
|`sat switch`|**This command has been deprecated.** It has been replaced by `sat swap`.|
|`sat xname2nid`|Requires authentication to the API gateway.|`sat-xname2nid`|Translate node and node [BMC][bmc] [xnames][xname] to [node IDs][nid].|

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

[auth-sat]: ../configuration/Authenticate_SAT_Commands.md
[gen-sat-s3-creds]: ../configuration/Generate_SAT_S3_Credentials.md
[sat-deps]: SAT_Dependencies.md

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example), 
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../../configure_cray_cli.md
[check-latest-docs]: ../../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../../glossary.md#ansible-execution-environment-aee
[an]: ../../../glossary.md#application-node-an
[ara]: ../../../glossary.md#ara-records-ansible-ara
[bmc]: ../../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../../glossary.md#boot-orchestration-service-bos
[bss]: ../../../glossary.md#boot-script-service-bss
[can]: ../../../glossary.md#customer-access-network-can
[canu]: ../../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../../glossary.md#configuration-framework-service-cfs
[chn]: ../../../glossary.md#customer-high-speed-network-chn
[cli]: ../../../glossary.md#cray-cli-cray
[cn]: ../../../glossary.md#compute-node-cn
[csi]: ../../../glossary.md#cray-site-init-csi
[fas]: ../../../glossary.md#firmware-action-service-fas
[hbtd]: ../../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../../glossary.md#hardware-management-network-hmn
[hsm]: ../../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../../glossary.md#high-speed-network-hsn
[ims]: ../../../glossary.md#image-management-service-ims
[iuf]: ../../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../../glossary.md#management-nodes
[mountain]: ../../../glossary.md#mountain-cabinet
[ncn]: ../../../glossary.md#non-compute-node-ncn
[nid]: ../../../glossary.md#node-id-nid
[nmn]: ../../../glossary.md#node-management-network-nmn
[pcs]: ../../../glossary.md#power-control-service-pcs
[pdu]: ../../../glossary.md#power-distribution-unit-pdu
[pit]: ../../../glossary.md#pre-install-toolkit-pit
[river]: ../../../glossary.md#river-cabinet
[rts]: ../../../glossary.md#redfish-translation-service-rts
[s3]: ../../../glossary.md#simple-storage-service-s3
[sat]: ../../../glossary.md#system-admin-toolkit-sat
[sbps]: ../../../glossary.md#scalable-boot-projection-service-sbps
[scsd]: ../../../glossary.md#system-configuration-service-scsd
[shcd]: ../../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../../glossary.md#slingshot
[sls]: ../../../glossary.md#system-layout-service-sls
[sma]: ../../../glossary.md#system-monitoring-application-sma
[smd]: ../../../glossary.md#hardware-state-manager-smd
[sops]: ../../../glossary.md#secrets-operations-sops
[tapms]: ../../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../../glossary.md#user-access-node-uan
[uss]: ../../../glossary.md#user-services-software-uss
[vcs]: ../../../glossary.md#version-control-service-vcs
[vnid]: ../../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../../glossary.md#xname

<!-- markdownlint-restore -->
