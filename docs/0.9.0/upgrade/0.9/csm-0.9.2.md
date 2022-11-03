Copyright 2021 Hewlett Packard Enterprise Development LP


# CSM 0.9.2 Patch Upgrade Guide

This guide contains procedures for upgrading systems running CSM 0.9.0 to CSM
0.9.2. It is intended for system installers, system administrators, and network
administrators. It assumes some familiarity with standard Linux and associated
tooling.

> **`NOTE:`** CSM 0.9.1 was not officially released so these procedures start
> with CSM 0.9.0.

See CHANGELOG.md in the root of a CSM release distribution for a summary of
changes in each CSM release.

Procedures:

- [Preparation](#preparation)
- [Run Validation Checks (Pre-Upgrade)](#run-validation-checks-pre-upgrade)
- [Update Customizations](#update-customizations)
- [Setup Nexus](#setup-nexus)
- [Deploy Manifests](#deploy-manifests)
- [Upgrade NCN Packages](#upgrade-ncn-packages)
- [Switch VCS Configuration Repositories to Private](#switch-vcs-configuration-repositories-to-private)
- [Configure Prometheus Alert Notifications to Detect Postgres Replication Lag](#configure-prometheus-alert-notifications-to-detect-postgres-replication-lag)
- [Run Validation Checks (Post-Upgrade)](#run-validation-checks-post-upgrade)
- [Update BGP Configuration](#update-bgp-configuration)
- [Upgrade Firmware on Chassis Controllers](#upgrade-firmware-on-chassis-controllers)
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
   CSM 0.9.2:

   > **`NOTE:`** Use `--no-same-owner` and `--no-same-permissions` options to
   > `tar` when extracting a CSM release distribution as `root` to ensure the
   > extracted files are owned by `root` and have permissions based on the current
   > `umask` value.

   ```bash
   ncn-m001# tar --no-same-owner --no-same-permissions -zxvf csm-0.9.2.tar.gz
   ncn-m001# CSM_DISTDIR="$(pwd)/csm-0.9.2"
   ```

1. Set `CSM_RELEASE_VERSION` to the version reported by
   `${CSM_DISTDIR}/lib/version.sh`:

   ```bash
   ncn-m001# CSM_RELEASE_VERSION="$(${CSM_DISTDIR}/lib/version.sh --version)"
   ```

1. Set `CSM_SYSTEM_VERSION` to `0.9.0`:

   ```bash
   ncn-m001# CSM_SYSTEM_VERSION="0.9.0"
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


<a name="update-customizations"></a>
## Update Customizations

Before [deploying upgraded manifests](#deploy-manifests), `customizations.yaml`
in the `site-init` secret in the `loftsman` namespace must be updated.

1. If the [`site-init` repository is available as a remote
   repository](../../067-SHASTA-CFG.md#push-to-a-remote-repository) then clone
   it on the host orchestrating the upgrade:

   ```bash
   ncn-m001# git clone "$SITE_INIT_REPO_URL" site-init
   ```

   Otherwise, create a new `site-init` working tree:

   ```bash
   ncn-m001# git init site-init
   ```

1. Download `customizations.yaml`:

   ```bash
   ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

1. Review, add, and commit `customizations.yaml` to the local `site-init`
   repository as appropriate.

   > **`NOTE:`** If `site-init` was cloned from a remote repository in step 1,
   > there may not be any differences and hence nothing to commit. This is
   > okay. If there are differences between what is in the repository and what
   > was stored in the `site-init`, then it suggests settings were improperly
   > changed at some point. If that is the case then be cautious, _there may be
   > dragons ahead_.

   ```bash
   ncn-m001# cd site-init
   ncn-m001# git diff
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Add customizations.yaml from site-init secret'
   ```

1. Update `customizations.yaml`.

   ```bash
   ncn-m001# yq d -i customizations.yaml spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.resources
   ```

1. Review the changes to `customizations.yaml` and verify [baseline system
   customizations](../../067-SHASTA-CFG.md#create-baseline-system-customizations)
   and any customer-specific settings are correct.

   ```
   ncn-m001# git diff
   ```

1. Add and commit `customizations.yaml` if there are any changes:

   ```
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m "Update customizations.yaml consistent with CSM $CSM_RELEASE_VERSION"
   ```

1. Update `site-init` sealed secret in `loftsman` namespace:

   ```bash
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. Push to the remote repository as appropriate:

   ```bash
   ncn-m001# git push
   ```


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


<a name="deploy-manifests"></a>
## Deploy Manifests

Run `kubectl delete -n spire job spire-update-bss` to allow the spire chart to be updated properly:

```bash
ncn-m001# kubectl delete -n spire job spire-update-bss
```

Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m001# ./upgrade.sh
```


<a name="upgrade-ncn-packages"></a>
## Upgrade NCN Packages

Upgrade packages on NCNs.

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

1. Install the `hpe-csm-scripts` package on each NCN:

  ```bash
  ncn-m001# pdsh -w "$ncns" 'zypper in -y hpe-csm-scripts'
  ```


<a name="switch-vcs-configuration-repositories-to-private"></a>
## Switch VCS Configuration Repositories to Private

Previous installs of CSM and other Cray products created git repositories in
the VCS service which were set to be publicly visible. To enhance security,
please follow the instructions in the Admin guide, chapter 12, "Version Control
Service (VCS)" section to switch the visibility of all `*-config-management`
repositories to private.

Future installations of configuration content into Gitea by CSM and other Cray
products will create or patch repositories to private visibility automatically.

As a result of this change, `git clone` operations will now require
credentials. CSM services that clone repositories have been upgraded to use the
`crayvcs` user to clone repositories.


<a name="configure-prometheus-alert-notifications-to-detect-postgres-replication-lag"></a>
## Configure Prometheus Alert Notifications to Detect Postgres Replication Lag

Three new Prometheus alert definitions have been added in CSM 0.9.1 for
monitoring replication across Postgres instances, which are used by some system
management services. The new alerts are `PostgresqlReplicationLagSMA` (for
Postgres instances in the `sma` namespace), `PostgresqlReplicationLagServices`
(for Postgres instances in all other namespaces), and
`PostgresqlInactiveReplicationSlot`.

In the event that a state of broken Postgres replication persists to the extent
that space allocated for its WAL files fills-up, the affected database will
likely shut down and create a state where it cannot be brought up again. This
can impact the reliability of the related service and can require that it be
redeployed with data re-population procedures.

To avoid this unexpected, but possible event, it is recommended that all
administrators configure Prometheus alert notifications for the early detection
of Postgres replication lag and, if notified, swiftly follow the suggested
remediation actions (to avoid service down-time).

Please access the relevant sections of the [1.4 HPE Cray EX System
Administration Guide] for information about how to configure Prometheus Alert
Notifications ("System Management Health Checks and Alerts" sub-section under
"Monitor the System") and how to re-initialize a Postgres cluster encountering
signs of replication lag ("About Postgres" sub-section under "Kubernetes
Architecture").

[1.4 HPE Cray EX System Administration Guide]: https://connect.us.cray.com/confluence/download/attachments/186435146/HPE_Cray_EX_System_Administration_Guide_1.4_S-8001_RevA.pdf?version=1&modificationDate=1616193177450&api=v2


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


<a name="update-bgp-configuration"></a>
## Update BGP Configuration

> **`IMPORTANT:`** This procedure applies to systems with Aruba management
> switches.

If your Shasta system is using Aruba management switches run the updated BGP
script `/opt/cray/csm/scripts/networking/BGP/Aruba_BGP_Peers.py`.

1. Set the `SWITCH_IPS` variable to an array containing the IP addresses of the switches.

   > **`EXAMPLE:`**: The following can be used to determine the IP addresses of the switches running BGP:
   > ```bash
   > ncn-m001# kubectl get cm config -n metallb-system -o yaml | head -12
   > apiVersion: v1
   > data:
   > config: |
   >    peers:
   >    - peer-address: 10.252.0.2
   >       peer-asn: 65533
   >       my-asn: 65533
   >    - peer-address: 10.252.0.3
   >      peer-asn: 65533
   >      my-asn: 65533
   >   address-pools:
   >    - name: customer-access
   > ```
   > In the above output `10.252.0.2` and `10.252.0.3` are the switches running
   > BGP. Set `SWITCH_IPS` as follows:
   >
   > ```bash
   > ncn-m001# SWITCH_IPS=( 10.252.0.2 10.252.0.3 )
   > ```

1. Run:

   ```bash
   ncn-m001# /opt/cray/csm/scripts/networking/BGP/Aruba_BGP_Peers.py "${SWITCH_IPS[@]}"
   ```

1. Remove the static routes configured in
   [LAYER3-CONFIG](../../411-MGMT-NET-LAYER3-CONFIG.md). Log into the switches
   running BGP (Spines/Aggs) and remove them:

   > **`Note`**: To view the current static routes setup on the switch run the following
   > ```bash
   > sw-spine01# show ip route static
   >
   > Displaying ipv4 routes selected for forwarding
   >
   > '[x/y]' denotes [distance/metric]
   >
   > 0.0.0.0/0, vrf default
   > 	via  10.103.15.161,  [1/0],  static
   > 10.92.100.60/32, vrf default
   > 	via  10.252.1.10,  [1/0],  static
   > 10.94.100.60/32, vrf default
   > 	via  10.252.1.10,  [1/0],  static
   > ```
   > In the above example the static routes that need to be removed point to `10.252.1.10`

   ```bash
   sw-spine-001(config)# no ip route 10.92.100.60/32 10.252.1.10
   sw-spine-001(config)# no ip route 10.94.100.60/32 10.252.1.10
   ```

1. Verify the [BGP configuration](../../400-SWITCH-BGP-NEIGHBORS.md).

<a name="upgrade-firmware-on-chassis-controllers"></a>
## Upgrade Firmware on Chassis Controllers

1. Check to see if firmware is loaded into FAS:

   ```bash
   ncn-m001# cray fas images list | grep cc.1.4.19
   ```

   If firmware not installed, rerun the FAS loader:

   ```bash
   ncn-w001# kubectl -n services get jobs | grep fas-loader
   cray-fas-loader-1  1/1  8m57s  7d15h
   ```

   > **`NOTE:`** In the above example, the returned job name is
   > `cray-fas-loader-1`, hence that is the job to rerun.


   ```bash
   ncn-m001# kubectl -n services get job cray-fas-loader-1 -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | kubectl replace --force -f -
   ```

   When completed, verify the firmware was loaded into FAS:

   ```bash
   ncn-m001# cray fas images list | grep cc.1.4.19
   ```

1. Update the Chassis Controller BMC Firmware:

  Power off the chassis slots.

  Disable the hms-discovery job:

  ```bash
  ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec":{"suspend":true}}'
  ```
   Power off all the components: for example, in chassis 0-7. cabinets 1000-1003:

   ```bash
   ncn-m001# cray capmc xname_off create --xnames x[1000-1003]c[0-7] --recursive true --continue true
   ```

  Create an upgrade JSON file `ccBMCupdate.json`:

  ```json
  {
    "inventoryHardwareFilter": {
      "manufacturer": "cray"
    },
    "stateComponentFilter": {
      "deviceTypes": [
        "chassisBMC"
      ]
    },
    "targetFilter": {
      "targets": [
        "BMC"
      ]
    },
    "command": {
      "version": "latest",
      "tag": "default",
      "overrideDryrun": false,
      "restoreNotPossibleOverride": true,
      "timeLimit": 1000,
      "description": "Dryrun upgrade of Cray Chassis Controllers"
    }
  }
  ```

  Using the above JSON file run a dry-run with FAS:

  ```bash
  ncn-w001# cray fas actions create ccBMCupdate.json
  ```

  Check the output from the dry-run with the command: `cray fas actions
  describe {action-id}` (where `action-id` was the `actionId` returned for the
  `fas actions create` command)

  If dry-run succeeded with updates to version 1.4.19, change
  `"overrideDryrun"` in the above JSON file to `true` and update the description.
  Rerun FAS with the updated JSON file to do the actual updates.

  After firmware update completes, restart the hms-discovery cronjob:

  ```bash
  ncn-m001 # kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
  ```

  The hms-discovery cronjob will run within 5 minutes of being unsuspended and
  start powering on the chassis enclosures, switches, and compute blades. If
  components are not being powered back on, then power them on manually:

  ```bash
  ncn-m001 # cray capmc xname_on create --xnames x[1000-1003]c[0-7]r[0-7],x[1000-1003]c[0-7]s[0-7] --prereq true --continue true
  ```

  The `--prereq` option ensures all required components are powered on first.
  The `--continue` option allows the command to complete in systems without
  fully populated hardware.

  After the components have powered on, boot the nodes using the Boot
  Orchestration Services (BOS).

<a name="exit-typescript"></a>
## Exit Typescript

Remember to exit your typescript.

```bash
ncn-m001# exit
```

It is recommended to save the typescript file for later reference.
