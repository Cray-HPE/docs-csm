# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.5 contains many changes spanning bug fixes, new feature development, and
documentation improvements. This page lists some of the highlights.

## New

### New Software Support

* Resolved CASTS:
    * `CAST-31486`: `cray-powerdns-manager` not adding compute nodes to external DNS
    * `CAST-31712`: Unbound slamming DNS server with requests
    * `CAST-31867`: Fixed Unbound not publishing to Prometheus
    * `CAST-32362`: Unable to to monitor the progress of a boot of single node in the power on process when using BOS V2
    * `CAST-32978`: `prerequisites.sh` makes DNS not functional for some minutes
    * `CAST-33450`: Worker rebuild workflow: `update-bss-no-wipe`
    * `CAST-33608`: `spire` server slow to respond and crashing
    * `CAST-33719`: Missing entries in `haproxy` on storage nodes
    * `CAST-33922`: `PXE-E18: Server response timeout`
    * `CAST-34613`: DNS has forgotten about all Compute/Application nodes
    * `CAST-34633`: Add worker nodes to running system
    * `CAST-34692`: Kubernetes DNS not working/will not start
* Highly available `prometheus` through integration of `thanos`
* Support and migration to `bitnami-etcd`
* Updates to all services using `etcd` cluster to migrate to use of `bitnami-etcd`
* Support for old and new `spire` versions running simultaneously toward zero downtime upgrades
* Technical Preview Support for `spire` `TPM-based` remote node attestation
* Power Control Service (PCS) is released
* The V3 CFS API is now available, including support for paging, external repository "sources", and new options for
  debugging.
* Update of all services using `postgres` to support new versions of `postgres` and `postgres-operator`
* `BOS V2` is the default
* Update `spire` version
* Update version of `cert-manager`
* Upgrade to `Kubernetes` version 1.22
* Bump `iuf-cli` version to 1.4.5
* Upgrade Argo version to pick up bug-fixes
* BOS implement OPA policies for Multi-Tenancy
* Create DNAME records in PowerDNS
* For Bifurcated CAN update `kiali` to use the new API Gateways
* For Bifurcated CAN update `cray-sysmgmt-health` to use the new API Gateways
* For Bifurcated CAN update `gitea-vcs-web` to use CMN Only Istio Gateway
* For Bifurcated CAN update `gitea-vcs-external` to use CMN Only Istio Gateway
* Improved logging in `cray-nls` based on `StageOutput`
* IMS - created an ARM64 version of the barebones recipe
* Support for large system ARP configuration for first boot and DHCP
* Hardware Discovery Process populates a nodes's architecture
* Argo-driven Upgrade Automation for Kubernetes Storage Nodes
* SLS: Added caching to improve performance and robustness
* Added support for specifying IMS Image and Recipe architecture in IUF
* Upgraded node-images to SLES15SP5
* Updated Spire Server to work with TPM
* Added improved error logging for`bos` command
* Added a method to stop `CFS/Batcher` and cancel configuration for in-flight customizations
* Added support for git `submodules` in CFS runs
* Added support for `ARM 64` based builds through emulation
* Improved IUF Logging
* Created Networking Red Light / Green Light Dashboard
* Removed clear text switch passwords from the `cray-sysmgmt-health-canu-test` pod log
* Ceph nodes run user facing docker registry that is writable anonymously
* Added support for NID allocation defragmentation
* Multi-tenancy: Vault Transit (KMS) Support for Encrypted Secrets in VCS
* Multi-tenancy: Enable Tenant ID + Tenant Admin `AuthZ` Awareness for API Ingress (OPA policy)
* Multi-tenancy: Enable Tenant ID + Tenant Admin `AuthZ` Awareness for API Ingress
* Multi-tenancy: BOS Support for boot, reboot, node power on and off in tenant
* Transitioned from `cray-heartbeat` to `csm-node-heartbeat`

### New Hardware Support

* Add switches in HSM to PCS and allow for power reset actions
* Updated HMS discovery process to populate a node's architecture when making the information available via Redfish
* Update to `ilorest-4.1.0.0` for `Gen11` Support
* Support for ARM64 added
* Hardware validation of the EX2500 Cabinet
* Support JL627A switches as an edge router for BI-CAN
* Support for Broadcom PXE boots, and interface naming

## Improvements

### Automation Improvements

