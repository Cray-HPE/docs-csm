# CSM 1.2.2 Patch Installation Instructions

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `v1.2.2` from `v1.2.0` or `1.2.1`.
If upgrading from CSM v1.0.x directly to `v1.2.2`, follow the procedures described in [Upgrade CSM](../1.2/README.md) instead.

## Bug Fixes and Improvements

* Fixes the incorrect `AppVersion` that was being reported from `csi` version report
* Fixes speed with which the pods are restarted as a part of the `precache` chart upgrade (for better performance)
* Increases the timeout for the `etcd_database_health` check in the `ncn-healthcheck`
* Fixes issue with `postgres` database backups that caused them to fail to restore and cleans up existing (bad) `postgres` backups on the system
* Fixes the pod anti-affinity settings and pod disruption budget settings for `cray-dns-unbound`
* Fixes problem with unbound forwarding to powerDNS in an air-gapped environment
* Fixes a race condition between MEDS adding the initial BMC entries and Kea `dhcp-helper` logic updating IP addresses
* Fixes an issue where `snmp` credentials being set on leaf switches were being lost
* Fixes an issue where `cray-hmcollector-poll` pod was not collecting river telemetry due to a check the collector does against the SMA `kafka` instance
* Fixes CVEs in the `ims-load-artifacts` container image
* Fixes CVE in the `oauth2-proxy` container image
* Adds opa policies to force keycloak admin operations through CMN and to address keycloak vulnerability around request_uri
* Fixes issue with missing `App.version` field in `csi version` command
* Adds capability to capmc to use the PATCH URI when trying to set multiple controls for Olympus hardware
* Fixes failure in backing up vcs data when there are extra spaces in the pod name
* Adds documentation to remediate security issues with NCN image access and secret exposure
* Documented remediation for NCN Image access and secret exposure
* Adds documentation for CSM post-install SNMP exporter settings
* Updates the System Power On documentation to add a rolling restart of spire `request-ncn-join-token` (to avoid issues with spire tokens)
* Documents workaround for iLO FW droppping redfish subscriptions
* Adds improvements to documentation of canu commands
* Documents known issues for gatekeeper constraint and refused connection
* Documents syntax error in gateway test example command
* Documents a workaround for known issue with boot order
* Improves documentation around CFS image customization session procedure
* Documents usage of the `--no-cache` flag when resuming CSM services install
* Improvements and better documentation for the `external SSH test`
* Adds clarity to Site Init documentation on external hosts
* Adds documentation for the DNS zone forwarding for powerDNS in an air-gapped environment
* Adds timeout to etcd database health check
* Fixes the NCN boot artifacts validation test
* Adds NTP goss test
* Improvements in pod back-up test scripts
 
 

## Known Issues

* `kdump` (kernel dump) may hang and fail on NCNs in CSM 1.2 (HPE Cray EX System Software 22.07 release). During the upgrade, a workaround is applied to fix this.
* The boot order on NCNs may not be correctly set. Because of a bug, the disk entries may be listed ahead of the PXE entries. During the upgrade, a workaround is applied to fix this. This workaround will also fix missing disk entries after an upgrade.

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

1. Download and extract the CSM `v1.2.2` release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/index.md#download-and-extract).

1. Set `CSM_DISTDIR` to the directory of the extracted files.

   **IMPORTANT**: If necessary, change this command to match the actual location of the extracted files.

   ```bash
   ncn-m001# CSM_DISTDIR="$(pwd)/csm-1.2.2"
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

   Example output that includes the new CSM version (`1.2.2`):

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
   ```

1. Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.2.2".configuration.import_date'
   ```

## Complete upgrade

1. Remember to exit the typescript that was started at the beginning of the upgrade.

     ```bash
     ncn-m001# exit
     ```

It is recommended to save the typescript file for later reference.
