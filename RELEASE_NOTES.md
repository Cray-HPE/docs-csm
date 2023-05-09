# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.4 contains approximately 500 changes spanning bug fixes, new feature development, and documentation improvements. This page lists some of the highlights.

## New

* v1 of Power Control Service (PCS) is active.
* Cray CLI will default to version 2 (v2) for BOS, if a version is not specified.
* IUF workflows are created for fresh and upgrade installs.
* Singular Method for ncn image customization
* Updates SLES SP4 Base Image 

### Monitoring

* Implemented pod monitors to scrape SMF Kafka server and zookeeper Prometheus metrics
* Created grafana dashboards for Kyverno and to monitor Kyverno policy metrics with Prometheus
* Created grafana dasboards to monitor the internals of SMF Kafka server and zookeeper
* Created grafana  dashboard for OpenSearch cluster monitoring using Prometheus metrics 
* Created Prometheus Alerts for CPU and Memory usage for NCNs
* Created grafana dashboard to record timing data for each stage in the install/upgrade of shasta products
* Updated Prometheus to v2.41.0, alert manager to v0.25.0, and node-exporter to v1.5.0


### Networking
### DNS

* Created dns records for all aliases on the NMN
* Fixed the URI for PCS inside the service mesh `http://cray-power-control/` without the version
* Added IMS image ID and CFS configuration name to cray-nls API
* Fixed HSN NIC to only count devices that are HSN NICs
* Replaced weave with cilium as `default CNI`
* Migrated CSM Ansible plays from NCN node personalization to NCN image customization where appropriate

### Management Nodes (Ceph, Kubernetes Workers, and Kubernetes Managers)

* Removed the subPath volumeMount in the multus daemonset
* Updated `enable_chn.yml` ansible playbook to work during image customization
* Added dvs-mqtt spire workload
* Updated spire workload and cray-drydock changes for Artemis MQTT
* Fixed velero sub chart kubectl container reference
* Added `cf-gitea-import 1.8.0` to the 1.4 `index.yaml`
* Added Ceph latency and performance tuning into Ceph image
* Updated Unbound and Kea to support multiple Unbound loadbalancers
* Updated Cray-crus to integrate etcd bitnami chart
* Updated the cilium chart in the k8s image to 1.12.4
* Updated HMCollector to set key in kafka message
* Installed and configured Kata as part of our K8S Workers


### User Application Nodes (UAN)

* Created S3 bucket for use with podman (and other user files)

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
* Added PCS to `run_hms_ct_tests.sh` script
* LiveCD Packer ISO to improve image builds 
* Created CFS Debugging tool
* Added ARA Plugin to CFS
* Moved NCN and LiveCD images to SLES 15 SP4
* Adopted the newer `manifestgen-1.3.8-1`
* Added Description Field to CFS Configuration Objects
* Added bulk component updates to CFS cli 
* Added method to stop CFS/Batcher and cancel configuration
* Added the ability to choose the name of the customized image from the command line for cfs
* Added enum to CFS status filters
* Updated CFS Ansible requests/limits to configurable
* Updated CFS log levels to be controlled through an option
* Optimized the database queries inside of SLS

### New hardware support

* Added TpmState support for Castle hardware to SCSD

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
* Provided artifactory auth to SHASTARELM tools in CSM builds
* Upgraded `vault` from 1.5.5 to 1.12.1 and the `vault operator` to `1.16.0`
* Fixed CVEs in NCN Images - non-kernel impacting changes only
* Created read-only tapms API for getting tenant status
* Added OPA Rules for TPM workloads

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
* Fixed the issue in automated cray cli script by a change in CMN LB DNS
* Fixed the build issue when cms-meta-tools upgraded to authenticate to both DST's artifactory as well as CASM's artifactory
* Fixed the issue to not support RFC 8357 and Kea should only respond to clients on UDP port 68 
* Fixed issue with `node-images` promotions 
* Mitigated chance of switchport flapping
* Fixed HSM Cray CLI calls in `make_node_groups` script
* Fixed the timing out issue in Console - Helm post-upgrade hooks on large system upgrades
* Fixed the incorrect data issue while generating topology files `hmn_connections.json` 
* Fixed the issue where CSM delivers two files with ARP cache sysctl tuning settings instead of using SHS files
* Fixed CFS to utilize new IMS failed flag when ansible hits a failure
* Fixed Ansible warning if HSM includes groups with invalid characters
* Fixed CFS sessions don't fail when "git checkout" fails
* Fixed 1.4 iPXE with the DHCP Timeouts for allowing slower intel NICs to boot

## Deprecations

* [CAPMC](glossary.md#cray-advanced-platform-monitoring-and-control-capmc)
* Deprecated and removed CRUS from the CSM manifests 
* Deprecated and removed `v1alpha3` k8s interface
* Eliminated use of deprecated K8s APIs
* 

CSI: deprecate ipv4-resolvers option
For a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

The following previously deprecated features now have an announced CSM version when they will be removed:

* [BOS](glossary.md#boot-orchestration-service-bos) v1 was deprecated in CSM 1.3, and will be removed in CSM 1.9.
* [CRUS](glossary.md#compute-rolling-upgrade-service-crus) was deprecated in CSM 1.2, and will be removed in CSM 1.5.
* Removed the `TRS operator` for fresh installs and on upgrades
* Removed `Postgres` from CVE
* Removed `opa-gatekeeper` for CSM upgrade support
* Removed deprecated HSM v1 
* Removed `/etc/chrony.d/pool.conf` in the pipeline

For a list of all features with an announced removal target, see [Removals](introduction/deprecated_features/README.md#removals).

## Known issues

* UAIs use a default route that sends outbound packets over the CMN, this will be addressed in a future release so that the default route uses the CAN/CHN.

* Documented known issue with Antero node NIDs

* The Slurm installer released in CPE 23.03 (`cpe-slurm-23.03-sles15-1.2.10.tar.gz`) has an issue that causes failures when installed with the IUF.
  * (`ncn-m001#`) To work around the issue, run the following commands before the IUF `process-media` stage:

    ```bash
    tar -xf cpe-slurm-23.03-sles15-1.2.10.tar.gz
    sed -i -e 's_-cn$_-cn/_' wlm-slurm-1.2.10/iuf-product-manifest.yaml
    tar -zcf cpe-slurm-23.03-sles15-1.2.10.tar.gz wlm-slurm-1.2.10
    ```

  * If a previous installation failed, apply the workaround and re-install with the `iuf run --force` option.

* The PBS installer released in CPE 23.03 (`cpe-pbs-23.03-sles15-1.2.10.tar.gz`) has an issue that causes failures when installed with the IUF.
  * (`ncn-m001#`) To work around the issue, run the following commands before the IUF `process-media` stage:

    ```bash
    tar -xf cpe-pbs-23.03-sles15-1.2.10.tar.gz
    sed -i -e 's_-cn$_-cn/_' wlm-pbs-1.2.10/iuf-product-manifest.yaml
    tar -zcf cpe-pbs-23.03-sles15-1.2.10.tar.gz wlm-pbs-1.2.10
    ```

  * If a previous installation failed, apply the workaround and re-install with the `iuf run --force` option.
* The CRUS subcommands are inadvertently missing from the Cray CLI. See
  [CRUS Subcommands Missing From Cray CLI](troubleshooting/known_issues/CRUS_Subcommands_Missing_From_Cray_CLI.md).

### Security vulnerability exceptions in CSM 1.4
