# Cray System Management (CSM) 1.6.1 Release Notes

This page documents the changes introduced by this patch, compared to the previous patch
version of CSM.

For the main CSM 1.6 release notes page, including links to other patch release notes,
see [CSM 1.6 release notes](RELEASE_NOTES.md).

* [Additions and improvements](#additions-and-improvements)
* [Bug fixes](#bug-fixes)
* [Known issues](#known-issues)

## Additions and improvements

### Hardware support

* Add support for systems with NVIDIA CPUs and GPUs.

### General

* Upgrade Victoria metrics to 0.24.5 in `cray-sysmgmt-health`
* Update `cray-keycloak` for new `JobConditionType` `SuccessCriteriaMet`
* Avoid infinite loop while uploading artifacts with `cray-nexus-setup` image
* Allow customization of `ipxe` debug options
* [Boot Orchestration Service (BOS)](glossary.md#boot-orchestration-service-bos)
    * Make BOS migration pod more polite
    * Add context managers around BOS requests/sessions; enable paging of BOS components
* [Configuration Framework Service (CFS)](glossary.md#configuration-framework-service-cfs)
    * Update CFS API spec to reject invalid component creation/update requests
    * Bypass needless work in some CFS queries
    * Make CFS Options class thread-safe and more performant
    * Add ability to create CFS source and specify secret name instead of username/password
    * Update CFS API spec with actual status code for successful source restore
    * Improve CFS config delete performance on scale systems
* [Power Control Service (PCS)](glossary.md#power-control-service-pcs)/TRS: Mitigate resource leaks / heavy usage
* Cleanup previous/old SquashFS images during upgrade
* Update `customization.yaml` for [System Monitoring Application (SMA)](glossary.md#system-monitoring-application-sma) Victoria metrics PVC size
* [System Admin Toolkit (SAT)](glossary.md#system-admin-toolkit-sat)
    * Update "sat bootprep" to support CFS v2 or v3
    * Update "sat bootsys" to support CFS v2 or v3
    * SAT: Add ability to sort reports by multiple fields

### Security

* Remove `sshd` from `cray-console-operator` image
* Fix CVEs in [Firmware Action Service (FAS)](glossary.md#firmware-action-service-fas) image `artifactory.algol60.net/csm-docker/stable/cray-firmware-action:1.34.0`
* Fix [CSM Automatic Network Utility (CANU)](glossary.md#csm-automatic-network-utility-canu) generated switch configuration security concern

### Tests

* [`cmsdev`](troubleshooting/known_issues/sms_health_check.md): Add explicit check for blank CFS ID field

## Customer-requested

* Fix CANU generated switch configuration security concern

## Known issues resolved from CSM 1.6.0

* [CFS Allows Some In-Use Sources To Be Deleted](troubleshooting/known_issues/CFS_Allows_Some_In-Use_Sources_To_Be_Deleted.md)
* [Omitting Authentication Method In API Call Causes CFS Source Creation To Fail](troubleshooting/known_issues/Omitting_Authentication_Method_In_API_Call_Causes_CFS_Source_Creation_To_Fail.md)

## Bug fixes

```text
* CASM-5042 product-deletion-utility version change
* CASMCMS-9037 Remove sshd from cray-ims-utils image
* CASMCMS-9068 Allow customization of ipxe debug options
* CASMCMS-9126 Console - log permissions get set incorrectly
* CASMCMS-9144 Add SOPS binary to Worker and Master Node Images
* CASMCMS-9166 IMS - deleted image always gets assigned arch=x86_64
* CASMCMS-9190 cfs-hwsync-agent should discard components with blank ID fields
* CASMCMS-9196 CFS exception creating source if authentication_method omitted
* CASMCMS-9198 CFS in CLBO if log level set to an invalid value
* CASMCMS-9199 Restore Python 3.6 support for Cray Product Catalog Python package
* CASMCMS-9201  IMS artifacts remained orphaned with CSM 1.5.2 systems
* CASMCMS-9206 Unable to create CFS v3 additional inventory with source specified
* CASMCMS-9210 CFS does not correctly determine in-use sources
* CASMCMS-9217 Evaluate console-node code for memory leaks
* CASMCMS-9226 Mis-spelled output in IMS job startup logging
* CASMCMS-9236 Fix BOS migration bug in CSM 1.6.1
* CASMCMS-9241 cfs-debugger: 'NoneType' object has no attribute 'group'
* CASMCMS-9245 Limit requests_retry_session version
* CASMCMS-9255 BOS: Image Regular Expression Fragile
* CASMHMS-6239 PCS: ETCD requests are too large at scale
* CASMHMS-6277 FAS: Investigate security fix from Dependabot
* CASMHMS-6288 PCS: Set http timeout/retries configurable in helm chart and update TRS module to latest version
* CASMHMS-6294 SMD: Investigate Scaling Issues in CSM 1.5
* CASMHMS-6295 hmcollector: Investigate Scaling Issues in CSM 1.5
* CASMHMS-6310 FAS: Investigate Scaling Issues in CSM 1.5
* CASMHMS-6324 Set up and run 'pprof' against HMS services to find memory leaks
* CASMHMS-6325 vShasta: HSM and PCS tests fail after 1.4 > 1.5 upgrade
* CASMINST-2551 kea and unbound should not have externaldns annotations until we start exposing NMN and HMN services in externalDNS
* CASMINST-3816 manually copying large files into s3fs cache directory prevents prune from pruning them
* CASMINST-6951 TESTS: csm-testing: add python virtualenv to avoid dependency conflicts
* CASMINST-7108 Simplify license checker filename pattern override
* CASMINST-7114 TESTS: rgw_endpoint_check throwing python error
* CASMMON-469 delete SMa postgres VMscrapeserive  for SMA
* CASMMON-475 seeing errors in the log systmgmt-health-redfish-exporter after configuring E100-smart-data
* CASMNET-2241 Resolve external DNS test fails with port present in URL
* CASMNET-2270 Exclude cray-shared-kafka-entity-operator network policy during Cilium live migration
* CASMPET-6707 Nexus Keycloak integration nexus-keycloak-realm-config does not set properly if nexus starts too fast
* CASMPET-7033 Investigate duplicates docker.io/weaveworks/weave-kube
* CASMPET-7034 Investigate duplicates docker.io/weaveworks/weave-npc
* CASMPET-7037 Investigate duplicates ghcr.io/k8snetworkplumbingwg/multus-cni
* CASMPET-7104 k8s_kyverno_pods_running.sh fails
* CASMPET-7261 TESTS: iSCSI test regex does not work as intended
* CASMPET-7266 TESTS: Bad hostname regex breaks goss-servers service on PIT
* CASMPET-7269 TESTS: csm-testing creating Python test/tool symlinks with wrong names
* CASMPET-7270 TESTS: Upgrade failed trying to install csm-testing RPM
* CASMPET-7271 TESTS: csm-testing: Remove urllib3 and certifi from virtual environment
* CASMPET-7273 TESTS: k8s_verify_cluster_2 fails during kube-etcdbackup container creation
* CASMPET-7291 Review csm-rie:1.4.0 (142 days)
* CASMSEC-505 Kyverno background policy scans are ignoring resourceFilters
* CASMSMF-8370 Remove cli command dependency from postgresDB
* CASMTRIAGE-7346 Upgrade of ncn-m001 to csm-1.6.0-beta.1 is failing setting NTP
* CASMTRIAGE-7413 hash of the CPC 2.4.1 is getting updated frequently which causing build failure on python-csm-api-client
* CASMTRIAGE-7425 deliver-products stage is failing to run due to non-existent running workflows
* CASMTRIAGE-7428 At the initiator iscsi sessions are displayed only for one worker node while SBPS is configured on all 4 worker nodes
* CASMTRIAGE-7440 TESTS: cmsdev BOS test fails during CSM upgrade
* CASMTRIAGE-7445 iSCSI is reporting "SQUASHFS errors" on gamora for unknown reasons
* CASMTRIAGE-7447 CMN iSCSI portal can be used off system without authentication
* CASMTRIAGE-7457 TESTS: Shortcut to compare_k8s_ncns test script not created
* CASMTRIAGE-7459 SBPS disconnected from all computes on gamora during rolling worker node upgrades
* CASMTRIAGE-7469 while configuring remote build node customization of barebones image failed with missing repos
* CASMTRIAGE-7489 odin 1.6.0-rc.4 boots Computes via DVS but iSCSI fails
* CASMTRIAGE-7490 Couple of Iscsi metrics values are not correct.
* CASMTRIAGE-7559 Lemondrop: CFS layer fails when upgraded to 25.3
* CASMTRIAGE-7567 Observed several thousand restarts of cray-sysmgmt-health-redfish-exporter on fanta
* CASMTRIAGE-7594 cray-console pods keep disconnecting conman sessions.
* CASMTRIAGE-7607 vShasta: upgrade 1.5 > 1.6: cray-nexus deployment fails in prerequisites.sh
* CASMTRIAGE-7627 check if cray-spire jwks and velero backup tests need additional logic
* CASMTRIAGE-7663 Compute node CFS configuration failing with key issue
* CASMTRIAGE-7682 Tyr:  March product set - ARM image fails to customize with CFS.
* CASMTRIAGE-7715 log files permissions changed manually remain unchanged
* CASMTRIAGE-7735 DOCS: Tyr: cray_shasta_64k aarch rpm stuck uploading during deliver-product
* CASMTRIAGE-7823 Install Pipeline -  management-nodes-rollout failed with 503
* CASMTRIAGE-7901 sbps-marshall is not projecting any images from IMS  due to a 403 error (marshall issue)
* CASMTRIAGE-7910 sbps-marshall is not projecting any images from IMS  due to a 403 error (marshall issue)
* CASMTRIAGE-7926 WASP: Unable to get workflow status after intermediate termination
* CRAYSAT-1551 Fix sorting of "sat showrev --products" by product version
* CRAYSAT-1649 Silent failure when FileNotFoundError is raised when opening a token file
* CRAYSAT-1847 Update outdated attributes used in unit test
* CRAYSAT-1875 Add new HSM types to sat status
* CRAYSAT-1895 sat bootprep - empty string handling for rootfs_provider key of boot_set
* CRAYSAT-1913 Remove printing of VCS password from python-csm-api-client
* CRAYSAT-1916 Remove or fix unused code in get_config_value for handling infinite BOS timeouts
* CRAYSAT-1917 Fix issues with Jinja2 template rendering of rootfs_provider_passthrough in sat bootprep
* CRAYSAT-1929 vidar >> sat not showing CFS related values
* CRAYSAT-1941 sat bootprep - allow for missing rootfs_provider key when handling empty strings
* CRAYSAT-1945 Bug: For lesser page size, cfs v2 session throws traceback error
* CRAYSAT-1947 Fix sorting warnings on sat --showrev
* CRAYSAT-1948 Baldar- Castle Blade Removal using SAT; Error "Could not determine slot class: multiple node classes: Hill, Mountain"
* CRAYSAT-1974 Resolve dependabot alerts (Jinja2)
* MTL-2484 CSI: Remove kube-api from all but NMN
* MTL-2513 Remove remaining COS packages from stock SLES compute image / fix network configuration
* STP-3724 Finalize docs-sat move to docs-csm
```

## Known issues

* CSM 1.5.4 included fixes to the [Boot Script Service (BSS)](glossary.md#boot-script-service-bss) and `cfs-trust` to allow large scale parallel boots of compute nodes.
  These changes did not make it into CSM 1.6.1 but will be present in CSM 1.6.2 and CSM 1.7.0. Workarounds until then include:
    * Boot in smaller sets of compute nodes
    * Disable debug logging in BSS by changing `BSS_DEBUG` from "true" to "false" in the `cray-bss` deployment.
      This may allow slightly larger sets of compute nodes to boot in parallel.
* After updating Paradise [BMC](glossary.md#baseboard-management-controller-bmc) firmware, the `hmcollector-poll` service will lose event subscriptions and must be restarted
    * See [Updating Foxconn Paradise Nodes with FAS](operations/firmware/FAS_Paradise.md) for details on how to do this
* `cfs-api` pods in CLBO state during CSM install.
    * When installing CSM 1.6, `cray-shared-kafka-kafka-` pods in the services namespace fail to come up which results in `cfs-api` pods in CLBO state.
    * A workaround is presented in [CFS API pods in CLBO](troubleshooting/known_issues/cfs-api_pods_in_CLBO_state.md).
* [Install and Upgrade Framework (IUF)](glossary.md#install-and-upgrade-framework-iuf) does not run the next stage for an activity
    * During CSM upgrade, IUF reports that multiple sessions are in progress for an activity.
    * A workaround is presented in [IUF does not run the next stage for an activity](troubleshooting/known_issues/iuf_unable_to_run_next_stage.md)
* iSCSI based boot content projection may fail if the image to be projected does not have an `etag`
    * A workaround is presented in [iSCSI SBPS boot failure](troubleshooting/known_issues/SBPS_boot_fail.md)
* CANU 1.8.0 and later is known to cause a brief [Node Management Network (NMN)](glossary.md#node-management-network-nmn) network outage.
    * CANU 1.8.0 and later introduce a separation of administrative traffic and user traffic on the management network
      via addition of a new VRF and OSPF area. Until all switches are updated and new routes are propagated, there is a
      brief NMN network outage. IP addressing does not change, but NMN traffic will flow over a new isolated VRF
      channel. The length of the outage is dependent on the time to apply new switch configurations to all management
      network switches - OSPF will propagate routes within seconds. As this affects liquid-cooled Mountain cabinets,
      running jobs may be affected. A dedicated outage window is highly recommended for applying these changes.
* SMA 1.10.15 and later includes an upgraded LDMS that introduces an incompatibility with configuration files used in prior versions.
    * When upgrading from an older SMA version to a version with this new LDMS, the administrator must change the configuration files.
    * A workaround is presented as an Action in the deliver-product stage in the **IUF Stage Details for SMA** section of the *HPE Cray Supercomputing EX System Monitoring Application Installation Guide*.
* Services that use PostgreSQL may fail when a Kubernetes master node is rebooted or rebuilt.
    * A PostgreSQL database may fail over without clients reconnecting to the new cluster leader.
    * A workaround is presented in [PostgreSQL Database is in Recovery](troubleshooting/known_issues/postgres_database_recovery.md)
* `cray-uas-mgr` may still be running on a system upgraded from CSM 1.5.
    * UAI was removed in CSM 1.6.0 but systems upgraded from CSM 1.5 may still have the `cray-uas-mgr` service and associated etcd cluster present.
    * A workaround is presented in [Remove User Access Service](troubleshooting/known_issues/remove_uas_service.md).

For a full list of known issues, see [Known issues](troubleshooting/README.md#known-issues).
