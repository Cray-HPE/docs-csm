# CSM 1.2.6 Patch Installation Instructions

## Introduction

This document guides an administrator through the upgrade to Cray Systems Management `v1.2.6` from `v1.2.0`.
Earlier version of CSM must first be upgraded to at least `v1.2.0`. For information on how to do that, see [Upgrade CSM](../index.md).

## Steps

1. [Preparation](#preparation)
1. [Setup Nexus](#setup-nexus)
1. [Upgrade services](#upgrade-services)
1. [Verification](#verification)
1. [Complete upgrade](#complete-upgrade)

## Preparation

1. Start a typescript on `ncn-m001` to capture the commands and output from this procedure.

   ```bash
   ncn-m001# script -af csm-update.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and extract the CSM `v1.2.6` release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/index.md#download-and-extract).

1. Set `CSM_DISTDIR` to the directory of the extracted files.

   **IMPORTANT**: If necessary, change this command to match the actual location of the extracted files.

   ```bash
   ncn-m001# CSM_DISTDIR="$(pwd)/csm-1.2.6"
   ncn-m001# echo "${CSM_DISTDIR}"
   ```

1. Set `CSM_RELEASE_VERSION` to the CSM release version.

   ```bash
   ncn-m001# export CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   ncn-m001# echo "${CSM_RELEASE_VERSION}"
   ```

1. Download and install/upgrade the **latest** documentation on `ncn-m001`.

   See [Check for Latest Documentation](../../update_product_stream/index.md#check-for-latest-documentation).

## Setup Nexus

Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
ncn-m001# cd "$CSM_DISTDIR"
ncn-m001# ./lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output `OK` on `stderr` and exit with status
code `0`. For example:

```console
ncn-m001# ./lib/setup-nexus.sh

[... output omitted ...]

+ Nexus setup complete
setup-nexus.sh: OK
ncn-m001# echo $?
0
```

In the event of an error, consult [Troubleshoot Nexus](../../operations/package_repository_management/Troubleshoot_Nexus.md)
to resolve potential problems and then try running `setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is okay as long as `setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits
with status code `0`.

## Upgrade services

> For TDS systems with only three worker nodes, the `customizations.yaml` file will be edited automatically during upgrade to lower CPU requests on
> several services, in order to improve pod scheduling on smaller systems. See the file `${CSM_DISTDIR}/tds_cpu_requests.yaml` for these settings. If
> desired, this file can be modified prior to proceeding with the CSM upgrade, if other settings are desired in the
> `customizations.yaml` file for this system. For more information about modifying `customizations.yaml` and tuning based on specific systems, see
> [Post Install Customizations](../../operations/CSM_product_management/Post_Install_Customizations.md).

Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m001# cd "$CSM_DISTDIR"
ncn-m001# /usr/share/doc/csm/upgrade/1.2.6/scripts/update-customization.sh
ncn-m001# ./upgrade.sh
ncn-m001# /usr/share/doc/csm/upgrade/1.2.6/scripts/post-csm-services-upgrade.sh
```

## Verification

1. Verify that the new CSM version is in the product catalog.

   Verify that the new CSM version is listed in the output of the following command:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   ```

   Example output that includes the new CSM version (`1.2.6`):

   ```text
   0.9.2
   0.9.3
   0.9.4
   0.9.5
   0.9.6
   1.0.1
   1.0.10
   1.2.0
   1.2.6
   ```

1. Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.0.10".configuration.import_date'
   ```

## Complete upgrade

1. Run NCN personalization to update the NCNs to the latest configuration.

   See [Perform NCN Personalization](../../operations/CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md#perform_ncn_personalization).

1. Confirm that the correct version of the Loftsman RPM is installed on each NCN.

   The expected version is `1.2.0-1`.

   ```bash
   ncn-m001# for xname in $(cray hsm state components list --role Management --format json | jq -r .Components[].ID); do
                 out=$(ssh -oStrictHostKeyChecking=no -q $xname "rpm -qa | grep loftsman")
                 echo $xname $out
             done
   ```

   Example of expected output:

   ```text
   x3000c0s11b0n0 loftsman-1.2.0-1.x86_64
   x3000c0s13b0n0 loftsman-1.2.0-1.x86_64
   x3000c0s15b0n0 loftsman-1.2.0-1.x86_64
   x3000c0s17b0n0 loftsman-1.2.0-1.x86_64
   x3000c0s1b0n0 loftsman-1.2.0-1.x86_64
   x3000c0s36b0n0 loftsman-1.2.0-1.x86_64
   x3000c0s38b0n0 loftsman-1.2.0-1.x86_64
   x3000c0s3b0n0 loftsman-1.2.0-1.x86_64
   x3000c0s5b0n0 loftsman-1.2.0-1.x86_64
   x3000c0s7b0n0 loftsman-1.2.0-1.x86_64
   x3000c0s9b0n0 loftsman-1.2.0-1.x86_64
   ```

   The number of lines of output will vary based on the number of NCNs in the system.
   If the version of the Loftsman RPM does not match the output above, look for errors
   in the Ansible play output in the CFS session logs created during NCN
   personalization.

1. Remember to exit the typescript that was started at the beginning of the upgrade.

     ```bash
     ncn-m001# exit
     ```

It is recommended to save the typescript file for later reference.
