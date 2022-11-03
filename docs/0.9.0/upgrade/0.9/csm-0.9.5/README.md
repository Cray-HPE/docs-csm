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
- [Remove zypper RIS services repositories](rm-zypper-services)
- [Run CVE Patch Script](#run-cve-patch)
- [Reboot NCNs](#reboot-ncns)
- [Validate NCNs Running Patched Kernel](#validate-new-kernel)
- [Upgrade Services](#upgrade-services)
- [Run Validation Checks (Post-Upgrade)](#run-validation-checks-post-upgrade)
- [Verify CSM Version in Product Catalog](#verify-version)
- [Update UAS/UAI](#update-uas-uai)
- [Exit Typescript](#exit-typescript)

<a name="preparation"></a>
## Preparation

1. Start a typescript to capture the commands and output from this procedure.
   ```bash
   ncn-m001# script -af csm-update.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

   > **`NOTE:`** Installed CSM versions may be listed from the product catalog using:
   >
   > ```
   > ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   > 0.9.2
   > 0.9.3
   > 0.9.4
   > ```

3. Set `CSM_DISTDIR` to the directory of the extracted release distribution for CSM 0.9.5:

   > **`NOTE:`** Use `--no-same-owner` and `--no-same-permissions` options to `tar` when extracting a CSM release
   > distribution as `root` to ensure the current `umask` value.

   If using a release distribution:
   ```
   ncn-m001# tar --no-same-owner --no-same-permissions -zxvf csm-0.9.5.tar.gz
   ncn-m001# export CSM_DISTDIR="$(pwd)/csm-0.9.5"
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
   > When installing or upgrading CSI the following error may appear, it can be safely
   > ignored.
   > ```
   > rm: cannot remove ‘/usr/bin/sic’: No such file or directory
   > ```

6. Download and install/upgrade the _latest_ documentation RPM. If this machine does not have direct internet access
   these RPMs will need to be externally downloaded and then copied to be installed.

   ```bash
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/docs-csm/docs-csm-latest.noarch.rpm
   ```

7. Set `CSM_SCRIPTDIR` to the scripts directory included in the docs-csm RPM for the CSM 0.9.5 patch:

   ```bash
   ncn-m001# export CSM_SCRIPTDIR=/usr/share/doc/metal/upgrade/0.9/csm-0.9.5/scripts
   ```

<a name="run-validation-checks-pre-upgrade"></a>
## Run Validation Checks (Pre-Upgrade)

It is important to first verify a healthy starting state. To do this, run the
[CSM validation checks](../../../008-CSM-VALIDATION.md). If any problems are
found, correct them and verify the appropriate validation checks before
proceeding.

<a name="rm-zypper-services"></a>
## Remove zypper RIS services repositories
Run `lib/remove-service-repos.sh` to remove repositories that are external to the system.

```bash
ncn-m001# ${CSM_SCRIPTDIR}/remove-service-repos.sh
```

<a name="run-cve-patch"></a>
## Run CVE Patch Script

The `run-patch.sh` script expects that the `TOKEN` environment variable is set. Either set this to a valid token of
your choosing or get a new one using the following:

```bash
ncn-m001# export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
  -d client_id=admin-client \
  -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

The script also expects that the Cray CLI is configured and authenticated.
Please see [Initialize cray CLI](../../../006-CSM-PLATFORM-INSTALL.md#initialize-cray-cli) for more information on
how to do this.

Run the `run-patch.sh` script. This does a few things:
   1. Updates all the NCNs via `zypper` to have the latest patched packages.
   2. Patches the kernel/initrd/squash image to have the correctly patched assets.
   3. Applies a pod priority to essential deployments to ensure that they are scheduled when rebooting the NCNs.

      **This step requires the latest SUSE updates tarball has been extracted and installed (i.e., synced with Nexus).**

      **Please see section, "Install SLE for V1.4.2A-security0821 Patch" in the main patch README if you have not already.**

       ```
       ncn-m001# "${CSM_SCRIPTDIR}/run-patch.sh"
       ```

       > **DO NOT REBOOT**
       >
       > The `zypper` commands issued by the `run-patch.sh` script may indicate a reboot is needed at several points during the
       > script run but this will happen in a later step so do not reboot the NCNs yet.


<a name="reboot-ncns"></a>
## Reboot NCNs

Reference the [Reboot NCNs procedure](operations/node_management/Reboot_NCNs.md).

<a name="validate-new-kernel"></a>
## Validate NCNs Running Patched Kernel

1. Start a typescript to capture the commands and output from this procedure.
   ```bash
   ncn-m001# script -af csm-update-post-reboot.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

2. Setup `CSM_DISTDIR` to point toward the location where the extracted csm-0.9.5 tarball.
   > If the tarball was not extracted to `~/csm-0.9.5`, then provide the alternative path instead.
   ```bash
   ncn-m001# CSM_DISTDIR=~/csm-0.9.5
   ```

3. Once a system has booted, verify the new kernel is running on each NCN. This should match `5.3.18-24.75-default`, which is the version
of the kernel that addresses the CVE.

   ```bash
   ncn-m001# cd "$CSM_DISTDIR"
   ncn-m001# pdsh -w $(./lib/list-ncns.sh| paste -sd,) "uname -r"
   + Getting admin-client-auth secret
   + Obtaining access token
   + Querying SLS
   ncn-s003: 5.3.18-24.75-default
   ncn-s002: 5.3.18-24.75-default
   ncn-s001: 5.3.18-24.75-default
   ncn-m001: 5.3.18-24.75-default
   ncn-m002: 5.3.18-24.75-default
   ncn-m003: 5.3.18-24.75-default
   ncn-w003: 5.3.18-24.75-default
   ncn-w001: 5.3.18-24.75-default
   ncn-w002: 5.3.18-24.75-default
   ```
   > Alternatively, login to each NCN and run the following command to get get currently running kernel version.
   > ```bash
   > ncn# uname -r
   > ```

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
ncn-m001# ./lib/setup-nexus.sh
...
+ Nexus setup complete
setup-nexus.sh: OK
ncn-m001# echo $?
0
```

In the event of an error, consult the [known
issues](../../../006-CSM-PLATFORM-INSTALL.md#known-issues) from the install
documentation to resolve potential problems and then try running
`setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is ok as long as
`setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits with status code `0`.

<a name="upgrade-services"></a>
## Upgrade Services

1. Run `upgrade.sh` to deploy upgraded CSM applications and services:

   ```bash
   ncn-m001# cd "$CSM_DISTDIR"
   ncn-m001# ./upgrade.sh
   ```

<a name="update-uas-uai"></a>
## Update UAS / UAI

This update includes a new basic UAI image and a new Broker UAI image. The HPE supplied basic UAI image, `cray-uai-sles15sp1:latest` simply needs to be updated by pulling it to the NCN worker nodes and restarting the UAI Kubernetes pods that are using it. The following commands ensure that the updated images are used for non-Broker and Broker UAIs:
```
ncn-m001:~ # pdsh -w ncn-w[000-999] crictl pull dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest 2>&1 | grep -v -e "Could not resolve hostname" -e "ssh exited with exit code 255"
ncn-m001:~ # pdsh -w ncn-w[000-999] crictl pull dtr.dev.cray.com/cray/cray-uai-broker:latest 2>&1 | grep -v -e "Could not resolve hostname" -e "ssh exited with exit code 255"
```
If you have any UAIs running, you will want to cause them to restart with the new images. If you get a non-empty list back from:
```
cray uas admin uais list
```
Then you have UAIs. If you are using Broker UAIs, there will be a mix of Broker and Non-Broker UAIs in the list. If not, you will only have non-Broker UAIs.

The following steps will interrupt any users who are working on UAIs (either through a broker or in legacy mode). To minimize surprise, make sure users are notified that you will be restarting UAIs before proceeding.

To refresh non-Broker UAIs (if you have them):
```
ncn-m001:~ # kubectl delete po -n user $(kubectl get po -n user | grep "^uai-" | awk '{ print $1 }')
```
To refresh Broker UAIs (if you have them):
```
ncn-m001:~ # kubectl delete po -n uas $(kubectl get po -n uas | grep "^uai-" | awk '{ print $1 }')
```

Finally, this update provides new Compute Node images. If your site uses UAI images built from the Compute Node Image, you will need to [build new images and register the new images with UAS](../../../500-UAS-UAI-ADMIN-AND-USER-GUIDE.md#main-uaiimages-customenduser), then delete and recreate your running UAIs (if any).

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
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   0.9.2
   0.9.3
   0.9.4
   0.9.5
   ```

2. Confirm the `import_date` reflects the timestamp of the upgrade:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r  - '"0.9.5".configuration.import_date'
   ```

<a name="exit-typescript"></a>
## Exit Typescript

Remember to exit your typescript.

```bash
ncn-m001# exit
```

It is recommended to save the typescript file for later reference.
