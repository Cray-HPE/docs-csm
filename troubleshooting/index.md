# CSM Troubleshooting Information

This document provides troubleshooting information for services and functionality provided by CSM.

### Known Issues
 * [Known Issues](#known-issues)
    * [Hardware Discovery](known_issues/Hardware_Discovery.md)
    * [SAT/HSM/CAPMC Component Power State Mismatch](https://github.com/Cray-HPE/docs-csm/blob/CASMINS-4311/troubleshooting/known_issues/component_power_state_mismatch.md)

### Troubleshoot Topics
 * Troubleshoot Kubernetes
    * [General Kubernetes Commands for Troubleshooting](https://github.com/Cray-HPE/docs-csm/blob/CASMINS-4311/troubleshooting/kubernetes/Kubernetes_Troubleshooting_Information.md)
    * [Kubernetes Log File Locations](https://github.com/Cray-HPE/docs-csm/blob/CASMINS-4311/troubleshooting/kubernetes/Kubernetes_Log_File_Locations.md)
    * [Troubleshoot Liveliness or Readiness Probe Failures](https://github.com/Cray-HPE/docs-csm/blob/CASMINS-4311/troubleshooting/kubernetes/Troubleshoot_Liveliness_Readiness_Probe_Failures.md)
    * [Troubleshoot Unresponsive kubectl Commands](https://github.com/Cray-HPE/docs-csm/blob/CASMINS-4311/troubleshooting/kubernetes/Troubleshoot_Unresponsive_kubectl_Commands.md)
    * [Troubleshoot Kubernetes Node NotReady](https://github.com/Cray-HPE/docs-csm/blob/CASMINS-4311/troubleshooting/kubernetes/Troubleshoot_Kubernetes_Node_NotReady.md)
    * [Troubleshoot Postgres Database](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/kubernetes/Troubleshoot_Postgres_Database.md)
    * [Recover from Postgres WAL Event](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/kubernetes/Troubleshoot_Postgres_Database.md)
    * [Restore Postgres](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/kubernetes/Restore_Postgres.md)
    * [Disaster Recovery for Postgres](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/kubernetes/Disaster_Recovery_Postgres.md)
 * Troubleshoot UAS Issues
      * [Troubleshoot UAS by Viewing Log Output](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/UAS_user_and_admin_topics/Troubleshoot_UAS_by_Viewing_Log_Output.md)
      * [Troubleshoot UAIs by Viewing Log Output](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/UAS_user_and_admin_topics/Troubleshoot_UAIs_by_Viewing_Log_Output.md)
      * [Troubleshoot Stale Brokered UAIs](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/UAS_user_and_admin_topics/Troubleshoot_Stale_Brokered_UAIs.md)
      * [Troubleshoot UAI Stuck in "ContainerCreating"](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/UAS_user_and_admin_topics/Troubleshoot_UAI_Stuck_in_ContainerCreating.md)
      * [Troubleshoot Duplicate Mount Paths in a UAI](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/UAS_user_and_admin_topics/Troubleshoot_Duplicate_Mount_Paths_in_a_UAI.md)
      * [Troubleshoot Missing or Incorrect UAI Images](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/UAS_user_and_admin_topics/Troubleshoot_Missing_or_Incorrect_UAI_Images.md)
     
      * [Troubleshoot Common Mistakes when Creating a Custom End-User UAI Image](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/UAS_user_and_admin_topics/Troubleshoot_Common_Mistakes_when_Creating_a_Custom_End-User_UAI_Image.md)
 * Troubleshoot Boot Issues
      * [Troubleshoot UAN Boot Issues](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/boot_orchestration/Troubleshoot_UAN_Boot_Issues.md)
      * [Troubleshoot Compute Node Boot Issues Related to Unified Extensible Firmware Interface (UEFI)](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Unified_Extensible_Firmware_Interface_UEFI.md)
      * [Troubleshoot Compute Node Boot Issues Related to Dynamic Host Configuration Protocol (DHCP)](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Dynamic_Host_Configuration_Protocol_DHCP.md)
      * [Troubleshoot Compute Node Boot Issues Related to the Boot Script Service](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_the_Boot_Script_Service_BSS.md)
      * [Troubleshoot Compute Node Boot Issues Related to Trivial File Transfer Protocol (TFTP)](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Trivial_File_Transfer_Protocol_TFTP.md)
      * [Troubleshoot Compute Node Boot Issues Using Kubernetes](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Using_Kubernetes.md)
      * [Log File Locations and Ports Used in Compute Node Boot Troubleshooting](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/boot_orchestration/Log_File_Locations_and_Ports_Used_in_Compute_Node_Boot_Troubleshooting.md)
      * [Troubleshoot Compute Node Boot Issues Related to Slow Boot Times](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Slow_Boot_Times.md)
 * Troubleshoot Compute Rolling Upgrades
      * [Troubleshoot Nodes Failing to Upgrade in a CRUS Session](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/compute_rolling_upgrades/Troubleshoot_Nodes_Failing_to_Upgrade_in_a_CRUS_Session.md)
      * [Troubleshoot a Failed CRUS Session Because of Unmet Conditions](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/compute_rolling_upgrades/Troubleshoot_a_Failed_CRUS_Session_Due_to_Unmet_Conditions.md)
      * [Troubleshoot a Failed CRUS Session Because of Bad Parameters](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/compute_rolling_upgrades/Troubleshoot_a_Failed_CRUS_Session_Due_to_Bad_Parameters.md)
 * Troubleshoot Configuration Management
      * [Troubleshoot Ansible Play Failures in CFS Sessions](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md)
      * [Troubleshoot CFS Session Failing to Complete](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/configuration_management/Troubleshoot_CFS_Session_Failing_to_Complete.md)
 * Troubleshoot Security and Authentication
      * [Troubleshoot Common Vault Cluster Issues](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/security_and_authentication/Troubleshoot_Common_Vault_Cluster_Issues.md)
 * Troubleshoot ConMan
      * [Troubleshoot ConMan Blocking Access to a Node BMC](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/conman/Troubleshoot_ConMan_Blocking_Access_to_a_Node_BMC.md)
      * [Troubleshoot ConMan Failing to Connect to a Console](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/conman/Troubleshoot_ConMan_Failing_to_Connect_to_a_Console.md)
      * [Troubleshoot ConMan Asking for Password on SSH Connection](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/conman/Troubleshoot_ConMan_Asking_for_Password_on_SSH_Connection.md)
 * Troubleshoot Utility Storage
      * [Troubleshoot Failure to Get Ceph Health](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/utility_storage/Troubleshoot_Failure_to_Get_Ceph_Health.md)
      * [Troubleshoot a Down OSD](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/utility_storage/Troubleshoot_a_Down_OSD.md)
      * [Troubleshoot Ceph OSDs Reporting Full](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/utility_storage/Troubleshoot_Ceph_OSDs_Reporting_Full.md)
      * [Troubleshoot System Clock Skew](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/utility_storage/Troubleshoot_System_Clock_Skew.md)
      * [Troubleshoot an Unresponsive S3 Endpoint](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/utility_storage/Troubleshoot_an_Unresponsive_S3_Endpoint.md)
      * [Troubleshoot Ceph-Mon Processes Stopping and Exceeding Max Restarts](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/utility_storage/Troubleshoot_Ceph-Mon_Processes_Stopping_and_Exceeding_Max_Restarts.md)
      * [Troubleshoot Large Object Map Objects in Ceph Health](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/utility_storage/Troubleshoot_Large_Object_Map_Objects_in_Ceph_Health.md)
      * [Troubleshoot Failure of RGW Health Check](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/utility_storage/Troubleshoot_RGW_Health_Check_Fail.md)
 * Troubleshoot Node Management
      * [Troubleshoot Issues with Redfish Endpoint DiscoveryCheck for Redfish Events from Nodes](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/node_management/Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md)
      * [Troubleshoot Interfaces with IP Address Issues](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/node_management/Troubleshoot_Interfaces_with_IP_Address_Issues.md)
      * [Troubleshoot Loss of Console Connections and Logs on Gigabyte Nodes](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/node_management/Troubleshoot_Loss_of_Console_Connections_and_Logs_on_Gigabyte_Nodes.md)
 * Troubleshoot Customer Access Network (CAN)
      * [Troubleshoot CAN Issues](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/network/customer_access_network/Troubleshoot_CAN_Issues.md)
 * Troubleshoot Dynamic Host Configuration Protocol (DHCP)
      
 * Domain Name Service (DNS)
      * [Troubleshoot Connectivity to Services with External IP addresses](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/network/external_dns/Troubleshoot_Systems_Not_Provisioned_with_External_IP_Addresses.md)
      * [Troubleshoot DNS Configuration Issues](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/network/external_dns/Troubleshoot_DNS_Configuration_Issues.md)
 * MetalLB in BGP-Mode
      * [Troubleshoot Services without an Allocated IP Address](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
      * [Troubleshoot BGP not Accepting Routes from MetalLB](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)
 * Spire
      * [Restore Spire Postgres without a Backup](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/spire/Restore_Spire_Postgres_without_a_Backup.md)
      * [Troubleshoot Spire Failing to Start on NCNs](https://github.com/Cray-HPE/docs-csm/blob/release/1.0/operations/spire/Troubleshoot_Spire_Failing_to_Start_on_NCNs.md)
<a name="known-issues"></a>


