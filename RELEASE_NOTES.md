# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.5 contains many changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

* Highly available `prometheus` through integration of `thanos`
* Support and migration to `bitnami-etcd`
* Updates to all services using `etcd` cluster to migrate to use of `bitnami-etcd`
* Support for old and new `spire` versions running simultaneously toward zero downtime upgrades
* Technical Preview Support for `spire` `TPM-based` remote node attestation
* v1 of Power Control Service (PCS) is active.
* The v3 CFS API is now available, including support for paging, external repository "sources", and new options for debugging.
* Update of all services using `postgres` to support new versions of `postgres` and `postgres-operator`
* Required changes in multiple places to make `bosV2` the default
* Update `spire` version
* Update version of `cert-manager`
* Upgrade to `Kubernetes` version 1.22
* Bump `iuf-cli` version to 1.4.5
* Upgrade `argo` version to pick up bug-fixes
* BOS implement OPA policies for Multi-Tenancy
* Create DNAME records in PowerDNS
* For Birfurcated CAN update kiali to use the new API Gateways
* For Birfurcated CAN update cray-sysmgmt-health to use the new API Gateways
* For Birfurcated CAN update gitea-vcs-web to use CMN Only Istio Gateway
* For Birfurcated CAN update gitea-vcs-external to use CMN Only Istio Gateway
* Improved logging in cray-nls based on StageOutput
* IMS - created an arm64 version of the barebones recipe
* Support for large system ARP configuration for first boot and DHCP    

### Monitoring
* Removed cleartext switch passwords from the cray-sysmgmt-health-canu-test pod log

### Networking

### Miscellaneous functionality
* Ceph nodes run user facing docker registry that is writable anonymously

### New hardware support
* Add switches in HSM to PCS and allow for power reset actions
* Updated HMS discovery process to populate a node's architecture when making the information available via Redfish
* Update to ilorest 4.1.0.0 for Gen11 Support

### Automation improvements

* Updates to etcd health checks due to replacement of `etcd` vendor to `bitnami-etcd`
* `IUF` stage for `management-nodes-rollout` consumes logs from `ncn-rebuild`
* Add a test to check taints on master nodes
* Augment `postgres` backup `goss` test to also check for `cronjob`
* Argo-driven Upgrade Automation for K8s Storage Nodes
* ceph upgrade added to automated storage upgrade    

### Base platform component upgrades

| Platform Component           | Version        |
|------------------------------|----------------|
| `Kubernetes`                 | 1.22.13        |
| `containerd`                 | 1.5.16         |
| `istio`                      | 1.11.8         |
| `thanos`                     | 0.31.0         |
| `prometheus-operator`        | 0.63.0         |
| `grafterm`                   | 1.0.3          |
| `keycloak`                   | 21.1.1         |
| `bitnami-etcd` on `ncn-mxxx` | 3.5.0          |
| `bitnami-etcd` for clusters  | 3.5.9          |
| `coredns`                    | 1.8.4          |
| `helm`                       | 3.11.2         |
| `postgresql`                 | 14.8           |
| `postgres-operator`          | 1.8.2          |
| `spire`                      | 0.12.2         |
| `spire-intermediate`         | 1.0.0          |
| `cray-spire`                 | 1.5.5          |
| `metrics-server`             | 0.6.3          |
| `cray-certmanager`           | 1.5.5          |
| `argo-workflows`             | 3.3.6          |
| `argo workflow-controller`   | 3.4.5          |

### Security improvements

