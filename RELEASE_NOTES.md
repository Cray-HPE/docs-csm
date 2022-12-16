# Cray System Management (CSM) - Release Notes

CSM 1.2 contains approximately 2000 changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

### Monitoring

* New network traffic dashboard
* New Kubernetes and microservice health dashboard
* New boot dashboard
* New command line dashboard for critical services like `smd`, `smd-postgres`, `capmc`, and `hbtd`
* New Grafana dashboard for critical services like `smd`, `capmc`, `smd-postgres`, and `hbtd`
* Management nodes sample SMART data and publish it to SMA/SMF
* Support for HPE PDU telemetry

### Networking

* Release Cray Automated Network Utility (CANU) V1.0.0
* Performance improvements to Unbound and DHCP Helper
* Initial Release of Bifurcated CAN
  * [BICAN summary page](operations/network/management_network/bican_technical_summary.md)
  * [BICAN technical details](operations/network/management_network/bican_technical_details.md)

  The user and administrative traffic segregation introduced by Bifurcated CAN has changed the URLs for certain services as it is now necessary to include the network path in the
  fully qualified domain name. Access to administrative services is now restricted to the Customer Management Network (CMN). API access is available via the Customer Management
  Network (CMN), Customer Access Network (CAN), and Customer Highspeed Network (CHN).

  The following table assumes the system was configured with a `system-name` of `shasta` and a `site-domain` of `dev.cray.com`.

  | Old Name                           | New Name                                  |
  |------------------------------------|-------------------------------------------|
  | `auth.shasta.dev.cray.com`         | `auth.cmn.shasta.dev.cray.com`            |
  | `nexus.shasta.dev.cray.com`        | `nexus.cmn.shasta.dev.cray.com`           |
  | `grafana.shasta.dev.cray.com`      | `grafana.cmn.shasta.dev.cray.com`         |
  | `prometheus.shasta.dev.cray.com`   | `prometheus.cmn.shasta.dev.cray.com`      |
  | `alertmanager.shasta.dev.cray.com` | `alertmanager.cmn.shasta.dev.cray.com`    |
  | `vcs.shasta.dev.cray.com`          | `vcs.cmn.shasta.dev.cray.com`             |
  | `kiali-istio.shasta.dev.cray.com`  | `kiali-istio.cmn.shasta.dev.cray.com`     |
  | `s3.shasta.dev.cray.com`           | `s3.cmn.shasta.dev.cray.com`              |
  | `sma-grafana.shasta.dev.cray.com`  | `sma-grafana.cmn.shasta.dev.cray.com`     |
  | `sma-kibana.shasta.dev.cray.com`   | `sma-kibana.cmn.shasta.dev.cray.com`      |
  | `api.shasta.dev.cray.com`          | `api.cmn.shasta.dev.cray.com`, `api.chn.shasta.dev.cray.com`, `api.can.shasta.dev.cray.com` |

* PowerDNS authoritative DNS server
  * Supports zone transfer to external DNS servers via AXFR query and DNSSEC
  * Refer to the [PowerDNS Migration Guide](operations/network/dns/PowerDNS_migration.md) and
    [PowerDNS Configuration Guide](operations/network/dns/PowerDNS_Configuration.md) for further information.
* Management network switch hostname changes

  The management network switch hostnames have changed in CSM 1.2 to more accurately reflect the usage of each switch type.

  | Old Name   | New Name      | Usage                                                     |
  |------------|---------------|-----------------------------------------------------------|
  | `sw-spine` | Unchanged     | Network spine that links to other switches.               |
  | `sw-agg`   | `sw-leaf`     | NMN connections for NCNs and application nodes.           |
  | `sw-leaf`  | `sw-leaf-bmc` | BMC connections, PDUs, Slingshot switches, cooling doors  |

### Miscellaneous functionality

