# CSM 1.2.1 Patch Installation Instructions

## Introduction

This document guides an administrator through the upgrade to Cray Systems Management `v1.2.1` from `v1.2.0`.
Earlier version of CSM must first be upgraded to at least `v1.2.0`. For information on how to do that, see [Upgrade CSM](../index.md).

## Steps

1. [Upgrade CSM network configuration](upgrade_network.md)
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

1. Download and extract the CSM `v1.2.1` release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/index.md#download-and-extract).

1. Set `CSM_DISTDIR` to the directory of the extracted files.

   **IMPORTANT**: If necessary, change this command to match the actual location of the extracted files.

   ```bash
   ncn-m001# CSM_DISTDIR="$(pwd)/csm-1.2.1"
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

Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m001# cd "$CSM_DISTDIR"
ncn-m001# ./upgrade.sh
```

## Verification

1. Verify that the new CSM version is in the product catalog.

   Verify that the new CSM version is listed in the output of the following command:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   ```

   Example output that includes the new CSM version (`1.2.1`):

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
   ```

1. Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.2.1".configuration.import_date'
   ```

## Complete upgrade

1. Remember to exit the typescript that was started at the beginning of the upgrade.

     ```bash
     ncn-m001# exit
     ```

It is recommended to save the typescript file for later reference.