* `CVE - KERNEL 5.14.21-150400.24.46.1 - mozilla-nss`
* Removed `postgresql` from `NCNs` to fix `CVEs`
* Updates to `bind-utils`, `curl`, `git-core`, `java-1_8_0-ibm`, and `less` in `NCN` image for `CVEs`
* Updates to `libfreebl3-hmac`, `libfreebl3`, `tar`, and `wireshark` in `NCN` image for `CVEs`
* `Metal-basecamp` and `cray-site-init` dependency updates
* Additional of `kyverno` and network policies to ensure some secure controls over `mqtt` namespace
* cf-gitea-import: Use CSM-provided alpine base image to resolve vulnerabilities
* Updated metacontroller:v4.4.0 to address CVE's
* Fixed CVE-2023-0386 in CSM 1.5 NCN Images
* Fixed CVE-2023-32233 in CSM 1.5 NCN Images 
* Developed OPA Policy to force Keycloak admin operations through CMN
* Updated cfs-ara:1.0.2 to address CVE's
* Updated hms-shcd-parser:1.8.0 to address CVE's
* Moved istio-ingressgateway-cmn service to use the customer-admin-gateway
  
### Customer-requested enhancements

* Keycloak upgrade for CVE fixes
* Enable bonded NMN connections for the UANs

### Documentation enhancements

* `IUF` documentation updates for `upgrade_all_products` issues
* Addition of a `CSM` cabling page for the management and edge network
* Added system recovery procedure for `keycloak`
* Updates in several places as a result of migration to `bitnami-etcd`
* Updates to `BOS` documentation to replace `CAPMC` references
* Update to `IUF` upgrade with `CSM` workflow diagram and documentation
* Updates to `postgres` backup procedures
* Updates to `NCN` Customization and Personalization documentation to use `sat bootprep`
* Remove known issue about restored etcd clusters missing PVC
* Added SNMP setup for all switches to Install/Update instructions
* Updated Keycloak documentation to use CMN LB for administrative tasks
* Updated screenshots and documentation steps for LDAP in upgraded Keycloak
* Updated IUF management-nodes-rollout documentation   

## Bug fixes

* Fix for invalid `preinstall` `VCS` check in `IUF` in the event of a fresh install
* Fix deployment failure due to `DNS` timeouts when `max_fails=0` is set in `coredns`
* Fixed an issue on upgrade of master `NCNs` due to not generating the `admin-tools` keyring
* Fix for case where `bootprep` files are missing when `prepare-images` stage is run in `IUF` with one argument
* Fix `IUF` issue with `SHS` error in `update-vcs-config` stage
* Ensure `IUF` stage for `management-node-rollout` is aborted, also abort `ncn-rebuild`
* Fixed issue with `Nexus` failing to move to another `NCN` on upgrade
* Fixed procedure to change root password and `SSH` keys so it would also work on image customization
* Update `tds_lower_cpu_requests.sh` script for `opensearch-masters` due to CPU it eats
* Fixed bug where `PCS` can become out of sync with `etcd`
* Removed `subPath` `volumeMount` in the `multus` `daemonset` to avoid being stuck in termination
* Improve existing image check logic for ims-python-helper
* Fix issue with etcd_cluster_balance.sh reporting failure when 3 pods are healthy and 4th is terminating
* Fixed issue where upgrading the cray-dns-unbound Helm chart should not wipe the DNS records
* Fixed an incorrectly written Network Policy in cray-drydock for mqtt/spire communication
* Fixed an issue where restarting kea on large systems wipes DNS records from configmap
* Updated Unbound to not forward .hsn queries to the site DNS
* Fxed for cray-externaldns-manager crashes when used with external-dns 0.13  
  
## Deprecations

* The `ipv4-resolvers` option has been removed for `CSI` as it is not used
* [CAPMC](glossary.md#cray-advanced-platform-monitoring-and-control-capmc)

For a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* Remove `TRS operator` for fresh installs and on upgrades
* Remove `metal-net` scripts as they are no longer used
* Remove `etcd-operator` as a result of migration to use `bitnami-etcd`
* [CRUS](glossary.md#compute-rolling-upgrade-service-crus)
* Deprecated [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos)
  v1 session template and boot set fields are no longer stored in BOS. For more information, see
  [Deprecated fields](operations/boot_orchestration/Session_Templates.md#deprecated-fields).

For a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

### Security vulnerability exceptions in CSM 1.5
