# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.4 contains approximately 500 changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

* v1 of Power Control Service (PCS) is active.
* Cray CLI will default to version 2 (v2) for BOS, if a version is not specified.

### Monitoring

* Implemented pod monitors to scrape SMF Kafka server and zookeeper Prometheus metrics
* Created grafana dasboards to monitor the internals of SMF Kafka server and zookeeper
* Created service monitor OpenSearch cluster monitoring using Prometheus
* Created grafana  dashboard for OpenSearch cluster monitoring using Prometheus metrics 
* Created grafana dashboard to record timing data for each stage in the install/upgrade of shasta products

### Networking
### DNS

* Created dns records for all aliases on the NMN
* Fixed the URI for PCS inside the service mesh `http://cray-power-control/` without the version
* Added IMS image ID and CFS configuration name to cray-nls API

### Management Nodes (Ceph, Kubernetes Workers, and Kubernetes Managers)

* Removed the subPath volumeMount in the multus daemonset
* Updated `enable_chn.yml` ansible playbook to work during image customization
* Added dvs-mqtt spire workload
* Updated spire workload and cray-drydock changes for Artemis MQTT
* Fixed velero sub chart kubectl container reference
* Added `cf-gitea-import 1.8.0` to the 1.4 `index.yaml`

### User Application Nodes (UAN)

* Created S3 bucket for use with podman (and other user files)
* 

### Miscellaneous functionality

* Increased the VCS Memory limit 
* Updated BOS V2 the default in SAT
* Created helm chart to deploy ActiveMQ Artemis + istio config changes
* libcsm is now available via the GCP distribution endpoint and is included in the CSM tarball
* Updated csm-tftpd to use `IPXE 1.11.1` image
* Updated prerequisite script to prevent ncn hostname change 
* Updated goss test to handle post build and rebuild cases for worker mount usage
* Added `hmcollector.hmnlb.<system-name>.<site-domain>` to collector's virtual service
* Restored "ll" alias in ncn images
* Updated the Cray CLI for BOS with the clear-stage option.
* Updated OPA rules for PCS

### New hardware support

### Automation improvements

* IUF workflows are created for fresh and upgrade installs.
* Used squashfs scan technique to get pit iso packages list

### Base platform component upgrades

| Platform Component           | Version        |
|------------------------------|----------------|
| Ceph                         | `16.6.29`      |
| `containerd`                 | `1.5.10`       |

### Security improvements

* IPXE binary name randomization for added security
* Used CSM-provided alpine base image to resolve Snyk vulnerabilities in cf-gitea-import
* Updated openssl for CVE
* Fixed CVEs in `artifactory.algol60.net/csm-dckr/stable/dckr.io/nfvpe/multus:v3.7`
* Added platform CA bundle to argo namespace
* Fixed CVEs in `artifactory.algol60.net/csm-dckr/stable/cray-uai-gateway-test:1.8.0`
* Fixed CVEs in `artifactory.algol60.net/csm-dckr/stable/cray-uas-mgr:1.22.0`
* Fixed CVEs in `artifactory.algol60.net/csm-dckr/stable/update-uas:1.8.0`
* Fixed CVEs in `artifactory.algol60.net/csm-dckr/stable/quay.io/cilium/json-mock:v1.3.3`

### Customer-requested enhancements

* Created dns records for all aliases on the NMN
* NERSC enablement of bonded NMN connections for the UANs
* Added csm-embedded repository to all NCNs on install and upgrade

### Documentation enhancements

* Added documentation for 
  * `IUF` workflows for fresh and upgrade install 
  * Increasing helm chart deploy timeout
  
* Updated documentation for
  * CSM upgrade `UPGRADE_KYVERNO_POLICY` step failed due to missing "dvs" namespace
  * Automated sat bootprep usage instead of manual steps for NCN customization and personalization
  * System recovery procedure for keycloak
  * Steps to configure SNMP credentials 
  * Use BOS v2 in prepare-images stage
  * Keycloak to use CMN LB for administrative tasks
  * Add cray product catalog module`scripts/operations/configuration/python_lib`
  * Add NCN squashfs IMS ID/version/name to cray product catalog
  * Keycloak API upgrade
  * new name for management NCN CFS configuration
  * `docs/pit-init` to include arch when referring to artifacts
  * Master node disk reboot test defaulted to PXE
  * New protected S3 NCN images
  * Stage 4 upgrade to include info on automation
  * Procedure to find Argo logs in S3
  * CFS usability changes
  * "NCN Node Personalization" step that modifies CPE/Analytics layers
  * Ceph troubleshooting page 
  * User to know cronjobs may need to be restarted after Bare-Metal etcd cluster restore
  * `hms_verification/verify_hsm_discovery.py` failure to reference SNMP configuration doc
  * `write_root_secrets_to_vault.py`
  
## Bug fixes

* Fixed the issue with master taint check that was added to kubernetes-cloudinit.sh isn't being called on "first-master"
* Fixed `cray-product-catalog image` path in cray-product-catalog chart
* Fixed the kyverno issue that prevents weave-net daemonset from creating pods
* Fixed `ncn-healthcheck-master-single` test failure when LDAP server not configured
* Fixed storage node upgrade in loop
* Fixed DNS timeouts
* Fixed(increased)Kyverno and Kyverno-pre containers memory resources causing critical pods fail to start
* Fixed `install-csi` to dynamically get `csm-sle-15spX` version
* Fixed Argo workflow for worker upgrade failing at csi install
* Fixed NCN health checks failing for Switch BGP test
* Fixed `set-bmc-ntp-dns.sh` options when BMC name not specified
* Fixed the Gitea web UI issue that requires logging in twice
* Fixed the missed ldap cert configuration for Keycloak 4.0.0
* Fixed the PCS issue /power-status returning invalid managementState of "undefined" for BMC
* Fixed `cray-sysmgmt-health-grok-exporter` instances to have all master nodes instead of just `m001`
* Fixed the pit-observability issue failing in a fresh/new PIT instance
* Fixed the "fabric" and "gitpython" dependencies for systems with `cfs-debug` tool installed
* Fixed(increased) the hnc replicas for redundancy webhook endpoints
* Added the missing whitespace from cray CLI CFS usage message
* Fixed the cps pods not restored during argo ncn rebuilds

## Deprecations

* [CAPMC](glossary.md#cray-advanced-platform-monitoring-and-control-capmc)
* Deprecated and thus removed CRUS from the CSM manifests 

CSI: deprecate ipv4-resolvers option
For a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

The following previously deprecated features now have an announced CSM version when they will be removed:

* [BOS](glossary.md#boot-orchestration-service-bos) v1 was deprecated in CSM 1.3, and will be removed in CSM 1.9.
* [CRUS](glossary.md#compute-rolling-upgrade-service-crus) was deprecated in CSM 1.2, and will be removed in CSM 1.5.
* Removed the `TRS operator` for fresh installs and on upgrades
* Removed Postgres from CVE

For a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

* UAIs use a default route that sends outbound packets over the CMN, this will be addressed in a future release so that the default route uses the CAN/CHN.
* Documented known issue with Antero node NIDs

### Security vulnerability exceptions in CSM 1.4