* SLES15 SP3 support for NCNs, UANs, Compute Nodes, and barebones validation image
* S3FS added to master and worker nodes for storing SDU dumps and CPS content
* Improved FAS (Firmware Action Service) error reporting
* CFS State Reporter added to storage nodes
* Numerous new tests added along with improved error logging
* CAPMC support for HPE Apollo 6500 power capping
* CAPMC support for new power schema for BardPeak power capping
* CAPMC support for HPE `G2 Metered 3Ph 39.9kVA 60A 480/277V FIO` PDU
* Improved CAPMC error handling in BOA
* `root` user password and SSH keys now handled by NCN personalization after initial install; locations of data changed in HashiCorp Vault from previous releases
* Generic Ansible passthrough parameter added to CFS session API
* Improved CFS session resiliency after power outages
* Pod priority class additions to improve upgrades and fail-over
* New procedure for exporting and restoring Nexus data
  * [Nexus Export and Restore](operations/package_repository_management/Nexus_Export_and_Restore.md)
  * New recommendation to take and save off cluster an export of all data using the procedure

### New hardware support

* Olympus Bard Peak Blade (AMD Trento with AMD MI200) with Slingshot 11 - Compute Node
* Olympus Grizzly Peak NVidia A100 80GB GPU - Compute Node
* Milan-Based DL385 Gen10+ with AMD Mi100 GPU - UAN and Application Node
* Milan-Based Apollo 6500/XL675d Gen10+ with NVIDIA A100 40GB - Compute Node
* Milan-Based Apollo 6500/XL645d Gen10+ with NVIDIA A100 80GB - Compute Node
* HPE `G2 Metered 3Ph 39.9kVA 60A 480/277V FIO` PDU

### Automation improvements

* Automated validation of CSM health in several areas
* Automated administrative access configuration
* Automated installation of CFS set-up of passwordless SSH
* Automated validation of Management Network cabling
* Automated firmware check on PIT node
* `keycloak-installer` is released
* CSM install and upgrade automation improvements

### Base platform component upgrades

| Platform Component           | Version        |
|------------------------------|----------------|
| Ceph                         | `15.2.15`      |
| `containerd`                 | `1.5.7`        |
| CoreDNS                      | `1.7.0`        |
| Etcd for Kubernetes          | `3.5.0`        |
| Etcd cluster                 | `3.3.22`       |
| Helm                         | `3.2.4`        |
| Istio                        | `1.8`          |
| Keepalived                   | `2.0.19`       |
| Kiali                        | `1.28.1`       |
| Kubernetes                   | `1.20.13`      |
| Loftsman                     | `1.2.0-1`      |
| MetalLB                      | `0.11.0`       |
| Multus                       | `3.7`          |
| PostgreSQL                   | `12.11`        |
| Strimzi Operator             | `0.27.1`       |
| Vault                        | `1.5.5`        |
| Vault Operator               | `1.8.0`        |
| Zookeeper                    | `3.5.9`        |

### Security improvements

* Switch to non-root containers
  * A significant number of `root` user container images have been removed
  * The remainder have been identified for removal in a future release
* Verification of signed RPMs
* CVE remediation
  * A significant number of CVEs have been addressed, including a majority of the critical and high CVEs, like `polkit` and `log4j`
* Updates to Nexus require authentication
* Removal of code injection vulnerability in `commit` and `cloneURL` fields of CFS configuration API
* Further restrictions on allowed HTTP verbs in API requests coming from Compute Nodes
* Option to restrict Compute Nodes to only call URIs by machine identity

### Customer-requested enhancements

* Ability to turn off slots without `hms-discovery` powering them on
* Resilient way to reboot a Compute Node into its current configuration with a single API call

## Bug fixes

