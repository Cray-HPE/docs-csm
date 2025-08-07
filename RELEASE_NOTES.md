# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.7 contains many changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

### Resiliency

* The optional [Rack Resiliency](operations/rack_resiliency/README.md) feature enhances CSM
  resiliency by offering protection to the management plane against rack-level failures.
    * This feature is disabled by default
    * This feature **can only be enabled during an upgrade from CSM 1.6 to CSM 1.7 or an install of CSM 1.7**.
    * See [Enabling Rack Resiliency](operations/rack_resiliency/Enabling_Rack_Resiliency.md) for more details.

### Monitoring

### Networking

### Miscellaneous functionality

* Console logs and interaction is now available and tenant aware through the `cray` CLI, see [console](operations/conman/ConMan.md#console) for more information.
* [Configuration Framework Service (CFS)](glossary.md#configuration-framework-service-cfs) components can now be updated in bulk through the [Cray CLI (`cray`)](glossary.md#cray-cli-cray).
  See [Managing many components](operations/configuration_management/CFS_Commands_Cheat_Sheet.md#managing-many-components) for more information.
  Support is added for `v2` and `v3` API versions.
* Recipe builds using kiwi-ng now include the signing keys contained in the `hpe-signing-key` secret, which allows for the verification of the recipe build artifacts.

### `cray-site-init` updates

CSM V1.7 includes a major version bump for `cray-site-init`.

#### Main Feature

* **Added IPv6 enablement for fresh installs and already deployed CSM systems**
* cloud-init data for IPv6 addresses and gateways on the CMN
* SLS data for IPv6 addresses and gateways on the CMN and CHN
* Supports IPv6 NTP servers
* Supports IPv6 site link (only supports IPv4 or IPv6 exclusively)

IPv6 data is now consumed during a Fresh install during `csi config init` by including the new IPv6 keys:

* `chn-gateway6`
* `chn-cidr6`
* `cmn-gateway6`
* `cmn-cidr6`

For runtime/upgrades, the same flags are used but with the `csi patch csm ipv6` command. This command will patch SLS
with IPv6 reservations for the `bootstrap_dhcp` and `network_hardware` subnets in the CHN and CMN. The list of subnets
can be overridden, but not the list of networks, and only during the `csi patch csm ipv6` command (not during
`csi config init`). This command is designed to be repeatable for use after new hardware has been added.

##### `csi patch csm ipv6`

This command defaults to a dry run; all proposed changes to BSS and SLS will be written to a timestamped directory in
the user's working directory (unless otherwise overridden by `-b|--backup-dir`) along with backups of the original data.

Passing `--commit` to the command will disable the dry run; all proposed changes and backups will be written in the same
manner as the dry run, before being applied to BSS and SLS.

This command will skip entries that already have IPv6 data unless the `-f|--force` flag is present. This means:

* Re-running `csi patch csm ipv6` on an already patched system with no hardware changes will result in no change
* Re-running `csi patch csm ipv6` on an already patched system *with new hardware added* will result in new IP
  reservations and BSS data *for only that hardware*
* Re-running `csi patch csm ipv6 --force` will update existing IPv6 addresses within `csi patch csm ipv6`'s scope

Without `--force`, `csi patch csm ipv6` will respect any existing `IPAddress6` reservations in BSS and SLS installed by
hand (e.g. by the customer or admin). Please be aware that after the first run of CSI `--commit`, the generated backups
are the only way to restore the manually added `IPAddress6` reservations.

###### Removing/Undoing IPv6

`csi patch csm ipv6` has a `--remove` flag, and by default this flag runs as a dry run unless `--commit` is present.
This removes all IPv6 data in BSS and SLS within the scope of `csi patch csm ipv6`, e.g. the CHN, CMN, and their
`bootstrap_dhcp` and `network_hardware` subnets (unless otherwise overridden with `--subnets`).

`--remove` will create backups in the same manner as the patch command.

###### Scoping

By default, `csi patch csm ipv6` targets the `bootstrap_dhcp` and `network_hardware` subnets within the Customer
High-speed Network (CHN) and Customer Management Network (CMN).

* The list of targeted subnets can be overridden with the `--subnets` flag (see usage)
* The list of targeted networks **are not** configurable beyond the CHN and CMN, to exclude one or the other, the
  corresponding flags should be omitted (e.g. leave out `--chn-cidr6/--chn-gateway6` to omit the CHN)

> ***NOTE***: Any SLS `IPReservation` within the target subnets will be given IPv6 leases (e.g. every `IPReservation`
> entry in the CMN's `bootstrap_dhcp` subnet will receive an `IPAddress6` entry, there is no hardware
> filter or differentiator to choose otherwise).

##### System administrator changes

These changes may be important for system administrators and configuration maintainers to be aware of.

* `csi config init empty` and `csi config init` produce `system_config.yaml` files without deprecated flags, alias
  flags, and program assistant flags. Examples:
    * `config` and `help`
    * `cmn-gw` and `can-gw`
    * Deprecated keys (e.g. `bgp-peers`)
  > ***It is strongly recommended to update saved configs with the new `system_config.yaml` after running this newer
  CSI***. CSI will remind users to replace existing backups with the newly generated `system_config.yaml` file
  after running `csi config init`
* All generated files from `csi config init` (with exception to where it is legal) now include in their headers:
    * The version of CSI that generated them
    * A ubiquitous timestamp for when `csi config init` was called

      Example:

      ```text
      #
      ## This file was generated by cray-site-init.
      ## Version: 2.0.5
      ## Generated time: 2025-08-02T21:09:36.528837Z
      #
      ```

#### Flag changes

Using deprecated flags will cause a warning to be emitted.

New flags:

* `csi config init` flags
    * `chn-gateway6`
    * `chn-cidr6`
    * `cmn-gateway6`
    * `cmn-cidr6`
    * `cmn-cidr4` *(deprecates `cmn-cidr`)*
    * `cmn-gateway4` *(deprecates`cmn-gateway`)*
    * `chn-cidr4` *(deprecates `chn-cidr`)*
    * `chn-gateway4` *(deprecates`chn-gateway`)*
* `csi` main program flags
    * `input-dir`  a directory to look for input files (not including `system_config.yaml` , that is looked for in
      the `PWD` unless an alternative path was passed to`--config`) example:
      `/tmp/csi config init -i /var/www/ephemeral/prep -c /var/www/ephemeral/prep/system_config.yaml` or on a local
      workstation,
      `./csi config init -i ~/gitstuff/hpc-shasta-system-config/redbull/1.6 -c ~/gitstuff/hpc-shasta-system-config/redbull/1.6/system_config.yaml`
    * `--k8s-secret-name` and `--k8s-namespace` can be used to override the location to read the OpenID token (
      defaults, `default`, and `admin-client-auth` respectively)
    * `--csm-api-url` can be used to change the target API URL (default `"https://api-gw-service-nmn.local"`)

#### New sub-commands

Deprecated sub-commands will not appear in `csi --help` usage, and invoking them will emit a warning.

* `csi patch csm ipv6` will patch IPv6 data into CSM for network devices, application nodes, and non-compute nodes.
* `csi patch init ca` *(deprecates `csi patch ca`)*
* `csi patch init packages` *(deprecates `csi patch packages`)*

#### Removed sub-commands

* `csi config load` was no longer used and had outdated/unmaintained structures
* `csi pit get` was no longer used and was causing problems with the lint workflow and circular dependencies

#### Behavior changes

* `csi config init` will exit immediately if any generated file fails to template.
    * Previously, `csi` would carry on and possibly leave the user with malformed files. The user would need to decipher
      an error happened between the dozens of innocuous messages printed to screen.
    * Now, if a template fails to generate for any reason the program will exit with an error.
      > ***NOTE*** Some templates required a refactor for this failure to be properly acknowledged, and while this issue
      is
      fixed it remains broken for templates like `metallb.yaml`
* ***IMPORTANT*** 1-2 addresses shift IP address reservations in some subnets
    * Previously, all subnet reservations started with a +2 deviation from their subnet's IP to account for the subnet
      IP and gateway IP
    * Now, this logic only applies to a subnet that shares the same IP as its "super net" network
      > ***Systems that are fresh installing CSM V1.7 that had been running a previous version of CSM V1.6 must
      > regenerate their switch configurations for BGP to work..***

#### Bugfixes

* Fixed an erroneous message during `csi config init` where "disk configuration" would print once for each NCN.
* Fixed a bug in the DNSMasq files where the `domain=` key was set to the SLS subnet start and end IP instead of the
  entire network.
* Previously, for CSM 1.7 the `k8s-primary-cni` value was ignored in `system_config.yaml`
* Fixes an issue where deprecated keys that had aliases were still required, this was due to the split-brain aspect of
  Cobra command line vs. Viper configs. Now keys are merged and removed and replaced with aliased values as defined by
  Cobra. This extends `MTL-2396` further, and was necessary for the proper deprecation of `chn-cidr`,
  `chn-gateway`, `cmn-cidr`, `cmn-gateway`
* Prohibits setting overlapping CIDRs between the `*-cidr` parameters during `csi config init` and
  `csi patch csm ipv6` (`CASMINST-7208`)

### New hardware support

### New software support

### Automation improvements

### Base platform component upgrades

| Platform Component           | Version |
|------------------------------|---------|
| `Kubernetes`                 | 1.32.5  |
| `Kyverno`                    | 1.13.4  |
| `Strimzi Kafka`              | 0.45.0  |
| `argo-workflow-controller`   | 3.4.5   |
| `argo-workflows`             | 3.4.5   |
| `bitnami-etcd` for clusters  | 3.5.21  |
| `etcd` on `ncn-mxxx`         | 3.5.18  |
| `ceph`                       | 17.2.6  |
| `containerd`                 | 1.7.27  |
| `coredns`                    | 1.11.3  |
| `cray-certmanager`           | 1.17.0  |
| `cray-externaldns`           | 0.15.0  |
| `cray-metallb`               | 0.14.9  |
| `cray-node-problem-detector` | 0.8.20  |
| `cray-spire`                 | 1.5.5   |
| `cray-vault-operator`        | 1.22.5  |
| `cray-velero`                | 10.0.1  |
| `helm`                       | 3.18.3  |
| `istio`                      | 1.26.0  |
| `kata`                       | 3.17.0  |
| `keycloak`                   | 21.1.1  |
| `kiali`                      | 2.10.0  |
| `metrics-server`             | 0.6.3   |
| `nexus`                      | 3.70.4  |
| `pause`                      | 3.10    |
| `postgres-operator`          | 1.10.1  |
| `postgresql`                 | 15.2    |
| `sealed-secrets`             | 0.28.0  |
| `spire-intermediate`         | 1.0.1   |
| `tapms-operator`             | 1.9.1   |

### Security improvements

* Spire node attestation can now be setup to use TPM chips on supported platforms, see [Enable TPM node attestation with Spire](operations/spire/Enable_TPM_node_attestation.md) for more information.
* The old version of the Spire server was removed to fully transition to the newer version of Spire.
* Updated all HMS services to point to latest upstream image and Go module dependencies.  This resolved all currently known point-in-time CVE issues in HMS services.

### Customer-requested enhancements

* CSM now provides the `csm.ssh_config` Ansible role to automatically restore the root user's SSH configuration file during
  [Management Node Personalization](operations/configuration_management/Management_Node_Personalization.md).
  For more details, see [SSH configuration files](operations/CSM_product_management/Set_Up_Passwordless_SSH.md#ssh-configuration-files).
* [CFS](glossary.md#configuration-framework-service-cfs) import tool now checks for running sessions before importing data.
  For more details, see [Import](operations/configuration_management/Exporting_and_Importing_CFS_Data.md#import).
* [BOS](glossary.md#boot-orchestration-service-bos) import tool now checks for running sessions before importing data. For more details,
  see [Import BOS session templates](operations/boot_orchestration/Exporting_and_Importing_BOS_Data.md#exporting-and-importing-bos-data).
* When a [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos) session starts,
  any nodes that are locked in the [Hardware State Manager (HSM)](glossary.md#hardware-state-manager-hsm) are removed from the session.
  For more information, see [BOS sessions and HSM locks](operations/boot_orchestration/Sessions.md#bos-sessions-and-hsm-locks).

### Documentation enhancements

## Noteworthy changes

* The default Kubernetes certificate validity period increased from 1 year to 3 years.
  For more details on the certificate validity period and how to modify it, see
  [Modify certificate validity period](operations/kubernetes/Cert_Renewal_for_Kubernetes_and_Bare_Metal_EtcD.md#modify-certificate-validity-period).
* Kyverno image verification policy is being shipped in `Enforce` mode. Container images that are unsigned will not be deployed.
  For more information on the policy, how to add exceptions, and how to allow third party signing keys, see
  [What is new in the HPE CSM 1.7 release and above](operations/kubernetes/Kyverno.md#what-is-new-in-the-hpe-csm-17-release-and-above).
* `PProf` debug support has been added to all remaining HMS services.  See [Debugging With HMS `PProf` Images](troubleshooting/debugging_with_hms_pprof_images.md) for more information.

## Test

* Modified `adjust k8s_nodes_ready_check.sh` to not fail when a node is in `Ready,SchedulingDisabled` state
* Modified `velero_backups_check.sh` to not fail if a newer, successful backup exists
* Modified `run_hms_ct_tests.sh` to handle concurrency better
* Fixed intermittent failures sometimes seen when running `check_key_id_in_jwks.sh`
* Added retry logic to `goss-postgresql-syncfailed.yaml` to prevent intermittent false positives
* Added retry logic to `postgres_clusters_running.sh to prevent` intermittent false positives
* Added tests to the Software Management Services (SMS) health checks:
    * Added [BOS](glossary.md#boot-orchestration-service-bos) create/update/delete (CRUD) tests for session templates and sessions.
    * Added [CFS](glossary.md#configuration-framework-service-cfs) CRUD tests for configurations and sources.
    * Added [IMS](glossary.md#image-management-service-ims) CRUD tests for images, recipes, and public keys.
    * These tests are part of the procedure to [Validate CSM Health](operations/validate_csm_health.md).
    * For more information on the SMS health checks, see
      [Software Management Services health checks](troubleshooting/known_issues/sms_health_check.md#software-management-services-health-checks).
* Added [CFS](glossary.md#configuration-framework-service-cfs) node personalization to the barebones image boot test.
    * This tests is part of the procedure to [Validate CSM Health](operations/validate_csm_health.md).
    * For more information, see [Barebones Image Boot Test](troubleshooting/cms_barebones_image_boot.md).
* Various updates to HMS services to prevent false positive failures in CT tests

## Bug fixes

* The [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos)
  [`session-setup` operator](operations/boot_orchestration/BOS_Services.md#session-setup) now ignores invalid
  [xnames](glossary.md#xname) referenced by [session templates](operations/boot_orchestration/Session_Templates.md),
  fixing a bug that caused BOS [sessions](operations/boot_orchestration/Sessions.md) to be stuck in `pending` state.
* BOS logging is significantly more memory efficient, fixing a problem where logging on large scale systems
  could cause [BOS operator](operations/boot_orchestration/BOS_Services.md#bos-operators) Kubernetes pods to be `OOMKilled`.
* When using the API or CLI to [Modify a BOS session template](operations/boot_orchestration/Manage_a_Session_Template.md#modify-a-session-template),
  it is no longer required to specify `boot_sets` in the update data (this fixes a regression bug present in CSM 1.6).
* Previously, the CSM 1.5.3 and CSM 1.6.1 releases included changes
  to resolve resource leaks found in the
  [PCS](glossary.md#power-control-service-pcs),
  [SMD](glossary.md#hardware-state-manager-smd),
  `hmcollector`, and [FAS](glossary.md#firmware-action-service-fas)
  services.  This reduced instances of pods being restarted due to
  `OOMKilled` and failed liveness and/or readiness probes.  These
  changes also improved the responsiveness and scalability of these
  services.
    * In the CSM 1.7.0 release, additional resource leaks in these same services were found and resolved.
    * Additionally, similar resource leaks were found and resolved in the following HMS services:
      [BSS](glossary.md#boot-script-service-bss),
      [CAPMC](glossary.md#cray-advanced-platform-monitoring-and-control-capmc),
      River Discovery,
      [HBTD](glossary.md#heartbeat-tracker-daemon-hbtd),
      [MEDS](glossary.md#mountain-endpoint-discovery-service-meds),
      [RTS](glossary.md#redfish-translation-service-rts),
      [HMNFD](glossary.md#hardware-management-notification-fanout-daemon-hmnfd),
      [SCSD](glossary.md#system-configuration-service-scsd),
      [SLS](glossary.md#system-layout-service-sls)
* A bug was fixed in the `hmcollector-poll` service so that event subscriptions are no longer lost after updating Paradise BMC firmware.  The service no longer needs to be restarted after performing firmware updates.
* Fixed an issue where a soft deleted IMS recipe was always assigned the architecture `x86_64`, regardless of the architecture of the recipe that was deleted.
* Fixed an issue where a soft deleted IMS recipe was always assigned `require_dkms=true`, regardless of the value of the recipe that was deleted.
* Fixed an issue where incorrect metadata was stored for newly created IMS images.
* Fixed an issue where IMS image tags were removed by a soft delete.
* Fixed an issue where updating a CFS session could fail and cause the session to be stuck in pending state.
* Fixed an issue where `cfs-debugger` crashed when `cfs-state-reporter` service status did not include a `since` timestamp.
* Fixed an issue where the post-upgrade job of `cms-ipxe` would fail if a previously failed `cms-ipxe` upgrade job entry existed.
* Fixed an issue where, when building an IMS image from a recipe, the job status would not update to `error` when the `zypper` repositories were not available.
* Fixed an issue where the hardware inventory history table in the HSM/SMD database grew too large due to duplicate "Detected" events.
    * See [Remove Duplicate Detected Events From the HSM Postgres Database](operations/hardware_state_manager/Remove_Duplicate_Detected_Events_From_HSM_Postgres_Database.md) for more information.
* Fixed an issue in [PCS](glossary.md#power-control-service-pcs) where the supported power transitions on Gigabyte BMCs can go missing.

## Deprecations

For more details and a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* Support for projecting root filesystems and PE images using the [Content Projection Service (CPS)](glossary.md#content-projection-service-cps) and the
  [Data Virtualization Service (DVS)](glossary.md#data-virtualization-service-dvs).
    * This projection is now done using the [Scalable Boot Projection Service](glossary.md#scalable-boot-projection-service-sbps).
* Top-level Ansible playbooks `ncn-master.yaml`, `ncn-storage.yaml`, and `ncn-worker.yaml` in `csm-config-management` repository in the
  [Version Control Service (VCS)](glossary.md#version-control-service-vcs).
    * These have been replaced by the unified `ncn_nodes.yaml` top-level playbook.
* Experimental `disable_components_on_completion` [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos)
  [option](operations/boot_orchestration/Options.md).

For more details and a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

* Systems running CSM V1.6 or earlier that fresh install CSM V1.7 must regenerate their management switch configuration due to the [`cray-site-init` behavior changes](#behavior-changes).
    * Systems upgrading from CSM V1.6 to CSM V1.7 **may ignore** this issue until the next CSM V1.7 (or higher version) reinstall.

For a full list of known issues, see [Known issues](troubleshooting/README.md#known-issues).

### Security vulnerability exceptions in CSM 1.7
