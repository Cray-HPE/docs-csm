# Cray System Management (CSM) - Release Notes

[CSM](glossary.md#cray-system-management-csm) 1.6.1 contains many changes spanning bug fixes, new feature development, and
documentation improvements. This page lists some of the highlights.

## Features

### New software support

* `CASMMON-458` Upgrade Victoria metrics to 0.24.5 in cray-sysmgmt-health
* `CASMHMS-6317` Upgrade HMS projects to golang 1.23
* `CASMHMS-6303` BSS and HMETCD - upgrade golang and go based 3rd party software
* `CASMPET-7251` Update cray-keycloak for new JobConditionType SuccessCriteriaMet
* `CASM-5107` Update iuf-cli,cray-nls and cray-nls-charts version in CSM

### New hardware support

> ***`IMPORTANT`*** For systems with NVIDIA CPUs and GPUs must see [Known issues](#known-issues)

## Improvements

### General improvements

* `CASMPET-7263` TESTS: goss-servers should delay start until hostname is set
* `CASMCMS-9188` TESTS: cmsdev: Add explicit check for blank CFS ID field
* `CASMPET-7262` TESTS: After installing csm-testing RPM, automatically restart goss-servers
* `CASMCMS-9189` Update CFS API spec to reject invalid component creation/update requests
* `CASMCMS-9197` Bypass needless work in some CFS queries
* `CASMCMS-9200` Make CFS Options class thread-safe and more performant
* `CASMCMS-9202` Add ability to create CFS source and specify secret name instead of username/pw
* `CASMCMS-9207` Update CFS API spec with actual status code for successful source restore
* `CASMCMS-9208` Decode source_name when restoring source
* `CASMCMS-9211` Improve CFS config delete performance on scale systems
* `CASMHMS-6299` PCS/TRS: Mitigate resource leaks / heavy usage
* `CASMPET-7288` TESTS: Minimize use of system Python packages in virtual environment
* `CASMPET-7290` TESTS: Add pylint to csm-testing build pipeline
* `MTL-2514` Pin cni / cni-plugins RPM's to the latest version from SLE-Module-Containers
* `CRAYSAT-1896` Update "sat bootprep" to support CFS v2 or v3
* `SSI-14310` Update CSM 1.6 configuration page to include USS product changes.
* `CRAYSAT-1923` Update "sat bootsys" to support CFS v2 or v3
* `CRAYSAT-1936` Add ability to sort reports by multiple fields
* `CASMINST-7039` Cleanup previous/old SquashFS images during upgrade
* `CRAYSAT-1942` Drop internal default values for rootfs_provider{,passthrough} from sat bootprep
* `CASMCMS-9225` Add context managers around BOS requests/sessions; enable paging of BOS components
* `CASMMON-463` Update customization.yaml for sma victoria metrics pvc size
* `CASMCMS-9068` Allow customization of ipxe debug options
* `CASMINST-6968` Replace `sed` calls with `yq` in upgrade_control_plane.sh
* `CASMCMS-9177` Make BOS migration pod more polite
* `CASMHMS-6360` Make cray-hms-rts version consistent in csm manifest
* `CASMINST-6968` Replace `sed` calls with `yq` in upgrade_control_plane.sh
* `CASM-5267` Avoid infinite loop while uploading artifacts with cray-nexus-setup image

### Base platform component upgrades

| Platform Component           | Version |
|------------------------------|---------|
| Kubernetes                   | 1.24.17 |
| `containerd`                 | 1.5.16  |
| `istio`                      | 1.19.10 |
| `kiali`                      | 1.75.0  |
| `Strimzi Kafka`              | 0.41.0  |
| `Kyverno`                    | 1.10.7  |
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

### Security improvements

* `Kyverno` is upgraded from 1.9.5 version to 1.10.7 version to address CVEs.
* `CASMHMS-6282` Fix CVE's in artifactory.algol60.net/csm-docker/stable/cray-firmware-action:1.34.0
* `CASMCMS-9035` Remove sshd from cray-console-operator image

### Customer-requested enhancements

* iSCSI based boot content projection for `rootfs` and `PE` images.
* `CASMNET-2240` CSCS - CSM 1.5.1 canu generated switch config security concern

### Documentation enhancements

* `CASMPET-7207` DOCS: Add in Tenant aware authorization to vault endpoints
* `CASMHMS-6298` DOCS: Fix hsm backup restore docs
* `CASMTRIAGE-7458` DOCS: Odin 1.6.0-rc.4 install - cannot boot any image (1.6 or previous 1.5.2)
* `CASMCMS-9191` DOCS: Document how to delete CFS components with ID fields that are empty strings
* `CASMCMS-9195` DOCS: CFS import tool should handle case where node has empty ID field value
* `CAST-32468` DOCS: 22.11.2 ncn-m001 upgrade fails
* `CASMTRIAGE-7226` DOCS: vShasta: cfs-api pods in CLBO due to absence of cray-shared-kafka-kafka-bootstrap service
* `CASMCMS-9194` DOCS: Update CFS export tools for v3 changes
* `CASMTRIAGE-7471` DOCS: IUF documentation needs to state when and how to create site_vars.yaml
* `CASMCMS-9204` DOCS: Update CFS import tool to handle v3 options
* `CASMTRIAGE-7470` DOCS: Odin : 1.6.0-rc.4 upgrade : cray-site-init path doesn't exist.
* `CASMINST-7042` DOCS: minor wording changes in the IUF CSM upgrade process
* `CASMINST-7035` DOCS: Rework IUF documentation to remove manual CSM upgrade option
* `CASMTRIAGE-7503` DOCS: configuring remote build node customization of barebones image failed with missing repos
* `CASMINST-7038` DOCS: Ensure CLI/test RPMs updated during CSM upgrade before doing post-service-upgrade health checks
* `CASMTRIAGE-7358` DOCS: Storage node cloud-init fails, mon_max_pg_per_osd exceeded
* `CASMTRIAGE-7475` DOCS: Import of IMS data terminated with message " Multiple images data files found in /app/src/server/app.py"
* `CASMCMS-9205` DOCS: Update CFS import tool with missing config fields
* `CASMCMS-9209` DOCS: Update CFS import tool to handle altered v3 component update response
* `CASMTRIAGE-7471` DOCS: IUF documentation needs to state when and how to create site_vars.yaml
* `CASMCMS-8712` DOCS: Document how to reference secrets in Vault using SOPS in Ansible.
* `CASMINST-6426` DOCS: LDAP cacert looking for wrong issuer
* `CASMINST-6922` DOCS: Add Information for QLogic Driver & Firmware
* `CASMPET-7280` DOCS: Create MDS fail troubleshooting pageCASMTRIAGE-7545 DOCS: cray-externaldns-external-dns in CLBO due to duplicate vault annotations
* `MTL-2455` DOCS: Update kdump documentation in docs-csm
* `CASMINST-6711` DOCS: Command Mismatch When Setting up SNMP on Dell and Mellanox switches
* `CASMPET-7286` DOCS: Update CSM 1.6 Release Notes with kafka PET component
* `CASMMON-461` DOCS: Modify upgrade fresh install scripts and change the documentation for victoriametrics upgrade
* `USS-2479` DOCS: Odin 1.6.0-rc4 tenant pods not in expected state
* `USS-2050` DOCS: Multitenancy example documentation needs changes
* `CASMNET-2238` DOCS Add switch firmware upgrade step to CSM upgrade procedure
* `CASMINST-7041` DOCS: add manual node upgrade procedure if manual intervention is needed
* `CASMINST-7088` DOCS: add note when creating site vars if USS is 1.1 or later
* `CASMCMS-9234` DOCS: BOS migration code can result in inaccessible templates
* `CASMTRIAGE-7504` DOCS: needs a correction on 'kubectl exec keycloak-postgres-0 -c postgres -n services -it -- patronictl list'
* `CASMTRIAGE-7577` DOCS: full system power up documentation needs cray-spire added to spire troubleshooting
* `CASMTRIAGE-7618` DOCS: loki >> pre-install-check failing on csm-1-6-0-pre-hook
* `CASMCMS-9232` DOCS: Improve BOS' documentation around the term `enabled`
* `CASMTRIAGE-7616` DOCS: #rocket : cert-manager helm chart version 1.12.9 note: no cert-manager upgrade steps needed, cert-manager 1.5.5 is not installed
* `CASMHMS-6286` DOCS: CAST-36961 changes for replacing a compute blade
* `CRAYSAT-1951` DOCS: update SAT documentation describing support for CFS v3 in CSM 1.6.1
* `CASMINST-7106` DOCS: Fix bad UAN ethernet naming for HPE nodes
* `CASMPET-6863` DOCS: etcd-base-chart has rollback issues in CSM 1.6
* `CASMCMS-9242` DOCS: BOS: Make CAPMC/PCS timeout configurable, like with CFS
* `CASMCMS-9244` DOCS: Make CASMCMS-9234 workaround more resilient
* `CASMHMS-6322` DOCS: Need to remove notice about NVIDIA GPU not being supported
* `CASMMON-467` DOCS: Update customization.yaml for sma victoria metrics in update-customizations.sh
* `CASMCMS-9246` DOCS: CSM upgrade failed: BOS database Kubernetes pod not running
* `CASMTRIAGE-6736` DOCS: Fresh install workflow lacks documentation for ARP tuning
* `CASMINST-7112` DOCS: Linting
* `CASMTRIAGE-7570` DOCS: Error setting ip address while adding storage node to cluster
* `CASMINST-7110` DOCS: Fix IUF diagram for CSM upgrade
* `CASMNET-2277` DOCS: update CAN reference to CMN in PowerDNS docs
* `CASMTRIAGE-7358` DOCS: Storage node cloud-init fails, mon_max_pg_per_osd exceeded
* `CASMCMS-9242` DOCS: BOS: Make CAPMC/PCS timeout configurable, like with CFS
* `USS-2317` DOCS: Document multi-tenancy VNI enforcement
* `CASMMON-468` DOCS: update-customizations.sh breaks customizations template for 1.6 > 1.6 and 1.6 > 1.7 upgrades
* `CASMTRIAGE-7705` DOCS: iuf management-rollout to canary worker node fails without MEDIA_DIR and refuses to run on canary node
* `CASMHMS-6367` DOCS: Document HSM memory leaks in 1.5.3 and 1.6.1 release notes
* `CASMINST-7138` DOCS: Prepare for upgrade procedures should link to previous release
* `CASMINST-7163` DOCS: IUF: Force SAT to use CFS v2 during upgrades from 1.5.0
* `CASMTRIAGE-7734` DOCS: FASUpdate.py recipe troubles for ERoT and nodeAccUC  (Vidar)
* `CASMTRIAGE-7735` DOCS: Tyr: cray_shasta_64k aarch rpm stuck uploading during deliver-product
* `CASMTRIAGE-7719` DOCS:ceph configuration "ceph.client.kube.keyring" is missing which is required to add storage to remote build node
* `CASMTRIAGE-7509` DOCS: Create workaround for CASMTRIAGE-7459 for USS-1.1 customers
* `HPCCHT3-5144` DOCS: Document how SDU should be reinitialized following a master node upgrade
* `CASMINST-7116` DOCS: add document for when IUF can't find master node upgrade workflow
* `CASMINST-7165` DOCS: Linting
* `CASMTRIAGE-7739` DOCS: ncn-upgrade-master-nodes.sh ncn-m001 failed due to time synch problem
* `CASMTRIAGE-7763` DOCS: cray-console-node pods intermittently are in  CLBO state
* `CASMINST-6893` DOCS: Weave troubleshooting
* `CASMCMS-9253` DOCS: IMS artifacts remained orphaned with CSM 1.5.2 systems
* `CASMCMS-9279` DOCS: Known Issue: Barebones boot image won't fully boot in CSM-1.6.0
* `CASMCMS-8164` DOCS: BOS: Allow the etag to not be specified in the boot set
* `CASMINST-7178` DOCS: Remove Rapid Rebuild content
* `CASMHMS-6366` DOCS: Document pprof in the CSM admin guide
* `CASMHMS-6370` DOCS: Document resetting BIOS factory defaults for Paradise
* `CASMHMS-6371` DOCS: Update Add a Standard Rock Node doc to remove quotes around NID
* `TECHPUBS-4619` Slingshot documentation for multitenancy to be added in csm-docs
* `CASMNET-2288` doc update/fixes for DHCP troubleshooting doc

## Bug fixes

* `CASMTRIAGE-7926` WASP: Unable to get workflow status after intermediate termination
* `CASMTRIAGE-7910` sbps-marshall is not projecting any images from IMS  due to a 403 error (marshall issue)
* `CASMTRIAGE-7901` sbps-marshall is not projecting any images from IMS  due to a 403 error (marshall issue)
* `CASMTRIAGE-7735` DOCS: Tyr: cray_shasta_64k aarch rpm stuck uploading during deliver-product
* `CASMTRIAGE-7559` Lemondrop: CFS layer fails when upgraded to 25.3
* `CASMTRIAGE-7413` hash of the CPC 2.4.1 is getting updated frequently which causing build failure on python-csm-api-client
* `CASMTRIAGE-7428` At the initiator iscsi sessions are displayed only for one worker node while SBPS is configured on all 4 worker nodes
* `CASMTRIAGE-7447` CMN iSCSI portal can be used off system without authentication
* `CRAYSAT-1913` Remove printing of VCS password from python-csm-api-client
* `CRAYSAT-1929` vidar >> sat not showing CFS related values
* `CASMPET-7261` TESTS: iSCSI test regex does not work as intended
* `CASMTRIAGE-7425` deliver-products stage is failing to run due to non-existent running workflows
* `CASMTRIAGE-7440` TESTS: cmsdev BOS test fails during CSM upgrade
* `CRAYSAT-1916` Remove or fix unused code in get_config_value for handling infinite BOS timeouts
* `CASMNET-2241` Resolve external DNS test fails with port present in URL
* `CASMPET-7269` TESTS: csm-testing creating Python test/tool symlinks with wrong names
* `CASMPET-7270` TESTS: Upgrade failed trying to install csm-testing RPM
* `CASMHMS-6288` PCS: Set http timeout/retries configurable in helm chart and update TRS module to latest version
* `CASMTRIAGE-7445` iSCSI is reporting "SQUASHFS errors" on gamora for unknown reasons
* `CASMCMS-9190` cfs-hwsync-agent should discard components with blank ID fields
* `CASMINST-6951` TESTS: csm-testing: add python virtualenv to avoid dependency conflicts
* `CASMPET-7266` TESTS: Bad hostname regex breaks goss-servers service on PIT
* `CASMTRIAGE-7457` TESTS: Shortcut to compare_k8s_ncns test script not created
* `MTL-2484` CSI: Remove kube-api from all but NMN
* `CASMPET-7271` TESTS: csm-testing: Remove urllib3 and certifi from virtual environment
* `CASMCMS-9198` CFS in CLBO if log level set to an invalid value
* `CASMINST-2551` kea and unbound should not have externaldns annotations until we start exposing NMN and HMN services in externalDNS
* `CASMTRIAGE-7459` SBPS disconnected from all computes on gamora during rolling worker node upgrades
* `CASMCMS-9196` CFS exception creating source if authentication_method omitted
* `CASMCMS-9199` Restore Python 3.6 support for Cray Product Catalog Python package
* `CRAYSAT-1917` Fix issues with Jinja2 template rendering of rootfs_provider_passthrough in sat bootprep
* `CASMCMS-9206` Unable to create CFS v3 additional inventory with source specified
* `CASMTRIAGE-7489` odin 1.6.0-rc.4 boots Computes via DVS but iSCSI fails
* `CASMCMS-9210` CFS does not correctly determine in-use sources
* `CRAYSAT-1895` sat bootprep - empty string handling for rootfs_provider key of boot_set
* `CRAYSAT-1551` Fix sorting of "sat showrev --products" by product version
* `MTL-2513` Remove remaining COS packages from stock SLES compute image / fix network configuration
* `CASMPET-7273` TESTS: k8s_verify_cluster_2 fails during kube-etcdbackup container creation
* `CASM-5042` product-deletion-utility version change
* `CRAYSAT-1941` sat bootprep - allow for missing rootfs_provider key when handling empty strings
* `CASMPET-7104` k8s_kyverno_pods_running.sh fails
* `CASMTRIAGE-7490` Couple of Iscsi metrics values are not correct.
* `CASMCMS-9144` Add SOPS binary to Worker and Master Node Images
* `CASMCMS-9217` Evaluate console-node code for memory leaks
* `CASMCMS-9037` Remove sshd from cray-ims-utils image
* `CASMCMS-9166` IMS - deleted image always gets assigned arch=x86_64
* `CASMCMS-9226` Mis-spelled output in IMS job startup logging
* `CASMHMS-6295` hmcollector: Investigate Scaling Issues in CSM 1.5
* `CASMHMS-6310` FAS: Investigate Scaling Issues in CSM 1.5
* `CASMTRIAGE-7469` while configuring remote build node customization of barebones image failed with missing repos
* `CASMPET-7033` Investigate duplicates docker.io/weaveworks/weave-kube
* `CASMPET-7034` Investigate duplicates docker.io/weaveworks/weave-npc
* `CASMPET-7037` Investigate duplicates ghcr.io/k8snetworkplumbingwg/multus-cni
* `CRAYSAT-1649` Silent failure when FileNotFoundError is raised when opening a token file
* `CRAYSAT-1847` Update outdated attributes used in unit test
* `CRAYSAT-1947` Fix sorting warnings on sat --showrev
* `CASMPET-6707` Nexus Keycloak integration nexus-keycloak-realm-config does not set properly if nexus starts too fast
* `CASMSMF-8370` Remove cli command dependency from postgresDB
* `CRAYSAT-1948` Baldar- Castle Blade Removal using SAT; Error "Could not determine slot class: multiple node classes: Hill, Mountain"
* `CASMCMS-9126` Console - log permissions get set incorrectly
* `CASMHMS-6294` SMD: Investigate Scaling Issues in CSM 1.5
* `CASMHMS-6325` vShasta: HSM and PCS tests fail after 1.4 > 1.5 upgrade
* `CASMTRIAGE-7594` cray-console pods keep disconnecting conman sessions.
* `CASMPET-7291` Review csm-rie:1.4.0 (142 days)
* `CRAYSAT-1945` Bug: For lesser page size, cfs v2 session throws traceback error
* `CASMTRIAGE-7346` Upgrade of ncn-m001 to csm-1.6.0-beta.1 is failing setting NTP
* `CRAYSAT-1875` Add new HSM types to sat status
* `CASMTRIAGE-7607` vShasta: upgrade 1.5 > 1.6: cray-nexus deployment fails in prerequisites.sh
* `CASMNET-2270` Exclude cray-shared-kafka-entity-operator network policy during Cilium live migration
* `CASMCMS-9068` Allow customization of ipxe debug options
* `CASMCMS-9236` Fix BOS migration bug in CSM 1.6.1
* `CASMTRIAGE-7559` Lemondrop: CFS layer fails when upgraded to 25.3
* `CASMHMS-6277` FAS: Investigate security fix from Dependabot
* `CASMSEC-505` Kyverno background policy scans are ignoring resourceFilters
* `STP-3724` Finalize docs-sat move to docs-csm
* `CASMINST-7108` Simplify license checker filename pattern override
* `CASMHMS-6239` PCS: ETCD requests are too large at scale
* `CASMTRIAGE-7567` Observed several thousand restarts of cray-sysmgmt-health-redfish-exporter on fanta
* `CRAYSAT-1974` Resolve dependabot alerts (Jinja2)
* `CASMTRIAGE-7627` check if cray-spire jwks and velero backup tests need additional logic
* `CASMHMS-6324` Set up and run 'pprof' against HMS services to find memory leaks
* `CASMTRIAGE-7663` Compute node CFS configuration failing with key issue
* `CASMCMS-9245` Limit requests_retry_session version
* `CASMTRIAGE-7682` Tyr:  March product set - ARM image fails to customize with CFS.
* `CASMINST-3816` manually copying large files into s3fs cache directory prevents prune from pruning them
* `CASMINST-7114` TESTS: rgw_endpoint_check throwing python error
* `CASMCMS-9255` BOS: Image Regular Expression Fragile
* `CASMCMS-9241` cfs-debugger: 'NoneType' object has no attribute 'group'
* `CASMCMS-9201`  IMS artifacts remained orphaned with CSM 1.5.2 systems
* `CASMTRIAGE-7715` log files permissions changed manually remain unchanged
* `CASMMON-469` delete SMa postgres VMscrapeserive  for SMA
* `CASMMON-475` seeing errors in the log systmgmt-health-redfish-exporter after configuring E100-smart-data
* `CASMTRIAGE-7823` Install Pipeline -  management-nodes-rollout failed with 503

## Deprecations

For a list of all deprecated CSM features, see [Deprecations](introduction/deprecated_features/README.md#deprecations).

## Removals

For a list of all features with an announced removal target,
see [Removals](introduction/deprecated_features/README.md#removals)

## Known issues

* CSM 1.6.0 does not support servers with NVIDIA CPUs and GPUs. Systems with these servers should not be upgraded to CSM 1.6.0.
* CSM 1.6.1 and later supports servers with NVIDIA CPUs and GPUs.
* After updating Paradise BMC firmware, the `hmcollector-poll` service will lose event subscriptions and must be restarted
    * See [Updating Foxconn Paradise Nodes with FAS](operations/firmware/FAS_Paradise.md) for details on how to do this
* `cfs-api` pods in CLBO state during CSM install.
    * When installing CSM 1.6, `cray-shared-kafka-kafka-` pods in the services namespace fail to come up which results in `cfs-api` pods in CLBO state.
    * A workaround is presented in [CFS API pods in CLBO](troubleshooting/known_issues/cfs-api_pods_in_CLBO_state.md).
* `istio-proxy` containers fail with too many open files.
    * This may happen when any pod with `istio injection` enabled is started.
    * A workaround is presented in [Istio-Proxy failing with too many open files](troubleshooting/known_issues/Istio-Proxy_failing_with_too_many_open_files.md)
* IUF does not run the next stage for an activity
    * During CSM upgrade, IUF reports that multiple sessions are in progress for an activity.
    * A workaround is presented in [IUF does not run the next stage for an activity](troubleshooting/known_issues/iuf_unable_to_run_next_stage.md)
* iSCSI based boot content projection may fail if the image to be projected does not have an `etag`
    * A workaround is presented in [iSCSI SBPS boot failure](troubleshooting/known_issues/SBPS_boot_fail.md)
* CANU 1.8.0 and later is known to cause a brief NMN network outage.
    * CANU 1.8.0 and later introduce a separation of administrative traffic and user traffic on the management network
      via addition of a new VRF and OSPF area. Until all switches are updated and new routes are propagated, there is a
      brief NMN network outage. IP addressing does not change, but NMN traffic will flow over a new isolated VRF
      channel. The length of the outage is dependent on the time to apply new switch configurations to all management
      network switches - OSPF will propagate routes within seconds. As this affects liquid-cooled Mountain cabinets,
      running jobs may be affected. A dedicated outage window is highly recommended for applying these changes.
* SMA 1.10.15 and later includes an upgraded LDMS that introduces an incompatibility with configuration files used in prior versions.
    * When upgrading from an older SMA version to a version with this new LDMS, the administrator must change the configuration files.
    * A workaround is presented as an Action in the deliver-product stage in the **IUF Stage Details for SMA** section of the _HPE Cray Supercomputing EX System Monitoring Application Installation Guide_.
* Services that use PostgreSQL may fail when a Kubernetes master node is rebooted or rebuilt.
    * A PostgreSQL database may fail over without clients reconnecting to the new cluster leader.
    * A workaround is presented in [PostgreSQL Database is in Recovery](troubleshooting/known_issues/postgres_database_recovery.md)
* There are resource leaks in several HMS services ([PCS](glossary.md#power-control-service-pcs), [SMD](glossary.md#hardware-state-manager-smd), hmcollector, and [FAS](glossary.md#firmware-action-service-fas))
    * This issue is partially resolved by a hotfix for the CSM 1.5.2 release and fully resolved in the CSM 1.5.3 and 1.6.1 releases
    * For more information, including a workaround, see [HMS Resource Leaks](troubleshooting/known_issues/HMS_Resource_Leaks.md).