* Documented optimized BIOS boot order for NCNs
* Fixed: Slingshot switches attempting DHCP renewal to unreachable address
* Fixed: Node will not reboot following upgrade of BMC and BIOS
* Fixed: Worker node container `/var/lib/containerd` is full and pods stuck in `ContainerCreating` state
* Fixed: Incorrect data or bad monitor filters in `sysmgmt-health` namespace
* Fixed: Hardware State Manager showing compute nodes in standby after cabinet-level power down procedure
* Fixed: Cray HSM inventory reports incorrect DIMM `Id` and `Name`
* Fixed: Image customization CFS jobs do not set an Ansible limit when customizing
* Fixed: No `/proc` available in CFS image container
* Fixed: ConMan reconnects to nodes every hour, reissuing old messages with updated time stamps
* Fixed: CFS can leave sessions `pending` after a power outage
* Fixed: `sonar-jobs-watcher` not stopping orphaned CFS pods
* Fixed: PXE boot failures during installs, upgrades, and NCN rebuilds
* Fixed: `cray-powerdns-manager` not correctly creating CAN reverse DNS records.

## Deprecations

* CRUS is deprecated in CSM 1.2.0. It will be removed in a future CSM release and replaced with BOS V2, which will provide similar functionality.
* PowerDNS will replace Unbound as the authoritative DNS source in a future CSM release.
  * The `cray-dns-unbound-manager` CronJob will be deprecated in a future release once all DNS records are migrated to PowerDNS.
  * The introduction of PowerDNS and Bifurcated CAN will introduce some node and service naming changes.
  * See the [PowerDNS Migration Guide](operations/network/dns/PowerDNS_migration.md) for more information.
* SLS support for downloading and uploading credentials in the SLS `dumpstate` and `loadstate` REST APIs is deprecated.

See [Deprecated features](introduction/differences.md#deprecated_features).

## Removals

* The V1 version of the CFS API has been removed
* The `cray-externaldns-coredns`, `cray-externaldns-etcd`, and `cray-externaldns-wait-for-etcd` pods have been removed. PowerDNS is now the provider of the external DNS service.

## Known issues

### Security vulnerability exceptions

A great deal of emphasis was placed on elimination or reduction of critical or high security vulnerabilities of container images included in the CSM 1.2 release.
There remain, however, a small number of exceptions that are listed below. General reasons for carrying exceptions include needing to version pin certain core components,
upstream fixes not being available, or new vulnerability detection or fixes occurring after release content is frozen. A new effort to track and address security vulnerabilities
of container images spins up with each major CSM release.

| Image | Reason |
|-----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `csm-dckr/stable/dckr.io/ceph/ceph:v15.2.8`                                 | This image is needed for the procedure to upgrade to CSM 1.2, but is purged afterwards. |
| `csm-dckr/stable/quay.io/ceph/ceph:v15.2.15`                                | This version of Ceph (Octopus) is pinned for the CSM 1.2 release. The next major version of CSM will support Ceph (Pacific). |
| `csm-dckr/stable/quay.io/cephcsi/cephcsi:v3.5.1`                            | Upstream fixes became available after CSM 1.2 release content was frozen. |
| `csm-dckr/stable/csm-config:1.9.31`                                         | The vulnerability was discovered after CSM 1.2 release content was frozen and will be addressed in the next major CSM release. |
| `csm-dckr/stable/dckr.io/bitnami/external-dns:0.10.2-debian-10-r23`         | Upstream fixes are needed and are not yet available. |
| `csm-dckr/stable/quay.io/kiali/kiali:v1.28.1`                               | Upstream fixes are needed and are not yet available. There is a procedure to [Remove Kiali](operations/system_management_health/Remove_Kiali.md) if desired. |
| `csm-dckr/stable/k8s.gcr.io/kube-proxy:v1.20.13`                            | Upstream fixes are needed and are not yet available for the `1.20.13` version of Kubernetes included in CSM 1.2. |
| `csm-dckr/stable/dckr.io/nfvpe/multus:v3.1`                                 | Upstream fixes are needed for resolution. However, this image is only needed for the upgrade to CSM 1.2 and is purged afterwards. |
| `csm-dckr/stable/dckr.io/nfvpe/multus:v3.7`                                 | Upstream fixes are needed and are not yet available. |
| `quay.io/oauth2-proxy/oauth2-proxy:v7.2.1`                                  | The latest tagged image was pinned to use `alpine:3.15.0` and was not addressed upstream until after CSM 1.2 release content was frozen. |