* Updates to `etcd` health checks due to replacement of `etcd` vendor to `bitnami-etcd`
* IUF stage for `management-nodes-rollout` consumes logs from `ncn-rebuild`
* Add a test to check master node taints
* Augment `postgres` backup `goss` test to also check for `cronjob`
* Argo-driven Upgrade Automation for Kubernetes Storage Nodes
* Ceph upgrade added to automated storage upgrade

### Base Platform Component Upgrades

| Platform Component           | Version |
|------------------------------|---------|
| `Kubernetes`                 | 1.22.13 |
| `containerd`                 | 1.5.16  |
| `istio`                      | 1.11.8  |
| `thanos`                     | 0.31.0  |
| `prometheus-operator`        | 0.63.0  |
| `grafterm`                   | 1.0.3   |
| `keycloak`                   | 21.1.1  |
| `bitnami-etcd` on `ncn-mxxx` | 3.5.0   |
| `bitnami-etcd` for clusters  | 3.5.9   |
| `coredns`                    | 1.8.4   |
| `helm`                       | 3.11.2  |
| `postgresql`                 | 14.8    |
| `postgres-operator`          | 1.8.2   |
| `spire`                      | 0.12.2  |
| `spire-intermediate`         | 1.0.0   |
| `cray-spire`                 | 1.5.5   |
| `metrics-server`             | 0.6.3   |
| `cray-certmanager`           | 1.5.5   |
| `argo-workflows`             | 3.3.6   |
| `argo-workflow-controller`   | 3.4.5   |
| `ceph`                       | 16.2.13 |

### Security Improvements

* CVE Kernel 5.14.21-150400.24.46.1 for `mozilla-nss`
* Removed `postgresql` from NCNs to fix CVEs
* Updates to `bind-utils`, `curl`, `git-core`, `java-1_8_0-ibm`, and `less` in `NCN` image for `CVEs`
* Updates to `libfreebl3-hmac`, `libfreebl3`, `tar`, and `wireshark` in `NCN` image for `CVEs`
* `Metal-basecamp` and `cray-site-init` dependency updates
* Additional of `kyverno` and network policies to ensure some secure controls over `mqtt` namespace
* `cf-gitea-import`: Use CSM-provided alpine base image to resolve vulnerabilities
* Updated `metacontroller:v4.4.0` to address CVE's
* Fixed `CVE-2023-0386` in CSM 1.5 NCN Images
* Fixed `CVE-2023-32233` in CSM 1.5 NCN Images
* Developed OPA Policy to force Keycloak admin operations through CMN
* Updated `cfs-ara:1.0.2` to address CVE's
* Updated `hms-shcd-parser:1.8.0` to address CVE's
* Moved `istio-ingressgateway-cmn` service to use the customer-admin-gateway
* Kyverno Upgrade Needed for `N-2` Support Policy
* Fixed Improper Certificate Validation CVE in `cfs-operator`
* Fixed Regular Expression DoS CVE in `cfs-ara`
* Addressed `Zenbleed` CVE on NCNs
* Addressed `CVE-2023-38545` (curl & `libcurl`) on NCNs
* Added Default RBAC Role for Telemetry API
* In SAT upgraded `paramiko` to resolve `CVE-2023-48795`

### Customer-Requested Enhancements

* Keycloak upgrade for CVE fixes
* Enable bonded `NMN` connections for the UANs

### Documentation enhancements

* IUF documentation updates for `upgrade_all_products` issues
* Addition of a CSM cabling page for the management and edge network
* Added system recovery procedure for `keycloak`
* Updates in several places as a result of migration to `bitnami-etcd`
* Update to BOS documentation to replace CAPMC references
* Update to IUF upgrade with CSM workflow diagram and documentation
* Update to `postgres` backup procedures
* Update to NCN Customization and Personalization documentation to use `sat-bootprep`
* Remove known issue about restored etcd clusters missing PVC
* Added SNMP setup for all switches to Install/Update instructions
* Updated Keycloak documentation to use CMN LB for administrative tasks
* Updated screenshots and documentation steps for LDAP in upgraded Keycloak
* Updated IUF management-nodes-rollout documentation

## Bug Fixes

* Fix for when QLogic adapter firmware stops responding then fails recovery causing the node to crash.
    * Fixes
        * QLogic/Marvel Driver Update -
          RPM: `qlgc-fastlinq-kmp-default-8.74.1.0_k5.14.21_150500.53-1.sles15sp5.x86_64.rpm`
        * SUSE Kernel Update: Version: `5.14.21-150500.55.39.1.27360.1.PTF.1215587`
