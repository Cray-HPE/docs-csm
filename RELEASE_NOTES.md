# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.3 contains approximately 500 changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

### Monitoring

* Temperature hardware monitoring dashboard for NCNs
* Support for export of SNMP data from multiple switches for population of SNMP Export `grafana` panel
* Space monitoring improvements - included volumes other than root file system

### DHCP

#### Changed in DHCP

* **Kea**: Fixed a bug that could cause the auto-repair logic to fail due to an incorrect index

### DNS

#### Changed in DNS

* **`ExternalDNS`**: Fixed a bug where `cray-externaldns-manager` could panic if it couldn't connect to PowerDNS on startup
* **PowerDNS**: Changed `powerdns-manager` SLS error message to debug
* **PowerDNS**: Fixed bug that caused `powerdns-manager` and `externaldns-manager` to update the same record
* **PowerDNS**: Fixed a bug that could cause `powerdns-manager` to intermittently crash when performing a lookup for an existing TSIG key
* **PowerDNS**: `powerdns-manager` will now retry attempts to add a TSIG key
* **PowerDNS**: `powerdns-manager` will now create PTR records that are not created by `external-dns`
* **Unbound**: Changed `cray-dns-unbound` `MaxUnavailable` default from 0 to 1 to avoid issues when evicting pods from NCNs

### Management Network

#### Added in Management Network

* **Documentation**: Added procedure to migrate from the customer access network (CAN) to the customer high-speed network (CHN), allowing user traffic over
  the HSN instead of the NMN (This is an extension of the `bi-furcated` CAN feature that shipped in CSM 1.2)
* **Documentation**: Added various troubleshooting guides
* **Hardware**: Validated the Aruba 8360 (JL705C) switch for the management network

#### Changed in Management Network

