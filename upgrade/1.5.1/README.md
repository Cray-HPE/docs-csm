# CSM 1.5.1 Patch Installation Instructions

* [Introduction](#introduction)
* [Bug fixes and improvements](#bug-fixes-and-improvements)
* [Steps](#steps)

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `v1.5.1`
from CSM `v1.5.0`. If upgrading from CSM `v1.4.x`,  then follow the procedures
described in [CSM major/minor version upgrade](../README.md#csm-majorminor-version-upgrade) instead.
In the unusual situation of upgrading from a pre-release version of CSM `v1.5.0`, then follow the procedures
described in [CSM major/minor version upgrade](../README.md#csm-majorminor-version-upgrade) instead.

If there are more recent CSM `v1.5` patch versions available, note that there is no need to perform
intermediate CSM `v1.5` patch upgrades. Instead, consider upgrading to the latest CSM `v1.5`
patch release. See [CSM patch version upgrade](../README.md#csm-patch-version-upgrade) for the full
list of patch versions.

## Bug fixes and improvements

* Updated [IMS](../../glossary.md#image-management-service-ims) to allow for remote node builds
* Fixed an issue where `hms-discovery` would put default credentials into vault disabling non default credentials
* Fixed an issue where `cray-ipxe` generated scripts would cause boot errors
* Fixed an issue where [BOS](../../glossary.md#boot-orchestration-service-bos) v2 would send large queries to [CFS](../../glossary.md#configuration-framework-service-cfs) resulting 503 and 431 responses
* Fixed an issue where [PCS](../../glossary.md#power-control-service-pcs) was adding invalid components to power operations
* Fixed an issue where [IUF](../../glossary.md#install-and-upgrade-framework-iuf) would encounter a race condition and stall on transitioning to new stages
* Fixed an issue where `Thanos` service is configured without storage limits
* Fixed an issue where `cray-dns-unbound-manager` `stderr` handling can corrupt configuration
* Fixed an issue where [SAT](../../glossary.md#system-admin-toolkit-sat) `status` unnecessarily queries BOS for session template for every component
* Fixed an issue where a PATCH to a BOS v2 session to change its name results in a bad state
* Updated `cray-hms-rts-init` job to include a TTL
* Updated `node-exporter` configuration to monitor SNMP counters
* Updated documentation to cover switch configuration for [NCNs](../../glossary.md#non-compute-node-ncn)
* Fixed an issue where a PATCH call to BOS v2 components with a filter and non existent component ID would result in 503 and 431 errors
* Fixed an issue where BOS operators would output errors when all nodes exceed retry limit
* Fixed an issue where `cray-upload-recovery-images` fails to upload recovery firmware
* Fixed an issue where `cm health report slingshot refresh` command was giving a trace back error
* Updated documentation for IUF to include rolling reboots after upgrading [HSN](../../glossary.md#high-speed-network-hsn) NIC firmware
* Updated documentation to provide instructions for creating a new Nexus repository and adding RPMs
* Updated documentation for [CAPMC](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc) to warn about URL character limits
* Fixed an issue where BOS v2 requests for too many nodes from PCS exceeding the URL character limit
* Updated Nexus export and restore script to add better checks for determining existence of `nexus-bak` PVC or `nexus-backup` job
* Updated documentation for `fix_failed_to_start_etcd_on_master` to better specify how to add a process
* Fixed an issue with IUF where process-media/pre-install-check dislikes PDF file
* Fixed an issue where `backup_smd_postgres.sh` script is not executable
* `CAST-34869`: Fixed an issue where `cray-hms-rts-snmp` would enter encounter a segmentation fault
* `CAST-34141`: Fixed an issue where the `QLogic` driver would crash the system
* Fixed an issue where an old version of the spire-agent was loaded into Nexus resulting in failed ARM compute builds

## Steps

1. [Preparation](#preparation)
1. [Setup Nexus](#setup-nexus)
1. [Upgrade services](#upgrade-services)
1. [Upload NCN images](#upload-ncn-images)
1. [Update management node CFS configuration](#update-management-node-cfs-configuration)
1. [Update test suite packages](#update-test-suite-packages)
1. [Verification](#verification)
1. [Take Etcd manual backup](#take-etcd-manual-backup)
1. [NCN reboot](#ncn-reboot)
1. [Complete upgrade](#complete-upgrade)

### Preparation

1. Validate CSM health.

   See [Validate CSM Health](../../operations/validate_csm_health.md).

   Run the CSM health checks to ensure that everything is working properly before the upgrade starts.
   After the upgrade is completed, another health check is performed.
   It is important to know if any problems observed at that time existed prior to the upgrade.

   IMPORTANT: See the CSM Install Validation and Health Checks procedures in the documentation for the CURRENT CSM version on the system.
   The validation procedures in the CSM documentation are only intended to work with that specific version of CSM.

1. (`ncn-m001#`) Start a typescript on `ncn-m001` to capture the commands and output from this procedure.

   ```bash
   script -af csm-update.$(date +%Y-%m-%d).txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and extract the CSM `v1.5.1` release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/README.md#download-and-extract).

1. (`ncn-m001#`) Set `CSM_DISTDIR` to the directory of the extracted files.

   **IMPORTANT**: If necessary, change this command to match the actual location of the extracted files.

   ```bash
   export CSM_DISTDIR="$(pwd)/csm-1.5.1"
   echo "${CSM_DISTDIR}"
   ```

1. (`ncn-m001#`) Set `CSM_RELEASE_VERSION` to the CSM release version.

   ```bash
   export CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   echo "${CSM_RELEASE_VERSION}"
   ```

1. Download and install/upgrade the **latest** documentation on `ncn-m001`.

   See [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

### Setup Nexus

(`ncn-m001#`) Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM repositories, container images, and
Helm charts:

```bash
cd "$CSM_DISTDIR"
./lib/setup-nexus.sh ; echo "RC=$?"
```

On success, the output should end with the following:

```text
+ Nexus setup complete
setup-nexus.sh: OK
RC=0
```

In the event of an error,
consult [Troubleshoot Nexus](../../operations/package_repository_management/Troubleshoot_Nexus.md)
to resolve potential problems and then try running `setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh`
may report `FAIL` when uploading duplicate assets. This is okay as long as `setup-nexus.sh` outputs `setup-nexus.sh: OK`
and exits with status code `0`.

### Upgrade services

(`ncn-m001#`) Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
cd "$CSM_DISTDIR"
./upgrade.sh
```

On success, the output should end with the following:

```text
+ CSM applications and services upgraded
upgrade.sh: OK
```

### Upload NCN images

It is important to upload NCN images to IMS and to edit the `cray-product-catalog`. This is necessary when updating
products with IUF. If this step is skipped, IUF will fail when updating or upgrading products in the future.

(`ncn-m001#`) Execute script to upload CSM NCN images and update the `cray-product-catalog`.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/upload-ncn-images.sh
```

On success, the output should end with the following:

```text
Uploading Kubernetes images...
Uploading Ceph images...
Updating image ids...
```

### Update management node CFS configuration

This step updates the CFS configuration which is set as the desired configuration for the management
nodes (NCNs). It ensures that the CFS configuration layers reference the correct commit hash for the
version of CSM being installed. It then waits for the components to reach a configured state in CFS.

1. **IMPORTANT**: The `update-mgmt-ncn-cfs-config.sh` script has a bug in CSM 1.5.1. This bug has
   been addressed in a hotfix that includes `CASMINST-7033` in its title. Review the current field
   notices to find and apply that hotfix before proceeding. If this hotfix is not applied, certain
   properties of the CFS configuration will be lost during its modification.

1. (`ncn-m001#`)

   ```bash
   cd "$CSM_DISTDIR"
   ./update-mgmt-ncn-cfs-config.sh --base-query role=management \
      --save --create-backups --clear-error
   ```

   The output will look similar to the truncated output shown below.

   ```text
   INFO: Querying CFS configurations for the following NCNs: x3000c0s5b0n0, ...
   INFO: Found configuration "management-csm-1.5.0" for component x3000c0s5b0n0
   ...
   INFO: Updating existing layer with repo path /vcs/cray/csm-config-management.git and playbook ncn_nodes.yml
   INFO: Property "commit" of layer with repo path /vcs/cray/csm-config-management.git and playbook ncn_nodes.yml updated ...
   INFO: Property "name" of layer with repo path /vcs/cray/csm-config-management.git and playbook ncn_nodes.yml updated ...
   INFO: No layer with repo path /vcs/cray/csm-config-management.git and playbook ncn-initrd.yml found.
   INFO: Adding a layer with repo path /vcs/cray/csm-config-management.git and playbook ncn-initrd.yml to the end.
   INFO: Successfully saved CFS configuration "management-csm-1.5.0-backup-20240410T205149"
   INFO: Successfully saved CFS configuration "management-csm-1.5.0"
   INFO: Successfully saved 1 changed CFS configuration(s) to CFS.
   INFO: Updated 9 CFS components.
   INFO: Waiting for 9 component(s) to finish configuration
   INFO: Summary of number of components in each status: pending: 9
   INFO: Waiting for 9 pending component(s)
   INFO: Sleeping for 30 seconds before checking status of 9 pending component(s).
   ...
   INFO: Sleeping for 30 seconds before checking status of 9 pending component(s).
   INFO: 9 pending components transitioned to status configured: x3000c0s5b0n0, ...
   INFO: Finished waiting for 9 component(s) to finish configuration.
   INFO: Summary of number of components in each status: configured: 9
   ====> Completed update of CFS configuration(s)
   ====> Cleaning up install dependencies
   ```

   When configuration of all components is successful, the summary line will show all components
   with status "configured".

### Update test suite packages

(`ncn-m001#`) Update select RPMs on the NCNs.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/util/upgrade-test-rpms.sh
```

On success, the output should end with the following:

```text
Enabling and restarting goss-servers
SUCCESS
```

### Verification

1. Verify that the new CSM version is in the product catalog.

   (`ncn-m001#`) Verify that the new CSM version is listed in the output of the following command:

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   ```

   Example output that includes the new CSM version (`1.5.1`):

   ```text
   0.9.2
   0.9.3
   0.9.4
   0.9.5
   0.9.6
   1.0.1
   1.0.10
   1.2.0
   1.2.1
   1.2.2
   1.3.0
   1.3.1
   1.4.0
   1.4.1
   1.4.2
   1.4.3
   1.4.4
   1.5.0
   1.5.1
   ```

1. Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   (`ncn-m001#`) Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.5.1".configuration.import_date'
   ```

### Take Etcd manual backup

(`ncn-m001#`) Execute the following script to take a manual backup of the Etcd clusters.

```bash
/usr/share/doc/csm/scripts/operations/etcd/take-etcd-manual-backups.sh post_patch
```

These clusters are automatically backed up every 24 hours, but taking a manual backup at this stage in the upgrade
enables restoring from backup later in this process if needed.

### NCN reboot

This is an optional step but is strongly recommended. As each patch release includes updated container images that may
contain CVE fixes, it is recommended to reboot each NCN to refresh cached container images. For detailed instructions on
how to gracefully reboot each NCN, refer to [Reboot NCNs](../../operations/node_management/Reboot_NCNs.md).

### Complete upgrade

(`ncn-m001#`) Remember to exit the typescript that was started at the beginning of the upgrade.

```bash
exit
```

It is recommended to save the typescript file for later reference.
