# Cray System Management (CSM) - Release Notes

## CSM 1.2.0
CSM 1.2 contains approximately 2000 changes spanning bug fixes, new feature development, and documentation improvements. Below are some of the highlights

## New

### Monitoring
* New Dashboard for network traffic dashboard
* New Dashboard for Kubernetes and microservice health dashboard
* New Dashboard for Boot Dashboard
* New command line Dashboard for critical services like smd, smd-postgres, capmc and hbtd
* New Dashboard for Grafana dashboard for critical services like smd,capmc,smd-postgres and hbtd
* Management nodes sample SMART data and publish it to SMA/SMF
* Support for HPE PDU telemetry

### Networking
* Release Cray Automated Network Utility - CANU V1.0.0
* Performance improvements to Unbound and DHCP Helper
* Initial Release of Bifurcated CAN

  The user and administrative traffic segregation introduced by Bifurcated CAN has changed the URLs for certain services as it is now necessary to include the network path in the fully qualified domain name. Access to administrative services is now restricted to the Customer Management Network (CMN). API access is available via the Customer Management Network (CMN), Customer Access Network (CAN), and Customer Highspeed Network (CHN).

  The following table assumes the system was configured with a `system-name` of `shasta` and a `site-domain` of `dev.cray.com`.

  | Old Name                         | New Name                                |
  |----------------------------------|-----------------------------------------|
  | auth.shasta.dev.cray.com         | auth.cmn.shasta.dev.cray.com            |
  | nexus.shasta.dev.cray.com        | nexus.cmn.shasta.dev.cray.com           |
  | grafana.shasta.dev.cray.com      | grafana.cmn.shasta.dev.cray.com         |
  | prometheus.shasta.dev.cray.com   | prometheus.cmn.shasta.dev.cray.com      |
  | alertmanager.shasta.dev.cray.com | alertmanager.cmn.shasta.dev.cray.com    |
  | vcs.shasta.dev.cray.com          | vcs.cmn.shasta.dev.cray.com             |
  | kiali-istio.shasta.dev.cray.com  | kiali-istio.cmn.shasta.dev.cray.com     |
  | s3.shasta.dev.cray.com           | s3.cmn.shasta.dev.cray.com              |
  | sma-grafana.shasta.dev.cray.com  | sma-grafana.cmn.shasta.dev.cray.com     |
  | sma-kibana.shasta.dev.cray.com   | sma-kibana.cmn.shasta.dev.cray.com      |
  | api.shasta.dev.cray.com          | api.cmn.shasta.dev.cray.com<br>api.chn.shasta.dev.cray.com<br>api.can.shasta.dev.cray.com |

* PowerDNS authoritative DNS server
  * Supports zone transfer to external DNS servers via AXFR query and DNSSEC
  * Please refer to the [PowerDNS Migration Guide](./operations/network/dns/PowerDNS_migration.md) and [PowerDNS Configuration Guide](./operations/network/dns/PowerDNS_Configuration.md) for further information.

* Management network switch hostname changes

  The management network switch hostnames have changed in CSM 1.2 to more accurately reflect the usage of each switch type.

  | Old Name | New Name    | Usage                                                     |
  |----------|-------------|-----------------------------------------------------------|
  | sw-spine | Unchanged   | Network spine that links to other switches.               |
  | sw-agg   | sw-leaf     | NMN connections for NCNs and Application nodes.           |
  | sw-leaf  | sw-leaf-bmc | BMC connections, PDUs, Slingshot switches, Cooling doors. |

### Miscellaneous Functionality
* SLES15 SP3 Support for NCNs, UANs, Compute Nodes, and Barebones validation image
* S3FS added to master and worker nodes for storing SDU dumps and CPS content
* Improved FAS (Firmware Action Service) error reporting
* CFS State reporter added to storage nodes
* Numerous new Goss tests added along with improved error logging
* CAPMC support for HPE Apollo 6500 power capping
* CAPMC support for new power schema for BardPeak power capping
* CAPMC support for HPE G2 Metered 3Ph 39.9kVA 60A 480/277V FIO PDU
* Improved CAPMC error handling in BOA
* Root user password and SSH keys now handled by NCN personalization after initial install; locations of data changed in Hashicorp Vault from previous releases
* Generic Ansible passthrough parameter added to CFS session API
* Improved CFS session resiliency after power outages
* Pod priority class additions to improve upgrades and fail-over

