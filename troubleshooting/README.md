# CSM Troubleshooting Information

This document provides links to troubleshooting information for services and functionality provided by CSM.

* [Helpful tips for navigating the CSM repository](#helpful-tips-for-navigating-the-csm-repository)
* [Known issues](#known-issues)
* [Booting](#booting)
    * [UAN boot issues](#uan-boot-issues)
    * [Compute node boot issues](#compute-node-boot-issues)
* [Configuration management](#configuration-management)
* [ConMan](#conman)
* [Customer Management Network (CMN)](#customer-management-network-cmn)
* [Domain Name Service (DNS)](#domain-name-service-dns)
* [Grafana dashboards](#grafana-dashboards)
* [Kubernetes](#kubernetes)
* [MetalLB](#metallb)
* [Node management](#node-management)
* [Security and authentication](#security-and-authentication)
* [Spire](#spire)
* [Utility storage](#utility-storage)

## Helpful tips for navigating the CSM repository

In the main repository landing page, change the branch to the CSM version being used on the system (for example, `release/1.0`, `release/1.2`, `release/1.3`, etc.).

Use the pre-populated GitHub "Search or jump to..." function in the upper left hand side of the page and append keywords related
to the exiting problem seen into the existing search. (The example searches for "ping" and "PXE" related troubleshooting resources on the "main" branch.)

* Follow any run-books, guides, or procedures which are directly related to the problem.

* Change the branch to `main` and search a second time to retrieve very recent or beta run-books and guides.

* Users can also expand the search beyond the "troubleshooting" section (instead of doing "path troubleshooting") and/or use more advanced GitHub searches such as "path configure" to find the right context.

## Known issues

* [SAT/HSM/CAPMC/PCS Component Power State Mismatch](known_issues/component_power_state_mismatch.md)
* [HMS Discovery job not creating `RedfishEndpoint`s in Hardware State Manager](known_issues/discovery_job_not_creating_redfish_endpoints.md)
* [SSL Certificate Validation Issues](known_issues/ssl_certificate_validation_issues.md)
* [SLS Not Working During Node Rebuild](known_issues/SLS_Not_Working_During_Node_Rebuild.md)
* [Antero node NID allocation](known_issues/antero_node_NID_allocation.md)
* [Software Management Services health check](known_issues/sms_health_check.md)
* [QLogic driver crash](known_issues/qlogic_driver_crash.md)
* [Nexus Fails Authentication with Keycloak Users](known_issues/Nexus_Fail_Authentication_with_Keycloak_Users.md)
* [Keycloak Error "Cannot read properties" in Web UI](known_issues/Keycloak_Error_Cannot_read_properties.md)
* [Gigabyte BMC Missing Redfish Data](known_issues/Gigabyte_BMC_Missing_Redfish_Data.md)
* [`admin*client-auth` Not Found](known_issues/admin_client_auth_not_found.md)
* [Ceph OSD latency](known_issues/ceph_osd_latency.md)
* [Cray CLI 403 Forbidden Errors](known_issues/craycli_403_forbidden_errors.md)
* [Flags Set For Nodes In HSM](known_issues/flags_set_for_nodes_in_hsm.md)
* [Goss Test Fails with Connection Refused](known_issues/goss_tests_fails_with_connection_refused.md)
* [Helm Chart Deploy Timeouts](known_issues/helm_chart_deploy_timeouts.md)
* [HPE iLO dropping event subscriptions and not properly transitioning power state in CSM software](known_issues/hpe_systems_not_transitioning_power_state.md)
* [IMS image creation failure](known_issues/ims_image_creation_failure.md)
* [`initrd.img.xz` Not Found](known_issues/initrd.img.zx_not_found.md)
* [NCN health checks known issues](known_issues/issues_with_ncn_health_checks.md)
* [`kubectl logs -f` returns no space left on device](known_issues/kubectl_logs_no_space_left_on_device.md)
* [Kubernetes Master or Worker node's root filesystem is out of space](known_issues/kubernetes_node_rootFS_out_of_space.md)
* [Mellanox `lacp-individual` Limitations](known_issues/mellanox_lacp_individual.md)
* [NCN resource checks known issues](known_issues/ncn_resource_checks.md)
* [Spire database connection pool configuration in an air*gapped environment](known_issues/spire_database_airgap_configuration.md)
* [Spire Database Cluster DNS Lookup Failure](known_issues/spire_database_lookup_error.md)
* [Postgres Database is in Recovery](known_issues/postgres_database_recovery.md)
* [Test Failures Due To No Discovered Compute Nodes In HSM](known_issues/test_failures_no_discovered_computes_in_hsm.md)
* [Velero Version Mismatch](known_issues/velero_version_mismatch.md)
* [wait for unbound hang](known_issues/wait_for_unbound_hang.md)
* [Product Catalog Upgrade Error](known_issues/product_catalog_upgrade_error.md)
* [Missing Binaries in aarch64 Images](known_issues/missing_binaries_in_aarch64_images.md)
* [PCS and CAPMC Transaction Size Limitation](known_issues/pcs_and_capmc_transaction_size_limitation.md)
* [Istio-Proxy failing with too many open files](known_issues/Istio-Proxy_failing_with_too_many_open_files.md)
* [IMS image delete loses the `arch` information](known_issues/ims_image_delete_loses_arch.md)
* [Spire pods stuck in `PodInitializing`](known_issues/spire_pod_initializing.md)
* [CFS Component With Zero-Length ID](known_issues/CFS_Component_With_Zero_Length_ID.md)
* [IMS Remote Node Image Build Failure](known_issues/ims_remote_node_image_build_failure.md)

## Booting

### UAN boot issues

* [UAN Boot Issues](../operations/boot_orchestration/Troubleshoot_UAN_Boot_Issues.md)

### Compute node boot issues

* [Issues Related to Unified Extensible Firmware Interface (UEFI)](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Unified_Extensible_Firmware_Interface_UEFI.md)
* [Issues Related to Dynamic Host Configuration Protocol (DHCP)](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Dynamic_Host_Configuration_Protocol_DHCP.md)
* [Issues Related to the Boot Script Service](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_the_Boot_Script_Service_BSS.md)
* [Issues Related to Trivial File Transfer Protocol (TFTP)](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Trivial_File_Transfer_Protocol_TFTP.md)
* [Troubleshooting Using Kubernetes](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Using_Kubernetes.md)
* [Log File Locations and Ports Used](../operations/boot_orchestration/Log_File_Locations_and_Ports_Used_in_Compute_Node_Boot_Troubleshooting.md)

## Configuration management

* [Troubleshoot CFS Issues](../operations/configuration_management/Troubleshoot_CFS_Issues.md)
* [Incrementally Configuring Images](incrementally_configuring_images.md)
* [CFS-API pods in CLBO state](known_issues/cfs-api_pods_in_CLBO_state.md)

## ConMan

* [Console Services Troubleshooting Guide](../operations/conman/Console_Services_Troubleshooting_Guide.md)
* [ConMan Blocking Access to a Node BMC](../operations/conman/Troubleshoot_ConMan_Blocking_Access_to_a_Node_BMC.md)
* [ConMan Failing to Connect to a Console](../operations/conman/Troubleshoot_ConMan_Failing_to_Connect_to_a_Console.md)
* [ConMan Asking for Password on SSH Connection](../operations/conman/Troubleshoot_ConMan_Asking_for_Password_on_SSH_Connection.md)
* [Console Node Pod Stuck in Terminating State](../operations/conman/Troubleshoot_ConMan_Node_Pod_Stuck_Terminating.md)

## Customer Management Network (CMN)

* [DHCP run book](dhcp_runbook.md)
* [DNS run book](dns_runbook.md)
* [General configuration and troubleshooting](../operations/network/management_network/README.md)
* [Troubleshoot CMN Issues](../operations/network/customer_accessible_networks/Troubleshoot_CMN_Issues.md)
* [Troubleshoot DHCP Issues](../operations/network/dhcp/Troubleshoot_DHCP_Issues.md)
* [Troubleshoot Common DNS Issues](../operations/network/dns/Troubleshoot_Common_DNS_Issues.md)
* [Troubleshoot PowerDNS Issues](../operations/network/dns/Troubleshoot_PowerDNS.md)
* [Troubleshoot Common DNS configuration Issues](../operations/network/external_dns/Troubleshoot_DNS_Configuration_Issues.md)
* [Troubleshoot External DNS Issues](../operations/network/external_dns/Troubleshoot_Systems_Not_Provisioned_with_External_IP_Addresses.md)
* [Troubleshoot BGP not accepting routes from MetalLB](../operations/network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)
* [Troubleshoot BGP services without an allocated IP address](../operations/network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
* [Troubleshoot PXE boot](../install/troubleshooting_pxe_boot.md)

## Grafana dashboards

* [Grafana Dashboards](../operations/system_management_health/Troubleshoot_Grafana_Dashboard.md)

## Domain Name Service (DNS)

* [Connectivity to Services with External IP addresses](../operations/network/external_dns/Troubleshoot_Systems_Not_Provisioned_with_External_IP_Addresses.md)
* [DNS Configuration Issues](../operations/network/external_dns/Troubleshoot_DNS_Configuration_Issues.md)

## Kubernetes

* [General Kubernetes Commands for Troubleshooting](kubernetes/Kubernetes_Troubleshooting_Information.md)
* [Kubernetes Log File Locations](kubernetes/Kubernetes_Log_File_Locations.md)
* [Liveliness or Readiness Probe Failures](kubernetes/Troubleshoot_Liveliness_Readiness_Probe_Failures.md)
* [Unresponsive `kubectl` Commands](kubernetes/Troubleshoot_Unresponsive_kubectl_Commands.md)
* [Kubernetes Node `NotReady`](kubernetes/Troubleshoot_Kubernetes_Node_NotReady.md)
* [Kubernetes Pods not Starting](kubernetes/Troubleshoot_Kubernetes_Pods_Not_Starting.md)
* [Postgres Database](../operations/kubernetes/Troubleshoot_Postgres_Database.md)
* [Recover from Postgres WAL Event](../operations/kubernetes/Troubleshoot_Postgres_Database.md)
* [Restore Postgres](../operations/kubernetes/Restore_Postgres.md)
* [Disaster Recovery for Postgres](../operations/kubernetes/Disaster_Recovery_Postgres.md)
* [Postgres Database is in Recovery](known_issues/postgres_database_recovery.md)

## MetalLB

* [Services Without an Allocated IP Address](../operations/network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
* [BGP not Accepting Routes from MetalLB](../operations/network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)

## Node management

* [Issues with Redfish Endpoint `DiscoveryCheck` for Redfish Events from Nodes](../operations/node_management/Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md)
* [Interfaces with IP Address Issues](../operations/node_management/Troubleshoot_Interfaces_with_IP_Address_Issues.md)
* [Loss of Console Connections and Logs on Gigabyte Nodes](../operations/node_management/Troubleshoot_Loss_of_Console_Connections_and_Logs_on_Gigabyte_Nodes.md)
* [Image projection inconsistent across nodes](image_projection_inconsistent_across_nodes.md)

## Security and authentication

* [Common Vault Cluster Issues](../operations/security_and_authentication/Troubleshoot_Common_Vault_Cluster_Issues.md)
* [Keycloak User Localization](../operations/security_and_authentication/Keycloak_User_Localization.md)
* [Troubleshoot Kyverno configuration manually](../operations/security_and_authentication/Troubleshoot_Kyverno_Configuration_manually.md)

## Spire

* [Restore Spire Postgres without a Backup](../operations/spire/Restore_Spire_Postgres_without_a_Backup.md)
* [Spire Database Cluster DNS Lookup Failure](known_issues/spire_database_lookup_error.md)
* [Spire Failing to Start on NCNs](../operations/spire/Troubleshoot_Spire_Failing_to_Start_on_NCNs.md)

## Utility storage

* [Failure to Get Ceph Health](../operations/utility_storage/Troubleshoot_Failure_to_Get_Ceph_Health.md)
* [Down OSDs](../operations/utility_storage/Troubleshoot_a_Down_OSD.md)
* [Ceph OSDs Reporting Full](../operations/utility_storage/Troubleshoot_Ceph_OSDs_Reporting_Full.md)
* [System Clock Skew](../operations/utility_storage/Troubleshoot_System_Clock_Skew.md)
* [Unresponsive S3 Endpoint](../operations/utility_storage/Troubleshoot_an_Unresponsive_S3_Endpoint.md)
* [Ceph-Mon Processes Stopping and Exceeding Max Restarts](../operations/utility_storage/Troubleshoot_Ceph-Mon_Processes_Stopping_and_Exceeding_Max_Restarts.md)
* [Large Object Map Objects in Ceph Health](../operations/utility_storage/Troubleshoot_Large_Object_Map_Objects_in_Ceph_Health.md)
* [Failure of RGW Health Check](../operations/utility_storage/Troubleshoot_RGW_Health_Check_Fail.md)
* [Troubleshoot S3FS Mounts](../operations/utility_storage/Troubleshoot_S3FS_Mounts.md)
* [Ceph New RGW Deployment Failing](../operations/utility_storage/Troubleshoot_Ceph_New_RGW_Deployment_Failing.md)
