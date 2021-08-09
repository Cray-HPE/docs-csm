# CVE-2021-22555 CVE-2021-33909

This procedure covers patching `CVE-2021-22555` and `CVE-2021-33909` on Shasta V1.4.X (and upgrades CSM to v0.9.5).  
These special directions are only for Linux dependencies, such as the kernel and internal packages compiled against the kernel.

A high-level overview of the procedure is as follows:

- install the new kernel directly to NCNs
- delete the existing artifacts from S3
- upload the new artifacts to S3
- reboot NCNs

Procedures:

- [Preparation](#preparation)
- [Run Validation Checks (Pre-Upgrade)](#run-validation-checks-pre-upgrade)
- [Run CVE Patch Script](#run-cve-patch)
- [Reboot NCNs](#reboot-ncns)
- [Validate NCNs Running Patched Kernel](#validate-new-kernel)
- [Upgrade Services](#upgrade-services)
- [Run Validation Checks (Post-Upgrade)](#run-validation-checks-post-upgrade)
- [Verify CSM Version in Product Catalog](#verify-version)
- [Exit Typescript](#exit-typescript)

<a name="preparation"></a>
## Preparation

1. Start a typescript to capture the commands and output from this procedure.
   ```bash
   ncn-m001# script -af csm-update.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

2. Set `CSM_SYSTEM_VERSION` to `0.9.5`:

   ```
   ncn-m001# CSM_SYSTEM_VERSION="0.9.5"
   ```

   > **`NOTE:`** Installed CSM versions may be listed from the product catalog using:
   >
   > ```
   > ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//'
   > ```

3. Set `CSM_DISTDIR` to the directory of the extracted release distribution for CSM 0.9.5:

   > **`NOTE:`** Use `--no-same-owner` and `--no-same-permissions` options to `tar` when extracting a CSM release 
   > distribution as `root` to ensure the current `umask` value.

   If using a release distribution:
   ```
   ncn-m001# tar --no-same-owner --no-same-permissions -zxvf csm-0.9.5.tar.gz
   ncn-m001# CSM_DISTDIR="$(pwd)/csm-0.9.5"
   ```

4. Set `CSM_RELEASE_VERSION` to the version reported by `${CSM_DISTDIR}/lib/version.sh`:

   ```
   ncn-m001# CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   ncn-m001# echo $CSM_RELEASE_VERSION
   ```
   
5. Install/upgrade CSI.

   ```bash
   linux# rpm -Uvh --force ${CSM_DISTDIR}/rpm/cray/csm/sle-15sp2/x86_64/cray-site-init-*.x86_64.rpm
   ```

6. Download and install/upgrade the _latest_ documentation RPM. If this machine does not have direct internet access
   these RPMs will need to be externally downloaded and then copied to be installed.

   ```bash
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/docs-csm-install/docs-csm-install-latest.noarch.rpm
   ```
   
7. Set `CSM_SCRIPTDIR` to the scripts directory included in the docs-csm RPM for the CSM 0.9.5 patch:

   ```bash
   ncn-m001# CSM_SCRIPTDIR=/usr/share/doc/metal/upgrade/0.9/csm-0.9.5/scripts
   ```

<a name="run-validation-checks-pre-upgrade"></a>
## Run Validation Checks (Pre-Upgrade)

It is important to first verify a healthy starting state. To do this, run the
[CSM validation checks](../../../008-CSM-VALIDATION.md). If any problems are
found, correct them and verify the appropriate validation checks before
proceeding.

<a name="run-cve-patch"></a>
## Run CVE Patch Script

8. Run the `run-patch.sh` script. This does a few things: 
   1. Updates all the NCNs via `zypper` to have the latest patched packages.
   2. Patches the kernel/initrd/squash image to have the correctly patched assets.
   3. Applies a pod priority to essential deployments to ensure that they are scheduled when rebooting the NCNs.
   
      **This step assumes the latest SUSE updates tarball has been extracted and installed (i.e., synced with Nexus).**
    
       ```
       ncn-m001# "${CSM_SCRIPTDIR}/run-patch.sh"
       ```
    
       > **DO NOT REBOOT**
       > 
       > The system (`zypper`) may indicate a reboot is needed at several points during the script run but this will 
       > happen in a later step so do not reboot the NCNs yet.


<a name="reboot-ncns"></a>
## Reboot NCNs

Reference the [Reboot NCNs procedure](operations/node_management/Reboot_NCNs.md).

Optionally, use cray-conman to observe the node as it boots:

```bash
ncn-m001# kubectl exec -it -n services cray-conman-<hash> cray-conman -- /bin/bash
cray-conman# conman -q
cray-conman# conman -j <name of terminal>
```


<a name="validate-new-kernel"></a>
## Validate NCNs Running Patched Kernel

Once a system has booted, verify the new kernel is running.  This should match `5.3.18-24.75`, which is the version 
of the kernel that addresses the CVE.

```bash
uname -a
```


<a name="upgrade-services"></a>
## Upgrade Services

1. Run `upgrade.sh` to deploy upgraded CSM applications and services:

   ```bash
   ncn-m001# cd "$CSM_DISTDIR"
   ncn-m001# ./upgrade.sh


<a name="run-validation-checks-post-upgrade"></a>
## Run Validation Checks (Post-Upgrade)

> **`IMPORTANT:`** Wait at least 15 minutes after
> [`upgrade.sh`](#upgrade-services) completes to let the various Kubernetes
> resources get initialized and started.

Run the following validation checks to ensure that everything is still working
properly after the upgrade:

1. [Platform health checks](../../../008-CSM-VALIDATION.md#platform-health-checks)
2. [Network health checks](../../../008-CSM-VALIDATION.md#network-health-checks)

Other health checks may be run as desired.


<a name="verify-version"></a>
## Verify CSM Version in Product Catalog

1. Verify the CSM version has been updated in the product catalog. Verify that the
   following command includes version `0.9.5`:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key'
   0.9.5
   0.9.4
   0.9.3
   ```

2. Confirm the `import_date` reflects the timestamp of the upgrade:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"0.9.4".configuration.import_date'
   ```


<a name="exit-typescript"></a>
## Exit Typescript

Remember to exit your typescript.

```bash
ncn-m001# exit
```

It is recommended to save the typescript file for later reference.