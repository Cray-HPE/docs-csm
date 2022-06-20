# CSM 1.2.6 Patch Installation Instructions

## Introduction

This document is intended to guide an administrator through the process going to Cray Systems Management v1.2.6 from v1.2.0. If you are at an earlier version, you must first upgrade to at least v1.2.0. For information on how to do that, see [Upgrade CSM](../index.md).

## Steps

1. [Preparation](#preparation)
1. [Setup Nexus](#setup-nexus)
1. [Upgrade Services](#upgrade-services)
1. [Verification](#verification)
1. [Run NCN Personalization](#run-ncn-personalization)
1. [Exit Typescript](#exit-typescript)

<a name="preparation"></a>

## Preparation

1. Start a typescript on `ncn-m001` to capture the commands and output from this procedure.

   ```bash
   ncn-m001# script -af csm-update.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and extract the CSM 1.2.6 release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/index.md#download-and-extract).

1. Set `CSM_DISTDIR` to the directory of the extracted files:

   **IMPORTANT**: If necessary, be sure to change this example command to match the actual location of the extracted files.

   ```bash
   ncn-m001# export CSM_DISTDIR="$(pwd)/csm-1.2.6"
   ```

1. Set `CSM_RELEASE_VERSION` to the version reported by `${CSM_DISTDIR}/lib/version.sh`:

   ```bash
   ncn-m001# CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   ncn-m001# echo $CSM_RELEASE_VERSION
   ```

1. Download and install/upgrade the _latest_ documentation and workarounds RPMs on `ncn-m001`.

   See [Check for Latest Workarounds and Documentation Updates](../../update_product_stream/index.md#workarounds).

<a name="setup-nexus"></a>

## Setup Nexus

Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
ncn-m001# cd "$CSM_DISTDIR"
ncn-m001# ./lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output `OK` on stderr and exit with status
code `0`, e.g.:

```bash
+ Nexus setup complete
setup-nexus.sh: OK
ncn-m001# echo $?
0
```

In the event of an error, consult [Troubleshoot Nexus](../../operations/package_repository_management/Troubleshoot_Nexus.md)
to resolve potential problems and then try running `setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is ok as long as `setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits
with status code `0`.

<a name="upgrade-services"></a>

## Upgrade Services

> For TDS systems with only three worker nodes the `customizations.yaml` file will be edited automatically during upgrade to lower CPU requests on 
several services which can improve pod scheduling on smaller systems. See the file: `${CSM_DISTDIR}/tds_cpu_requests.yaml` for these settings. If 
desired, this file can be modified (prior to proceeding with this upgrade) with different values if other settings are desired in the `customizations.
yaml` file for this system. For more information about modifying `customizations.yaml` and tuning based on specific systems, see [Post Install 
Customizations](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/CSM_product_management/Post_Install_Customizations.md).

Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m001# cd "$CSM_DISTDIR"
ncn-m001# ./upgrade.sh
ncn-m001# /usr/share/doc/csm/upgrade/1.2.6/scripts/post-csm-services-upgrade.sh
```

<a name="verification"></a>

## Verification

### Verify CSM Version in Product Catalog

1. Verify that the following command includes the new CSM version:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
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

1. Confirm the `import_date` reflects the timestamp of the upgrade:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.0.10".configuration.import_date'
   ```

<a name="run-ncn-personalization"></a>

## Run NCN Personalization

1. Run NCN Personalization to update the NCNs to the latest configruation.
   Complete the [Run NCN Personalization](../../operations/CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md#run-ncn-personalization)
   procedure.

1. Confirm the version of the Loftsman RPM installed on each NCN. Output below
   will vary based on the number of NCNs in the system.

   ```bash
   ncn-m001# for xname in $(cray hsm state components list --role Management --format json | jq -r .Components[].ID);
   do
       out=$(ssh -oStrictHostKeyChecking=no -q $xname "rpm -qa | grep loftsman")
       echo $xname $out
   done
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

   If the version of the Loftsman RPM does not match the output above, review
   the Ansible play output in the CFS session logs created during NCN
   Personalization for any errors.

<a name="exit-typescript"></a>

## Exit Typescript

Remember to exit your typescript.

```bash
ncn-m001# exit
```

It is recommended to save the typescript file for later reference.
