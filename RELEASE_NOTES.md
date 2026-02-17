# Cray System Management (CSM) - Release Notes

* [New](#new)
    * [iSCSI SBPS](#iscsi-sbps)
    * [Monitoring](#monitoring)
    * [Miscellaneous functionality](#miscellaneous-functionality)
    * [`csi` tool updates](#csi-tool-updates)
    * [New hardware support](#new-hardware-support)
    * [New software support](#new-software-support)
    * [Automation improvements](#automation-improvements)
    * [Base platform component upgrades](#base-platform-component-upgrades)
    * [Security improvements](#security-improvements)
    * [Customer-requested enhancements](#customer-requested-enhancements)
    * [Documentation enhancements](#documentation-enhancements)
    * [Rack Resiliency technology preview](#rack-resiliency-technology-preview)
* [Noteworthy changes](#noteworthy-changes)
* [Test](#test)
* [Bug fixes](#bug-fixes)
* [Deprecations](#deprecations)
* [Removals](#removals)
* [Known issues](#known-issues)
    * [Security vulnerability exceptions in CSM 1.7](#security-vulnerability-exceptions-in-csm-17)
* [Resolved CASTs](#resolved-casts)
* [All resolved issues](#all-resolved-issues)
    * [Networking](#networking)
    * [IUF](#iuf)
    * [Cray SAT](#cray-sat)
    * [Security and Kyverno Policies](#security-and-kyverno-policies)
    * [Upgrades](#upgrades)
    * [DOCS](#docs)
    * [CASM](#casm)
    * [CASMCMS](#casmcms)
    * [CASMCVT](#casmcvt)
    * [CASMDIAG](#casmdiag)
    * [CASMHMS](#casmhms)
    * [CASMINST](#casminst)
    * [CASMMON](#casmmon)
    * [CASMPET](#casmpet)
    * [CASMSMF](#casmsmf)
    * [MTL](#mtl)
    * [USS](#uss)

## New

### iSCSI SBPS

* The [iSCSI SBPS feature](operations/iscsi_sbps/README.md) is enhanced to allow administrators
  to select which worker NCNs are enabled as iSCSI targets. This is a change from CSM 1.6, where
  all worker NCNs are enabled as iSCSI targets. For more information, see
  [Managing Selective Node Personalization](operations/iscsi_sbps/Managing_Selective_Node_Personalization.md).

### Monitoring

### Miscellaneous functionality

* Console logs and interaction is now available and tenant aware through the `cray` CLI, see [ConMan](operations/conman/ConMan.md) for more information.
* [Configuration Framework Service (CFS)](glossary.md#configuration-framework-service-cfs) components can now be updated in bulk through the [Cray CLI (`cray`)](glossary.md#cray-cli-cray).
  See [Managing many components](operations/configuration_management/CFS_Commands_Cheat_Sheet.md#managing-many-components) for more information.
  Support is added for `v2` and `v3` API versions.
* Recipe builds using kiwi-ng now include the signing keys contained in the `hpe-signing-key` secret, which allows for the verification of the recipe build artifacts.

### `csi` tool updates

CSM 1.7 includes a major version bump for [Cray Site Init (CSI)](glossary.md#cray-site-init-csi).

* **Added IPv6 enablement for fresh installs and already deployed CSM systems**
* cloud-init data for IPv6 addresses and gateways on the [CMN](glossary.md#customer-management-network-cmn)
* [SLS](glossary.md#system-layout-service-sls) data for IPv6 addresses and gateways on the CMN and
  [CHN](glossary.md#customer-high-speed-network-chn)
* Supports IPv6 NTP servers
* Supports IPv6 site link (only supports IPv4 or IPv6 exclusively)
* **Extensive usage changes** and bug fixes in support of the new features. This includes behavior changes
  to `csi config` that administrators performing fresh installs of CSM should be aware of.

For full details on these extensive changes, see [`csi` Tool Changes](introduction/csi_Tool_Changes.md).

### New hardware support

### New software support

### Automation improvements

* IUF now supports customized images and CFS configurations for rebuilding nodes during the 'management-nodes-rollout' stage.
  See [`management-nodes-rollout`](operations/iuf/workflows/management_rollout.md#note-for-csm-v170) for further information.
* IUF can now reboot worker and storage NCNs without rebuilding them. See
  [Reboot NCNs with IUF](operations/node_management/Reboot_NCNs_iuf.md) for more information.

### Base platform component upgrades

| Platform Component           | Version |
|------------------------------|---------|
| Kubernetes                   | 1.32.5  |
| Kyverno                      | 1.13.4  |
| `Strimzi Kafka`              | 0.45.0  |
| `argo-workflow-controller`   | 3.4.5   |
| `argo-workflows`             | 3.4.5   |
| `bitnami-etcd` for clusters  | 3.5.21  |
| `etcd` on `ncn-mxxx`         | 3.5.18  |
| Ceph                         | 17.2.6  |
| `containerd`                 | 1.7.27  |
| `coredns`                    | 1.11.3  |
| `cray-certmanager`           | 1.17.0  |
| `cray-externaldns`           | 0.15.0  |
| `cray-metallb`               | 0.14.9  |
| `cray-node-problem-detector` | 0.8.20  |
| `cray-spire`                 | 1.5.5   |
| `cray-vault-operator`        | 1.22.5  |
| `cray-velero`                | 10.0.1  |
| Helm                         | 3.18.3  |
| `istio`                      | 1.26.0  |
| Kata                         | 3.17.0  |
| Keycloak                     | 21.1.1  |
| Kiali                        | 2.10.0  |
| `metrics-server`             | 0.6.3   |
| Nexus                        | 3.70.4  |
| `pause`                      | 3.10    |
| `postgres-operator`          | 1.10.1  |
| PostgreSQL                   | 15.2    |
| `sealed-secrets`             | 0.28.0  |
| `spire-intermediate`         | 1.0.1   |
| `tapms-operator`             | 1.9.1   |
| Cilium                       | 1.16.5  |

### Security improvements

* Spire node attestation can now be setup to use TPM chips on supported platforms, see [Enable TPM node attestation with Spire](operations/spire/Enable_TPM_node_attestation.md) for more information.
* The old version of the Spire server was removed to fully transition to the newer version of Spire.
* Updated all HMS services to point to latest upstream image and Go module dependencies. This resolved all currently known point-in-time CVE issues in HMS services.
* Pod Security Policies (PSP) have been removed. Pod Security Standards (PSS) Baseline policies are now enforced using Kyverno.
  For details and exceptions, see [What is new in the HPE CSM 1.7 release and above](operations/kubernetes/Kyverno.md#what-is-new-in-the-hpe-csm-17-release-and-above).
* Container image signature verification is enforced by Kyverno policies to enhance supply chain security;
  the policy remains flexible to allow sites to use their own signed containers.
  For details and exceptions, see [What is new in the HPE CSM 1.7 release and above](operations/kubernetes/Kyverno.md#what-is-new-in-the-hpe-csm-17-release-and-above).
* Platform components are upgraded to address critical and high vulnerabilities.
* Kyverno version is upgraded from 1.10.7 to 1.13.4; version 1.13.4 addresses CVEs and has additional features.
  For details, see the [Kyverno Changelog](https://github.com/kyverno/kyverno/blob/main/CHANGELOG.md)

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

* Updated Kyverno documentation.

### Rack Resiliency technology preview

> Rack Resiliency is available as a technology preview for evaluation purposes in a test environment;
> it **should not** be used in a production environment. For more details, see
> [RR is experimental](operations/rack_resiliency/README.md#attention-rr-is-experimental).

The optional [Rack Resiliency](operations/rack_resiliency/README.md) technology preview enhances CSM
resiliency by offering protection to the management plane against rack-level failures.

* Rack Resiliency is disabled by default
* See [Enabling Rack Resiliency During Install or Upgrade](operations/rack_resiliency/Enabling_RR_During_Install_or_Upgrade.md) for more details.
* For details on enabling this feature operationally outside of an install or upgrade, see
  [Enabling Rack Resiliency on a Running System](operations/rack_resiliency/Enabling_RR_on_running_system.md)
* Rack Resiliency cannot be disabled after it has been enabled.

## Noteworthy changes

* The default Kubernetes certificate validity period increased from 1 year to 3 years.
  For more details on the certificate validity period and how to modify it, see
  [Modify certificate validity period](operations/kubernetes/Cert_Renewal_for_Kubernetes_and_Bare_Metal_EtcD.md#modify-certificate-validity-period).
* Kyverno image verification policy is being shipped in `Enforce` mode. Container images that are unsigned will not be deployed.
  For more information on the policy, how to add exceptions, and how to allow third party signing keys, see
  [What is new in the HPE CSM 1.7 release and above](operations/kubernetes/Kyverno.md#what-is-new-in-the-hpe-csm-17-release-and-above).
* `PProf` debug support has been added to all remaining HMS services. See [Debugging With HMS `PProf` Images](troubleshooting/debugging_with_hms_pprof_images.md) for more information.
* IPv6 support on Customer Accessible Networks. See the [IPv6 Configuration Guide](operations/network/customer_accessible_networks/ipv6_configuration_guide.md) for more information.
* The `Weave` Container Networking Interface (CNI) has been replaced by Cilium.
    * A fresh install of CSM 1.7 will use Cilium by default.
    * Upgrading from CSM 1.6 to 1.7 will migrate the CNI from Weave to Cilium. See [Upgrade CSM and additional products with IUF](operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md) for more information.

## Test

* Modified `adjust k8s_nodes_ready_check.sh` to not fail when a node is in `Ready,SchedulingDisabled` state
* Modified `velero_backups_check.sh` to not fail if a newer, successful backup exists
* Modified `run_hms_ct_tests.sh` to handle concurrency better
* Fixed intermittent failures sometimes seen when running `check_key_id_in_jwks.sh`
* Added retry logic to `goss-postgresql-syncfailed.yaml` to prevent intermittent false positives
* Added retry logic to `postgres_clusters_running.sh` to prevent intermittent false positives
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
  [`session-setup` operator](operations/boot_orchestration/Operators.md#session-setup) now ignores invalid
  [xnames](glossary.md#xname) referenced by [session templates](operations/boot_orchestration/Session_Templates.md),
  fixing a bug that caused BOS [sessions](operations/boot_orchestration/Sessions.md) to be stuck in `pending` state.
* BOS logging is significantly more memory efficient, fixing a problem where logging on large scale systems
  could cause [BOS operator](operations/boot_orchestration/Operators.md) Kubernetes pods to be `OOMKilled`.
* When using the API or CLI to [Modify a BOS session template](operations/boot_orchestration/Manage_a_Session_Template.md#modify-a-session-template),
  it is no longer required to specify `boot_sets` in the update data (this fixes a regression bug present in CSM 1.6).
* Previously, the CSM 1.5.3 and CSM 1.6.1 releases included changes
  to resolve resource leaks found in the
  [PCS](glossary.md#power-control-service-pcs),
  [SMD](glossary.md#hardware-state-manager-smd),
  `hmcollector`, and [FAS](glossary.md#firmware-action-service-fas)
  services. This reduced instances of pods being restarted due to
  `OOMKilled` and failed liveness and/or readiness probes. These
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
* A bug was fixed in the `hmcollector-poll` service so that event subscriptions are no longer lost after updating Paradise BMC firmware. The service no longer needs to be restarted after performing firmware updates.
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
* Fixed an issue in the Ansible code in the `csm-config-management` repository in the [Version Control Service (VCS)](glossary.md#version-control-service-vcs)
  that caused some plays to end prematurely.
    * The bug was only observed when root SSH credentials were not set in Vault.
    * For more information on setting root credentials in Vault, see
      [Configure the root Password and SSH Keys in Vault](operations/CSM_product_management/Configure_the_root_Password_and_SSH_Keys_in_Vault.md).
* The [Cray Site Init (CSI)](glossary.md#cray-site-init-csi) tool had several bug fixes.
  For details, see [Bugfixes](introduction/csi_Tool_Changes.md#bugfixes).

## Deprecations

* Some parts of the [Cray Site Init (CSI)](glossary.md#cray-site-init-csi)
  tool are deprecated in CSM 1.7.0. For details, see
  [`csi` Tool Changes](introduction/csi_Tool_Changes.md).

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
* The `Weave` Container Networking Interface (CNI) has been removed and replaced by Cilium.
    * A fresh install of CSM 1.7 will use Cilium by default.
    * Upgrading from CSM 1.6 to 1.7 will migrate the CNI from Weave to Cilium. See
      [Upgrade CSM and additional products with IUF](operations/iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md)
      for more information.
* Some sub-commands of the [Cray Site Init (CSI)](glossary.md#cray-site-init-csi)
  tool are removed in CSM 1.7.0. For details, see
  [Removed sub-commands](introduction/csi_Tool_Changes.md#removed-sub-commands).

For more details and a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

* Systems running CSM 1.6 or earlier that fresh install CSM 1.7 must regenerate their
  management switch configuration because of the
  [Other behavior changes](introduction/csi_Tool_Changes.md#other-behavior-changes)
  made in the [Cray Site Init (CSI)](glossary.md#cray-site-init-csi) tool.
    * Systems upgrading from CSM 1.6 to CSM 1.7 **may ignore** this issue until the next
      CSM 1.7+ reinstall.

For a full list of known issues, see [Known issues](troubleshooting/README.md#known-issues).

### Security vulnerability exceptions in CSM 1.7

## Resolved CASTs

```text
CAST-30585 x1101c7s2b0n0 - Timeout at power state 60 . Hex: 3c . Flagged fields: warm_reset_cap rst_reset
CAST-30601 JT: Timeout at power state 60
CAST-30837 JT: BIOS-nC communication error
CAST-30883 JT: NCs unresponsive after chassis power cycle
CAST-30991 JT: chassis does not sense CDU after reboot
CAST-31057 JT: CMM FW will not allow power on of slots
CAST-31074 JT: CMM FW will not power on
CAST-31122 NCAR - GPU Power resource has detected a fatal fault
CAST-31168 JT: i2c bus lockup on CMM
CAST-31404 RFE: Ability to update SLES on NCNs rapidly
CAST-32054 CSI: The csi software doesn't check if network definitions overlap
CAST-32609 CSM 1.3.1 ncn-lifecycle-rebuild fails on cordoned nodes
CAST-34566 IUF appears to be unable to issue rolling reboot of NCNs without first installing a product stream
CAST-35696 BOS v2 should report the error instead of just 400 Bad Request
CAST-35972 CSM 1.3.1 ncn-personalization playbook bugs
CAST-36230 ProLiant DL325 Gen10 Plus - network issue at reboot
CAST-36628 csm-1.5.1: test "Validate token key ID exists in cray-spire jwks" fails
CAST-36695 Opaque whitelist files found in ansible repos
CAST-36707 CSM - DHCP troubleshooting doc
CAST-36720 csm-1.5.1: How to install patched images on ncn ceph nodes?
CAST-36727 Need SLES updates for CSM-1.5 CR 24.8.0 recipe
CAST-36834 csm 1.5.1 [Alvarez - TDS]: update to ncn-m001 stalls while waiting for cloud-init
CAST-36852 Update Gitea to version 1.19+
CAST-37040 CSCS - IMS image delete changes arch value to x86_64
CAST-37291 USS 1.1 pxc-operator deployment configures a cluster wide mutating webhook which breaks pre-existing PXC
CAST-37335 CSM-1.5 cray-power-control istio-proxy memory leak
CAST-37470 Security vulnerabilities in cipher used by cray-oauth2-proxie.  Please disable  3DES and TLS1.2 support
CAST-37617 [RZ] CSM 1.5.2 Installation: Post-PIT-swing failures in service externalIPs
CAST-37722 most compute nodes not doing cfs
CAST-37761 [VE] Gitea random password generation includes a /
CAST-37771 DNS NMN entries not created during CSM 1.6 install
CAST-38312 iuf management rollout - reboot doesn't work
CAST-38336 iuf management rollout fails if the list of nodes is "too long"???
CAST-38373 GOSS test failure for HSM
CAST-38383 Clean hardware inventory history
```

## All resolved issues

### Networking

```text
CASMNET-2086 Update default bootprep file to include UAN layer to configure the CHN on compute nodes
CASMNET-2090 CANU | in SCHD.py strip parent value if incorrect
CASMNET-2186 Support Cilium upgrade with multus
CASMNET-2187 Add metrics settings to cilium helm chart values
CASMNET-2189 Add Cilium dashboards to Grafana
CASMNET-2192 Add cilium scrape_configs to prometheus
CASMNET-2194 set up oauth2 proxy for hubble
CASMNET-2197 Add cilium images to the precache image list
CASMNET-2199 Add virtual service for hubble UI
CASMNET-2202 Figure out how to change k8s_primary_cni metadata on upgrade
CASMNET-2204 Add cilium goss tests and make both weave and cilium goss tests conditional
CASMNET-2212 Switch to install Cilium by default (not weave) in cloud-init
CASMNET-2215 Determine ordering of the migration of weave -> cilium in the IUF upgrade workflow
CASMNET-2259 CSM ships with net.ipv4.conf.all.rp_filter=2
CASMNET-2276 NCN rebuild should not restore the Weave Multus configuration with Cilium enabled
CASMNET-2285 Python: Switch ACLs between Mountain Cabinets
CASMNET-2289 Python: CANU NMN Isolation Tests
CASMNET-2294 Remove Weave goss tests
CASMNET-2299 Create CANU 1.7 templates
CASMNET-2300 CSM 1.7 Aruba firmware selection and plumbing
CASMNET-2301 CANU testing uses the wrong VRF name
CASMNET-2302 Cilum kubeProxyReplacement value must be true/false
CASMNET-2304 Cannot SSH to spine switches over the CMN
CASMNET-2305 NTP is blocked by ACLs and configured for the wrong VRF
CASMNET-2306 Managing eBGP Route Advertisement with MetalLB
CASMNET-2309 CANU Test: 'KeyError' observed in BGP tests
CASMNET-2310 IPv6 addressing template updates
CASMNET-2317 CANU: Modify the CCJ to allow the validate command line in the JSON file
CASMNET-2318 Add switch and network information to MetalLB data
CASMNET-2319 Modify SLS utils to all retrieval and setting of system default route
CASMNET-2322 Pick up latest cray-postgres in cray-dns-powerdns chart for CSM 1.7
CASMNET-2323 Pick up latest cray-postgres in cray-dhcp-kea chart for CSM 1.7
CASMNET-2327 Test and Verify SSH over IPv6
CASMNET-2329 Network attachment definition for DNS and LDAPS
CASMNET-2331 canu switch config updates for IPv6 addressing
CASMNET-2332 CSM 1.7 templates don't work in the RPM version of canu
CASMNET-2334 CANU: Create tests scripts for CSM 1.5 and above
CASMNET-2338 Define list of services available on management nodes
CASMNET-2339 CANU: Fix json schema checks for SLS VlanRange
CASMNET-2341 Develop ACLs for services between Management and Managed nodes
CASMNET-2343 Fix CVE's in artifactory.algol60.net/csm-docker/stable/quay.io/cilium/hubble-ui:v0.13.1
CASMNET-2345 DOCS: IPv6 support -Add/Remove node procedures
CASMNET-2349 canu test fails with IPv6 data in SLS
CASMNET-2350 cani - Add support for IPv6 enabled SLS schema
CASMNET-2353 CANU: Release NMN Isolation and IPv6 to CSM
CASMNET-2355 IPv6 addressing support for fresh installs and existing deployments
```

### IUF

```text
CASM-3864 As a System Admin, I do want to clean up files in /tmp directory from nodes in iuf/nls workflows
CASM-5599 While getting workflows status in IUF , skip workflows with Unknown status
CASM-5623 Provide default path for --site-vars in iuf-cli
```

### Cray SAT

```text
CRAYSAT-1517 LANL-tycho sat slscheck fails to report on mismatches for components in CDU cabinets
CRAYSAT-1584 Add HSM lock status to output of "sat status"
CRAYSAT-1603 Develop automated functional tests for SAT based on avocado
CRAYSAT-1604 Add configurable retries to API requests in SAT
CRAYSAT-1619 Prompt individually for each image that already exists in sat bootprep
CRAYSAT-1652 Include skipped items in sat bootprep report
CRAYSAT-1690 sat bootprep - Always print report even when some items fail
CRAYSAT-1784 Stop resolving branch names to commit hashes in "sat bootprep"
CRAYSAT-1846 Log HTTP request bodies at debug level
CRAYSAT-1886 Ceph takes a long time to become healthy after system reboot
CRAYSAT-1887 Repeated libceph errors delay shutdown of Kubernetes worker nodes during sat bootsys
CRAYSAT-1930 Drop the "Arch" field from "sat status" for NodeBMC
CRAYSAT-1938 Create functional tests for "sat bootprep" in csm-testing
CRAYSAT-1939 Create functional tests for "sat status" in csm-testing
CRAYSAT-1949 Add ability to specify skip or overwrite of existing items in bootprep file
CRAYSAT-1952 Create functional tests for "sat showrev" in csm-testing
CRAYSAT-1953 Create functional tests for "sat nid2xname" and "sat xname2nid" in csm-testing
CRAYSAT-1957 Create functional tests for "sat firmware" in csm-testing
CRAYSAT-1958 Include name of snapshot created by "sat firmware" in INFO log message
CRAYSAT-1959 Create functional tests for "sat init" in csm-testing
CRAYSAT-1961 Add INFO-level log message to output of "sat slscheck" when consistent
CRAYSAT-1965 Increment the version of cray-sat included in CSM 1.7.0 release
CRAYSAT-1969 Add "sat bootprep" support for CFS configuration layer "source" property
CRAYSAT-1977 Investigate CryptographyDeprecationWarning message
CRAYSAT-1979 add visibility for environment variables inside of container
CRAYSAT-1980 Create image creation tests for "sat bootprep" in csm-testing
CRAYSAT-1981 Create BOS session template tests for "sat bootprep" in csm-testing
CRAYSAT-1982 Resolve dependabot alerts for cryptography
CRAYSAT-1985 build failure due to change in location of k8s
CRAYSAT-1987 Resolve dependabot alerts for jinja2
CRAYSAT-1988 Create unit tests for duplicate image prompting
CRAYSAT-1991 Support debug-on-failure of cfs v3 in sat bootprep
CRAYSAT-1994 local variable 'skipped_images' referenced before assignment
CRAYSAT-1998 Resolve dependabot alert for requests
CRAYSAT-1999 Fix debug_on_failure error when using cfs v2
CRAYSAT-2000 Add "sat bootprep" support for commit hash in source-based CFS configuration layer
CRAYSAT-2003 Resolve dependabot alert for urllib3
CRAYSAT-2005 Improve coverage of skip/overwrite behavior in "sat bootprep" functional tests
```

### Security and Kyverno Policies

```text
CASMSEC-495 kyverno-policies needs updates for deprecations.
CASMSEC-512 Security:Kyverno baseline policy violations for different CSM components
CASMSEC-518 As a developer, I need to ensure kyverno upstream baseline policies chart is optimized for exceptions
CASMSEC-524 Investigation: As an architect, I need to investigate which version of Kyverno to be supported in CSM v1.7.0
CASMSEC-525 Changes: As a developer, I need to perform the code changes required to support the finalized Kyverno version on CSM v1.7.0.
CASMSEC-528 Report generation: Generate list of complete Baseline policy violations
CASMSEC-529 Create Jira tickets and coordinate with service owners to address Baseline policy violations
CASMSEC-534 Prepending registry.local to container images is complicated
CASMSEC-535 As a developer, I want to ensure the trust between Kyverno and Nexus
CASMSEC-537 As a developer, I want to ensure the container images are signed and verified during CSM upgrades
CASMSEC-538 As a developer, I want to ensure the container images are signed and verified during CSM fresh install
CASMSEC-539 As a developer, I want to ensure the container images are signined and verified in high availability across reboots
CASMSEC-540 As a developer, I want to do demonstrate container image signing and verificarion for CSM 1.7
CASMSEC-542 Policy exception needed for argo/automate-*
CASMSEC-545 Ensure Kyverno baseline Pod Security Standards policies in enforce mode
CASMSEC-547 Starlord: nexus pod in IPBO
CASMSEC-548 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/bitnami/kubectl:1.31.0
CASMSEC-549 PolicyException for sma/opensearch-bootstrap-*
CASMSEC-550 PolicyExceptions for IUF Workflow Templates
CASMSEC-552 Provide validation exceptions in Container Image Signature Validation Policy for unsigned container images released in Slurm
CASMSEC-553 Provide validation exceptions in Container Image Signature Validation Policy for unsigned container images released in PBS
CASMSEC-554 Provide validation exceptions in Container Image Signature Validation Policy for unsigned container images released in Slingshot suite of products
CASMSEC-555 Move Image verification policy after nexus
CASMSEC-559 PolicyExceptions for IUF post-install checks and managed-node-rollout stages
CASMSEC-562 Provide Image verification policy in Enforce mode
CASMSEC-563 Image verification policy didn't get values from the customizations.yaml file
CASMSEC-564 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/bitnami/kubectl:1.32.3
CASMSEC-565 CSM services are not ready yet for Kyverno baseline policy enforcement
CASMSEC-566 Ensure runtime validation using Kyverno should work with DST signed images
CASMSEC-569 Investigate if IUF installs or upgrades require further exceptions
CASMSEC-571 observation  for rack-resiliency and cos-config-service
CASMSEC-572 Provide validation exceptions in Container Image Signature Validation Policy for unsigned container images released in Diags
CASMSEC-573 IUF exceptions for new worker and storage node reboot stage
CASMSEC-574 Exceptions to be modified for ceph-csi-cephfs-nodeplugin and ceph-csi-rbd-nodeplugin
CASMSEC-576 vShasta: 1.7.0-alpha.23 install fails, kyverno blocks new hostPath in velero 1.16.1
CASMSEC-577 Errors displayed after csm only upgrade
CASMSEC-579 starlord: kyverno policy violations during post-install-check
CASMSEC-584 DOCS: Add additional documentation support in Kyverno for using image signatures
CASMSEC-590 DOCS: Point kyverno document under noteworthy-changes in the docs-CSM release notes
```

### Upgrades

```text
CASM-5240 Upgrade external-dns for 1.7
CASM-5241 Upgrade vault-operator for CSM 1.7
CASM-5285 Update prodmgr to use 1.0.1 version of product-deletion-utility
CASM-5650 Update cray-iuf helm chart to  latest (5.1.2)
CASM-5651 Update cray-nexus-setup image in cray-nexus helm chart to latest
CASMHMS-6512 Update cray-etcd-base chart version for CSM 1.7.0
CASMMON-481 Upgrade latest Victoriametrics version in cray-sysmgmt-health
CASMMON-482 Upgrade node exporter in victoria-metrics-k8s-stack  for cray-sysmgmt-health
CASMMON-484 Upgrade kube-state-metrics in victoria-metrics-k8s-stack  for cray-sysmgmt-health
CASMMON-488 Upgrade grafana to 11.5 version in  cray-sysmgmt-health
CASMMON-501 Upgrade grafana to 11.5 version in  csm pit node
CASMMON-514 Upgrade grafana clusterview panels plugins in SMH
CASMMON-543 upgrade artifactory.algol60.net/csm-docker/stable/docker.io/bitnami/kubectl:1.32.3
CASMNET-2280 Update Cilum to 1.16.5
CASMPET-6947 Upgrade cephcsi in CSM 1.7
CASMPET-7335 Upgrade the cray-postgres-operator
CASMPET-7346 Upgrade node-problem-detector for 1.7
CASMPET-7368 Upgrade cert-manager for CSM 1.7
CASMPET-7376 Upgrade Kiali Operator for CSM 1.7
CASMPET-7381 Upgrade sealed-secrets for CSM 1.7
CASMPET-7382 Upgrade strimzi-kafka-operator for CSM 1.7
CASMPET-7393 Upgrade nexus for CSM V1.7.0
CASMPET-7503 Investigate ceph version to be upgraded for CSM 1.7.0
CASMPET-7504 Update MetalLB kubectl version to 1.24.17
CASMPET-7554 Upgrade velero to 1.16.1
CASMPET-7580 Complete Istio Upgrade to 1.26.0: Enable logging for undeploying charts and deleting secrets
CASMPET-7598 Support stage wise upgrade go k8s from 1.24 to 1.32
CASMSMF-8464 Upgrade sma grafana to 11.5.2
CASMSMF-8515 Upgrade grafana panels plugins in SMA
MTL-2548 Upgrade platform-utils to support python 3.11
MTL-2577 node-images package sweep + kernel upgrade
```

### DOCS

```text
CASM-5635 DOCS: Add management-rollout-strategy  Rolling Reboot of NCNs(worker,storage) (currently a manual process)
CASM-5636 DOCS: jq unable to process the large output
CASM-5652 DOCS: Updating IUF diagram flow for CSM upgrade to include cilium migration
CASMCMS-8131 DOCS: Remove BOS V2 Verify Declarative Mode
CASMCMS-8164 DOCS: BOS: Allow the etag to not be specified in the boot set
CASMCMS-8802 DOCS: gitea restore needs to emphasize the importance of PVC data export
CASMCMS-8843 DOCS: BOS - no useful feedback when attempting to boot an hsm locked node
CASMCMS-8866 DOCS: Update BOS import tool to check for running sessions
CASMCMS-8867 DOCS: Update CFS import tool to check for running sessions
CASMCMS-9025 DOCS: Remove --include-v1 option from BOS exporter, prerequisites.sh
CASMCMS-9050 Document how to set up a key in Vault that can be used to decrypt SOPS secrets.
CASMCMS-9235 DOCS: Remove workaround for CASMCMS-9234 from CSM 1.7 upgrade scripts
CASMCMS-9242 DOCS: BOS: Make CAPMC/PCS timeout configurable, like with CFS
CASMCMS-9253 DOCS: IMS artifacts remained orphaned with CSM 1.5.2 systems
CASMCMS-9260 DOCS: Slow IMS image jobs: Document reason and workarounds
CASMCMS-9299 DOCS: Improve VCS password change documentation
CASMCMS-9300 DOCS: Linting
CASMCMS-9306 Document SOPS use with tenant-specific host_vars and global_vars with Ansible
CASMCMS-9318 Console MT - Update documentation for new apis
CASMCMS-9329 DOCS: Document "update many CFS components" CLI option
CASMCMS-9332 DOCS: Document "update many CFS components" CLI option in release notes
CASMCMS-9336 DOCS: importing cfs data fails with "--clear-cfs" option
CASMCMS-9358 DOCS: Known issue: BOS session setup operator failure loop
CASMCMS-9359 DOCS: Release notes: Document fix for CASMCMS-9355
CASMCMS-9361 DOCS: Release notes: Document fix for CASMCMS-9357
CASMCMS-9384 TESTS: cmsdev should warn if docs-csm RPM is not installed
CASMCMS-9400 DOCS: Update 1.7 release notes for IMS fixes
CASMCMS-9423 DOCS: Remove/modify DVS/CPS references
CASMCMS-9427 DOCS: Release notes: BOS: boot_sets no longer required when patching session templates
CASMCMS-9435 DOCS: Validate the doc "Set up passwordless SSH"
CASMCMS-9436 DOCS: Create script to export ssh configuration into Vault
CASMCMS-9437 DOCS: Create script to import ssh configuration from Vault
CASMCMS-9442 DOCS: Python script linting
CASMCMS-9443 DOCS: Document CFS csm.ssh_config role; add to release notes
CASMCMS-9448 DOCS: Update release notes about removal of long-deprecated csm-config plays
CASMCMS-9449 Fix console API document
CASMCMS-9457 DOCS: Improve CFS "source" documentation in docs-csm
CASMCMS-9458 DOCS: update IMS remote build node configuration doc with kernel params
CASMHMS-6258 Remove last few references to capmc from our docs
CASMHMS-6362 DOCS: Add pprof support to hmcollector-poll
CASMHMS-6366 DOCS: Document pprof in the CSM admin guide
CASMHMS-6370 DOCS: Document resetting BIOS factory defaults for Paradise
CASMHMS-6371 DOCS: Update Add a Standard Rock Node doc to remove quotes around NID
CASMHMS-6432 DOCS: Move PCS Docs
CASMHMS-6483 DOCS: Document Antero/ParryPeak power capping issue in CSM docs
CASMHMS-6501 Document scaling/resource improvements in CSM 1.7.0 release notes
CASMINST-5657 DOCS: As a system admin, I want common WorkflowTemplate to sync secret to Argo namespace
CASMINST-6893 DOCS: Weave troubleshooting
CASMINST-6939 DOCS: Audit procedure does not update cloud-init data correctly
CASMINST-7102 DOCS: IUF master node upgrade backup fails if node has been removed from cluster
CASMINST-7110 DOCS: Fix IUF diagram for CSM upgrade
CASMINST-7138 DOCS: Prepare for upgrade procedures should link to previous release
CASMINST-7165 DOCS: Linting
CASMINST-7178 DOCS: Remove Rapid Rebuild content
CASMINST-7209 DOCS: Fix RPM naming in NCN kdump documentation
CASMINST-7215 DOCS: PosgreSQL upgrade gets stuck with HTTP 403 in CSM 1.7 upgrade
CASMINST-7236 DOCS: Prevent invalid VCS password generation
CASMINST-7245 DOCS: Do not upgrade platform-utils RPM during prerequisites.sh
CASMINST-7251 DOCS:Remove Spire PostgreSQL backup procedure from documentation
CASMINST-7252 DOCS: De-dupe pre-installation steps
CASMINST-7253 DOCS: update IUF diagrams because FW update step move
CASMINST-7259 DOCS: Reset CSM 1.7.0 release notes to pristine status
CASMINST-7274 DOCS: Create 1.6.2 release notes; link release notes to main known issues list
CASMINST-7275 DOCS: Update 1.6.2 release notes for your tickets
CASMINST-7298 DOCS: goss_tests_fails_with_connection_refused.md
CASMINST-7302 DOCS: ims_image_delete_loses_arch.md
CASMINST-7305 DOCS: initrd.img.zx_not_found.md
CASMINST-7307 DOCS: Remove "iuf_unable_to_run_next_stage.md" from known issues as it fixed in CSM V1.6.1
CASMINST-7309 DOCS: kubernetes_node_rootFS_out_of_space.md
CASMINST-7310 DOCS: mellanox_lacp_individual.md
CASMINST-7314 DOCS: pcs_and_capmc_transaction_size_limitation.md
CASMINST-7317 DOCS: qlogic_driver_crash.md
CASMINST-7325 DOCS: wait_for_unbound_hang.md
CASMINST-7328 DOCS: upload-ncn-images.sh script missing from 1.6 and 1.7 docs-csm
CASMINST-7329 DOCS: IUF ncn-m001 rollout fails with syntax errors
CASMINST-7341 DOCS: Setting the ims image of an NCN fails silently with argo
CASMINST-7342 DOCS: update_tags.sh script uses wrong version for kubectl-shell image
CASMINST-7351 DOCS: remove references to UAS and UAI
CASMINST-7360 DOCS: DBG message becomes elements in sets array during rebuild-worker-nodes
CASMINST-7361 DOCS: Fix typo in Python script message
CASMINST-7370 DOCS: API docs generator does not fail on inaccessible URL
CASMINST-7404 DOCS: Linting
CASMMON-468 DOCS: update-customizations.sh breaks customizations template for 1.6 > 1.6 and 1.6 > 1.7 upgrades
CASMMON-545 DOCS: Improve Redfish exporter docs for CSM-1.7
CASMMON-546 DOCS: Document newly added Cilium monitoring for CSM-1.7
CASMMON-549 DOCS: IUF Timing dashboard changes needs to be updated
CASMNET-2277 DOCS: update CAN reference to CMN in PowerDNS docs
CASMNET-2287 DOCS: Tests: Switch ACLs between Mountain Cabinets
CASMNET-2288 DOCS: update/fixes for DHCP troubleshooting doc
CASMNET-2290 DOCS: NMN Isolation tests
CASMNET-2293 DOCS: Request for documentation changes:  mgmt network firmware upgrade
CASMNET-2297 DOCS: CSI does not include edge switches in MetalLB configuration
CASMNET-2344 DOCS: Cilium migration cannot be rerun in the event of a failure.
CASMNET-2357 DOCS: Apply missing network-attachment-definition during Cilium migration
CASMNET-2360 DOCS: Exclude SMA kafka network policies from Cilium migration
CASMPET-7306 DOCS: Edit the storage node upgrade workflow for the ceph version upgrade in CSM 1.7.0
CASMPET-7311 DOCS: Update multi-attach troubleshooting procedure
CASMPET-7362 DOCS: Remove all documentation referencing the old spire server
CASMPET-7364 DOCS: Add note in release notes that old spire is being removed
CASMPET-7377 DOCS: Review prerequisites.sh script for CSM v1.7.0
CASMPET-7384 DOCS: TAPMS CRD Allows for KMS Transit Engine Key of Any Name; Disagrees with current documentation
CASMPET-7385 DOCS: Clear old SquashFS before storage node upgrade
CASMPET-7389 DOCS: Restarting job fails - batch.kubernetes.io/controller-uid label needs to be removed
CASMPET-7398 DOCS: Create a Script to set the proper Pod resource requests for smaller CSM systems (ex. TDS)
CASMPET-7409 DOCS: Cray-postgres-operator fails in prerequisites.sh
CASMPET-7415 DOCS: Remove POST_CSM_ENABLE_PSP state from csm-upgrade.sh
CASMPET-7416 DOCS: Improve xname validation script and instructions
CASMPET-7440 DOCS: vShasta: patronictl error in fix-postgres.sh in prerequisites
CASMPET-7441 DOCS: IMS is temporarily unreachable during NCN upgrade
CASMPET-7446 DOCS: As ISCSI Developer , I Want to apply the WAR of creation of NMN entries while configuring SBPS
CASMPET-7452 DOCS: Create documentation for how to turn on TPM node Attestation for x86 nodes
CASMPET-7458 DOCS: create_rgw_buckets.sh script mismanages known_hosts on ncn-s001 during upgrade
CASMPET-7464 Create TPM disablement script and update TPM docs
CASMPET-7498 DOCS: Fix update-customizations to remove configinline
CASMPET-7507 DOCS: CSM 1.4 documentation: URL update needed for Postgres WAL Event link
CASMPET-7552 DOCS: manifests_dir path is incorrect in upgrade_control_plane.sh
CASMPET-7556 DOCS: Document on how to create HSM groups before bootprep time
CASMPET-7582 DOCS: Remove PodSecurityPolicy from kube-apiserver
CASMPET-7583 DOCS: Complete Istio Upgrade to 1.26.0: Restart StatefulSets
CASMPET-7584 DOCS: Cannot execute cleanup.sh - doesn't have execute permissions
CASMPET-7585 DOCS: Exit when IMS is unreachable during NCN upgrade
CASMPET-7586 DOCS: cleanup.sh can't find cleanup.py
CASMPET-7596 DOCS: Address CAST-38296
CASMPET-7599 DOCS: Postgres cluster check failure during the upgrade
CASMPET-7603 DOCS: Postgres_reinit script issue with lagged replicas
CASMPET-7607 DOCS: undeploy spire chart in prerequisites
CASMPET-7608 DOCS: Add kubectl wait for nexus after worker drain
CASMPET-7609 DOCS: Add log prefix to upgrade_k8s.sh so IUF picks up output
CASMPET-7623 DOCS: k8spsp* CRDs should be removed
CASMPET-7628 DOCS: Create script to re-run iSCSI layer on NCN workers
CASMSEC-398 DOCS: Port security hardening guide to 1.4, 1.5+
CASMSEC-413 DOCS: CIS: Ensure that the --audit-log-maxage argument is set to 30 or as appropriate
CASMSEC-415 DOCS: CIS: Ensure that the --audit-log-maxsize argument is set to 100 or as appropriate
CASMSEC-516 As a developer, I want my Documentation to be reviewed and approved
CASMSEC-517 DOCS: As a developer, I need to ensure PSP migration documentation is provided for customer-deployed services
CASMSEC-527 DOCS: As a developer, I need to Change/Include information pertaining upgrade Kyverno version in CSM 1.7.0
CASMSEC-541 DOCS: As a developer, I want to do the provide a clear documentation for container image signing and verification policy
CASMSEC-575 DOCS: Customizations is not applied in CSM 1.7 upgrade
CASMSEC-580 DOCS: Modify docs-csm 'Adding images' section to upload signatures
CASMSEC-581 DOCS: Documentation on setting signing infrastructure for yum repos
CASMSEC-582 DOCS: Document a known issue about image verification policy during CSM upgrade
CASMSMF-8593 Create documentation for SMA victoriametrics documentation grafana dashboard
CASMSMF-8594 DOCS: Updates docs with Flow changes
CASMSMF-8606 DOCS: SMA charts fail to deploy due to apparent mismatch with k8s APIs
CASMTRIAGE-7511 Docs: sbps_marshall docs reference URL that doesn't redirect correctly
CASMTRIAGE-7668 DOCS: Lemondrop: iuf update-cfs-config failed with ERROR
CASMTRIAGE-7705 DOCS: iuf management-rollout to canary worker node fails without MEDIA_DIR and refuses to run on canary node
CASMTRIAGE-7719 DOCS:ceph configuration "ceph.client.kube.keyring" is missing which is required to add storage to remote build node
CASMTRIAGE-7734 DOCS: FASUpdate.py recipe troubles for ERoT and nodeAccUC  (Vidar)
CASMTRIAGE-7735 DOCS: Tyr: cray_shasta_64k aarch rpm stuck uploading during deliver-product
CASMTRIAGE-7739 DOCS: ncn-upgrade-master-nodes.sh ncn-m001 failed due to time synch problem
CASMTRIAGE-7758 DOCS: cray-console-node pods are in CLBO on drax
CASMTRIAGE-7763 DOCS: cray-console-node pods intermittently are in  CLBO state
CASMTRIAGE-7918 DOCS: WASP: ncn-m002 rebuild is looping trying to join the K8s cluster
CASMTRIAGE-7926 DOCS: WASP: Unable to get workflow status after intermediate termination
CASMTRIAGE-7950 DOCS: cannot delete tenant via custom resource yaml file
CASMTRIAGE-7980 DOCS: Drax: cray-spire is unhealthy
CASMTRIAGE-7981 DOCS: "istio-proxy too many open files" workaround improvements
CASMTRIAGE-7986 DOCS: pre-upgrade-status.sh incorrectly handles --hsn-not-required flag
CASMTRIAGE-8008 DOCS: wasp: ncn-gateway-test.sh failing
CASMTRIAGE-8069 DOCS and code: arp cache tuning topic has errors
CASMTRIAGE-8077 DOCS: IUF workflow does not start after the re-installation of Keycloak
CASMTRIAGE-8092 DOCS: Document enable_chn.yml CFS layer in SAT management-bootprep.yaml file
CASMTRIAGE-8095 DOCS: Possible removal of documentation page needed.
CASMTRIAGE-8097 DOCS: cray-uas-mgr still installed in CSM 1.6.1
CASMTRIAGE-8203 DOCS: Baldar : NCN heathchecks fails with cray-spire
CASMTRIAGE-8204 DOCS: Secret not getting created for tapms tenant
CASMTRIAGE-8276 DOCS: IUF hotfix for cray-nexus-setup broke upgrades for 1.6.0/1.6.1/1.6.2
CASMTRIAGE-8286 DOCS: wasp: hung during spire request-ncn-join-token rollout in prerequisites.sh
CASMTRIAGE-8292 DOCS: wasp: rollout of keycloak hung during prerequisites.sh
CASMTRIAGE-8295 DOCS: Wasp - Etcd failures due to PSP related issues.
CASMTRIAGE-8297 DOCS: wasp: rollout of ncn-m002 hung
CASMTRIAGE-8327 DOCS: Compute nodes rollout failing due to iscsi issue
CASMTRIAGE-8332 DOCS: "postgres-pod" in namespace "default" exists and cannot be imported into the current release
CASMTRIAGE-8339 DOCS: POST CSM Upgrade Validation failing at istio-ingressgateway
CASMTRIAGE-8340 DOCS: gamora: platform-utils needs to be upgraded before node rollout
CASMTRIAGE-8373 DOCS: drax: prerequisites.sh, UPDATE_CRAY_POSTGRES_OPERATOR_CRDS failing.
CASMTRIAGE-8378 DOCS: ncn-m002 rebuild loops at cloud init
CASMTRIAGE-8379 DOCS: platform-utils RPM gets updated on ncn-m00[2-3], but not ncn-m001
CASMTRIAGE-8424 DOCS: Starlord:  Upgrade activity failing at pre-install check
CASMTRIAGE-8425 DOCS: prerequisites.sh error at DELETE_CRAY_ISTIO_HELM_SECRETS
CASMTRIAGE-8426 DOCS: preinstall check display error at PREPARE_KUBEADM
CASMTRIAGE-8427 DOCS: istio-ingressgateway cpu requests are too low on TDS systems
CASMTRIAGE-8434 DOCS: IUF failure not showing in the argo
CASMTRIAGE-8448 DOCS: platform-utils at 1.8.2-1.noarch instead of 1.8.3-1.noarch
CASMTRIAGE-8451 DOCS: vShasta: cilium migration fails, Kyverno blocks Argo pod
CASMTRIAGE-8466 DOCS: management rollout of ncn-m001 error
CASMTRIAGE-8473 DOCS: vShasta: cilium migration step delete-cilium-node-config is not idempotent
CASMUSER-2660 FEATURE:: Setup HSN macvlan/ipvlan by default and deprecate WLM script and docs
CRAYSAT-1903 DOCS: BOS sessions list command in doc should be modified to give only Running sessions
CRAYSAT-1906 DOCS: Remove "sat bootsys shutdown --stage capture-state" command from shutdown procedure
CRAYSAT-1986 DOCS: Update shutdown/boot ncn-power stages new output
CRAYSAT-1995 DOCS: Need to remove DVS/CPS references in compute-and-uan-bootprep.yaml
HPCCHT3-5144 DOCS: Document how SDU should be reinitialized following a master node upgrade
MTL-2126 DOCS: Update boot trim doc - refer to script
MTL-2571 DOCS: Remove references to "COS", "CPS" and UAN as a standalone product stream in docs-csm for CSM 1.7.0
USS-2317 DOCS: Document multi-tenancy VNI enforcement
USS-4483 Update Cray-HPE/docs-csm to remove cos-prechecks-for-worker-reboots.yaml
```

### CASM

```text
CASM-4572 Add an argo workflow for the Rolling Reboot of NCNs (currently a manual process)
CASM-5037 Setting Kyverno policies for replacing Kubernetes PSP
CASM-5264 Incorrect variable being used in Warning statement
CASM-5267 Avoid infinite loop while uploading artifacts with cray-nexus-setup image
CASM-5499 As a developer, I need to add conditional enablement of RRS (Rack Resiliency Service)
CASM-5664 Policy exception for upgrade-k8s-job
CASM-5671 Rack resiliency Ansible should not default to assuming it is enabled
CASM-5672 Rack resiliency Ansible should skip storage steps if placement validation fails
CASM-5673 Improvements in csm-config
CASM-5675 The length of zone name to be fixed.
```

### CASMCMS

```text
CASMHMS-6578 CAST-38383: Clean redundant "Detected" events from hardware inventory history
CASMHMS-6583 bump HMS chart versions to pick up new etcd-base chart 1.3.1
CASMHMS-6588 DOCS: Misc final docs changes for CSM 1.7.0
CASMHMS-6589 DOCS: Followup doc changes to CPU/GPU events
CASMCMS-7866 Check cray-bos-db pod permissions
CASMCMS-7902 BOS session setup operator fails with an OOM error when loading large files
CASMCMS-7979 cfs-hwsync-agent logs that it discovers components before registering them
CASMCMS-8022 IMS - fix deprecated code and 3rd party modules
CASMCMS-8620 Retest BOS v2 for PCS integration at scale
CASMCMS-8666 Do not include name field in example BOS v2 session template
CASMCMS-8703 TESTS: Add CFS node personalization to the barebones image boot test
CASMCMS-8782 IMS - swap in kata:3.2.0 to latest
CASMCMS-8893 AEE Needs an init script to automatically set the global CFS vault key for SOPS
CASMCMS-8923 OPTIMIZATION: Better cleanup of remote resources on irregular exit
CASMCMS-8939 Make sftp work for remote customization jobs
CASMCMS-8942 Add "update many CFS components" option to Cray CLI
CASMCMS-8965 CAST-35696 BOS v2 should report the error instead of just 400 Bad Request
CASMCMS-9024 Load DST signing keys from K8S secret for image recipe builds
CASMCMS-9036 Remove sshd from cray-cfs-operator image
CASMCMS-9085 Console MT - Add api endpoints for interactive and log console access
CASMCMS-9086 Console MT - Make console api tenant aware.
CASMCMS-9149 Cray-bos: switch to HorizontalPodAutoscaler autoscaling/v2
CASMCMS-9150 Cray-cfs-api: switch to HorizontalPodAutoscaler autoscaling/v2
CASMCMS-9180 Move bos-reporter into its own repository
CASMCMS-9181 TESTS: cmsdev: Should record installed version of Cray CLI RPM
CASMCMS-9201  IMS artifacts remained orphaned with CSM 1.5.2 systems
CASMCMS-9203 Post install upgrade job of cms-ipxe is not idempotent
CASMCMS-9228 CFS Configurations Need to Store Tenant Information in the CFS API
CASMCMS-9229 CFS Operator Needs to Perform VAULT_TOKEN lookup whenever a Session is Scheduled with a Tenant Name
CASMCMS-9237 Pull full code changes for CASMCMS-9225 into CSM 1.7
CASMCMS-9239 Allow OPA Changes for CFS for Configurations Creation Endpoint
CASMCMS-9241 cfs-debugger: 'NoneType' object has no attribute 'group'
CASMCMS-9251 Build bos-reporter RPM for aarch64 and x86_64
CASMCMS-9252 Update node-images for CSM 1.7 for bos-reporter, cfs-debugger, cfs-state-reporter RPMs
CASMCMS-9254 Publish bos-reporter by SLES version
CASMCMS-9255 BOS: Image Regular Expression Fragile
CASMCMS-9258 cfs-debugger fails to install during ARM image customization
CASMCMS-9262 Update RPM lists in csm-config
CASMCMS-9263 CFS batcher sad on large scale systems
CASMCMS-9265 BOS: Add type annotations (part 1)
CASMCMS-9266 SECURITY: CVEs in console-node, cray-console-operator
CASMCMS-9267 TESTS: SECURITY: Resolve CVEs in cmstools
CASMCMS-9269 BOS: Add type annotations (part 2)
CASMCMS-9270 BOS: Validate nonexistent template -> internal server error
CASMCMS-9271 BOS: Add type annotations (part 3)
CASMCMS-9272 BOS: Add type annotations (part 4)
CASMCMS-9273 BOS: Add type annotations (part 5)
CASMCMS-9275 BOS: Add type annotations (part 6)
CASMCMS-9276 BOS: Add type annotations (part 7)
CASMCMS-9277 BOS: Add type annotations (part 8)
CASMCMS-9282 Update Alpine versions for CMS repos that are on 3.15 or earlier
CASMCMS-9283 Address CVEs in cfs-ara
CASMCMS-9284 BOS: Add/improve type annotations (part 1); fix syntax error
CASMCMS-9285 BOS: Add/improve type annotations (part 2)
CASMCMS-9286 BOS: Add/improve type annotations (part 3)
CASMCMS-9287 BOS: Address some non-fatal pylint complaints
CASMCMS-9288 bos.operators.base - Unhandled exception detected: Attempted to access uninitialized API client
CASMCMS-9289 BOS API client error constructing URLs
CASMCMS-9290 BOS exception handling BSS response
CASMCMS-9291 BOS: Add/improve type annotations (part 4)
CASMCMS-9292 cfs-trust: Fix BSS meta-data query
CASMCMS-9293 Teach cfs-trust to be a little more patient
CASMCMS-9294 BOS: Add/improve type annotations (part 5)
CASMCMS-9295 BOS: Add/improve type annotations (part 6)
CASMCMS-9296 BOS: Add/improve type annotations (part 7)
CASMCMS-9297 BOS: Add/improve type annotations (part 8)
CASMCMS-9298 Investigate duplicates cray-keycloak-setup
CASMCMS-9319 Work with QE team on how the feature works
CASMCMS-9320 Add "app.kubernetes.io/instance: cray-bos" label to cray-bos-db pod
CASMCMS-9328 IMS: Store Artifact logs after signing key test failure
CASMCMS-9330 BOS: Log name of new log level, rather than integer value
CASMCMS-9331 BOS: Add/improve type annotations (part 9)
CASMCMS-9333 cfs-trust changed how it indicates missing cfs_public_key
CASMCMS-9335 cfs session patch fails to update Job ID causing session to remain in pending state
CASMCMS-9337 bos-reporter: Need to build RPMs for Python 3.6 & 3.9
CASMCMS-9338 cfs-debugger: Restore RPM builds for Python 3.9
CASMCMS-9339 BOS: Add/improve type annotations (part 10)
CASMCMS-9340 BOS: Improve efficiency by using Redis mget/mset
CASMCMS-9346 Improve BOS type annotations for components endpoint
CASMCMS-9348 TESTS: BOS: Add create/modify/delete tests
CASMCMS-9349 TESTS: CFS: Add create/modify/delete tests
CASMCMS-9350 TESTS: IMS: Add create/modify/delete tests
CASMCMS-9351 BOS logging bugs
CASMCMS-9353 BOS operator should log more detailed exception information
CASMCMS-9355 BOS session setup operator should gracefully handle failed component patch
CASMCMS-9356 Error retrieving BOS options: redis.exceptions.ConnectionError
CASMCMS-9357 BOS: Improve efficiency of compact_response_text function
CASMCMS-9363 IMS - deleted recipe always gets assigned arch=x86_64
CASMCMS-9375 During create image ims stores incorrect metadata for an image
CASMCMS-9377 TESTS: IMS: cmsdev: Verify delete operations
CASMCMS-9378 TESTS: IMS: cmsdev: Verify create operations through listing
CASMCMS-9379 TESTS: IMS: cmsdev: Test v2 API and default version API
CASMCMS-9382 BOS: Fix errors reported by mypy
CASMCMS-9386 IMS: Correct API spec errors
CASMCMS-9387 API V2: During create image ims stores incorrect metadata for an image
CASMCMS-9389 IMS image tags removed by soft delete
CASMCMS-9390 BOS: Fix errors reported by mypy in options code
CASMCMS-9391 BOS: Fix errors reported by mypy in migrations code
CASMCMS-9392 BOS: Fix errors reported by mypy in boot artifacts code
CASMCMS-9393 BOS: Fix errors reported by mypy in session templates controller code
CASMCMS-9394 BOS: Fix errors reported by mypy in operators code
CASMCMS-9395 BOS: Fix errors reported by mypy in sessions controller code
CASMCMS-9396 IMS - deleted recipe always gets assigned require_dkms=true
CASMCMS-9399 SECURITY: IMS: Resolve gunicorn CVE
CASMCMS-9402 BOS: Add type annotations to CFS client
CASMCMS-9403 BOS: Add type annotations to BSS & PCS clients
CASMCMS-9405 BOS: Refactor and type annotate S3 client & boot image code
CASMCMS-9406 BOS: Address type annotation issues in status & discovery operators
CASMCMS-9407 BOS: Address type annotation issues in session setup operator
CASMCMS-9408 Conditionalize podsecuritypolicies references in cray-ims
CASMCMS-9409 IMS cli test should suppress expected failures from log
CASMCMS-9411  Pick up latest cray-postgres in CMS charts for CSM 1.7
CASMCMS-9412 BOS: Finish BOS type annotations and add build-time gate
CASMCMS-9420 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-csm-sles15sp6-barebones-recipe:2.7.0
CASMCMS-9421 Update BOS for removal of CPS/DVS in CSM 1.7
CASMCMS-9426 BOS: Do not require boot_sets to be specified on PATCH operations
CASMCMS-9428 BOS: Enumerate component phase and action fields
CASMCMS-9429 BOS: Refactor _get_v2_session_status
CASMCMS-9430 BOS: Replace select properties with cached_properties
CASMCMS-9432 Update BOS API spec examples to use SBPS instead of CPS/DVS
CASMCMS-9434 Get newer SOPS client (3.9+) version on NCNs
CASMCMS-9439 Add Ansible play to restore user SSH configuration
CASMCMS-9445 csm-config: Remove cray-uai-util from packages list
CASMCMS-9447 csm-config: Remove long-deprecated top-level playbooks
CASMCMS-9451 IMS: add pod security context
CASMCMS-9452 Cleanup of leftover Cluster/RoleBindings under CMS
CASMCMS-9453 BOS: Pin Alpine version and update Python deps
CASMCMS-9454 cray-ipxe: add pod security context
CASMCMS-9455 Building image from recipe Job stuck at waiting_for_repos status
CASMCMS-9459 Investigate ARA warning messages
CASMCMS-9461 Tenant information not stored when creating CFS configurations
CASMCMS-9462 CFS API spec should include tenant parameter for relevant endpoints
CASMCMS-9463 Tenant ownership not enforced for configuration PATCH operations
CASMCMS-9464 CFS API spec should include new 403 statuses
CASMCMS-9465 cmsdev " RPM signing keys test" failed in CSM 1.7.0 beta.1
CASMCMS-9466 cfs pods in Error state when ansible container terminated with exit code 2
CASMCMS-9467 TESTS: SECURITY: Resolve security issue in cmsdev
CASMCMS-9468 Update kubernetes Python module versions
CASMCMS-9473 Fix Loading DST signing keys from K8S secret for emulation builds.
CASMCMS-9474 Add certs to CFS ansible container
CASMCMS-9479 Investigate duplicates docker.io/library/redis: BOS / CFS
CASMCMS-9512: csm.ssh roles problems when no root credentials in Vault
```

### CASMCVT

```text
CASMCVT-295 CVT: Add new collection details for Tracebility
CASMCVT-296 Support for reporting in the JSON format
CASMCVT-297 Password details should be obfuscated in ps
CASMCVT-298 CVT : Delete snapshot functionality
CASMCVT-299 CVT: If there inaccessible nodes, cvt does not report that it has added the other accessible nodes
CASMCVT-301 update all scripts with short args as i/p
```

### CASMDIAG

```text
CASMDIAG-1626 Non-root container Investigation
CASMDIAG-1627 Diags Framework Investigation : Syschecker
CASMDIAG-1668 Investigate the difference between 'nhc' used in diags and 'pulse' used in system checker
CASMDIAG-1700 CVT rpm in 1.7.0 showing old rpm ( 1.6.3)
```

### CASMHMS

```text
CASMHMS-5678 Update all HMS go module and base Alpine image dependencies (early catch-all before breaking up)
CASMHMS-6257 hmcollector-poll needs to be restarted after BMC update
CASMHMS-6285 Update cray-hms-rts chart for New JobConditionType SuccessCriteriaMet
CASMHMS-6291 Fill SMD with enough fake data to cause PCS to poll for power status on fake nodes.
CASMHMS-6302 supportedPowerTransitions status is empty for gigabyte nodes
CASMHMS-6356 HSM: Error message incorrect when creating a group with duplicate xnames
CASMHMS-6358 Investigate RTS pprof support
CASMHMS-6359 Investigate SCSD pprof support
CASMHMS-6361 Add pprof support to MEDS
CASMHMS-6364 rebuild hms-hbtd chart to adopt cray-service wait container change
CASMHMS-6372 Inconsistent indentation in BSS cloud-init YAML output
CASMHMS-6386 CAST-37722: Improve responsiveness of BSS /meta-data requests
CASMHMS-6387 HSM: Change the test to accept a Warning value in the Flag field
CASMHMS-6389 BSS: Improve scaling and fix resource leaks
CASMHMS-6390 CAPMC: Improve scaling and fix resource leaks
CASMHMS-6391 Discovery: Improve scaling and fix resource leaks
CASMHMS-6393 Heartbeat (client & server): Improve scaling and fix resource leaks
CASMHMS-6395 MEDS: Improve scaling and fix resource leaks
CASMHMS-6396 RTS: Improve scaling and fix resource leaks
CASMHMS-6397 HMNFD: Improve scaling and fix resource leaks
CASMHMS-6398 SCSD: Improve scaling and fix resource leaks
CASMHMS-6399 SLS: Improve scaling and fix resource leaks
CASMHMS-6401 hms-certs: Improve scaling and fix resource leaks
CASMHMS-6402 hms-go-http-lib: Improve scaling and fix resource leaks
CASMHMS-6408 PCS (deux): Update module and base Alpine image dependencies
CASMHMS-6409 hmcollector (deux): Update module and base Alpine image dependencies
CASMHMS-6410 FAS (deux): Update module and base Alpine image dependencies
CASMHMS-6411 CAPMC: Update module and base Alpine image dependencies
CASMHMS-6412 Discovery: Update module and base Alpine image dependencies
CASMHMS-6413 hardware-topology-assistant: Update module and base Alpine image dependencies
CASMHMS-6414 HBTD: Update module and base Alpine image dependencies
CASMHMS-6415 RTS: Update module and base Alpine image dependencies
CASMHMS-6416 SHCD: Update module and base Alpine image dependencies
CASMHMS-6417 HMNFD: Update module and base Alpine image dependencies
CASMHMS-6418 SCSD: Update module and base Alpine image dependencies
CASMHMS-6437 Heartbeat client reports "failed: Success" at LANL
CASMHMS-6438 OCHAMI BSS: Merge OCHAMI changes into CSM on a test branch
CASMHMS-6439 OCHAMI BSS: Get unit tests working in BSS OCHAMI on CSM sync branch
CASMHMS-6477 RTS: Panic in InitForXName()
CASMHMS-6482 hms-base: Improve scaling and fix resource leaks
CASMHMS-6499 Add curl to any HMS containers missing them
CASMHMS-6514 Conditionalize podsecuritypolicies references in cray-hms-rts
CASMHMS-6516 Pick up latest cray-postgres in HMS charts for CSM 1.7
CASMHMS-6525 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-firmware-action-hmth-test:1.42.0
CASMHMS-6526 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-sls-hmth-test:2.9.0
CASMHMS-6527 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-scsd-test:1.23.0
CASMHMS-6528 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-capmc-hmth-test:3.8.0
CASMHMS-6529 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-hbtd-test:1.23.0
CASMHMS-6530 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-power-control-hmth-test:2.12.0
CASMHMS-6531 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-hmnfd-hmth-test:1.24.0
CASMHMS-6532 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-sls:2.9.0
CASMHMS-6533 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-sls-pprof:2.9.0
CASMHMS-6535 Update BSS API spec examples to use SBPS instead of CPS/DVS
CASMHMS-6553 Check RTS against PDU to verify TLS Handshake error does not occur
CASMHMS-6554 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-bss-hmth-test:1.34.0
CASMHMS-6555 SLS: Update tests to allow the IPv6 fields
CASMHMS-6557 Revisit race condition change at startup in CASMHMS-6415
CASMHMS-6568 CAST-38383: Prevent redundant "Detected" events in hardware inventory history
```

### CASMINST

```text
CASMINST-3816 manually copying large files into s3fs cache directory prevents prune from pruning them
CASMINST-6734 As a System Admin, I do not want to pass SW_ADMIN_PASSWORD  as a parameter to IUF/NLS workflows as goss test do not require it
CASMINST-6900 Complete a Comparison of CSM V1.4.x and CSM V1.5.x/1.6.x Node Resource Usage
CASMINST-7104 As a Sys Admin, I want to pass image and CFS config for management nodes in management-nodes-rollout stage
CASMINST-7114 TESTS: rgw_endpoint_check throwing python error
CASMINST-7167 adjust k8s nodes ready test to ignore SchedulingDisabled?
CASMINST-7168 adjust velero backup test to pass is a newer success exists after a failure?
CASMINST-7172 add retry logic to Postgresql SyncFailed status check test
CASMINST-7173 add retry logic to Kubernetes Postgres Check that All Clusters are in a Running State test
CASMINST-7175 As a Sys Admin, I want cray-nls backend to propagate image and CFS config for management nodes to SAT
CASMINST-7256 Opaque whitelist files found in ansible repos
CASMINST-7286 SBPS_boot_fail.md
CASMINST-7287 SLS_Not_Working_During_Node_Rebuild.md
CASMINST-7294 cray-console-node_pods_in_CrashLoopBackOff.md
CASMINST-7301 ims_image_creation_failure.md
CASMINST-7304 ims_remote_node_image_build_failure.md
CASMINST-7333 cray vnid jobs create fails
CASMINST-7350 CLI: remove UAS and UAI
CASMINST-7353 CLI: Remove/modify DVS/CPS references
CASMINST-7371 ARGO_DEADLINE too short and terminating workflow step before it completes
CASMINST-7373 deploy-product-onexit hook gives up following the log for argo pod and exits
CASMINST-7376 cilium migration is removed from IUF, but post-install check is still there
CASMINST-7382 ODIN: multiple products pre-hooks failed during post-install-service-check due to Kyverno Violations
CASMINST-7208 Input Validation: csi config init should error out when network CIDRs overlap
CASMINST-7281 DOCS: Known Issue - CFS_Component_With_Zero_Length_ID.md
CASMINST-7308 DOCS: kubectl_logs_no_space_left_on_device.md
CASMINST-7315 DOCS: postgres_database_recovery.md
CASMINST-7316 DOCS: product_catalog_upgrade_error.md
CASMINST-7324 DOCS: velero_version_mismatch.md
CASMINST-7395 New flags from CASMNET-2355 appear in system_config.yaml
CASMINST-7396 vshasta data.json merge fails
CASMINST-7398 extraneous log messages during csi config init
CASMINST-7408 "new reservation" count is incorrect
CASMINST-7409 Fix bugs from CASMNET-2345 testing
CASMINST-7411 DOCS: k8s-upgrade-job logs are lost when job pod deleted
CASMINST-7429 DOCS: Linting
CASMINST-7430 DOCS: csm 1.7 cray-site-init release notes
```

### CASMMON

```text
CASMMON-469 delete SMa postgres VMscrapeserive  for SMA
CASMMON-475 seeing errors in the log systmgmt-health-redfish-exporter after configuring E100-smart-data
CASMMON-478 SNMP exporter for cray-sysmgmt-health
CASMMON-500 duplicates quay.io/prometheus/prometheus issue
CASMMON-517 change cray-sysmgmt-health values.yaml for  grafana node exporter , kube state metric  etc values.yaml with latest  victoria-metrics-k8s-stack
CASMMON-518 SMH Dashboard Bugs
CASMMON-519 Investigate  alertmanager duplicate not grouped alerts  in cray-sysmgmt-health
CASMMON-520 create latest VMinsert, VMselect, VMstorage, VMalert container images for victoria-metrics-k8s-stack
CASMMON-531 vmagent unable to scrape node exporter enpoints with latest VM
CASMMON-532 Fix all the minor bugs reported as a part of Victoria-metrics-k8s-stack upgrade
CASMMON-534 Remove cray-node-exporter from Ceph nodes as we already have prometheus-node-exporter packages there.
CASMMON-535 Change RFSF branching logic to parse the data.
CASMMON-536 Use latest attributes for REST calls in collectors.
CASMMON-537 Support ClusterStor IP in target (currently it only supports FQDN)
CASMMON-540  security context is different on tyr vs starlord  vmalertmanager-vms-0
CASMMON-542 cray-sysmgmt-health upgrade fails
CASMMON-544 Some of the panels in Node Exporter Full dashboard has No Data
CASMMON-547 Remove sma-cli-util RPM from csm
CASMMON-548 UAN image creation is failing during prepare images
CASMMON-552 Review usage of cray-canu/canu-test:1.6.36 image and fix CVE's

```

### CASMPET

```text
CASMPET-6096 weave.yaml contains two copies
CASMPET-6217 LUMI telemetry & ceph performance config and tuning
CASMPET-6561 Fix CVE's in artifactory.algol60.net/csm-docker/stable/docker.io/bitnami/kube-state-metrics:v2.8.0
CASMPET-6903 Fix Keycloak Setup to update redirect urls on Upgrade
CASMPET-6937 Reduce noise from spire-agent.service
CASMPET-7033 Investigate duplicates docker.io/weaveworks/weave-kube
CASMPET-7034 Investigate duplicates docker.io/weaveworks/weave-npc
CASMPET-7037 Investigate duplicates ghcr.io/k8snetworkplumbingwg/multus-cni
CASMPET-7071 Create OPA Policy for access to Vault Transit Engines
CASMPET-7088 CSM 1.5.2: validate_certifi_version goss test failure
CASMPET-7103 Sporadic spire_check_key_id_in_jwks goss test failure
CASMPET-7132 Set resource requests for cert-manager pods
CASMPET-7155 Verify if this new feature impacts the SMA Team
CASMPET-7156 Verify if this new feature impacts the Slingshot Team
CASMPET-7157 Verify if this new feature impacts the COS/USS Team
CASMPET-7158 Verify if this new feature impacts the PE Team
CASMPET-7159 Verify if this new feature impacts the SDU Team
CASMPET-7181 Verify if this new feature impacts the WLM Team
CASMPET-7182 Verify if this new feature impacts the CPE Team
CASMPET-7190 Verify if ISCSI is impacted to valut transition
CASMPET-7241 Update cray-sonar container image to use docker-kubectl latest
CASMPET-7243 Remove PSPs from CSM charts for K8s 1.25+ in CSM 1.7
CASMPET-7246 cray-drydock update to CronJob batch/v1
CASMPET-7247 cray-nls update to PodDisruptionBudget policy/v1
CASMPET-7248 cray-istio update HorizontalPodAutoscaler to autoscaling/v2
CASMPET-7260 iSCSI SBPS: During bootprep provide a method to select specific worker nodes for node personalization
CASMPET-7293 Review iuf:v0.1.12 (149 days)
CASMPET-7298 Investigate duplicates docker.io/weaveworks/weave-npc
CASMPET-7300 Update cray-ceph-csi-cephfs chart to use new cephcsi version
CASMPET-7301 Update cray-ceph-csi-rbd chart to use new cephcsi version
CASMPET-7304 Update Ceph Daemon Container images for Ceph upgrade
CASMPET-7305 Update `update_container_images.sh` script for Ceph CSM 1.7.0 upgrade
CASMPET-7308 Update CSM 1.7 to use ncn-upgrade-storage-test.yaml change
CASMPET-7310 Fix check_master_taints function in k8s cloud-init to use contol-plane
CASMPET-7325 cray-spire: PSP chart changes for K8s 1.25+
CASMPET-7328 cray-kyverno: PSP chart changes for K8s 1.25+
CASMPET-7329 cray-psp: PSP chart changes for K8s 1.25+
CASMPET-7330 sealed-secrets: PSP chart changes for K8s 1.25+
CASMPET-7331 cray-node-problem-detector: PSP chart changes for K8s 1.25+
CASMPET-7332 cray-externaldns: PSP chart changes for K8s 1.25+
CASMPET-7333 node-images: Create node images with Kubernetes 1.32
CASMPET-7334 container-images: Images for K8s 1.32
CASMPET-7336 cray-dns-unbound: PSP chart changes for K8s 1.25+
CASMPET-7337 cray-dhcp-kea: PSP chart changes for K8s 1.25+
CASMPET-7347 Investigate if Postgres leader lock issue exists after postgres-operator upgrade
CASMPET-7351 As a developer, I want to enable provision LIO services to preferred worker nodes
CASMPET-7358 Include Argo Workflow CLI in the NCN image
CASMPET-7359 Make Kubernetes certificate expiry configurable
CASMPET-7361 node-images: Need etcd 3.5.18-0 image for k8s 1.32 install
CASMPET-7363 Remove manifest reference to spire and update the upgrade.sh
CASMPET-7369 Make sonar-sync requests and limits customizable
CASMPET-7371 node-images: PSP is not supported in K8s 1.25+
CASMPET-7373 spire-intermediate chart update to CronJob batch/v1
CASMPET-7374  cray-etcd-backup chart update to CronJob batch/v1
CASMPET-7375 cray-baremetal-etcd-backup chart update to CronJob batch/v1
CASMPET-7380 cray-certmanager: PSP chart changes for K8s 1.25+
CASMPET-7383 Disable TLS1.2 support in oauth2 proxies
CASMPET-7390 Complete an upgrade of istio for CSM V1.7
CASMPET-7397 csm-testing: Remove goss-k8s-psp-enabled test
CASMPET-7410 Remove SRC_TIME from iscsi node exporter metrics
CASMPET-7414 Address "disallow-host-path" and "disallow-host-namespaces" exception for cray-node-discovery pod
CASMPET-7443 csm-config: Correctly detect curl failures in sbps_dns_srv_records.sh
CASMPET-7444 csm-config: sbps.dns_srv_records doesn't handle CRLFs in script output
CASMPET-7447 cray-vpa pods in CLBO status in K8s 1.32
CASMPET-7453 Retest TPM node attestation for x86 nodes in CSM 1.7
CASMPET-7454 Remove stub for webhook credentials in TAPMS
CASMPET-7460 Figure out how to apply different CSM manifests to intermediate K8s versions
CASMPET-7463 Fix saved token for TPM enablement script
CASMPET-7471 Modify update-customizations.sh to add device name and network
CASMPET-7481 Goss tests for iSCSI SBPS are not reporting error if no NMN A records
CASMPET-7497 Fix MetalLB shasta customizations file error
CASMPET-7501 Test Boot lifecycle of TPM enabled node attestation
CASMPET-7522 Pick up latest cray-postgres in cray-nls chart for CSM 1.7
CASMPET-7523 Write and test script that upgrades k8s
CASMPET-7524 Add k8s blocks to deploy-product-onexit.sh
CASMPET-7525 Pick up latest cray-postgres in cray-spire chart for CSM 1.7
CASMPET-7526 keycloak-installer release startegy is broken - old releases are getting overwritten
CASMPET-7527 Create node image and CSM image that can be used for both 1.32 and 1.24 -> 1.25 upgrades
CASMPET-7531 Fix request ncn join token
CASMPET-7535 Update Spire-agent to not clobber config
CASMPET-7545 Add new cephcsi container images to node-images
CASMPET-7549 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-dhcp-kea:0.11.6
CASMPET-7550 Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-dns-unbound:0.8.4
CASMPET-7551 New cephcsi images are referenced but not shipped
CASMPET-7553 undeploy function cannot be re-run now that we're using --keep-history flag
CASMPET-7562 Add K8s upgrade cleanup script and update BSS to remove upgrade runcmd stuff
CASMPET-7565 Create csi subvolumegroup for cephfs
CASMPET-7574 Cannot undeploy cray-psp in upgrade_control_plane.sh when K8s is 1.26
CASMPET-7577 On upgrade, cannot remove cray-psp chart in upgrade.sh before storage node rollout
CASMPET-7578 Return kubernetes-cni-1.2.0 to CSM
CASMPET-7579 Timing issue with metallb post-install job
CASMPET-7581 Update DNS and Kyverno precache images in platform-v1.24.yaml
CASMPET-7587 Move postgres upgrade out of prerequisites.sh
CASMPET-7604 cray-postgres-operator CRD upgrade sometimes fails
CASMPET-7612 sealed-secrets CRD are not updated on a CSM 1.7 upgrade
CASMPET-7613 cray-vault-operator CRD are not updated on a CSM 1.7 upgrade
CASMPET-7615 Reconcile -v1.24 manifests
CASMPET-7616 Create HSM group to configure all worker nodes as iSCSI targets
CASMPET-7624 iSCSI csm-config playbook should explicitly check for empty HSM group
CASMPET-7625 iSCSI csm-config apply_labels role should run inside CFS pod
CASMPET-7626 TESTS: Create Goss test to detect bad iSCSI HSM group
CASMPET-7633 etcd_health_status check produces false positive result
CASMPET-7483 DOCS: CSM 1.7.0 release notes: Platform component upgrades
CASMPET-7619 DOCS: Create operational procedure for changing iSCSI workers
CASMPET-7620 DOCS: Update CSM install docs with iSCSI worker step
CASMPET-7621 DOCS: Update CSM upgrade docs with iSCSI worker step
CASMPET-7630 DOCS: iSCSI HSM group procedure has errors
CASMPET-7631 DOCS: Update add/remove worker procedures for iSCSI feature
CASMPET-7632 DOCS: Remove/move iSCSI_SBPS_Node_Personalization.md
CASMPET-7640 DOCS: Create/restore iSCSI verification procedures
CASMPET-7643 DOCS: Assist with CAST-38579
CASMPET-7644 Remove Kubernetes 1.24.17 from CSM 1.7
CASMPET-7646 Update comments in the -v1.24.yaml
CASMPET-7651 DOCS: Add default k8s cert expiry increased to 3 years to RELEASE_NOTES
```

### CASMSMF

```text
CASMSMF-8335 Can SMA use of cm cli migrate to SMA release
CASMSMF-8435 Understand HPCM Grafana alerting framework
CASMSMF-8438 Create GPU alerts  - view hpcm rules
CASMSMF-8439 Create Slingshot congestion alerts - view hpcm rules
CASMSMF-8440 Create Redfish events alerts - crayalerts
CASMSMF-8442 Create cray-node topic alerts for node statistics
CASMSMF-8444 Alertman CLI changes for monasca and Grafana alerting
CASMSMF-8445 Redirect all the Grafana alerts back to "Alerts" kafka topic.
CASMSMF-8477 Investigate SMA PSP chart changes for K8s 1.25+
CASMSMF-8478 Implement alterative solution instead of hostpath t SMA PSP chart changes for K8s 1.25+
CASMSMF-8528 Correct SMA Redfish Dashboard
CASMSMF-8539 Fix Pod sma/opensearch-bootstrap-0 violates PodSecurity "baseline:latest" error
CASMSMF-8548 SMA Dashboard Bugs
CASMSMF-8558 SMA VictoriaMetrics monitoring
```

### MTL

```text
MTL-2397 Add psmisc rpm to worker and master node images
MTL-2460 ProLiant DL325 Gen10 Plus - network issue at reboot
MTL-2490 cloud-init cc_timezone failure
MTL-2511 Plan NCN Rapid Updates
MTL-2527 DEV: build new security patched images with CFS
MTL-2540 Update csm-docker-sle Build Environment to SLE-15-SP7
MTL-2541 Update csm-docker-sle-python Build Environment
MTL-2542 Add SP7 Builds for OS-Specific CSM Packages
MTL-2547 Package sweep for SLE-15-SP6
MTL-2550 cloud-init fails on storage nodes when running ansible-playbook
MTL-2554 Lowercase mtl.conf conflicts with CSI generated conf
MTL-2555 Migrate hpc-shasta-os-cray-cps-dracut
MTL-2556 Migrate hpc-shasta-os-cps-utils
MTL-2567 Need Additional SDU Mount Point for Adhoc Feature
MTL-2568 Package sweep for SLE-15-SP6
MTL-2569 Migrate cray-udev-network / cray-udev-network-ncn
MTL-2573 Migrate hpc-shasta-os-cray-scripts-dracut
MTL-2574 Migrate cray-netif-dracut
MTL-2575 CSI Dependency and HMS Cleanup
MTL-2580 IPv6: cloud-init can't set IPv6 default route
MTL-2581 NIC renaming fails and causes booting to fail for compute nodes
MTL-2583 Install legacy python modules for system python
MTL-2584 Package sweep for SLE-15-SP6 -- CSM 1.7
```

### USS

```text
USS-959 Sign container images released with USS
USS-3710 SUSE Provided RPM tool 'SOPS' Not functional on master/worker nodes
```
