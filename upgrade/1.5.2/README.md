# CSM 1.5.2 Patch Installation Instructions

* [Introduction](#introduction)
* [Bug fixes and improvements](#bug-fixes-and-improvements)
* [Steps](#steps)

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `v1.5.2`
from CSM `v1.5.0`. If upgrading from CSM `v1.4.x`,  then follow the procedures
described in [CSM major/minor version upgrade](../README.md#csm-majorminor-version-upgrade) instead.
In the unusual situation of upgrading from a pre-release version of CSM `v1.5.0`, then follow the procedures
described in [CSM major/minor version upgrade](../README.md#csm-majorminor-version-upgrade) instead.

If there are more recent CSM `v1.5` patch versions available, note that there is no need to perform
intermediate CSM `v1.5` patch upgrades. Instead, consider upgrading to the latest CSM `v1.5`
patch release. See [CSM patch version upgrade](../README.md#csm-patch-version-upgrade) for the full
list of patch versions.

## Bug fixes and improvements

INSTRUCTIONS FOR CASM FOLKS (delete this line later): Replace any line below that contains your
name with a one line description of the change tha occurred as a result of your Jira. Combine
bullets together if it makes sense (eg. many Paradise bullets combined into a single "Support
for Paradise hardware"..

* Added support for Paradise hardware
* Fixed issue in `conman` in order to support Paradise hardware
* Fixed issue in `run_hms_ct_tests.sh` which caused false positives for CDU switches
* Enhanced `hmcollector` logging
* Mike Buchmann: CASMHMS-6207
* Mitchell Harding: CASMCMS-8971
* Mitchell Harding: CASMCMS-8973
* Mitchell Harding: CASMCMS-8978
* Mitchell Harding: CASMCMS-8186
* Mitchell Harding: CASMCMS-8438
* Mitchell Harding: CASMINST-6861
* Mitchell Harding: CASMTRIAGE-6993
* Mitchell Harding: CASMTRIAGE-7019
* Mitchell Harding: CASMHMS-5838
* Mitchell Harding: CASMCMS-9001
* Mitchell Harding: CASMCMS-8997
* Mitchell Harding: CASMCMS-8998
* Mitchell Harding: CASMCMS-9017
* Mitchell Harding: CASMCMS-9018
* Mitchell Harding: CASMCMS-9015
* Mitchell Harding: CASMCMS-9022
* Shreni Agrawal: CASMMON-364
* Shreni Agrawal: CASMMON-396
* David Laine: CASMCMS-8976
* Russell Bunch: CASMTRIAGE-6991
* Russell Bunch: MTL-2393
* Jason Davis: MTL-2394
* Mikhail Tupitsyn: CASMPET-7093
* Chris Spiller: CASMPET-7021
* Chris Spiller: CASMNET-2221

## Limitations

* Power capping support for Paradise Hardware
  * Power caps are applied to the processor complex, not to the entire node
  * A power cap cannot be applied when node power is off
  * If a power cap is set when node power is on, it will be removed if the node is ever powered off.  A new power cap must be applied after the node powers back on

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

1. Download and extract the CSM `v1.5.2` release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/README.md#download-and-extract).

1. (`ncn-m001#`) Set `CSM_DISTDIR` to the directory of the extracted files.

   **IMPORTANT**: If necessary, change this command to match the actual location of the extracted files.

   ```bash
   export CSM_DISTDIR="$(pwd)/csm-1.5.2"
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

   Example output that includes the new CSM version (`1.5.2`):

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
   1.5.2
   ```

1. Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   (`ncn-m001#`) Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.5.2".configuration.import_date'
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
