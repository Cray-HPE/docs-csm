# CSM Troubleshooting Information

This document provides links to troubleshooting information for services and functionality provided by CSM.

## Helpful tips for navigating the CSM repository

In the main repository landing page, change the branch to the CSM version being used on the system (for example, release/1.0, release/1.2, release/1.3).

Use the pre-populated GitHub "Search or jump to..." function in the upper left hand side of the page and append keywords related
to the exiting problem seen into the existing search. (The example searches for "ping" and "PXE" related troubleshooting resources on the "main" branch.)

* Follow any run-books, guides, or procedures which are directly related to the problem.

* Change the branch to "main" and search a second time to retrieve very recent or beta run-books and guides.

* Users can also expand the search beyond the "troubleshooting" section (instead of doing "path troubleshooting") and/or use more advanced GitHub searches such as "path configure" to find the right context.

## Quick links

* [Known issues](#known-issues)
* [Booting](#booting)
* [Compute rolling upgrades](#compute-rolling-upgrades)
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
* [UAS](#user-access-service-uas)
* [Utility storage](#utility-storage)

## Known issues

* [SAT/HSM/CAPMC Component Power State Mismatch](known_issues/component_power_state_mismatch.md)
* [HMS Discovery job not creating `RedfishEndpoint`s in Hardware State Manager](known_issues/discovery_job_not_creating_redfish_endpoints.md)
* [`initrd.img.xz` not found](known_issues/initrd.img.zx_not_found.md)
* [SSL Certificate Validation Issues](known_issues/ssl_certificate_validation_issues.md)
* [SLS Not Working During Node Rebuild](known_issues/SLS_Not_Working_During_Node_Rebuild.md)
* [Antero node NID allocation](known_issues/antero_node_NID_allocation.md)
* [HPE nodes not properly transitioning power state](known_issues/hpe_systems_not_transitioning_power_state.md)

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
* [Issues Related to Slow Boot Times](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Slow_Boot_Times.md)

## Compute rolling upgrades

CRUS was deprecated in CSM 1.2.0. It will be removed in a future CSM release and replaced with BOS V2, which will provide similar functionality.
See [Deprecated features](../introduction/differences.md#deprecated-features).

* [Nodes Failing to Upgrade in a CRUS Session](../operations/compute_rolling_upgrades/Troubleshoot_Nodes_Failing_to_Upgrade_in_a_CRUS_Session.md)
* [Failed CRUS Session Because of Unmet Conditions](../operations/compute_rolling_upgrades/Troubleshoot_a_Failed_CRUS_Session_Due_to_Unmet_Conditions.md)
* [Failed CRUS Session Because of Bad Parameters](../operations/compute_rolling_upgrades/Troubleshoot_a_Failed_CRUS_Session_Due_to_Bad_Parameters.md)

## Configuration management

* [Ansible Play Failures in CFS Sessions](../operations/configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md)
* [CFS Session Failing to Complete](../operations/configuration_management/Troubleshoot_CFS_Session_Failing_to_Complete.md)

## ConMan

* [ConMan Blocking Access to a Node BMC](../operations/conman/Troubleshoot_ConMan_Blocking_Access_to_a_Node_BMC.md)
* [ConMan Failing to Connect to a Console](../operations/conman/Troubleshoot_ConMan_Failing_to_Connect_to_a_Console.md)
* [ConMan Asking for Password on SSH Connection](../operations/conman/Troubleshoot_ConMan_Asking_for_Password_on_SSH_Connection.md)

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

## MetalLB

* [Services Without an Allocated IP Address](../operations/network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
* [BGP not Accepting Routes from MetalLB](../operations/network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)

## Node management

* [Issues with Redfish Endpoint `DiscoveryCheck` for Redfish Events from Nodes](../operations/node_management/Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md)
* [Interfaces with IP Address Issues](../operations/node_management/Troubleshoot_Interfaces_with_IP_Address_Issues.md)
* [Loss of Console Connections and Logs on Gigabyte Nodes](../operations/node_management/Troubleshoot_Loss_of_Console_Connections_and_Logs_on_Gigabyte_Nodes.md)

## Security and authentication

* [Common Vault Cluster Issues](../operations/security_and_authentication/Troubleshoot_Common_Vault_Cluster_Issues.md)
* [Keycloak User Localization](../operations/security_and_authentication/Keycloak_User_Localization.md)
* [Troubleshoot Kyverno configuration manually](../operations/security_and_authentication/Troubleshoot_Kyverno_Configuration_manually.md)

## Spire

* [Restore Spire Postgres without a Backup](../operations/spire/Restore_Spire_Postgres_without_a_Backup.md)
* [Spire Database Cluster DNS Lookup Failure](known_issues/spire_database_lookup_error.md)
* [Spire Failing to Start on NCNs](../operations/spire/Troubleshoot_Spire_Failing_to_Start_on_NCNs.md)

## User Access service UAS

* [Viewing UAI Log Output](../operations/UAS_user_and_admin_topics/Troubleshoot_UAIs_by_Viewing_Log_Output.md)
* [Stale Brokered UAIs](../operations/UAS_user_and_admin_topics/Troubleshoot_Stale_Brokered_UAIs.md)
* [UAI Stuck in `ContainerCreating`](../operations/UAS_user_and_admin_topics/Troubleshoot_UAI_Stuck_in_ContainerCreating.md)
* [Duplicate Mount Paths in a UAI](../operations/UAS_user_and_admin_topics/Troubleshoot_Duplicate_Mount_Paths_in_a_UAI.md)
* [Missing or Incorrect UAI Images](../operations/UAS_user_and_admin_topics/Troubleshoot_Missing_or_Incorrect_UAI_Images.md)
* [Common Mistakes When Creating a Custom End-User UAI Image](../operations/UAS_user_and_admin_topics/Troubleshoot_Common_Mistakes_when_Creating_a_Custom_End-User_UAI_Image.md)

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
