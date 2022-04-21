# CSM Troubleshooting Information

This document provides troubleshooting information for services and functionality provided by CSM.

### Known Issues
 * [Known Issues](#known-issues)
    * [SAT/HSM/CAPMC Component Power State Mismatch](known_issues/component_power_state_mismatch.md)
    * [HMS Discovery job not creating RedfishEndpoints in Hardware State Manager](known_issues/discovery_job_not_creating_redfish_endpoints.md)
    * [initrd.img.xz not found](known_issues/initrd.img.zx_not_found.md) 
### Troubleshoot Topics
 * Troubleshoot Kubernetes
    * [General Kubernetes Commands for Troubleshooting](kubernetes/Kubernetes_Troubleshooting_Information.md)
    * [Kubernetes Log File Locations](kubernetes/Kubernetes_Log_File_Locations.md)
    * [Troubleshoot Liveliness or Readiness Probe Failures](kubernetes/Troubleshoot_Liveliness_Readiness_Probe_Failures.md)
    * [Troubleshoot Unresponsive kubectl Commands](kubernetes/Troubleshoot_Unresponsive_kubectl_Commands.md)
    * [Troubleshoot Kubernetes Node NotReady](kubernetes/Troubleshoot_Kubernetes_Node_NotReady.md)
    * [Troubleshoot Postgres Database](../operations/kubernetes/Troubleshoot_Postgres_Database.md)
    * [Recover from Postgres WAL Event](../operations/kubernetes/Troubleshoot_Postgres_Database.md)
    * [Restore Postgres](../operations/kubernetes/Restore_Postgres.md)
    * [Disaster Recovery for Postgres](../operations/kubernetes/Disaster_Recovery_Postgres.md)
 * Troubleshoot UAS Issues
      * [Troubleshoot UAIs by Viewing Log Output](../operations/UAS_user_and_admin_topics/Troubleshoot_UAIs_by_Viewing_Log_Output.md)
      * [Troubleshoot Stale Brokered UAIs](../operations/UAS_user_and_admin_topics/Troubleshoot_Stale_Brokered_UAIs.md)
      * [Troubleshoot UAI Stuck in "ContainerCreating"](../operations/UAS_user_and_admin_topics/Troubleshoot_UAI_Stuck_in_ContainerCreating.md)
      * [Troubleshoot Duplicate Mount Paths in a UAI](../operations/UAS_user_and_admin_topics/Troubleshoot_Duplicate_Mount_Paths_in_a_UAI.md)
      * [Troubleshoot Missing or Incorrect UAI Images](../operations/UAS_user_and_admin_topics/Troubleshoot_Missing_or_Incorrect_UAI_Images.md)
      * [Troubleshoot Common Mistakes when Creating a Custom End-User UAI Image](../operations/UAS_user_and_admin_topics/Troubleshoot_Common_Mistakes_when_Creating_a_Custom_End-User_UAI_Image.md)
 * Troubleshoot Boot Issues
      * [Troubleshoot UAN Boot Issues](../operations/boot_orchestration/Troubleshoot_UAN_Boot_Issues.md)
      * [Troubleshoot Compute Node Boot Issues Related to Unified Extensible Firmware Interface (UEFI)](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Unified_Extensible_Firmware_Interface_UEFI.md)
      * [Troubleshoot Compute Node Boot Issues Related to Dynamic Host Configuration Protocol (DHCP)](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Dynamic_Host_Configuration_Protocol_DHCP.md)
      * [Troubleshoot Compute Node Boot Issues Related to the Boot Script Service](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_the_Boot_Script_Service_BSS.md)
      * [Troubleshoot Compute Node Boot Issues Related to Trivial File Transfer Protocol (TFTP)](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Trivial_File_Transfer_Protocol_TFTP.md)
      * [Troubleshoot Compute Node Boot Issues Using Kubernetes](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Using_Kubernetes.md)
      * [Log File Locations and Ports Used in Compute Node Boot Troubleshooting](../operations/boot_orchestration/Log_File_Locations_and_Ports_Used_in_Compute_Node_Boot_Troubleshooting.md)
      * [Troubleshoot Compute Node Boot Issues Related to Slow Boot Times](../operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Slow_Boot_Times.md)
 * Troubleshoot Compute Rolling Upgrades
      * [Troubleshoot Nodes Failing to Upgrade in a CRUS Session](../operations/compute_rolling_upgrades/Troubleshoot_Nodes_Failing_to_Upgrade_in_a_CRUS_Session.md)
      * [Troubleshoot a Failed CRUS Session Because of Unmet Conditions](../operations/compute_rolling_upgrades/Troubleshoot_a_Failed_CRUS_Session_Due_to_Unmet_Conditions.md)
      * [Troubleshoot a Failed CRUS Session Because of Bad Parameters](../operations/compute_rolling_upgrades/Troubleshoot_a_Failed_CRUS_Session_Due_to_Bad_Parameters.md)
 * Troubleshoot Configuration Management
      * [Troubleshoot Ansible Play Failures in CFS Sessions](../operations/configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md)
      * [Troubleshoot CFS Session Failing to Complete](../operations/configuration_management/Troubleshoot_CFS_Session_Failing_to_Complete.md)
 * Troubleshoot Security and Authentication
      * [Troubleshoot Common Vault Cluster Issues](../operations/security_and_authentication/Troubleshoot_Common_Vault_Cluster_Issues.md)
 * Troubleshoot ConMan
      * [Troubleshoot ConMan Blocking Access to a Node BMC](../operations/conman/Troubleshoot_ConMan_Blocking_Access_to_a_Node_BMC.md)
      * [Troubleshoot ConMan Failing to Connect to a Console](../operations/conman/Troubleshoot_ConMan_Failing_to_Connect_to_a_Console.md)
      * [Troubleshoot ConMan Asking for Password on SSH Connection](../operations/conman/Troubleshoot_ConMan_Asking_for_Password_on_SSH_Connection.md)
 * Troubleshoot Utility Storage
      * [Troubleshoot Failure to Get Ceph Health](../operations/utility_storage/Troubleshoot_Failure_to_Get_Ceph_Health.md)
      * [Troubleshoot a Down OSD](../operations/utility_storage/Troubleshoot_a_Down_OSD.md)
      * [Troubleshoot Ceph OSDs Reporting Full](../operations/utility_storage/Troubleshoot_Ceph_OSDs_Reporting_Full.md)
      * [Troubleshoot System Clock Skew](../operations/utility_storage/Troubleshoot_System_Clock_Skew.md)
      * [Troubleshoot an Unresponsive S3 Endpoint](../operations/utility_storage/Troubleshoot_an_Unresponsive_S3_Endpoint.md)
      * [Troubleshoot Ceph-Mon Processes Stopping and Exceeding Max Restarts](../operations/utility_storage/Troubleshoot_Ceph-Mon_Processes_Stopping_and_Exceeding_Max_Restarts.md)
      * [Troubleshoot Large Object Map Objects in Ceph Health](../operations/utility_storage/Troubleshoot_Large_Object_Map_Objects_in_Ceph_Health.md)
      * [Troubleshoot Failure of RGW Health Check](../operations/utility_storage/Troubleshoot_RGW_Health_Check_Fail.md)
 * Troubleshoot Node Management
      * [Troubleshoot Issues with Redfish Endpoint DiscoveryCheck for Redfish Events from Nodes](../operations/node_management/Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md)
      * [Troubleshoot Interfaces with IP Address Issues](../operations/node_management/Troubleshoot_Interfaces_with_IP_Address_Issues.md)
      * [Troubleshoot Loss of Console Connections and Logs on Gigabyte Nodes](../operations/node_management/Troubleshoot_Loss_of_Console_Connections_and_Logs_on_Gigabyte_Nodes.md)
 * Troubleshoot Customer Access Network (CAN)
      * [Troubleshoot CAN Issues](../operations/network/customer_access_network/Troubleshoot_CAN_Issues.md)
 * Troubleshoot Dynamic Host Configuration Protocol (DHCP)
      
 * Domain Name Service (DNS)
      * [Troubleshoot Connectivity to Services with External IP addresses](../operations/network/external_dns/Troubleshoot_Systems_Not_Provisioned_with_External_IP_Addresses.md)
      * [Troubleshoot DNS Configuration Issues](../operations/network/external_dns/Troubleshoot_DNS_Configuration_Issues.md)
 * MetalLB in BGP-Mode
      * [Troubleshoot Services without an Allocated IP Address](../operations/network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
      * [Troubleshoot BGP not Accepting Routes from MetalLB](../operations/network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)
 * Spire
      * [Restore Spire Postgres without a Backup](../operations/spire/Restore_Spire_Postgres_without_a_Backup.md)
      * [Troubleshoot Spire Failing to Start on NCNs](../operations/spire/Troubleshoot_Spire_Failing_to_Start_on_NCNs.md)
<a name="known-issues"></a>


