Copyright 2021 Hewlett Packard Enterprise Development LP


# CSM 0.9.4 Patch Upgrade Guide

This guide contains procedures for upgrading systems running CSM 0.9.3 to CSM
0.9.4. It is intended for system installers, system administrators, and network
administrators. It assumes some familiarity with standard Linux and associated
tooling.

Procedures:

- [Preparation](#preparation)
- [Run Validation Checks (Pre-Upgrade)](#run-validation-checks-pre-upgrade)
- [Update /etc/hosts on Workers](#update-hosts-on-workers)
- [Setup Nexus](#setup-nexus)
- [Backup VCS Content](#backup-vcs-content)
- [Upgrade Services](#upgrade-services)
- [Clean Up CFS Sessions](#clean-up-cfs-sessions)
- [Update NTP and DNS Servers on BMCs](#update-ntp-dns-on-bmcs)
- [Fix Kubelet and Kube-Proxy Target Down Prometheus Alerts](#fix-kubelet-and-kube-proxy-target-down-prometheus-alerts)
- [Install Prometheus Node-Exporter on Utility Storage Nodes](#install-prometheus-node-exporter-on-utility-storage-nodes)
- [Restore VCS Content](#restore-vcs-content)
- [Disable TPM Kernel Module](#disable-tpm-kernel-module)
- [Run Validation Checks (Post-Upgrade)](#run-validation-checks-post-upgrade)
- [Verify CSM Version in Product Catalog](#verify-version)
- [Exit Typescript](#exit-typescript)


<a name="changes"></a>
## Changes

See CHANGELOG.md in the root of a CSM release distribution for a summary of
changes in each CSM release. This patch includes the following changes:

- CFS sessions stuck with no job. A race condition sometimes caused CFS
  sessions to never start a job, which could in turn block other sessions
  targeting the same nodes from starting. The fix is an updated cfs-operator
  image which will retry when this race condition is hit.
- Configure NTP and DNS for HPE NCN BMCs.
- Unbound no longer forwards requests to Shasta zones to site DNS.
- Add static entries for `registry.local` and `packages.local` to the
  `/etc/hosts` files on the worker nodes.
- Update Kea externTrafficPolicy from `Cluster` to `Local`.
- Prometheus can now to scrape kubelet/kube-proxy for metrics.
- Install node-exporter on storage nodes.
- BOS will now leave any nodes that it cannot communicate with behind. These
  nodes will not prolong a BOS session. A message describing how to relaunch
  BOS to pick up any failing nodes is output in the log for the BOA pod
  corresponding to the BOS session.
- Updates the VCS PVC name so that it can be found on system restart.


<a name="preparation"></a>
## Preparation

For convenience, these procedures make use of environment variables. This
section sets the expected environment variables to appropriate values.

1. Start a typescript to capture the commands and output from this procedure.
   ```bash
   ncn-m001# script -af csm-update.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Set `CSM_SYSTEM_VERSION` to `0.9.3`:

   ```bash
   ncn-m001# CSM_SYSTEM_VERSION="0.9.3"
   ```

   > **`NOTE:`** Installed CSM versions may be listed from the product catalog using:
   >
   > ```bash
   > ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//'
   > ```

1. Set `CSM_DISTDIR` to the directory of the extracted release distribution for
   CSM 0.9.4:

   > **`NOTE:`** Use `--no-same-owner` and `--no-same-permissions` options to
   > `tar` when extracting a CSM release distribution as `root` to ensure the
   > extracted files are owned by `root` and have permissions based on the current
   > `umask` value.

   If using a release distribution:
   ```bash
   ncn-m001# tar --no-same-owner --no-same-permissions -zxvf csm-0.9.4.tar.gz
   ncn-m001# CSM_DISTDIR="$(pwd)/csm-0.9.4"
   ```
   Else if using a hotfix distribution:
   ```bash
   ncn-m001# CSM_HOTFIX="csm-0.9.4-hotfix-0.0.1"
   ncn-m001# tar --no-same-owner --no-same-permissions -zxvf ${CSM_HOTFIX}.tar.gz
   ncn-m001# CSM_DISTDIR="$(pwd)/${CSM_HOTFIX}"
   ncn-m001# echo $CSM_DISTDIR
   ```

1. Set `CSM_RELEASE_VERSION` to the version reported by
   `${CSM_DISTDIR}/lib/version.sh`:

   ```bash
   ncn-m001# CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   ncn-m001# echo $CSM_RELEASE_VERSION
   ```

1. **NEEDS REVIEW** Download and install/upgrade the _latest_ workaround and
   documentation RPMs. If this machine does not have direct internet access
   these RPMs will need to be externally downloaded and then copied to be
   installed.

   ```bash
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/docs-csm-install/docs-csm-install-latest.noarch.rpm
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   ```

1. Set `CSM_SCRIPTDIR` to the scripts directory included in the docs-csm RPM
   for the CSM 0.9.4 upgrade:

   ```bash
   ncn-m001# CSM_SCRIPTDIR=/usr/share/doc/metal/upgrade/0.9/csm-0.9.4/scripts
   ```

<a name="run-validation-checks-pre-upgrade"></a>
## Run Validation Checks (Pre-Upgrade)

It is important to first verify a healthy starting state. To do this, run the
[CSM validation checks](../../../008-CSM-VALIDATION.md). If any problems are
found, correct them and verify the appropriate validation checks before
proceeding.


<a name="update-hosts-on-workers"></a>
## Update /etc/hosts on Workers

Run the `update-host-records.sh` script to update /etc/hosts on NCN workers:

```bash
ncn-m001# "${CSM_SCRIPTDIR}/update-host-records.sh"
```

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


<a name="backup-vcs-content"></a>
## Backup VCS Content

1. Run the `vcs-backup.sh` script to backup all VCS content to a temporary
   location.

   ```bash
   ncn-m001# "${CSM_SCRIPTDIR}/vcs-backup.sh"
   ```

1. Confirm the local tar file `vcs.tar` was created. It contains the Git
   repository data. Once [`upgrade.sh`](#upgrade-services) is run, the git data
   will not be recoverable if this step failed.

1. If `vcs.tar` was successfully created, run `vcs-prep.sh`.  This will force
   the PVC into the correct state for the upgrade if necessary.

   ```bash
   ncn-m001# "${CSM_SCRIPTDIR}/vcs-prep.sh"
   ```

1. It is also recommended to save the VCS password to a safe location prior to
   making changes to VCS. The current password can can be retrieved with:

   ```bash
   ncn-m001# kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode; echo
   ```


<a name="upgrade-services"></a>
## Upgrade Services

1. Run `upgrade.sh` to deploy upgraded CSM applications and services:

   ```bash
   ncn-m001# ./upgrade.sh
   ```

**Note**: If you have not already installed the workload manager product
including slurm and munge, then the `cray-crus` pod is expected to be in the
`Init` state. After running `upgrade.sh`, you may observe there are now *two*
copies of the `cray-crus` pod in the `Init` state. This situation is benign and
should resolve itself once the workload manager product is installed.


<a name="clean-up-cfs-sessions"></a>
## Clean Up CFS Sessions

> **`NOTE:`** This fix only applies to new sessions and will not correct
> sessions that are already in the stuck state.

1. Delete all sessions that are in stuck:

   ```bash
   ncn-m001# cray cfs sessions list --format json | jq -r '.[] | select(.status.session.startTime==null) | .name' | while read name ; do cray cfs sessions delete $name; done
   ```


<a name="update-ntp-dns-on-bmcs"></a>
## Update NTP and DNS servers on BMCs

1. Deploy the `set-bmc-ntp-dns.sh` script (and its helper script `make_api_call.py`) to each NCN:

   ```bash
   ncn-m001# for h in $( grep ncn /etc/hosts | grep nmn | awk '{print $2}' ); do
      ssh $h "mkdir -p /opt/cray/ncn"
      scp "${CSM_SCRIPTDIR}/make_api_call.py" "${CSM_SCRIPTDIR}/set-bmc-ntp-dns.sh" root@$h:/opt/cray/ncn/
      ssh $h "chmod 755 /opt/cray/ncn/set-bmc-ntp-dns.sh"
   done
   ```

1. Run the `/opt/cray/ncn/set-bmc-ntp-dns.sh` script on each NCN.

   > **`NOTE:`** For Gigabyte or Intel NCNs this **step can be skipped**.

   > Pass `-h` to see some examples and use the information below to run the
   > script.

   > The following process can restoring NTP and DNS server values after a
   > firmware is update to HPE NCNs. If you update the System ROM of a NCN, you
   > will lose NTP and DNS server values. Correctly setting these also allows
   > FAS to function properly.

   1. Determine HMN IP address for m001:
      ```bash
      ncn# M001_HMN_IP=$(cat /etc/hosts | grep m001.hmn | awk '{print $1}')
      ncn# echo $M001_HMN_IP
      10.254.1.4
      ```
   2. Specify the name and credentials for the BMC:
      ```bash
      ncn# BMC=ncn-<NCN name>-mgmt # e.g. ncn-w003-mgmt
      ncn# export USERNAME=root 
      ncn# export IPMI_PASSWORD=changeme
      ````
   3. View the existing DNS and NTP settings on the BMC:
      ```bash
      ncn# /opt/cray/ncn/set-bmc-ntp-dns.sh ilo -H $BMC -s
      ```
   4. Set the NTP servers to point toward time-hmn and ncn-m001. 
      ```bash
      ncn# /opt/cray/ncn/set-bmc-ntp-dns.sh ilo -H $BMC -N "time-hmn,$M001_HMN_IP" -n
      ```
   5. Set the DNS server to point toward Unbound and ncn-m001.
      ```bash
      ncn# /opt/cray/ncn/set-bmc-ntp-dns.sh ilo -H $BMC -D "10.94.100.225,$M001_HMN_IP" -d
      ```


<a name="fix-kubelet-and-kube-proxy-target-down-prometheus-alerts"></a>
## Fix Kubelet and Kube-Proxy Target Down Prometheus Alerts

> **NOTE**: These scripts should be run from a Kubernetes NCN (manager or
> worker).  Also note it can take several minutes for the target down alerts to
> clear after the scripts have been executed.

1. Run the `fix-kube-proxy-target-down-alert.sh` script to fix the kube-proxy
   alert.

   ```bash
   ncn-m001# "${CSM_SCRIPTDIR}/fix-kube-proxy-target-down-alert.sh"
   ```

1. Run the `fix-kubelet-target-down-alert.sh` script to fix the kube-proxy
   alert.

   ```bash
   ncn-m001# "${CSM_SCRIPTDIR}/fix-kubelet-target-down-alert.sh"
   ```


<a name="install-prometheus-node-exporter-on-utility-storage-nodes"></a>
## Install Prometheus Node-Exporter on Utility Storage Nodes

1. Copy the `install-node-exporter-storage.sh` script out to the storage nodes.

   ```bash
   ncn-m001# for h in $( cat /etc/hosts | grep ncn-s | grep nmn | awk '{print $2}' ); do
     scp "${CSM_SCRIPTDIR}/install-node-exporter-storage.sh" root@$h:/tmp
   done
   ```

1. Run the `install-node-exporter-storage.sh` script on **each** of the storage
   nodes to enable the node-exporter:

   > **NOTE**: This script should be run on each storage node.

   ```bash
   ncn-s# /tmp/install-node-exporter-storage.sh
   ```


<a name="restore-vcs-content"></a>
## Restore VCS Content

1. Run the `vcs-restore.sh` script to restore all VCS content.

   ```bash
   ncn-m001# "${CSM_SCRIPTDIR}/vcs-restore.sh"
   ```


<a name="disable-tpm-kernel-module"></a>
## Disable TPM Kernel Module

1. Disable the TPM kernel module from being loaded by the GRUB bootloader.

   ```bash
   ncn-m001# "${CSM_SCRIPTDIR}/tpm-fix-install.sh"
   ```


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

> **`CAUTION:`** The following HMS functional tests may fail due to locked
> components in HSM:
>
> 1. `test_bss_bootscript_ncn-functional_remote-functional.tavern.yaml`
> 2. `test_smd_components_ncn-functional_remote-functional.tavern.yaml`
>
> ```bash
>         Traceback (most recent call last):
>           File "/usr/lib/python3.8/site-packages/tavern/schemas/files.py", line 106, in verify_generic
>             verifier.validate()
>           File "/usr/lib/python3.8/site-packages/pykwalify/core.py", line 166, in validate
>             raise SchemaError(u"Schema validation failed:\n - {error_msg}.".format(
>         pykwalify.errors.SchemaError: <SchemaError: error code 2: Schema validation failed:
>          - Key 'Locked' was not defined. Path: '/Components/0'.
>          - Key 'Locked' was not defined. Path: '/Components/5'.
>          - Key 'Locked' was not defined. Path: '/Components/6'.
>          - Key 'Locked' was not defined. Path: '/Components/7'.
>          - Key 'Locked' was not defined. Path: '/Components/8'.
>          - Key 'Locked' was not defined. Path: '/Components/9'.
>          - Key 'Locked' was not defined. Path: '/Components/10'.
>          - Key 'Locked' was not defined. Path: '/Components/11'.
>          - Key 'Locked' was not defined. Path: '/Components/12'.: Path: '/'>
> ```
>
> Failures of these tests due to locked components as shown above can be safely
> ignored.


<a name="verify-version"></a>
## Verify CSM Version in Product Catalog

1. Verify the CSM version has been updated in the product catalog. Verify that the
   following command includes version `0.9.4`:

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key'
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
