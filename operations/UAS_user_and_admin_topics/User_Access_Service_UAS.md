---
category: numbered
---

# User Access Service \(UAS\)

Provides information about the features of UAS.

The User Access Service \(UAS\) is a containerized service managed by Kubernetes that enables application developers to create and run user applications. UAS runs on a non-compute node \(NCN\) that is acting as a Kubernetes worker node.

Users launch a User Access Instance \(UAI\) using the cray command. Users can also transfer data between the Cray system and external systems using the UAI.

When a user requests a new UAI, the UAS service returns status and connection information to the newly-created UAI. External access to UAS is routed through a node that hosts gateway services.

The timezone inside the UAI container matches the timezone on the host on which it is running, For example, if the timezone on the host is set to CDT, the UAIs on that host will also be set to CDT.

|Component|Function/Description|
|---------|--------------------|
|User Access Instance \(UAI\)|An instance of UAS container.|
|`uas-mgr`|Manages UAI life cycles.|

|Container Element|Components|
|-----------------|----------|
|Operating system|SLES15 SP1|
|kubectl command|Utility to interact with Kubernetes.|
|cray command|Command that allows users to create, describe, and delete UAIs.|

Use cray uas list to list the following parameters for a UAI.

**Note:** The example values below are used throughout the UAS procedures. They are used as examples only. Users should substitute with site-specific values.

|Parameter|Description|Example value|
|---------|-----------|-------------|
|`uai_connect_string`|The UAI connection string|`ssh user@203.0.113.0 -i ~/.ssh/id\_rsa`|
|`uai_img`|The UAI image ID|`registry.local/cray/cray-uas-sles15sp1-slurm:latest`|
|`uai_name`|The UAI name|`uai-user-be3a6770`|
|`uai_status`|The state of the UAI.|`Running: Ready`|
|`username`|The user who created the UAI.|`user`|
|`uai_age`|The age of the UAI.|`11m`|
|`uai_host`|The node hosting the UAI.|`ncn-w001`|

-   **[UAS Limitations](UAS_Limitations.md)**  
Functionality that is currently not supported while using UAS.
-   **[Elements of a UAI](Elements_of_a_UAI.md)**  
All UAIs require a container image. UAIs may also include volumes, a resource specification, and other small configuration items.
-   **[End-User UAIs](End_User_UAIs.md)**  
What User Access Instances \(UAIs\) are, what their purpose is, and how they differ from UANs.
-   **[Special Purpose UAIs](Special_Purpose_UAIs.md)**  
UAIs are not only for interactive user logins. UAI classes enable HPE Cray EX administrators to build and deploy UAIs that server special functions, like the prebuilt broker UAI.
-   **[Configure UAIs in UAS](Configure_UAIs_in_UAS.md)**  
The four main items of UAI configuration in UAS. Links to procedures for listing, adding, examining, updating, and deleting each item.
-   **[Select and Configure Host Nodes for UAIs](Select_and_Configure_Host_Nodes_for_UAIs.md)**  
Site administrators can control the set of UAI host nodes by labeling Kubernetes worker nodes appropriately.
-   **[About UAI Classes](About_UAI_Classes.md)**  
This topic explains all the fields in a UAI class and gives guidance on setting them when creating UAI classes.
-   **[Create and Register a Custom UAI Image](Create_and_Register_a_Custom_UAI_Image.md)**  
Use the compute node image to build a custom UAI image so that users can build compute node software using the HPE Cray PE.
-   **[Create a UAI with Additional Ports](Create_a_UAI_with_Additional_Ports.md)**  
Displays when you mouse over the topic on the Cray Portal.
-   **[Delete a UAI](Delete_a_UAI.md)**  
Procedure to delete a UAS instance.
-   **[List and Delete All UAIs](List_and_Delete_All_UAIs.md)**  
Displays when you mouse over the topic on the Cray Portal.
-   **[List UAS Information](List_UAS_Information.md)**  
List descriptive information about the User Access Service.
-   **[Troubleshoot UAS Issues](Troubleshoot_UAS_Issues.md)**  
UAS troubleshooting tips and techniques.

**Related information**  


[About the HPE Cray EX System Administration Guide](About_the_HPE_Cray_EX_System_Administration_Guide.md)

[System Services](System_Services.md)

[Cray System Management \(CSM\) Support](Cray_System_Management_Support.md)

[Reboot NCNs](Reboot_NCNs.md)

[Compute Node Boot Sequence](Compute_Node_Boot_Sequence.md)

[Boot Orchestration Service \(BOS\)](Boot_Orchestration_Service_BOS.md)

[Compute Rolling Upgrade Service \(CRUS\)](Compute_Rolling_Upgrade_Service_CRUS.md)

[System Security and Authentication](System_Security_and_Authentication.md)

[Artifact Management](Artifact_Management.md)

[Image Management with Kiwi-NG Recipes](Image_Management_with_Kiwi-NG_Recipes.md)

[Package Repository Management with Nexus](Package_Repository_Management_with_Nexus.md)

[Configuration Management](Configuration_Management.md)

[Utility Storage](Utility_Storage.md)

[Kubernetes Architecture](Kubernetes_Architecture.md)

[Resilience of System Management Services](Resilience_of_System_Management_Services.md)

[Network Administration](Network_Administration.md)

[Slingshot Network Management](Slingshot_Network_Management.md)

[Use Slurm Workload Manager](Use%20Slurm%20Workload%20Manager.md)

[Use PBS Pro Workload Manager](Use_PBS_Pro_Workload_Manager.md)

[Application Task Orchestration and Management \(ATOM\)](Application_Task_Orchestration_and_Management.md)

[Parallel Application Launch Service \(PALS\)](Parallel_Application_Launch_Service_PALS.md)

[About UAN Configuration](About_UAN_Configuration.md)

[Content Projection Service \(CPS\)](Content_Projection_Service_CPS.md)

[Configure Overlay Preload](Configure_Overlay_Preload.md)

[About the System Admin Toolkit \(SAT\)](About_the_System_Admin_Toolkit.md)

