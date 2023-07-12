# CSM 1.4.1 Patch Installation Instructions

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `v1.4.1` from `v1.4.0`.
If upgrading from CSM `v1.3.4` directly to `v1.4.1`, follow the procedures described in [Upgrade CSM](../README.md) instead.

## Bug Fixes and Improvements

* Updates to the `bos` API specification
* Refactoring of the `hms-rts` chart for deployment of multiple back ends
* Allow the power control service `pcs` to be able to report power status of `RTS` management switches
* Support adding types of `MgmtHLSwitch` and `CDUMgmtSwitch` to vault to be able to set their SNMP credentials
* Support for discovering `RTS` switches and updating their data in hardware state manager
* Generation of API docs from swagger files in the `Cray-HPE` codebase
* CVE fixes against the `metacontroller:v4.4.0` container image
* Fix in `bos v2` to filter out any nodes disabled in hardware state manager at `bos` session creation
* Fix for accidental removal of `crus` from the `cray-cli`
* Fix for error in `cray fas loader` due to a python library change  
* Fix permissions issue with the `goss-servers.service` that caused extraneous messages to print to the console
* Add troubleshooting documentation instructing users to redeploy daemons that are stuck in error state during `upload_ceph_images_to_nexus`
* Fix for upgrade of the `cray-dns-unbound` helm chart leading to deletion of `DNS` records
* Add `SNMP` set up for all switches to the install and upgrade instructions
* Fix for `grok-exporter` not running on the `ncn-m001` node
* CVE fixes against the `cray-sat:3.21.4` container image
* CVE fixes against the `cilium:v1.12.4` container image
* Fix for `hsm_discovery_status_test` error
* Fix for `bos v2` setting the wrong status at scale
* Fix for `goss-platform-ca-in-bundle` test time out
* Fix trace back in `bos` log with `bos` shutdown failure
* Update to `bos v1 session create` API specification to fix missing required parameters
* Fix issue with missing data in `bos v1 list sessions`
* Fix for return of expected object when describing a `bos v1` session
* Fix for incorrect response from `bos v2 sessiontemplatetemplate` endpoint
* Support for `python 3.11` in `bos` server
* CVE fixes against the `argoexec` container image
* Fix errors in `prerequisites.sh` for upgrading `nls`
* Fix for wiping of `DNS` records from the `configmap` when restarting `kea`
* Fix network policy in `cray-drydock` for communications between `mqtt` and `spire`
* Fix failure in image pull during upgrade
* Fix to ensure the `bos` API specification is accurate for get or list `sessiontemplates` endpoints
* CVE fixes against the `cfs-ara:1.0.2` container image
* Fix timeout deploying `cray-dns-unbound` during the install of `csm` services
* Fix for allowing underscores in `bos sessiontemplate` names

## Steps

1. [Preparation](#preparation)
1. [Setup Nexus](#setup-nexus)
1. [Update Argo CRDs](#update-argo-crds)
1. [Upgrade services](#upgrade-services)
1. [Upload NCN images](#upload-ncn-images)
1. [Verification](#verification)
1. [Complete upgrade](#complete-upgrade)

## Preparation

1. Start a typescript on `ncn-m001` to capture the commands and output from this procedure.

   ```bash
   script -af csm-update.$(date +%Y-%m-%d).txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and extract the CSM `v1.4.1` release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/index.md#download-and-extract).

1. Set `CSM_DISTDIR` to the directory of the extracted files.

   **IMPORTANT**: If necessary, change this command to match the actual location of the extracted files.

   ```bash
   export CSM_DISTDIR="$(pwd)/csm-1.4.1"
   echo "${CSM_DISTDIR}"
   ```

1. Set `CSM_RELEASE_VERSION` to the CSM release version.

   ```bash
   export CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   echo "${CSM_RELEASE_VERSION}"
   ```

1. Download and install/upgrade the **latest** documentation on `ncn-m001`.

   See [Check for Latest Documentation](../../update_product_stream/index.md#check-for-latest-documentation).

## Setup Nexus

Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
cd "$CSM_DISTDIR"
./lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output `OK` on `stderr` and exit with status
code `0`. For example:

```console
./lib/setup-nexus.sh

[... output omitted ...]

+ Nexus setup complete
setup-nexus.sh: OK
echo $?
0
```

In the event of an error, consult [Troubleshoot Nexus](../../operations/package_repository_management/Troubleshoot_Nexus.md)
to resolve potential problems and then try running `setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is okay as long as `setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits
with status code `0`.

## Update Argo CRDs

Run the following script in preparation for 1.4.1 patch upgrade:

```bash
for c in $(kubectl get crd |grep argo | cut -d' ' -f1)
do
   kubectl label --overwrite crd $c app.kubernetes.io/managed-by="Helm"
   kubectl annotate --overwrite crd $c meta.helm.sh/release-name="cray-nls"
   kubectl annotate --overwrite crd $c meta.helm.sh/release-namespace="argo"
done
```

## Upgrade services

Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
cd "$CSM_DISTDIR"
./upgrade.sh
```

## Upload NCN images

It is important to upload NCN images to IMS and to edit the `cray-product-catalog`. This is necessary when updating products
with IUF. If this step is skipped, IUF will fail when updating or upgrading products in the future.

(`ncn-m001#`) Execute script to upload CSM NCN images and update the `cray-product-catalog`.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/upload-ncn-images.sh
```

## Update test suite packages

Update the `csm-testing` and `goss-servers` RPMs on the NCNs.

```bash
pdsh -b -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') 'zypper install -y csm-testing goss-servers craycli'
```

## Verification

1. Verify that the new CSM version is in the product catalog.

   Verify that the new CSM version is listed in the output of the following command:

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   ```

   Example output that includes the new CSM version (`1.4.1`):

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
   ```

1. Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.4.1".configuration.import_date'
   ```

## Complete upgrade

Remember to exit the typescript that was started at the beginning of the upgrade.

```bash
exit
```

It is recommended to save the typescript file for later reference.
