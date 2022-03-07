## Configuration Management

The Configuration Framework Service \(CFS\) is available on systems for remote execution and configuration management of nodes and boot images. This includes nodes available in the Hardware State Manager \(HSM\) inventory \(compute, management, and application nodes\), and boot images hosted by the Image Management Service \(IMS\).

CFS configures nodes and images via a gitops methodology. All configuration content is stored in a version control service \(VCS\), and is managed by authorized system administrators. CFS provides a scalable Ansible Execution Environment \(AEE\) for the configuration to be applied with flexible inventory and node targeting options.

### Use Cases

CFS is available for the following use cases on systems:

-   Image customization: Pre-configure bootable images available via IMS. This use case enables partitioning a full configuration of a target node. Non-node-specific settings are applied pre-boot, which reduces the amount of configuration required after a node boots, and therefore reduces the bring-up time for nodes.
-   Post-boot configuration: Fully configure or reconfigure booted nodes in a scalable, performant way to add the required settings.
-   "Push-based" deployment: When using post-boot configuration with only node-specific configuration data, the target undergoes node personalization. The two-step process of pre-boot image customization and post-boot node personalization results in a fully configured node, optimized for minimal bring-up times.
-   "Pull-based" deployment: Provide configuration management to nodes by prescribing a desired configuration state and ensuring the current node configuration state matches the desired state automatically. This is achieved via the CFS Hardware Synchronization Agent and the CFS Batcher implementation.

### CFS Components

CFS is comprised of a group of services and components interacting within the Cray System Management \(CSM\) service mesh, and provides a means for system administrators to configure nodes and boot images via Ansible. CFS includes the following components:

-   A REST API service.
-   A command-line interface \(CLI\) to the API \(via the cray cfs command\).
-   Pre-packaged AEE\(s\) with values tuned for performant configuration for executing Ansible playbooks, and reporting plug-ins for communication with CFS.
-   The CFS Hardware Sync Agent, which pulls in node information from the system inventory to the CFS database to track the node configuration state.
-   The CFS Batcher, which manages the configuration state of system components \(nodes\).

Although it is not a formal part of the service, CFS integrates with a Gitea instance \(VCS\) running in the CSM service mesh for management of the configuration content life-cycle.

### High-Level Configuration Workflow

CFS remotely executes Ansible configuration content on nodes or boot images with the following workflow:

1.  Creating a configuration with one or more layers within a specific Git repository, and committing it to be executed by Ansible.
2.  Targeting a node, boot image, or group of nodes to apply the configuration.
3.  Creating a configuration session to apply and track the status of Ansible, applying each configuration layer to the targets specified in the session metadata.

Additionally, configuration management of specific components \(nodes\) can also be achieved by doing the following:

1.  Creating a configuration with one or more layers within a specific Git repository, and committing it to be executed by Ansible.
2.  Setting the desired configuration state of a node to the prescribed layers.
3.  Enabling the CFS Batcher to automatically configure nodes by creating one or more configuration sessions to apply the configuration layer\(s\).

### Table of Contents

Use the following procedures to manage configurations with CFS.

-   [Configuration Layers](Configuration_Layers.md)
    -   [Create a CFS Configuration](Create_a_CFS_Configuration.md)
    -   [Update a CFS Configuration](Update_a_CFS_Configuration.md)
-   [Ansible Inventory](Ansible_Inventory.md)
    -   [Manage Multiple Inventories in a Single Location](Manage_Multiple_Inventories_in_a_Single_Location.md)
-   [Configuration Sessions](Configuration_Sessions.md)
    -   [Create a CFS Session with Dynamic Inventory](Create_a_CFS_Session_with_Dynamic_Inventory.md)
    -   [Create an Image Customization CFS Session](Create_an_Image_Customization_CFS_Session.md)
    -   [Set Limits for a Configuration Session](Set_Limits_for_a_Configuration_Session.md)
    -   [Use a Specific Inventory in a Configuration Session](Use_a_Specific_Inventory_in_a_Configuration_Session.md)
    -   [Change the Ansible Verbosity Logs](Change_the_Ansible_Verbosity_Logs.md)
    -   [Set the ansible.cfg for a Session](Set_the_ansible-cfg_for_a_Session.md)
    -   [Delete CFS Sessions](Delete_CFS_Sessions.md)
    -   [Automatic Session Deletion with sessionTTL](Automatic_Session_Deletion_with_sessionTTL.md)
    -   [Track the Status of a Session](Track_the_Status_of_a_Session.md)
    -   [View Configuration Session Logs](View_Configuration_Session_Logs.md)
    -   [Troubleshoot Ansible Play Failures in CFS Sessions](Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md)
    -   [Troubleshoot CFS Session Failing to Complete](Troubleshoot_CFS_Session_Failing_to_Complete.md)
-   [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md)
-   [Configuration Management of System Components](Configuration_Management_of_System_Components.md)
-   [Ansible Execution Environments](Ansible_Execution_Environments.md)
    -   [Use a Custom ansible-cfg File](Use_a_Custom_ansible-cfg_File.md)
    -   [Enable Ansible Profiling](Enable_Ansible_Profiling.md)
-   [CFS Global Options](CFS_Global_Options.md)
-   [Version Control Service \(VCS\)](Version_Control_Service_VCS.md)
    -   [Git Operations](Git_Operations.md)
    -   [VCS Branching Strategy](VCS_Branching_Strategy.md)
    -   [Customize Configuration Values](Customize_Configuration_Values.md)
    -   [Update the Privacy Settings for Gitea Configuration Content Repositories](Update_the_Privacy_Settings_for_Gitea_Configuration_Content_Repositories.md)
    -   [Create and Populate a VCS Configuration Repository](Create_and_Populate_a_VCS_Configuration_Repository.md)
-   [Write Ansible Code for CFS](Write_Ansible_Code_for_CFS.md)
    -   [Target Ansible Tasks for Image Customization](Target_Ansible_Tasks_for_Image_Customization.md)


