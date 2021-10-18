Copyright 2021 Hewlett Packard Enterprise Development LP


# CSM 0.9.3 Patch Upgrade Guide

This guide contains procedures for upgrading systems running CSM 0.9.2 to CSM
0.9.3. It is intended for system installers, system administrators, and network
administrators. It assumes some familiarity with standard Linux and associated
tooling.

See CHANGELOG.md in the root of a CSM release distribution for a summary of
changes in each CSM release.

Procedures:

- [Preparation](#preparation)
- [Run Validation Checks (Pre-Upgrade)](#run-validation-checks-pre-upgrade)
- [Setup Nexus](#setup-nexus)
- [Update Resources](#update-resources)
- [Increase Max pty on Workers](#increase-pty-max)
- [Deploy Manifests](#deploy-manifests)
- [Upgrade NCN Packages](#upgrade-ncn-packages)
- [Enable PodSecurityPolicy](#enable-psp)
- [Apply iSCSI Security Fix](#iscsi-security-fix)
- [Configure LAG for CMMs](#configure-lag-for-cmms)
- [Run Validation Checks (Post-Upgrade)](#run-validation-checks-post-upgrade)
- [Exit Typescript](#exit-typescript)

<a name="preparation"></a>
## Preparation

For convenience, these procedures make use of environment variables. This
section sets the expected environment variables to the appropriate values.

1. Start a typescript to capture the commands and output from this procedure.
   ```bash
   ncn-m001# script -af csm-update.$(date +%Y-%m-%d).txt
   ncn-m001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   ```

1. Set `CSM_DISTDIR` to the directory of the extracted release distribution for
   CSM 0.9.3:

   > **`NOTE:`** Use `--no-same-owner` and `--no-same-permissions` options to
   > `tar` when extracting a CSM release distribution as `root` to ensure the
   > extracted files are owned by `root` and have permissions based on the current
   > `umask` value.

   ```bash
   ncn-m001# tar --no-same-owner --no-same-permissions -zxvf csm-0.9.3.tar.gz
   ncn-m001# CSM_DISTDIR="$(pwd)/csm-0.9.3"
   ```

1. Download and install/upgrade the workaround and documentation RPMs. If this machine does not have direct internet
   access these RPMs will need to be externally downloaded and then copied to be installed.
   ```bash
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/docs-csm/docs-csm-latest.noarch.rpm
   ncn-m001# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.4/csm-install-workarounds/csm-install-workarounds-latest.noarch.rpm
   ```

1. Set `CSM_RELEASE_VERSION` to the version reported by
   `${CSM_DISTDIR}/lib/version.sh`:

   ```bash
   ncn-m001# CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   ```

1. Set `CSM_SYSTEM_VERSION` to `0.9.2`:

   ```bash
   ncn-m001# CSM_SYSTEM_VERSION="0.9.2"
   ```

   > **`NOTE:`** Installed CSM versions may be listed from the product catalog using:
   >
   > ```bash
   > ncn-m001# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'keys[]' | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//'
   > ```


<a name="run-validation-checks-pre-upgrade"></a>
## Run Validation Checks (Pre-Upgrade)

It is important to first verify a healthy starting state. To do this, run the
[CSM validation checks](../../008-CSM-VALIDATION.md). If any problems are
found, correct them and verify the appropriate validation checks before
proceeding.


<a name="setup-nexus"></a>
## Setup Nexus

Run `lib/setup-nexus.sh` to configure Nexus and upload new CSM RPM
repositories, container images, and Helm charts:

```bash
ncn-m001# cd "$CSM_DISTDIR"
ncn-m001# ./lib/setup-nexus.sh
```

On success, `setup-nexus.sh` will output to `OK` on stderr and exit with status
code `0`, e.g.:

```bash
ncn-m001# ./lib/setup-nexus.sh
...
+ Nexus setup complete
setup-nexus.sh: OK
```

In the event of an error, consult the [known
issues](../../006-CSM-PLATFORM-INSTALL.md#known-issues) from the install
documentation to resolve potential problems and then try running
`setup-nexus.sh` again. Note that subsequent runs of `setup-nexus.sh` may
report `FAIL` when uploading duplicate assets. This is ok as long as
`setup-nexus.sh` outputs `setup-nexus.sh: OK` and exits with status code `0`.


<a name="update-resources"></a>
## Update Resources
Update the `coredns` and `kube-multus` resources.

1. Run `lib/0.9.3/coredns-bump-resources.sh`
    ```bash
    ncn-m001# ./lib/0.9.3/coredns-bump-resources.sh
    ```
    
    Expected output looks similar to:
    ```
    Applying new resource limits to coredns pods
    Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
    deployment.apps/coredns configured
    ```

1. Verify that the pods restart with status `Running`:
    ```bash
    ncn-m001# watch "kubectl get pods -n kube-system -l k8s-app=kube-dns"
    ```

1. Run `lib/0.9.3/multus-bump-resources.sh`
    ```bash
    ncn-m001# ./lib/0.9.3/multus-bump-resources.sh
    ```
    
    Expected output looks similar to:
    ```
    Applying new resource limits to kube-multus pods
    daemonset.apps/kube-multus-ds-amd64 configured
    ```

1. Verify that the pods restart with status `Running`:
    ```bash
    ncn-m001# watch "kubectl get pods -n kube-system -l app=multus"
    ```

On success, the `coredns` and `kube-multus` pods should restart with a status of `Running`.
If any `kube-multus` pods remain in `Terminating` status, force delete them so that the
daemonset can restart them successfully.
```bash
ncn-m001# kubectl delete pod <pod-name> -n kube-system --force
```

<a name="increase-pty-max"></a>
## Increase Max pty on Workers
```bash
ncn-m001# pdsh -w $(./lib/list-ncns.sh | grep ncn-w | paste -sd,) "echo kernel.pty.max=8196 > /etc/sysctl.d/991-maxpty.conf && sysctl -p /etc/sysctl.d/991-maxpty.conf"
```

<a name="deploy-manifests"></a>
## Deploy Manifests

1. Before deploying the manifests, the `cray-product-catalog` role in Kubernetes needs to be updated.
    
    a. Display the role before changing it:
        
        ```bash
        ncn-m001# kubectl get role -n services cray-product-catalog -o json| jq '.rules[0]'
        ```
    
        Expected output looks like:
        ```
        {
          "apiGroups": [
            ""
          ],
          "resources": [
            "configmaps"
          ],
          "verbs": [
            "get",
            "list",
            "update",
            "patch"
          ]
        }
        ```
    
    b. Patch the role:
        
        ```bash
        ncn-m001# kubectl patch role -n services cray-product-catalog --patch \
                    '{"rules": [{"apiGroups": [""],"resources": ["configmaps"],"verbs": ["create","get","list","update","patch","delete"]}]}'
        ```
        
        On success, expected output looks like:
        ```
        role.rbac.authorization.k8s.io/cray-product-catalog patched
        ```
        
    c. Display the role after the patch:
        
        ```bash
        ncn-m001# kubectl get role -n services cray-product-catalog -o json| jq '.rules[0]'
        ```
        
        Expected output looks like:
        ```
        {
          "apiGroups": [
            ""
          ],
          "resources": [
            "configmaps"
          ],
          "verbs": [
            "create",
            "get",
            "list",
            "update",
            "patch",
            "delete"
          ]
        }
        ```

1. Add a ClusterRoleBinding for cray-unbound-coredns PodSecurityPolicies

	a. create `cray-unbound-coredns-psp.yaml` with the following contents

       ```
       ---
       apiVersion: rbac.authorization.k8s.io/v1
       kind: ClusterRoleBinding
       metadata:
         name: cray-unbound-coredns-psp
       roleRef:
         apiGroup: rbac.authorization.k8s.io
         kind: ClusterRole
         name: restricted-transition-net-raw-psp
       subjects:
         - kind: ServiceAccount
           name: cray-dns-unbound-manager
           namespace: services
         - kind: ServiceAccount
           name: cray-dns-unbound-coredns
           namespace: services
        ```

	b. run kubectl apply -f on cray-unbound-coredns-psp.yaml

       ```bash
       ncn-m001# kubectl apply -f cray-unbound-coredns-psp.yaml
       ```

1. Add a ClusterRoleBinding to update the PodSecurityPolicies used by the cray-hms-rts-init job.

    1. Create `cray-hms-rts-init-psp.yaml` with the following contents:
        ```yaml
        ---
        apiVersion: rbac.authorization.k8s.io/v1
        kind: ClusterRoleBinding
        metadata:
          name: cray-rts-vault-watcher-psp
        roleRef:
          apiGroup: rbac.authorization.k8s.io
          kind: ClusterRole
          name: restricted-transition-net-raw-psp
        subjects:
        - kind: ServiceAccount
          name: cray-rts-vault-watcher
          namespace: services
        ```

    2. Run kubectl apply -f on cray-hms-rts-init-psp.yaml:
        ```bash
        ncn-m001# kubectl apply -f cray-hms-rts-init-psp.yaml
        ```

1. Run `kubectl delete -n spire job spire-update-bss` to allow the spire chart to be updated properly:

	```bash
	ncn-m001# kubectl delete -n spire job spire-update-bss
	```

1. Run `upgrade.sh` to deploy upgraded CSM applications and services:
    ```bash
    ncn-m001# ./upgrade.sh
    ```

**Note**: If you have not already installed the workload manager product including slurm and munge, then the `cray-crus` pod is
expected to be in the `Init` state. After running `upgrade.sh`, you may observe there are now *two* copies of the `cray-crus` pod in
the `Init` state. This situation is benign and should resolve itself once the workload manager product is installed.

<a name="upgrade-ncn-packages"></a>
## Upgrade NCN Packages

Upgrade CSM packages on NCNs.

1. Get the list of NCNs:

   ```bash
   ncn-m001# ncns="$(./lib/list-ncns.sh | paste -sd,)"
   ```

1. Use `zypper ms -d` to **disable** the following zypper RIS services that
   configure repositories external to the system:

   - `Basesystem_Module_15_SP2_x86_64`
   - `Public_Cloud_Module_15_SP2_x86_64`
   - `SUSE_Linux_Enterprise_Server_15_SP2_x86_64`
   - `Server_Applications_Module_15_SP2_x86_64`

   ```bash
   ncn-m001# pdsh -w "$ncns" 'zypper ms -d Basesystem_Module_15_SP2_x86_64'
   ncn-m001# pdsh -w "$ncns" 'zypper ms -d Public_Cloud_Module_15_SP2_x86_64'
   ncn-m001# pdsh -w "$ncns" 'zypper ms -d SUSE_Linux_Enterprise_Server_15_SP2_x86_64'
   ncn-m001# pdsh -w "$ncns" 'zypper ms -d Server_Applications_Module_15_SP2_x86_64'
   ```

   > **`NOTE`**: Field notice _FN #6615a - Shasta V1.4 and V1.4.1 Install Issue
   > with NCN Personalization for SMA_ included similar guidance as below. If
   > these zypper services have been previously disabled, verify that they are
   > in fact disabled:
   >
   > ```bash
   > ncn-m001# pdsh -w "$ncns" 'zypper ls -u'
   > ```

1. Ensure the `csm-sle-15sp2` repository is configured on every NCN:

   ```bash
   ncn-m001# pdsh -w "$ncns" 'zypper ar -fG https://packages.local/repository/csm-sle-15sp2/ csm-sle-15sp2'
   ```

   > **`WARNING`**: If the `csm-sle-15sp2` repository is already configured on a
   > node `zypper ar` will error with e.g.:
   >
   > ```
   > Adding repository 'csm-sle-15sp2' [...error]
   > Repository named 'csm-sle-15sp2' already exists. Please use another alias.
   > ```
   >
   > These errors may be ignored.

1. Use `zypper up` on each NCN to upgrade installed packages:

   ```bash
   ncn-m001# pdsh -w "$ncns" 'zypper up -y'
   ```

<a name="enable-psp"></a>
## Enable PodSecurityPolicy

Run `./lib/0.9.3/enable-psp.sh` to enable PodSecurityPolicy:

```bash
ncn-m001# ./lib/0.9.3/enable-psp.sh
```


<a name="iscsi-security-fix"></a>
## Apply iSCSI Security Fix

Apply the workaround for the following CVEs: CVE-2021-27365, CVE-2021-27364, CVE-2021-27363.

The affected kernel modules are not typically loaded on Shasta NCNs. The following prevents them
from ever being loaded.

```bash
ncn-m001# pdsh -w $(./lib/list-ncns.sh | paste -sd,) "echo 'install libiscsi /bin/true' >> /etc/modprobe.d/disabled-modules.conf"
```


<a name="configure-lag-for-cmms"></a>

## Configure LAG for CMMs

> **`CRITICAL:`** Only perform the following procedure if `$CSM_RELEASE_VERSION >= 0.9.3`.

> **`IMPORTANT:`** This procedure applies to systems with CDU switches.

If your Shasta system is using CDU switches you will need to update the configuration going to the CMMs.

- This **requires** updated CMM firmware. (version 1.4.20) `See v1.4 Admin Guide for details on updating CMM firmware`
- A static LAG will be configured on the CDU switches.
- The CDU switches have two cables (10Gb RJ45) connecting to each CMM.
- This configuration offers increased throughput and redundancy.
- The CEC will not need to be programmed in order to support the LAG configuration as it was required in previous versions. The updated firmware takes care of this.

### Aruba CDU switch configuration.
This configuration is identical across CDU VSX pairs.
The VLANs used here are generated from CSI.
```
sw-cdu-001(config)# int lag 2 multi-chassis static
sw-cdu-001(config-lag-if)# no shutdown
sw-cdu-001(config-lag-if)# description CMM_CAB_1000
sw-cdu-001(config-lag-if)# no routing
sw-cdu-001(config-lag-if)# vlan trunk native 2000
sw-cdu-001(config-lag-if)# vlan trunk allowed 2000,3000,4091
sw-cdu-001(config-lag-if)# exit

sw-cdu-001(config)# int 1/1/2
sw-cdu-001(config-if)# no shutdown
sw-cdu-001(config-if)# lag 2
sw-cdu-001(config-if)# exit
```

## Dell

Dell CDU switch configuration.
This configuration is identical across CDU VLT pairs.
The VLANs used here are generated from CSI.
```
interface port-channel1
 description CMM_CAB_1000
 no shutdown
 switchport mode trunk
 switchport access vlan 2000
 switchport trunk allowed vlan 3000,4091
 mtu 9216
 vlt-port-channel 1

interface ethernet1/1/1
 description CMM_CAB_1000
 no shutdown
 channel-group 1 mode on
 no switchport
 mtu 9216
 flowcontrol receive on
 flowcontrol transmit on
```

<a name="run-validation-checks-post-upgrade"></a>
## Run Validation Checks (Post-Upgrade)

> **`IMPORTANT:`** Wait at least 15 minutes after
> [`upgrade.sh`](#deploy-manifests) completes to let the various Kubernetes
> resources get initialized and started.

Run the following validation checks to ensure that everything is still working
properly after the upgrade:

1. [Platform health checks](../../008-CSM-VALIDATION.md#platform-health-checks)
2. [Network health checks](../../008-CSM-VALIDATION.md#network-health-checks)

Other health checks may be run as desired.

> **`CAUTION:`** The following HMS functional tests may fail because of locked
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
> Failures of these tests because of locked components as shown above can be safely
> ignored.

<a name="exit-typescript"></a>
## Exit Typescript

Remember to exit your typescript.

```bash
ncn-m001# exit
```

It is recommended to save the typescript file for later reference.
