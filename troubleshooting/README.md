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
* [Hardware Management System (HMS)](#hardware-management-system-hms)
* [Image management](#image-management)
* [Kubernetes](#kubernetes)
* [MetalLB](#metallb)
* [Node management](#node-management)
* [Rack Resiliency](#rack-resiliency)
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

* [SAT/HSM/PCS Component Power State Mismatch](known_issues/component_power_state_mismatch.md)
* [HMS Discovery job not creating `RedfishEndpoint`s in Hardware State Manager](known_issues/discovery_job_not_creating_redfish_endpoints.md)
* [SSL Certificate Validation Issues](known_issues/ssl_certificate_validation_issues.md)
* [SLS Not Working During Node Rebuild](known_issues/SLS_Not_Working_During_Node_Rebuild.md)
* [Antero node NID allocation](known_issues/antero_node_NID_allocation.md)
* [Software Management Services health check](known_issues/sms_health_check.md)
* [Nexus Fails Authentication with Keycloak Users](known_issues/Nexus_Fail_Authentication_with_Keycloak_Users.md)
* [Keycloak Error "Cannot read properties" in Web UI](known_issues/Keycloak_Error_Cannot_read_properties.md)
* [Gigabyte BMC Missing Redfish Data](known_issues/Gigabyte_BMC_Missing_Redfish_Data.md)
* [`admin*client-auth` Not Found](known_issues/admin_client_auth_not_found.md)
* [Ceph OSD latency](known_issues/ceph_osd_latency.md)
* [Cray CLI 403 Forbidden Errors](known_issues/craycli_403_forbidden_errors.md)
* [Flags Set For Nodes In HSM](known_issues/flags_set_for_nodes_in_hsm.md)
* [Helm Chart Deploy Timeouts](known_issues/helm_chart_deploy_timeouts.md)
* [HPE iLO dropping event subscriptions and not properly transitioning power state in CSM software](known_issues/hpe_systems_not_transitioning_power_state.md)
* [NCN health checks known issues](known_issues/issues_with_ncn_health_checks.md)
* [NCN resource checks known issues](known_issues/ncn_resource_checks.md)
* [Spire database connection pool configuration in an air*gapped environment](known_issues/spire_database_airgap_configuration.md)
* [Spire Database Cluster DNS Lookup Failure](known_issues/spire_database_lookup_error.md)
* [Test Failures Due To No Discovered Compute Nodes In HSM](known_issues/test_failures_no_discovered_computes_in_hsm.md)
* [Missing Binaries in aarch64 Images](known_issues/missing_binaries_in_aarch64_images.md)
* [Spire pods stuck in `PodInitializing`](known_issues/spire_pod_initializing.md)
* [CFS Component With Zero-Length ID](known_issues/CFS_Component_With_Zero_Length_ID.md)
* [IMS Images Orphaned in S3](known_issues/ims_images_orphaned_in_s3.md)
* [CFS-API pods in CLBO state](known_issues/cfs-api_pods_in_CLBO_state.md)
* [VCS Password With Illegal Characters](known_issues/VCS_Password_With_Illegal_Characters.md)
* [IMS Image Job Performance](../operations/image_management/Image_Job_Performance.md)
* [Keycloak Hung During Prerequisites](known_issues/keycloak_hung_during_prerequisites.md)
* [`etcd` Pods in CLBO State](known_issues/etcd_pods_in_CLBO_state.md)
* [Kyverno policy management](../operations/kubernetes/Kyverno.md#known-issues)
* [PostgreSQL Cluster Upgrades Failing](known_issues/postgres_cluster_upgrade_failure.md)
* [IMS Image Customization Job Status Stuck at `waiting_on_user`](known_issues/ims_image_customization_job_status_stuck_at_waiting_on_user.md)
* [CFS Session for Image Customization Status Stuck at `running`](known_issues/cfs_session_status_for_image_customization_on_remote_node_stuck_at_running.md)
* [PostgreSQL System ID Mismatch](known_issues/postgres_system_id_mismatch.md)
* [`cray-rrs` deployment in Init state](../operations/rack_resiliency/Troubleshooting.md#cray-rrs-pod-is-in-init-state)
* [Sensitive input echoed when using CLI to access console](../operations/conman/Log_in_to_a_Node_Using_ConMan.md#sensitive-input-echoed-when-using-cli-to-access-console)
* Systems running CSM 1.6 or earlier that fresh install CSM 1.7 must regenerate their
  management switch configuration because of the
  [Other behavior changes](../introduction/csi_Tool_Changes.md#other-behavior-changes)
  made in the [Cray Site Init (CSI)](../glossary.md#cray-site-init-csi) tool.
    * Systems upgrading from CSM 1.6 to CSM 1.7 **may ignore** this issue until the next
      CSM 1.7+ reinstall.

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
* [iSCSI SBPS Verification](../operations/iscsi_sbps/iSCSI_SBPS_Verification.md)

## Configuration management

* [Troubleshoot CFS Issues](../operations/configuration_management/Troubleshoot_CFS_Issues.md)
* [CFS Sessions Race Condition Test](cfs_sessions_race_condition_test.md)
* [Incrementally Configuring Images](incrementally_configuring_images.md)
* [CFS-API pods in CLBO state](known_issues/cfs-api_pods_in_CLBO_state.md)
* [VCS Password With Illegal Characters](known_issues/VCS_Password_With_Illegal_Characters.md)
* [CFS Session for Image Customization Status Stuck at `running`](known_issues/cfs_session_status_for_image_customization_on_remote_node_stuck_at_running.md)
* [CFS Key Management](../operations/configuration_management/CFS_Key_Management.md)

## ConMan

* [Console Services Troubleshooting Guide](../operations/conman/Console_Services_Troubleshooting_Guide.md)
* [ConMan Blocking Access to a Node BMC](../operations/conman/Troubleshoot_ConMan_Blocking_Access_to_a_Node_BMC.md)
* [ConMan Failing to Connect to a Console](../operations/conman/Troubleshoot_ConMan_Failing_to_Connect_to_a_Console.md)
* [ConMan Asking for Password on SSH Connection](../operations/conman/Troubleshoot_ConMan_Asking_for_Password_on_SSH_Connection.md)
* [Console Node Pod Stuck in Terminating State](../operations/conman/Troubleshoot_ConMan_Node_Pod_Stuck_Terminating.md)
* [Sensitive input echoed when using CLI to access console](../operations/conman/Log_in_to_a_Node_Using_ConMan.md#sensitive-input-echoed-when-using-cli-to-access-console)

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

## Domain Name Service (DNS)

* [Connectivity to Services with External IP addresses](../operations/network/external_dns/Troubleshoot_Systems_Not_Provisioned_with_External_IP_Addresses.md)
* [DNS Configuration Issues](../operations/network/external_dns/Troubleshoot_DNS_Configuration_Issues.md)

## Grafana dashboards

* [Grafana Dashboards](../operations/system_management_health/Troubleshoot_Grafana_Dashboard.md)

## Hardware Management System (HMS)

* [Antero Node NID Allocation](known_issues/antero_node_NID_allocation.md)
* [Component Power State Mismatch for SAT/HSM/PCS](known_issues/component_power_state_mismatch.md)
* [Debugging With HMS PPROF Images](debugging_with_hms_pprof_images.md)
* [Discovery Job Not Creating `RedfishEndpoints` in HSM](known_issues/discovery_job_not_creating_redfish_endpoints.md)
* [Flags Set For Nodes In HSM](known_issues/flags_set_for_nodes_in_hsm.md)
* [Gigabyte BMC Missing Redfish Data](known_issues/Gigabyte_BMC_Missing_Redfish_Data.md)
* [HPE iLO dropping event subscriptions and not properly transitioning power state](known_issues/hpe_systems_not_transitioning_power_state.md)
* [Interpreting HMS Health Check Results](interpreting_hms_health_check_results.md)
* [Manual BMC SSH Key Setting Process](BMC_SSH_key_manual_fixup.md)
* [Remove Duplicate Detected Events From the HSM Postgres Database](../operations/hardware_state_manager/Remove_Duplicate_Detected_Events_From_HSM_Postgres_Database.md)
* [Running HMS CT Tests Manually](hms_ct_manual_run.md)
* [SLS Not Working During Node Rebuild](known_issues/SLS_Not_Working_During_Node_Rebuild.md)
* [Test Failures Due To No Discovered Compute Nodes](known_issues/test_failures_no_discovered_computes_in_hsm.md)

## Image management

* [Image Job Performance](../operations/image_management/Image_Job_Performance.md)
* [Missing Binaries in aarch64 Images](known_issues/missing_binaries_in_aarch64_images.md)
* [IMS Images Orphaned in S3](known_issues/ims_images_orphaned_in_s3.md)
* [IMS Image Customization Job Status Stuck at `waiting_on_user`](known_issues/ims_image_customization_job_status_stuck_at_waiting_on_user.md)
* [Troubleshoot Issues with Large Images](../operations/image_management/Troubleshoot_Large_Image.md)
* [Troubleshoot Remote Build Node](../operations/image_management/Troubleshoot_Remote_Build_Node.md)
* [Troubleshoot Interactions with zypper](../operations/image_management/Troubleshoot_zypper_interaction.md)
* [iSCSI SBPS Verification](../operations/iscsi_sbps/iSCSI_SBPS_Verification.md)

## Kubernetes

* [General Kubernetes Commands for Troubleshooting](kubernetes/Kubernetes_Troubleshooting_Information.md)
* [Kubernetes Log File Locations](kubernetes/Kubernetes_Log_File_Locations.md)
* [Liveliness or Readiness Probe Failures](kubernetes/Troubleshoot_Liveliness_Readiness_Probe_Failures.md)
* [Unresponsive `kubectl` Commands](kubernetes/Troubleshoot_Unresponsive_kubectl_Commands.md)
* [Kubernetes Node `NotReady`](kubernetes/Troubleshoot_Kubernetes_Node_NotReady.md)
* [Kubernetes Pods not Starting](kubernetes/Troubleshoot_Kubernetes_Pods_Not_Starting.md)
* [Postgres Database](../operations/kubernetes/Troubleshoot_Postgres_Database.md)
* [Recover from Postgres WAL Event](../operations/kubernetes/Recover_from_Postgres_WAL_Event.md)
* [Restore Postgres](../operations/kubernetes/Restore_Postgres.md)
* [Disaster Recovery for Postgres](../operations/kubernetes/Disaster_Recovery_Postgres.md)
* [`etcd` Pods in CLBO State](known_issues/etcd_pods_in_CLBO_state.md)
* [Cilium Network Troubleshooting Runbook](Cilium_Network_Troubleshooting_Runbook.md)

## MetalLB

* [Services Without an Allocated IP Address](../operations/network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
* [BGP not Accepting Routes from MetalLB](../operations/network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)

## Node management

* [Issues with Redfish Endpoint `DiscoveryCheck` for Redfish Events from Nodes](../operations/node_management/Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md)
* [Interfaces with IP Address Issues](../operations/node_management/Troubleshoot_Interfaces_with_IP_Address_Issues.md)
* [Loss of Console Connections and Logs on Gigabyte Nodes](../operations/node_management/Troubleshoot_Loss_of_Console_Connections_and_Logs_on_Gigabyte_Nodes.md)
* [Manual NCN Upgrade](../upgrade/manual_ncn_upgrade.md)

## Security and authentication

* [Common Vault Cluster Issues](../operations/security_and_authentication/Troubleshoot_Common_Vault_Cluster_Issues.md)
* [Keycloak User Localization](../operations/security_and_authentication/Keycloak_User_Localization.md)
* [Troubleshoot Kyverno configuration manually](../operations/security_and_authentication/Troubleshoot_Kyverno_Configuration_manually.md)
* [Kyverno policy management known issues](../operations/kubernetes/Kyverno.md#known-issues)
* [VCS Password With Illegal Characters](known_issues/VCS_Password_With_Illegal_Characters.md)

## Rack Resiliency

Please refer to [Rack Resiliency Troubleshooting](../operations/rack_resiliency/Troubleshooting.md#troubleshooting-rack-resiliency)

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
