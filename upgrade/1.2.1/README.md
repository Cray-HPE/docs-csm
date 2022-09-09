# CSM 1.2.1 Patch Installation Instructions

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `v1.2.1` from `v1.2.0`.
If upgrading from CSM v1.0.x directly to v1.2.1, follow the procedures described in [Upgrade CSM](../1.2/README.md) instead.

## Bug Fixes

* Fixes two issues in CFS, restoring the additional inventory field functionality.
* Fixes an issue restoring console services functionality on "Hill" cabinets.
* Fixes a few issues in PowerDNS where various records were missing in the AXFR transfer.
* Fixes a rare issue where the Istio container would not be available during a future upgrade to CSM 1.3.0.
* Fixes an issue where a modified NCN image can no longer boot to disk when specified instead of the default PXE boot.
* Fixes a rare issue where NCNs booted with a modified image containing Slingshot Host Software had NO-CARRIER on all network interfaces.
* Fixes an issue where CANU generates incorrect VLANs for switch ports connected to UANs over the CHN.
* Fixes an issue where dhcp-manager could apply NIC data to the wrong reservation in Kea

## Known Issues

* `kdump` (kernel dump) may hang and fail on NCNs in CSM 1.2 (HPE Cray EX System Software 22.07 release). During the upgrade, a workaround is applied to fix this.
* The boot order on NCNs may not be correctly set. Because of a bug, the disk entries may be listed ahead of the PXE entries. During the upgrade, a workaround is applied to fix this.

## Steps

1. [Upgrade CSM network configuration](upgrade_network.md)
1. [Preparation](#preparation)
1. [Setup Nexus](#setup-nexus)
1. [Upgrade services](#upgrade-services)
1. [Verification](#verification)
1. [Complete upgrade](#complete-upgrade)

## Optional: Upgrade CSM network configuration

If you are using the CHN network tech preview, upgrade the CSM management network configuration before proceeding with the patch installation.

Detailed information on the fixes and configuration updates after CANU release 1.6.5 can be found from [CANU release notes](../../operations/network/management_network/canu_install_update.md)

 1. [Upgrade CSM network configuration](upgrade_network.md)

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
