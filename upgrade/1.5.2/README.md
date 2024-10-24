# CSM 1.5.2 Patch Installation Instructions

* [Introduction](#introduction)
* [Bug fixes and improvements](#bug-fixes-and-improvements)
* [Steps](#steps)

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `v1.5.2`
from CSM `v1.5.0`.

If upgrading from CSM `v1.4.x`,  then follow the procedures
described in [CSM major/minor version upgrade](../README.md#csm-majorminor-version-upgrade) instead.

> _In the unusual situation of upgrading from a pre-release version of CSM `v1.5.0`, then follow the procedures described in [CSM major/minor version upgrade](../README.md#csm-majorminor-version-upgrade) instead._

If more recent CSM `v1.5` patch versions are available, note that there is no need to perform
intermediate CSM `v1.5` patch upgrades. Instead, consider upgrading to the latest CSM `v1.5`
patch release. See [CSM patch version upgrade](../README.md#csm-patch-version-upgrade) for the full
list of patch versions.

## Bug fixes and improvements

* Added support for Paradise hardware
* Added support for Parry Peak hardware
* Console: Fixed issue in `conman` in order to support Paradise hardware
* HSM: Fixed issue in `run_hms_ct_tests.sh` which caused false positives for CDU switches
* HSM: Enhanced `hmcollector` logging
* HSM: FAS now waits for the time limit to expire when verifying update. `FASUpdate.py` script also updated to accept a `--timeLimit` parameter to change the preset time limit
* Required environment variables now set to address breaking changes in the latest ca-certificates RPM
* Update IMS recipe builds to use new DST signing key
* Multitenancy: Allowed tenant admins to list their BOS v2 sessions
* CFS: Fixed error when updating multiple components using CFS v2
* BOS: Changes to avoid pods being `OOMKilled`
* HSM: Fixed bug preventing bulk updates of roles/subroles
* BOS: Improved logging
* BOS: v2 performance improvements, particularly at scale
* BOS: Fix possible false BOS failure in `cmsdev` health check
* CFS: Updated dependency version to prevent deprecation warnings in pod logs during image customization
* BOS: Fixed some failures when multiple simultaneous BOS sessions are created soon after the service first starts
* BOS: Perform better checking of age string arguments to relevant API endpoints
* Fixed issue for `goss-servers` being able to be installed without `goss`, `goss-servers` now requires `goss` as a dependency
* Fixed issue for `goss-servers.service` from being disabled when updating the `goss-servers`’s package.
* DHCP: Boot filename can be overridden on a per-node basis.

## Steps

1. [Preparation](#preparation)
1. [Setup Nexus](#setup-nexus)
1. [Upgrade services](#upgrade-services)
1. [Upload NCN images](#upload-ncn-images)
1. [Update management node CFS configuration](#update-management-node-cfs-configuration)
1. [Update NCN images](#update-ncn-images)
1. [Update test suite packages](#update-test-suite-packages)
1. [Verification](#verification)
1. [Take Etcd manual backup](#take-etcd-manual-backup)
1. [NCN upgrade](#ncn-upgrade)
1. [Configure E1000 node and Redfish Exporter for SMART data](#configure-e1000-node-and-redfish-exporter-for-smart-data)
1. [Complete upgrade](#complete-upgrade)

### Preparation

1. Validate CSM health.

   See [Validate CSM Health](../../operations/validate_csm_health.md).

   Run the CSM health checks to ensure that everything is working properly before the upgrade starts.
   After the upgrade is completed, another health check is performed.
   It is important to know if any problems observed at that time existed prior to the upgrade.

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

1. **IMPORTANT**: The `update-mgmt-ncn-cfs-config.sh` script has a bug in CSM 1.5.2. This bug has
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

### Update NCN images

NCN images should be rebuilt at this time to acquire any changes from CSM config.

This step does not rebuild NCNs. These new images are built and stored in S3 to facilitate the add and rebuild NCN procedures.

#### Image customization

1. Print the product catalog `ConfigMap`.

    ```bash
    kubectl -n services get cm cray-product-catalog -o jsonpath='{.data}' | jq '. | keys'
    ```

   Example outputs:

    * CSM running with additional products:

        ```json
        [
            "HFP-firmware",
            "analytics",
            "cos",
            "cos-base",
            "cpe",
            "cpe-aarch64",
            "cray-sdu-rda",
            "csm",
            "csm-diags",
            "hfp",
            "hpc-csm-software-recipe",
            "pbs",
            "sat",
            "sle-os-backports-15-sp3",
            "sle-os-backports-15-sp4",
            "sle-os-backports-sle-15-sp3-x86_64",
            "sle-os-backports-sle-15-sp4-x86_64",
            "sle-os-backports-sle-15-sp5-aarch64",
            "sle-os-backports-sle-15-sp5-x86_64",
            "sle-os-products-15-sp3",
            "sle-os-products-15-sp3-x86_64",
            "sle-os-products-15-sp4",
            "sle-os-products-15-sp4-x86_64",
            "sle-os-products-15-sp5-aarch64",
            "sle-os-products-15-sp5-x86_64",
            "sle-os-updates-15-sp3",
            "sle-os-updates-15-sp3-x86_64",
            "sle-os-updates-15-sp4",
            "sle-os-updates-15-sp4-x86_64",
            "sle-os-updates-15-sp5-aarch64",
            "sle-os-updates-15-sp5-x86_64",
            "slingshot",
            "slingshot-host-software",
            "slurm",
            "sma",
            "uan",
            "uss"
        ]
        ```

    * CSM on a CSM-only system:

        ```json
        [
          "csm"
        ]
        ```

1. Choose one of the following options based on the output from the previous step.

    * Option 1: [Upgrade of CSM on system with additional products](./CSM-With-Other-Products.md)
    * Option 2: [Upgrade of CSM on CSM-only system](./CSM-Only.md#steps)
      _(Do not use this procedure if more than CSM is installed on the system.\)_

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

### NCN upgrade

This step is necessary so that nodes are using the correct images after running [Update NCN images](../1.5.2/README.md#update-ncn-images).

The rebuild will also ensure that the NCN has the latest cached container images that often accompany a CSM patch release.

Follow the [Upgrade NCNs during CSM `1.5.2` Patch](./Upgrade_NCN_images.md) instructions to perform the NCN node image upgrades.

### Configure E1000 node and Redfish Exporter for SMART data

> **NOTE:** Please follow this step if SMART disk data is needed for E1000 node.

This step is for getting the SMART data from the disks on E1000 node using the Redfish exporter into `prometheus` time-series database.
To configure the LDAP instance on the E1000 primary management node and reconfigure the redfish-exporter instance running on the `ncn`, see [Configure E1000 node and Redfish Exporter](../../operations/system_management_health/E1000_SMART_data_configuration.md).

### Complete upgrade

(`ncn-m001#`) Remember to exit the typescript that was started at the beginning of the upgrade.

```bash
exit
```

It is recommended to save the typescript file for later reference.