* **CANU**: Fixed bug where UAN VLANs in generated switch configurations were wrong when using the CHN
* **CANU**: Other various bug fixes (see [CANU `Github` Page](https://github.com/cray-hpe/canu) for a full changelog)
* **CANU**: Added an ACL on systems with Dell and Mellanox switches to prevent high-speed network (HSN) switches on the Hardware Management Network (HMN)
  from communicating with the Fabric Manager service on the Node Management Network (NMN) API gateway
* **CSI**: Fixed bug where CSI could generate bad SLS chassis data
* **Documentation**: Admins are now asked to updated CANU to the latest version when beginning a CSM upgrade
* **Documentation**: Management network switch upgrade instructs are now separate from the CSM upgrade procedure
* **Documentation**: Removed stale reference to Kea `postgres` from troubleshooting documentation
* **Documentation**: Fixed invalid commands in `generate_switch_configs.md`

### Management Nodes (Ceph, Kubernetes Workers, and Kubernetes Managers)

#### Added in Management Nodes

* **ALL**: Initial support for NVME drives

#### Changed in Management Nodes

* **All**: Updated kernel to `kernel-default-5.3.18-150300.59.87.1`
* **All**: Various package updates to apply latest security patches
* **All**: `kdump` is now more reliable and remains functional after IMS image customization
* **All**: S3 now requires authentication to retrieve Management Node OS images
* **All**: `metal.no-wipe=0` is now more reliable when running during a net boot
* **All**: SSH keys must now be injected into images
* **All**: Time synchronization is now more reliable on initial configuration
* **All**: Pressure Stall Information (PSI) is now enabled by default ([see related CSM 1.3 docs](https://github.com/Cray-HPE/docs-csm/tree/release/1.3/background#psi))
* **Documentation**: Various updates to installation guides

### User Application Service (UAS) and User Application Instances (UAI)

* No significant changes

### User Application Nodes (UAN)

#### Added in UAN

* **UAN**: Initial release of UAN images based on kernels without modifications (technical preview)
* **Documentation**: Added procedure for re-purposing compute nodes as UAN's (only applicable in specific scenarios)
* **Documentation**: Added instructions to set/trim the boot order on UANs

#### Changed in UAN

* **UAN**: Pressure Stall Information (PSI) is now enabled by default on COS-based images
* **UAN**: Updated to the latest COS image
* **UAN**: Network changes related to the CAN and CHN may impact VLAN tagging on management network ports connected to UANs to ensure proper network traffic segregation.

### Miscellaneous functionality

* Integrated Kyverno Native Policy Management engine
* Ansible has been added to [NCN](glossary.md#non-compute-node-ncn)s
* Added support for procedures:
  * Replace/Remove/Add NCNs
  * Add River cabinets
* Integrated Argo server workflow engine for Kubernetes
* Technology Preview: [BOS](glossary.md#boot-orchestration-service-bos) V2
  * Asynchronous boot state handling and [CRUS](glossary.md#compute-rolling-upgrade-service-crus) replacement for rolling upgrades
* Technology Preview: Tenant and Partition Management Service (TAPMS)
* Added support for using SCSD to enable or disable TPM BIOS setting on Gigabyte and HPE hardware
* Boot NCNs using private S3 bucket
* Enable [IMS](glossary.md#image-management-service-ims) recipe templating to allow for dynamic repository selection
* CSM health check performance improvements
  * HMS tests now execute in parallel using Helm Test
  * NCN and Kubernetes health checks now execute in parallel and eliminate lengthy output for tests that pass
* Included [SAT](glossary.md#system-admin-toolkit-sat) CLI in CSM (see [SAT in CSM](operations/sat/sat_in_csm.md))

### New hardware support

* Aruba JL705C, JL706C, JL707C management network switches
* Milan-based DL325 as a Compute Node
* Olympus Antero Blade (AMD Genoa) with Slingshot 11
  * No power capping support

### Automation improvements

* Support for Argo-driven upgrade of multiple Kubernetes Worker NCNs in parallel (Tech Preview)
* Support for Argo-driven rebuild of multiple Kubernetes Worker NCNs in parallel (Tech Preview)
* Support for Argo-driven upgrade of Storage NCNs, serially
* Ceph upgrade is now driven using a utility called the  `cubs_tool`.
* Re-organization of `goss` test execution during installs and upgrades to remove duplicated tests
* Improvement of `goss` test suite output to display summary of failing tests
* Removed manual prompts from upgrade of storage NCNs
* Introduced weekly spire-intermediate cron-job to check CA to see when it needs automatic renewal

### Base platform component upgrades

| Platform Component           | Version        |
|------------------------------|----------------|
| Ceph                         | `16.2.9`       |
| `containerd`                 | `1.5.12`       |
| `coredns`                    | `1.8.0`        |
| `cray-dhcp-kea`              | `0.10.15`      |
| `cray-ipxe`                  | `1.11.0`       |
| Istio                        | `1.10.6`       |
| Kubernetes                   | `1.21.12`      |
| Kiali                        | `1.36.7`       |
| Nexus                        | `3.38.0-1`     |
| `podman`                     | `3.4.4`        |
| `postgreSQL`                 | `12.12`        |
| Prometheus                   | `2.36.1`       |
| `oauth2-proxy`               | `7.3.0`        |
| `cray-opa`                   | `0.42.1`       |
| `cray-velero`                | `1.6.3-2`      |

### Security improvements

* Boot Security - Randomized iPXE File Name
* Boot Security - NCN boots via pre-signed S3 URLs
* API least privileges (xname filtering)
* Role Based Access Control (RBAC) Role for monitoring
* Kubernetes Pod Runtime Security – Phase 1 (non-root)
* Kubernetes API (etcd) Encryption (opt-in)
* Tenant and Partition Management Service (TAPMS Tech Preview)
* Access allowed to heartbeat's tunables OPA for `cray-heartbeat`
* NCN CVE Remediation
* CVE remediation near zero - high/critical (container images)
* Replaced High/Critical CVE container use in Spire
* Addressed CVE remediation for `postgres-operator`
* Addressed Expat-15: High/Critical CVE container use in [UAS](glossary.md#user-access-service-uas)/[UAI](glossary.md#user-access-instance-uai)

### Customer-requested enhancements

* Added the ability to list all lock conditions with Cray [HSM](glossary.md#hardware-state-manager-hsm) locks API
* Enabled pressure stats on all nodes with Linux 5.x kernel
* Added initial (Tech Preview) support for API-driven NCN lifecycle operations driven via Argo workflows (for worker and storage NCN upgrades)

### Documentation enhancements

* Added documentation for:
  * Add/Remove/Replace NCN procedures
  * Add/Remove/Replace compute nodes using `sat swap blade`
  * How to troubleshoot `ncn-m001` PXE loop
  * NCN image modification using [IMS](glossary.md#image-management-service-ims) and [CFS](glossary.md#configuration-framework-service-cfs)
  * Minimal space requirements for CSM V1.3.0
  * The new `cray-externaldns-manager` service
* [CAN](glossary.md#customer-access-network) documentation updated to reflect BICAN

## Bug fixes

* TBD

## Deprecations

The following features are now deprecated and will be removed from CSM in a future release.

* [BOS](glossary.md#boot-orchestration-service-bos) v1 is now deprecated, in favor of BOS v2. BOS v1 will be removed from CSM in the `CSM-1.9` release.
  * It is likely that even prior to BOS v1 being removed from CSM, the [Cray CLI](glossary.md#cray-cli-cray) will change its behavior when no
    version is explicitly specified in BOS commands. Currently it defaults to BOS v1, but it may change to default to BOS v2 even before BOS v1
    is removed from CSM.

For a list of all deprecated CSM features, including those that were deprecated in previous CSM releases but have not yet been removed,
see [Deprecated Features](introduction/deprecated_features/README.md).

## Removals

* [SLS](glossary.md#system-layout-service-sls) support for downloading and uploading credentials in the `dumpstate` and `loadstate` REST APIs

The following previously deprecated feature now has an announced CSM version when it will be removed:

* [CRUS](glossary.md#compute-rolling-upgrade-service-crus) was deprecated in CSM 1.2, and will be removed in CSM 1.5.

For a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

* UAIs use a default route that sends outbound packets over the CMN, this will be addressed in a future release so that the default route uses the CAN/CHN.

* On some systems, Ceph can begin to exhibit latency over time, and if this occurs it can eventually cause services like `slurm` and services that are backed by `etcd` clusters to exhibit slowness and possible timeouts.
See [Known Issue: Ceph OSD latency](troubleshooting/known_issues/ceph_osd_latency.md) for a workaround.

### Security vulnerability exceptions in CSM 1.3

Significant effort went into the tracking, elimination, and/or reduction of critical or high (and lower) security vulnerabilities of container images included in the CSM 1.3 release.
There remain, however, a small number of exceptions that are listed below. General reasons for carrying exceptions include needing to version pin certain core components,
upstream fixes not being available, or new vulnerability detection or fixes occurring after release content is frozen. A new effort to track and address security vulnerabilities
of container images spins up with each major CSM release.

| Image | Reason |
|-----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `csm-dckr/stable/quay.io/ceph/ceph:v15.2.15`                                | This version of Ceph (Octopus) is needed in the upgrade procedure, but is not present after that. |
| `csm-docker/stable/quay.io/ceph/ceph:v15.2.16`                              | This version of Ceph (Octopus) is needed in the upgrade procedure, but is not present after that. |
| `csm-docker/stable/quay.io/ceph/ceph:v16.2.9`                               | This version of Ceph (Pacific) is pinned for the CSM 1.3 release. The next CSM version released as a part of a recipe will support Ceph (`Quincy`). |
| `csm-docker/stable/quay.io/cephcsi/cephcsi:v3.6.2`                          | Upstream fixes became available after CSM 1.3 release content was frozen. |
| `csm-dckr/stable/dckr.io/bitnami/external-dns:0.10.2-debian-10-r23`         | Upstream fixes are needed and are not yet available. |
| `csm-docker/stable/quay.io/kiali/kiali-operator:v1.36.7`                    | The updated `RedHat` base image is available but not pulled in by upstream. See procedure to [Remove Kiali](operations/system_management_health/Remove_Kiali.md) if desired. |
| `csm-dckr/stable/k8s.gcr.io/kube-proxy:v1.20.13`                            | This version is needed for the upgrade procedure but will not be running after the upgrade has been completed. |
| `csm-docker/stable/k8s.gcr.io/kube-proxy:v1.21.12`                          | Upstream fixes are needed and are not yet available for the `1.21.12` version of Kubernetes included in CSM 1.3. |
| `csm-docker/stable/cray-postgres-db-backup:0.2.3`                           | To ensure success of `postgres` restore functionality, we needed to pin to `psql v12` in this image. |
| `csm-dckr/stable/dckr.io/nfvpe/multus:v3.7`                                 | Upstream fixes are needed and are not yet available, however we have engaged with the project to make a reduced-vulnerability version available.|
| `csm-docker/stable/docker.io/sonatype/nexus3:3.38.0-1`                      | Upstream fixes are needed to the base image in order to address the remaining vulnerabilities. |
| `csm-docker/stable/cray-uas-mgr:1.21.0`                                     | This will be addressed in a future version of CSM. |
