## Node Management

The HPE Cray EX system includes two types of nodes:

-   **Compute Nodes**, where high performance computing applications are run, and node names in the form of `nidXXXXXX`
-   **Non-Compute Nodes \(NCNs\)**, which carry out system functions and come in three versions:
    -   **Master** nodes, with names in the form of `ncn-mXXX`
    -   **Worker** nodes, with names in the form of `ncn-wXXX`
    -   **Utility Storage** nodes, with names in the form of `ncn-sXXX`

The HPE Cray EX system includes the following nodes:

-   Nine or more non-compute nodes \(NCNs\) that host system services:
    -   `ncn-m001`, `ncn-m002`, and `ncn-m003` are configured as Kubernetes master nodes.
    -   `ncn-w001`, `ncn-w002`, and `ncn-w003` are configured as Kubernetes worker nodes. Every system contains three or more worker nodes.
    -   `ncn-s001`, `ncn-s002` and `ncn-s003` for storage. Every system contains three or more utility storage node.
-   Four or more compute nodes, starting at `nid000001`.


### Table of Contents

* [Node Management Workflows](Node_Management_Workflows.md)
* [Rebuild NCNs](Rebuild_NCNs.md)
* [Reboot NCNs](Reboot_NCNs.md)
  * [Check and Set the metalno-wipe Setting on NCNs](Check_and_Set_the_metalno-wipe_Setting_on_NCNs.md)
* [Enable Nodes](Enable_Nodes.md)
* [Disable Nodes](Disable_Nodes.md)
* [Find Node Type and Manufacturer](Find_Node_Type_and_Manufacturer.md)
* [Add a Standard Rack Node](Add_a_Standard_Rack_Node.md)
  * [Move a Standard Rack Node](Move_a_Standard_Rack_Node.md)
  * [Move a Standard Rack Node (Same Rack/Same HSN Ports)](Move_a_Standard_Rack_Node_SameRack_SameHSNPorts.md)
* [Clear Space in Root File System on Worker Nodes](Clear_Space_in_Root_File_System_on_Worker_Nodes.md)
* [Manually Wipe Boot Configuration on Nodes to be Reinstalled](Manually_Wipe_Boot_Configuration_on_Nodes_to_be_Reinstalled.md)
* [Troubleshoot Issues with Redfish Endpoint DiscoveryCheck for Redfish Events from Nodes](Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md)
* [Reset Credentials on Redfish Devices](Reset_Credentials_on_Redfish_Devices_for_Reinstallation.md)
* [Access and Update Settings for Replacement NCNs](Access_and_Update_the_Settings_for_Replacement_NCNs.md)
* [Change Settings for HMS Collector Polling of Air Cooled Nodes](Change_Settings_for_HMS_Collector_Polling_of_Air_Cooled_Nodes.md)
* [Use the Physical KVM](Use_the_Physical_KVM.md)
* [Launch a Virtual KVM on Gigabyte Servers](Launch_a_Virtual_KVM_on_Gigabyte_Servers.md)
* [Launch a Virtual KVM on Intel Servers](Launch_a_Virtual_KVM_on_Intel_Servers.md)
* [Change Java Security Settings](Change_Java_Security_Settings.md)
* [Verify Accuracy of the System Clock](Verify_Accuracy_of_the_System_Clock.md)
* [Configuration of NCN Bonding](Configuration_of_NCN_Bonding.md)
  * [Change Interfaces in the Bond](Change_Interfaces_in_the_Bond.md)
  * [Troubleshoot Interfaces with IP Address Issues](Troubleshoot_Interfaces_with_IP_Address_Issues.md)
* [Troubleshoot Loss of Console Connections and Logs on Gigabyte Nodes](Troubleshoot_Loss_of_Console_Connections_and_Logs_on_Gigabyte_Nodes.md)
* [Check the BMC Failover Mode](Check_the_BMC_Failover_Mode.md)
* [Update Compute Node Mellanox HSN NIC Firmware](Update_Compute_Node_Mellanox_HSN_NIC_Firmware.md)
* [TLS Certificates for Redfish BMCs](TLS_Certificates_for_Redfish_BMCs.md)
  * [Add TLS Certificates to BMCs](Add_TLS_Certificates_to_BMCs.md)
* [Run a Manual ckdump on Compute Nodes](Run_a_Manual_ckdump_on_Compute_Nodes.md)
* [Dump a Compute Node with Node Memory Dump (NMD)](Dump_a_Compute_Node_with_Node_Memory_Dump_nmd.md)
* [Dump a Non-Compute Node](Dump_a_Non-Compute_Node.md)
* [Enable Passwordless Connections to Liquid Cooled Node BMCs](Enable_Passwordless_Connections_to_Liquid_Cooled_Node_BMCs.md)
  * [View BIOS Logs for Liquid Cooled Nodes](View_BIOS_Logs_for_Liquid_Cooled_Nodes.md)
* [Enable Nvidia GPU Support](Enable_Nvidia_GPU_Support.md)
  * [Update Nvidia GPU Software without Rebooting](Update_Nvidia_GPU_Software_without_Rebooting.md)



