# CSM 1.4.2 Patch Installation Instructions

* [Introduction](#introduction)
* [Bug fixes and improvements](#bug-fixes-and-improvements)
* [Steps](#steps)

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `v1.4.2` from `v1.4.0` or `1.4.1`.
If upgrading from CSM `v1.3.x` directly to `v1.4.2`, follow the procedures described in [Upgrade CSM](../README.md) instead.

## Bug fixes and improvements

* Reinstated the `arp-cache` tuning settings that were lost in the upgrade to `CSM 1.4` that caused system performance issues
* Added capability for `SMART` data to be collected from storage nodes and passed to `prometheus`
* Changed configuration of `apparmor` for `node-exporter` in the `prometheus` chart to stop flood of messages to `dmesg` log
* Fixed a bug with a `csm-config` change which caused a failure in the `prepare-images` stage of `iuf` because of a `cfs ansible` layer that was not running
* Added support for the `include_disabled_nodes` option for `bos` within the `cray-cli`
* Changed procedure for the update of the `cray-cli`, `csm-testing`, and `goss-server` `rpm` packages such that they are updated on all management nodes
* Upgraded version of `ceph` to `16.2.13`
* Addressed a regular expression `DoS` `CVE` in `cfs-ara`
* Addressed an improper certificate validation `CVE` in `cfs` and `cfs-operator`
* Optimized main `csm goss` test run in the `csm` validation procedure by adding `cms` and `hms` tests to it
* Added a test to validate the `nexus` and `keycloak` integration is configured properly
* Updated the version of `cray-cli` used in the `iuf` container image to the latest version
* Fixed edge case bugs in the `ceph` service status script which is leveraged in `ceph` health checks
* Fixed test failures for duplicate `DNS` entries
* Removed the `-P` option for non-standard client port number from `cray-dhcp-kea` to eliminate failures it caused in some environments
* Replaced `latest` tag for `iuf-container` images with a dynamic `look-up` which pulls in the correct `iuf` version tag
* Updated patch instructions to run `etcd back-ups` after the upgrade has completed to avoid health check failures on `back-ups` that have been around for greater than 24 hours

## Steps

1. [Preparation](#preparation)
1. [Setup Nexus](#setup-nexus)
1. [Update Argo CRDs](#update-argo-crds)
1. [Upgrade services](#upgrade-services)
1. [Upload NCN images](#upload-ncn-images)
1. [Upgrade Ceph and stop local Docker registries](#upgrade-ceph-and-stop-local-docker-registries)
1. [Enable `smartmon` metrics on storage NCNs](#enable-smartmon-metrics-on-storage-ncns)
1. [Configure NCNs without restart](#configure-ncn-nodes-without-restart)
1. [Update test suite packages](#update-test-suite-packages)
1. [Verification](#verification)
1. [Take Etcd manual backup](#take-etcd-manual-backup)
1. [NCN node reboot](#ncn-node-reboot)
1. [Complete upgrade](#complete-upgrade)

### Preparation

1. (`ncn-m001#`) Start a typescript on `ncn-m001` to capture the commands and output from this procedure.

   ```bash
   script -af csm-update.$(date +%Y-%m-%d).txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and extract the CSM `v1.4.2` release to `ncn-m001`.

   See [Download and Extract CSM Product Release](../../update_product_stream/README.md#download-and-extract).

1. (`ncn-m001#`) Set `CSM_DISTDIR` to the directory of the extracted files.

   **IMPORTANT**: If necessary, change this command to match the actual location of the extracted files.

   ```bash
   export CSM_DISTDIR="$(pwd)/csm-1.4.2"
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

(`ncn-m001#`) Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

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

In the event of an error, consult [Troubleshoot Nexus](../../operations/package_repository_management/Troubleshoot_Nexus.md)
to resolve potential problems and then try running `setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is okay as long as `setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits
with status code `0`.

### Update Argo CRDs

(`ncn-m001#`) Run the following script in preparation for 1.4.2 patch upgrade:

```bash
for c in $(kubectl get crd |grep argo | cut -d' ' -f1)
do
   kubectl label --overwrite crd $c app.kubernetes.io/managed-by="Helm"
   kubectl annotate --overwrite crd $c meta.helm.sh/release-name="cray-nls"
   kubectl annotate --overwrite crd $c meta.helm.sh/release-namespace="argo"
done
```

### Upgrade services

(`ncn-m001#`) Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
cd "$CSM_DISTDIR"
./upgrade.sh
```

### Upload NCN images

It is important to upload NCN images to IMS and to edit the `cray-product-catalog`. This is necessary when updating products
with IUF. If this step is skipped, IUF will fail when updating or upgrading products in the future.

(`ncn-m001#`) Execute script to upload CSM NCN images and update the `cray-product-catalog`.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/upload-ncn-images.sh
```

### Upgrade Ceph and stop local Docker registries

**Note:** This step may not be necessary if it was already completed by the CSM `v1.3.5` patch.
If it was already run, the following steps can be re-executed to verify that Ceph daemons are using images
in Nexus and the local Docker registries have been stopped.

These steps will upgrade Ceph to `v16.2.13`. Then the Ceph monitoring daemons' images will be pushed to Nexus and the monitoring daemons will be redeployed so that they use these images in Nexus.
Once this is complete, all Ceph daemons should be using images in Nexus and not images hosted in the local Docker registry on storage nodes.
The third step stops the local Docker registry on all storage nodes.

1. (`ncn-m001#`) Run Ceph upgrade to `v16.2.13`.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/ceph/ceph-upgrade-tool.py --version "v16.2.13"
   ```

1. (`ncn-m001#`) Redeploy Ceph monitoring daemons so they are using images in Nexus.

   ```bash
   scp /usr/share/doc/csm/scripts/operations/ceph/redeploy_monitoring_stack_to_nexus.sh ncn-s001:/srv/cray/scripts/common/redeploy_monitoring_stack_to_nexus.sh
   ssh ncn-s001 "/srv/cray/scripts/common/redeploy_monitoring_stack_to_nexus.sh"
   ```

1. (`ncn-m001#`) Stop the local Docker registries on all storage nodes.

   ```bash
   scp /usr/share/doc/csm/scripts/operations/ceph/disable_local_registry.sh ncn-s001:/srv/cray/scripts/common/disable_local_registry.sh
   ssh ncn-s001 "/srv/cray/scripts/common/disable_local_registry.sh"
   ```

### Enable `smartmon` metrics on storage NCNs

This step will install the `smart-mon` rpm on storage nodes, and reconfigure the `node-exporter` to provide `smartmon` metrics.

1. (`ncn-m001#`) Execute the following script.

   ```bash
   /usr/share/doc/csm/scripts/operations/ceph/enable-smart-mon-storage-nodes.sh
   ```

### Configure NCNs without restart

This step will create an imperative CFS session that can be used to configure booted NCN with updated `sysctl` values.

1. (`ncn-m001#`) Run `configure_ncns.sh` to create a CFS configuration and session.

    **IMPORTANT**: This script will overwrite any CFS configuration called `ncn_nodes`.
    Change the `CONFIG_NAME` variable in the script to change this behavior.

    **IMPORTANT**: This script will not start a new CFS session if one of the same name already exists.
    If an old session exists, delete it first or change the  `SESSION_NAME` variable in the script to use
    a different session name.

    ```bash
    /usr/share/doc/csm/upgrade/scripts/cfs/configure_ncns.sh
    ```

1. (`ncn-m001#`) Wait for CFS to complete configuration.

   ```bash
   cray cfs sessions describe ncnnodes
   kubectl logs -f -n services jobs/`cray cfs sessions describe ncnnodes --format json | jq -r " .status.session.job"` -c ansible
   ```

   The playbook in question will run to completion with a message indicating success.

   ```text
   All playbooks completed successfully
   ```

### Update test suite packages

(`ncn-m001#`) Update the `csm-testing` and `goss-servers` RPMs on the NCNs.

```bash
pdsh -b -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') 'zypper install -y csm-testing goss-servers craycli'
```

### Verification

1. Verify that the new CSM version is in the product catalog.

   (`ncn-m001#`) Verify that the new CSM version is listed in the output of the following command:

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   ```

   Example output that includes the new CSM version (`1.4.2`):

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
   ```

1. Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   (`ncn-m001#`) Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.4.2".configuration.import_date'
   ```

### Take Etcd manual backup

(`ncn-m001#`) Execute the following script to take a manual backup of the Etcd clusters.

```bash
/usr/share/doc/csm/scripts/operations/etcd/take-etcd-manual-backups.sh post_patch
```

These clusters are automatically backed up every 24 hours, but taking a manual backup
at this stage in the upgrade enables restoring from backup later in this process if needed.

### NCN node reboot

This is an optional step but strongly recommended. As each patch release includes updated container images that may contain CVE fixes, it is recommended to reboot each NCN node to refresh cached container images. For detailed instructions on how to gracefully reboot each NCN node, refer to relevant steps in [Stage 1 - Kubernetes Upgrade](../Stage_1.md).

### Complete upgrade

(`ncn-m001#`) Remember to exit the typescript that was started at the beginning of the upgrade.

```bash
exit
```

It is recommended to save the typescript file for later reference.