### New Hardware Support
* Olympus Bard Peak Blade (AMD Trento with AMD MI200) with Slingshot 11 - Compute Node
* Olympus Grizzly Peak NVidia A100 80GB GPU - Compute Node
* Milan-Based DL385 Gen10+ with AMD Mi100 GPU - UAN and Application Node
* Milan-Based Apollo 6500/XL675d Gen10+ with NVIDIA A100 40GB - Compute Node
* Milan-Based Apollo 6500/XL645d Gen10+ with NVIDIA A100 80GB - Compute Node
* HPE G2 Metered 3Ph 39.9kVA 60A 480/277V FIO PDU

### Automation Improvements
* Validation of CSM health in several areas
* Automated Administrative Access configuration
* Automated Installation of CFS set-up of passwordless SSH
* Validation of Management Network cabling
* Automated the firmware check on PIT
* keycloak-installer is released
* CSM Install and Upgrade automation improvements

### Base Platform Component Upgrades
* istio V1.8 from istio V1.7
* Release of Loftsman V1.2.0-1
* Kubernetes V1.20.13 from Kubernetes V1.19.9
* Ceph V15.2.15 from V15.2.8

### Security Improvements
* Switch to non-root containers - A significant number of root user container images have been removed. The remainder have been identified for a future release
* Verification of signed RPMs
* CVE Remediation - A significant number of CVEs have been addressed, including a majority of the critical and High CVEs like `polkit` and `log4j`
* Updates to Nexus require authentication
* Remove of code injection vulnerability in `commit` and `cloneURL` fields of CFS configuration API
* Further restrictions on allowed HTTP verbs in API requests coming from compute nodes
* Option to restrict compute to only call URIs by machine identity

### Customer Requested Enhancements
* Ability to turn off slots without `hms-discovery` powering them on
* Resilient way to reboot a compute node into its current configuration with a single API call

## Bug Fixes
* Documented Optimized BIOS Boot Order for NCNs
* Slingshot switches attempting dhcp renewal to unreachable address
* Node will not reboot following upgrade of BMC and BIOS
* Worker node container /var/lib/containerd is full and pods in 'ContainerCreating' state
* Incorrect data or bad monitor filters in sysmgmt-health namespace
* Hardware State Manager showing compute nodes in standby after cabinet level power down procedure
* Cray hsm inventory hardware describe reports incorrect DIMM Id and Name
* Image customization CFS jobs do not set an ansible limit when customizing
* No /proc available in CFS image container
* "conman" reconnects to nodes every hour, reissuing old messages with updated time stamps
* CFS can leave sessions pending after a power outage
* sonar-jobs-watcher not stopping orphaned CFS pods
* fixed issues causing PXE boot failures during installs, upgrades, and NCN rebuilds

## Deprecations
* CRUS has been deprecated. It will be removed in a future release and replaced with BOSv2, which will provide similar functionality.
* PowerDNS will replace Unbound as the authoritative DNS source in a future CSM release.
  * The cray-dns-unbound-manager CronJob will be deprecated in a future release once all DNS records are migrated to PowerDNS.
  * The introduction of PowerDNS and Bifurcated CAN will introduce some node and service naming changes.
  * Please see the [PowerDNS Migration Guide](./operations/network/dns/PowerDNS_migration.md) for more information.
## Removals
* The V1 version of the CFS API was removed
* The cray-externaldns-coredns, cray-externaldns-etcd, and cray-externaldns-wait-for-etcd pods have been removed. PowerDNS is now the provider of the external DNS service.

## Known Issues
