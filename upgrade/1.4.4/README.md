# CSM 1.4.4 Patch Installation Instructions

* [Introduction](#introduction)
* [Bug fixes and improvements](#bug-fixes-and-improvements)
* [Steps](#steps)

## Introduction

This document guides an administrator through the patch update to Cray Systems Management `v1.4.4`
from `v1.4.0`, `v1.4.1`,
`v1.4.2`, or `v1.4.3`. If upgrading from CSM `v1.3.x` directly to `v1.4.4`, follow the procedures described
in [Upgrade CSM](../README.md) instead.

## Bug fixes and improvements

* Security patch `CVE-2023-48795` for SAT
* NCN kernel panic remediation for SuSE networking driver via new kernel
* NCN network connectivity remediation for Marvell/QLogic FastLinQ Ethernet adapters via new QLogic driver
* Blacklisting of QLogic RDMA driver (`qedr`) for increased NCN stability when using Marvell/QLogic FastLinQ Ethernet
  adapters
* Kernel panic remediation for Marvell/QLogic FastLinQ Ethernet adapters
* Broadcom PCIe support for NCNs (`metal-ipxe`)
* `cray-dns-unbound` fix for leaving existing configuration in place if new configuration fails to load
* CPU limit removal for OPA

## Steps

1. [Preparation](#preparation)
1. [Setup Nexus](#setup-nexus)
1. [Update Argo CRDs](#update-argo-crds)
1. [Upgrade services](#upgrade-services)
1. [Upload NCN images](#upload-ncn-images)
1. [Upgrade Ceph and stop local Docker registries](#upgrade-ceph-and-stop-local-docker-registries)
1. [Enable `smartmon` metrics on storage NCNs](#enable-smartmon-metrics-on-storage-ncns)
1. [Update management node CFS configuration](#update-management-node-cfs-configuration)
1. [Update NCN images](#update-ncn-images)
    1. [Warnings](#warnings)
    1. [Image customization](#image-customization)
    1. [WLM backup](#wlm-backup)
1. [Storage nodes in-place update](#storage-nodes-in-place-update)
1. [Kubernetes nodes rolling rebuild](#kubernetes-nodes-rolling-rebuild)
1. [Update test suite packages](#update-test-suite-packages)
1. [Verification](#verification)
1. [Take Etcd manual backup](#take-etcd-manual-backup)
1. [Complete upgrade](#complete-upgrade)

### Preparation

1. (`ncn-m001#`) Start a typescript on `ncn-m001` to capture the commands and output from this procedure.

   ```bash
   script -af csm-update.$(date +%Y-%m-%d).txt
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Download and install/upgrade the **latest** documentation on `ncn-m001`.

   See [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

1. (`ncn-m001#`) Run the script to create a `cephfs` file share at `/etc/cray/upgrade/csm`.

    * This script creates a new `cephfs` file share, and  will unmount the `rbd` device that may have been used in a previous version of CSM (if detected).
      Running this script is a one time step needed only on the master node the upgrade is being initiated on (`ncn-m001`).
      If a previous `rbd` mount is detected at `/etc/cray/upgrade/csm`, that content will be remounted and available at `/mnt/csm-1.3-rbd`.

      ```bash
      /usr/share/doc/csm/scripts/mount-cephfs-share.sh
      ```

1. Download and extract the CSM `v1.4.4` release to `ncn-m001`.

    1. Change into the `cephfs` file share.

       ```bash
       cd /etc/cray/upgrade/csm/
       ```

    1. Follow the directions for [Download and Extract CSM Product Release](../../update_product_stream/README.md#download-and-extract-csm-product-release).

1. (`ncn-m001#`) Set `CSM_DISTDIR` to the directory of the extracted files.

   ***IMPORTANT*** If necessary, change this command to match the actual location of the extracted files.

   > ***NOTE*** `CSM_RELEASE` is set during the [Download and Extract CSM Product Release](../../update_product_stream/README.md#download-and-extract-csm-product-release) guide.

   ```bash
   export CSM_RELEASE_VERSION="$CSM_RELEASE"
   export CSM_DISTDIR="$(pwd)/csm-${CSM_RELEASE}"
   echo "${CSM_DISTDIR}"
   ```

### Setup Nexus

(`ncn-m001#`) Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM repositories, container images, and
Helm charts:

```bash
cd "$CSM_DISTDIR" && ./lib/setup-nexus.sh
echo "RC=$?"
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

### Update Argo CRDs

(`ncn-m001#`) Run the following script in preparation for 1.4.4 patch upgrade:

```bash
function run_cmd {
  "$@" && return 0 || echo "ERROR: Command failed with rc $?: $*" >&2 ; return 1
}

for c in $(kubectl get crd | grep argo | cut -d' ' -f1); do
   run_cmd kubectl label --overwrite crd $c app.kubernetes.io/managed-by="Helm" || break
   run_cmd kubectl annotate --overwrite crd $c meta.helm.sh/release-name="cray-nls" || break
   run_cmd kubectl annotate --overwrite crd $c meta.helm.sh/release-namespace="argo" || break
done
```

### Upgrade services

(`ncn-m001#`) Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
cd "$CSM_DISTDIR" && ./upgrade.sh
```

### Upload NCN images

It is important to upload NCN images to IMS and to edit the `cray-product-catalog`. This is necessary when updating
products with IUF. If this step is skipped, IUF will fail when updating or upgrading products in the future.

(`ncn-m001#`) Execute script to upload CSM NCN images and update the `cray-product-catalog`.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/upload-ncn-images.sh
```

### Upgrade Ceph and stop local Docker registries

**Note:** This step is not necessary if it was already completed by the CSM `v1.3.5` patch, CSM `v1.4.2` patch, or
CSM `V1.4.3` patch. If it was already run, the following steps can be re-executed to verify that Ceph daemons are using
images in Nexus and the local Docker registries have been stopped.

These steps will upgrade Ceph to `v16.2.13`. Then the Ceph monitoring daemons' images will be pushed to Nexus and the
monitoring daemons will be redeployed so that they use these images in Nexus. Once this is complete, all Ceph daemons
should be using images in Nexus and not images hosted in the local Docker registry on storage nodes. The third step
stops the local Docker registry on all storage nodes.

1. (`ncn-m001#`) Run Ceph upgrade to `v16.2.13`.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/ceph/ceph-upgrade-tool.py --version "v16.2.13"
   ```

1. (`ncn-m001#`) Redeploy Ceph monitoring daemons so they are using images in Nexus.

   ```bash
   scp /usr/share/doc/csm/scripts/operations/ceph/redeploy_monitoring_stack_to_nexus.sh ncn-s001:/srv/cray/scripts/common/redeploy_monitoring_stack_to_nexus.sh
   ssh ncn-s001 /srv/cray/scripts/common/redeploy_monitoring_stack_to_nexus.sh
   ```

1. (`ncn-m001#`) Stop the local Docker registries on all storage nodes.

   ```bash
   scp /usr/share/doc/csm/scripts/operations/ceph/disable_local_registry.sh ncn-s001:/srv/cray/scripts/common/disable_local_registry.sh
   ssh ncn-s001 /srv/cray/scripts/common/disable_local_registry.sh
   ```

### Enable `smartmon` metrics on storage NCNs

This step will install the `smart-mon` rpm on storage nodes, and reconfigure the `node-exporter` to provide `smartmon`
metrics.

(`ncn-m001#`) Execute the following script.

 ```bash
 /usr/share/doc/csm/scripts/operations/ceph/enable-smart-mon-storage-nodes.sh
 ```

### Update management node CFS configuration

This step updates the CFS configuration which is set as the desired configuration for the management nodes (NCNs). It
ensures that the CFS configuration layers reference the correct commit hash for the version of CSM being installed. It
then waits for the components to reach a configured state in CFS.

(`ncn-m001#`) Update CFS configuration.

```bash
cd "$CSM_DISTDIR"
./update-mgmt-ncn-cfs-config.sh --base-query role=management \
   --save --create-backups --clear-error
```

The output will look similar to the truncated output shown below.

```text
INFO: Querying CFS configurations for the following NCNs: x3000c0s5b0n0, ...
INFO: Found configuration "management-csm-1.4.0" for component x3000c0s5b0n0
...
INFO: Updating existing layer with repo path /vcs/cray/csm-config-management.git and playbook site.yml
INFO: Property "commit" of layer with repo path /vcs/cray/csm-config-management.git and playbook site.yml updated ...
INFO: Property "name" of layer with repo path /vcs/cray/csm-config-management.git and playbook site.yml updated ...
INFO: No layer with repo path /vcs/cray/csm-config-management.git and playbook ncn-initrd.yml found.
INFO: Adding a layer with repo path /vcs/cray/csm-config-management.git and playbook ncn-initrd.yml to the end.
INFO: Successfully saved CFS configuration "management-csm-1.4.0-backup-20230918T205149"
INFO: Successfully saved CFS configuration "management-csm-1.4.0"
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

When configuration of all components is successful, the summary line will show all components with status "configured".

### Update NCN images

NCN images must be rebuilt at this time in order to acquire an important Kernel panic mitigation. The mitigation entails
a new Kernel and networking drivers for SP4 images \(Kubernetes\), as well as the blacklisting of the QLogic RDMA driver
for SP4 and SP3 (all NCNs).

Despite rebuilding both Kubernetes and Storage CEPH images, **only Kubernetes nodes will embark on a rolling rebuilt**.
Storage CEPH nodes will receive an in-place modification, and do not need to be rebuilt at this time.

#### Warnings

***IMPORTANT*** This minor version bump has an unprecedented rolling rebuild. This is a friendly reminder that any
system administration data living on masters and workers **will be wiped** during the rebuild. Administrators are
advised to take backups of their local, site files.

> Examples:
>
> * `~/.config/sat/sat`
> * `/etc/motd`
> * `/etc/sudoers`
> * `/home`
> * `/root/.ssh/config`

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

    * [Upgrade of CSM on system with additional products](../Stage_0_Prerequisites.md#option-2-upgrade-of-csm-on-system-with-additional-products)
    * [Upgrade of CSM on CSM-only system](./CSM-Only.md#steps) \(***Do not use this procedure if more than CSM is
      installed on the system.***\)

#### WLM backup

> ***NOTE*** For CSM-only systems, skip this step and continue
> onto [Storage nodes in-place update](#storage-nodes-in-place-update)

1. Follow the directions in [Stage 0.4](../Stage_0_Prerequisites.md#stage-04---backup-workload-manager-data).

### Storage nodes in-place update

In lieu of rebuilding the storage nodes, they will be live patched.

1. (`ncn-m001#`) Unload and blacklist the QLogic RDMA `qedr` driver.

   ```bash
   /usr/share/doc/csm/upgrade/1.4.4/scripts/storage-in-place-patch.sh
   ```

1. (`ncn-m001#`) Verify that `qedr` is no longer loaded.

   ```bash
   pdsh -b -w $(grep -oP 'ncn-s\d+' /etc/hosts | sort -u | tr -t '\n' ',') '
   lsmod | grep -Eo '\''^qedr'\'' || echo OK
   ' | dshbak -c
   ```

   Expected output:

   ```text
   ----------------
   ncn-s[001-003]
   ----------------
   OK
   ```

### Kubernetes nodes rolling rebuild

1. (`ncn-m001#`) Set environment variables.

   > ***NOTE*** This relies on variables set during [preparation](#preparation).

   ```bash
   export CSM_REL_NAME="csm-${CSM_RELEASE}"
   export CSM_ARTI_DIR="${CSM_DISTDIR}"
   ```

1. (`ncn-m001#`) Set/update re-usable environment variables.

   ```bash
   sed -i '/^export CSM_ARTI_DIR=.*/d' /etc/cray/upgrade/csm/myenv
   echo "export CSM_ARTI_DIR=$CSM_ARTI_DIR" >>/etc/cray/upgrade/csm/myenv
   ```

1. (`ncn-m001#`) Ensure `cray-site-init` is installed, use the latest one provided by the CSM tarball.

   ```bash
   zypper install -y cray-site-init
   ```

1. Proceed with the following sections from Stage 1:

    * [Stage 1.1 - Master node image upgrade](../Stage_1.md#stage-11---master-node-image-upgrade)
    * [Stage 1.2 - Worker node image upgrade](../Stage_1.md#stage-12---worker-node-image-upgrade)
    * [Stage 1.3 - `ncn-m001` upgrade](../Stage_1.md#stage-13---ncn-m001-upgrade)

1. (`ncn-m001#`) Verify the booted images match the expected output.

   ```bash
   pdsh -b -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | tr -t '\n' ',') '
   rpm -q kernel-default
   rpm -q qlgc-fastlinq-kmp-default
   grep -q qedr /etc/modprobe.d/disabled-modules.conf 2>/dev/null && echo "OK - rootfs blacklist" || echo "NOT OK - rootfs blacklist"
   grep -q qedr /etc/dracut.conf.d/99-csm-ansible.conf 2>/dev/null && echo "OK - initrd blacklist" || echo "NOT OK - initrd blacklist"
   lsmod | grep -qoE '\''^qedr'\'' && echo "NOT OK - qedr loaded" || echo "OK - no qedr"
   lsinitrd /metal/recovery/boot/initrd.img.xz | grep -q '\''qedr'\'' && echo "NOT OK - initrd has qedr" || echo "OK - initrd no qedr"
   ' | dshbak -c
   ```

   Expected output:

   ```text
   ----------------
   ncn-m[001-003],ncn-w[001-005]
   ----------------
   kernel-default-5.14.21-150400.24.100.2.27359.1.PTF.1215587.x86_64
   qlgc-fastlinq-kmp-default-8.74.1.0_k5.14.21_150400.22-1.sles15sp4.x86_64
   OK - rootfs blacklist
   OK - initrd blacklistt
   OK - no qedr
   OK - initrd no qedr
   ----------------
   ncn-s[001-003]
   ----------------
   kernel-default-5.3.18-150300.59.87.1.x86_64
   package qlgc-fastlinq-kmp-default is not installed
   OK - rootfs blacklist
   OK - initrd blacklist
   OK - no qedr
   OK - initrd no qedr
   ```

### Update test suite packages

(`ncn-m001#`) Update select RPMs on the NCNs.

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/util/upgrade-test-rpms.sh
```

### Verification

1. Verify that the new CSM version is in the product catalog.

   (`ncn-m001#`) Verify that the new CSM version is listed in the output of the following command:

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   ```

   Example output that includes the new CSM version (`1.4.4`):

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
   ```

1. Confirm that the product catalog has an accurate timestamp for the CSM upgrade.

   (`ncn-m001#`) Confirm that the `import_date` reflects the timestamp of the upgrade.

   ```bash
   kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"1.4.4".configuration.import_date'
   ```

### Take Etcd manual backup

(`ncn-m001#`) Execute the following script to take a manual backup of the Etcd clusters.

```bash
/usr/share/doc/csm/scripts/operations/etcd/take-etcd-manual-backups.sh post_patch
```

These clusters are automatically backed up every 24 hours, but taking a manual backup at this stage in the upgrade
enables restoring from backup later in this process if needed.

### Complete upgrade

(`ncn-m001#`) Remember to exit the typescript that was started at the beginning of the upgrade.

```bash
exit
```

> ***NOTE*** It is recommended to save the typescript file for later reference.