* Fix for invalid `preinstall` VCS check in IUF in the event of a fresh install
* Fix deployment failure due to DNS timeouts when `max_fails=0` is set in `coredns`
* Fixed an issue on upgrade of master NCNs due to not generating the `admin-tools` keyring
* Fix for a case where `bootprep` files are missing when `prepare-images` stage is run in IUF with one argument
* Fix IUF issue with SHS error in `update-vcs-config` stage
* Ensure IUF stage for `management-node-rollout` is aborted, also abort `ncn-rebuild`
* Fixed issue with Nexus failing to move to another NCN on upgrade
* Fixed procedure to change root password and SSH keys so it would also work on image customization
* Update `tds_lower_cpu_requests.sh` script for `opensearch-masters` due to CPU it eats
* Removed `subPath-volumeMount` in the `multus-daemonset` to avoid being stuck in termination
* Improve existing image check logic for `ims-python-helper`
* Fix issue with `etcd_cluster_balance.sh` reporting failure when 3 pods are healthy and 4th is terminating
* Fixed issue where upgrading the `cray-dns-unbound` Helm chart should not wipe the DNS records
* Fixed an incorrectly written Network Policy in `cray-drydock` for `mqtt/spire` communication
* Fixed an issue where restarting `kea` on large systems wipes DNS records from `configmap`
* Updated Unbound to not forward `.hsn` queries to the site DNS
* Fixed when `cray-externaldns-manager` crashes when used with `external-dns-0.13`
* Fixed an issue where Weave pods were not starting after upgrading to CSM V1.4 content
* Fixed PowerDNS server TLD is missing NS delegation records for subdomains
* Fixed an issue where FRU Tracking doesn't create a detected event after a removed event

## Deprecations

* The `ipv4-resolvers` option has been removed for CSI as it is not used
* [CAPMC](glossary.md#cray-advanced-platform-monitoring-and-control-capmc)
* Removed ARS from Cray CLI and BSS API specification
* Removed deprecated BOS V1 CFS fields from session templates

For a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

* Remove `TRS-operator` for fresh installs and on upgrades
* Remove `metal-net` scripts as they are no longer used
* Remove `etcd-operator` as a result of migration to use `bitnami-etcd`
* [CRUS](glossary.md#compute-rolling-upgrade-service-crus)
* Deprecated [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos) v1 session template and boot
  set fields are no longer stored in BOS.
    * For more information,
      see [Deprecated fields](operations/boot_orchestration/Session_Templates.md#deprecated-fields)
* Removed -P option from `cray-dhcp-kea` startup options
* Stopped using `skopeo` images < 1.13.2

For a list of all features with an announced removal target,
see [Removals](introduction/deprecated_features/README.md#removals)

## Known Issues

* FAS Loader / HFP script `post-deliver-product.sh`
    * Loading firmware from Nexus using the FAS Loader will intermittently crash with HFP release 23.12 or later. Rerunning the FAS Loader will be required.
    * This affects the HFP script `post-deliver-product.sh` which will hang when the FAS Loader crashes. Rerunning the script will be required.
    * IUF procedure calls the `post-deliver-product.sh` script and may require restarting that IUF process.
    * This is expected to be fixed in CSM 1.5.1.
* PCS (Power Control Service) is unable to place power caps on `Blanca Peak` (`ex254n`) and Parry Peak (`ex255a`) compute nodes
    * To workaround this issue, use CAPMC to place power caps on these node types
    * Issue is fixed in CSM 1.5.1
* `cray-tftp-upload`
    * The `cray-tftp-upload` script errors out because of a change to the `ipxe` pods and the TFTP repository.
    * This error affects the `cray-upload-recovery-images` script.
    * This is expected to be fixed in CSM 1.5.1.
    * A workaround is presented in [Upload BMC Recovery Firmware into TFTP Server](operations/firmware/Upload_Olympus_BMC_Recovery_Firmware_into_TFTP_Server.md)
* `check_bios_firmware_versions.sh` script does not report valid expected firmware versions.
    * Correct firmware versions are:
        * 1.53, 2.78 or 2.98 for DL325 / DL385 firmware.
        * `v1.48`, `v1.50`, `v1.69` or `v2.84` for DL325 / DL385 BIOS.
        * C38 for Gigabyte BIOS.
    * Update will be in CSM 1.5.1.
