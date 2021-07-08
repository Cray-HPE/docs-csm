## Boot Orchestration 

The Boot Orchestration Service \(BOS\) is responsible for booting, configuring, and shutting down collections of nodes. This is accomplished using BOS components, such as boot orchestration session templates and sessions, as well as launching a Boot Orchestration Agent \(BOA\) that fulfills boot requests.

BOS users create a BOS session template via the REST API. A session template is a collection of metadata for a group of nodes and their desired boot artifacts and configuration. A BOS session can then be created by applying an action to a session template. The available actions are boot, reboot, shutdown, and configure. BOS will create a Kubernetes BOA job to apply an action. BOA coordinates with the underlying subsystems to complete the action requested. The session can be monitored to determine the status of the request.

BOS depends on each of the following services to complete its tasks:

-   BOA - Handles any action type submitted to the BOS API. BOA jobs are created and launched by BOS.
-   Boot Script Service \(BSS\) - Stores the configuration information that is used to boot each hardware component. Nodes consult BSS for their boot artifacts and boot parameters when nodes boot or reboot.
-   Configuration Framework Service \(CFS\) - BOA launches CFS to apply configuration to the nodes in its boot sets \(node personalization\).
-   Cray Advanced Platform Monitoring and Control \(CAPMC\) - Used to power on and off the nodes.
-   Hardware State Manager \(HSM\) - Tracks the state of each node and what groups and roles nodes are included in.


### Use the BOS Cray CLI Commands

BOS utilizes the Cray CLI commands. The latest API information can be found with the following command:

```bash
ncn-m001# cray bos list
[[results]]
major = "1"
minor = "0"
patch = "0"
[[results.links]]
href = "https://api-gw-service-nmn.local/apis/bos/v1"
rel = "self"
```

### BOS API Changes in Upcoming CSM-1.2.0 Release

This is a forewarning of changes that will be made to the BOS API in the upcoming CSM-1.2.0 release. The following changes will be made:

* The `--template-body` option for the Cray CLI `bos` command will be deprecated.
* Performing a GET on the session status for a boot set (i.e. /v1/session/{session_id}/status/{boot_set_name}) currently returns a status code of 201, but instead it should return a status code of 200. This will be corrected to return 200.


### Table of Contents

The procedures in this section include the information required to boot, configure, and shut down collections of nodes with BOS.

- [BOS Workflows](BOS_Workflows.md)
- [BOS Session Templates](Session_Templates.md)
    - [Manage a Session Template](Manage_a_Session_Template.md)
    - [Create a Session Template to Boot Compute Nodes with CPS](Create_a_Session_Template_to_Boot_Compute_Nodes_with_CPS.md)
    - [Boot UANs](Boot_UANs.md)
- [BOS Sessions](Sessions.md)
    - [Manage a BOS Session](Manage_a_BOS_Session.md)
    - [View the Status of a BOS Session](View_the_Status_of_a_BOS_Session.md)
    - [Limit the Scope of a BOS Session](Limit_the_Scope_of_a_BOS_Session.md)
    - [Configure the BOS Timeout When Booting Compute Nodes](Configure_the_BOS_Timeout_When_Booting_Nodes.md)
    - [Check the Progress of BOS Session Operations](Check_the_Progress_of_BOS_Session_Operations.md)
    - [Kernel Boot Paramaters](Kernel_Boot_Parameters.md)
    - [Clean Up Logs After a BOA Kubernetes Job](Clean_Up_Logs_After_a_BOA_Kubernetes_Job.md)
    - [Clean Up After a BOS/BOA Job is Completed or Cancelled](Clean_Up_After_a_BOS-BOA_Job_is_Completed_or_Cancelled.md)
    - [Troubleshoot UAN Boot Issues](Troubleshoot_UAN_Boot_Issues.md)
    - [Troubleshoot Booting Nodes with Hardware Issues](Troubleshoot_Booting_Nodes_with_Hardware_Issues.md)
- [BOS Limitations for Gigabyte BMC Hardware](Limitations_for_Gigabyte_BMC_Hardware.md)
- [Compute Node Boot Sequence](Compute_Node_Boot_Sequence.md)
  - [Healthy Compute Node Boot Process](Healthy_Compute_Node_Boot_Process.md)
  - [Node Boot Root Cause Analysis](Node_Boot_Root_Cause_Analysis.md)
    - [Compute Node Boot Issue Symptom: Duplicate Address Warnings and Declined DHCP Offers in Logs](Compute_Node_Boot_Issue_Symptom_Duplicate_Address_Warnings_and_Declined_DHCP_Offers_in_Logs.md)
    - [Compute Node Boot Issue Symptom: Node is Not Able to Download the Required Artifacts](Compute_Node_Boot_Issue_Symptom_Node_is_Not_Able_to_Download_the_Required_Artifacts.md)
    - [Compute Node Boot Issue Symptom: Message About Invalid EEPROM Checksum in Node Console or Log](Compute_Node_Boot_Issue_Symptom_Message_About_Invalid_EEPROM_Checksum_in_Node_Console_or_Log.md)
    - [Boot Issue Symptom: Node HSN Interface Does Not Appear or Show Detected Links Detected](Boot_Issue_Symptom_Node_HSN_Interface_Does_Not_Appear_or_Shows_No_Link_Detected.md)
    - [Compute Node Boot Issue Symptom: Node Console or Logs Indicate that the Server Response has Timed Out](Boot_Issue_Symptom_Node_Console_or_Logs_Indicatate_that_the_Server_Response_has_Timed_Out.md)
    - [Tools for Resolving Compute Node Boot Issues](Tools_for_Resolving_Boot_Issues.md)
    - [Troubleshoot Compute Node Boot Issues Related to Unified Extensible Firmware Interface (UEFI)](Troubleshoot_Compute_Node_Boot_Issues_Related_to_Unified_Extensible_Firmware_Interface_UEFI.md)
    - [Troubleshoot Compute Node Boot Issues Related to Dynamic Host Configuration Protocol (DHCP)](Troubleshoot_Compute_Node_Boot_Issues_Related_to_Dynamic_Host_Configuration_Protocol_DHCP.md)
    - [Troubleshoot Compute Node Boot Issues Related to the Boot Script Service](Troubleshoot_Compute_Node_Boot_Issues_Related_to_the_Boot_Script_Service_BSS.md)
    - [Troubleshoot Compute Node Boot Issues Related to Trivial File Transfer Protocol (TFTP)](Troubleshoot_Compute_Node_Boot_Issues_Related_to_Trivial_File_Transfer_Protocol_TFTP.md)
    - [Troubleshoot Compute Node Boot Issues Using Kubernetes](Troubleshoot_Compute_Node_Boot_Issues_Using_Kuberentes.md)
    - [Log File Locations and Ports Used in Compute Node Boot Troubleshooting](Log_File_Locations_and_Ports_Used_in_Compute_Node_Boot_Troubleshooting.md)
    - - [Troubleshoot Compute Node Boot Issues Related to Slow Boot Times](Troubleshoot_Compute_Node_Boot_Issues_Related_to_Slow_Boot_Times.md)
  - [Edit the iPXE Embedded Boot Script](Edit_the_iPXE_Embedded_Boot_Script.md)
  - [Redeploy the iPXE and TFTP Services](Redeploy_the_IPXE_and_TFTP_Services.md)
  - [Upload Node Boot Information to Boot Script Service](Upload_Node_Boot_Information_to_Boot_Script_Service_BSS.md)
  
