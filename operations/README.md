# Cray System Management (CSM) Administration Guide

The Cray System Management (CSM) operational activities are administrative procedures required to operate an HPE Cray EX system with CSM software installed.

The following administrative topics can be found in this guide:

- [CSM product management](#csm-product-management)
- [Bare-metal](#bare-metal)
- [Image management](#image-management)
- [Boot orchestration](#boot-orchestration)
- [System power off procedures](#system-power-off-procedures)
- [System power on procedures](#system-power-on-procedures)
- [Power management](#power-management)
- [Artifact management](#artifact-management)
- [Compute rolling upgrades](#compute-rolling-upgrades)
- [Configuration management](#configuration-management)
- [Kubernetes](#kubernetes)
- [Package repository management](#package-repository-management)
- [Security and authentication](#security-and-authentication)
- [Resiliency](#resiliency)
- [ConMan](#conman)
- [Utility storage](#utility-storage)
- [System management health](#system-management-health)
- [System Layout Service (SLS)](#system-layout-service-sls)
- [System configuration service](#system-configuration-service)
- [Hardware State Manager (HSM)](#hardware-state-manager-hsm)
- [Hardware Management (HM) collector](#hardware-management-hm-collector)
- [HPE Power Distribution Unit (PDU)](#hpe-power-distribution-unit-pdu)
- [Node management](#node-management)
- [Network](#network)
    - [Management network](#management-network)
    - [Customer accessible networks (CMN/CAN/CHN)](#customer-accessible-networks-cmncanchn)
    - [Dynamic Host Configuration Protocol (DHCP)](#dynamic-host-configuration-protocol-dhcp)
    - [Domain Name Service (DNS)](#domain-name-service-dns)
    - [External DNS](#external-dns)
    - [MetalLB in BGP-mode](#metallb-in-bgp-mode)
- [Spire](#spire)
- [Update firmware with FAS](#update-firmware-with-fas)
- [System Admin Toolkit (SAT)](#system-admin-toolkit-sat)
- [Install and Upgrade Framework (IUF)](#install-and-upgrade-framework-iuf)
- [Backup and recovery](#backup-and-recovery)
- [Multi-tenancy](#multi-tenancy)

## CSM product management

Important procedures for configuring, managing, and validating the CSM environment.

- [Validate CSM Health](validate_csm_health.md)
- [Configure Keycloak Account](CSM_product_management/Configure_Keycloak_Account.md)
- [Configure the Cray Command Line Interface (Cray CLI)](configure_cray_cli.md)
- [Change Passwords and Credentials](CSM_product_management/Change_Passwords_and_Credentials.md)
      - [Configure the `root` password and SSH keys in Vault](CSM_product_management/Configure_the_root_Password_and_SSH_Keys_in_Vault.md)
      - [Set up passwordless SSH](CSM_product_management/Set_Up_Passwordless_SSH.md)
- [Configure CSM Packages with CFS](CSM_product_management/Configure_CSM_Packages_with_CFS.md)
- [Access the LiveCD USB Device After Reboot](../install/livecd/Access_LiveCD_USB_Device_After_Reboot.md)
- [Post-Install Customizations](CSM_product_management/Post_Install_Customizations.md)
- [Validate Signed RPMs](CSM_product_management/Validate_Signed_RPMs.md)
- [Remove Artifacts from Product Installation](CSM_product_management/Remove_Artifacts_from_Product_Installations.md)

## Bare-metal

General information on what needs to be done before the initial install of CSM.

- [Bare-Metal Steps](bare_metal/Bare-Metal.md)
- [Change Air-Cooled BMC Credentials](bare_metal/Change_River_BMC_Credentials.md)
- [Change Credentials on ServerTech PDUs](security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md)

## Image management

Build and customize image recipes with the Image Management Service (IMS).

- [Image Management](image_management/Image_Management.md)
- [Image Management Workflows](image_management/Image_Management_Workflows.md)
- [Upload and Register an Image Recipe](image_management/Upload_and_Register_an_Image_Recipe.md)
- [Build a New UAN Image Using the Default Recipe](image_management/Build_a_New_UAN_Image_Using_the_Default_Recipe.md)
- [Build an Image Using IMS REST Service](image_management/Build_an_Image_Using_IMS_REST_Service.md)
- [Import External Image to IMS](image_management/Import_External_Image_to_IMS.md)
- [Import NCN Image to IMS](image_management/Import_NCN_Image_to_IMS.md)
- [Customize an Image Root Using IMS](image_management/Customize_an_Image_Root_Using_IMS.md)
      - [Create UAN Boot Images](image_management/Create_UAN_Boot_Images.md)
      - [Convert TGZ Archives to SquashFS Images](image_management/Convert_TGZ_Archives_to_SquashFS_Images.md)
- [Configure a Remote Build Node](image_management/Configure_a_Remote_Build_Node.md)
- [Delete or Recover Deleted IMS Content](image_management/Delete_or_Recover_Deleted_IMS_Content.md)
- [Configure IMS to Use DKMS](image_management/Configure_IMS_to_Use_DKMS.md)
- [Configure IMS to Validate RPMs](image_management/Configure_IMS_to_validate_rpms.md)
- [Exporting and Importing IMS Data](image_management/Exporting_and_Importing_IMS_Data.md)
- [Working With `aarch64` Images](image_management/Working_With_aarch64_Images.md)
- [Troubleshoot Large Image](image_management/Troubleshoot_Large_Image.md)
- [Troubleshoot Remote Build Node](image_management/Troubleshoot_Remote_Build_Node.md)
- [Troubleshoot zypper interaction](image_management/Troubleshoot_zypper_interaction.md)
- [IMS API](../api/ims.md)

## Boot orchestration

Use the Boot Orchestration Service \(BOS\) to boot, reboot, and shut down collections of nodes.

- [BOS data notice](../upgrade/README.md#bos-data-notice)
- [Boot Orchestration Service (BOS)](boot_orchestration/Boot_Orchestration.md)
      - [BOS Cheat Sheet](boot_orchestration/Cheatsheet.md)
      - [BOS Services](boot_orchestration/BOS_Services.md)
      - [BOS API Versions](boot_orchestration/BOS_API_Versions.md)
      - [BOS Multi-tenancy](boot_orchestration/Multi_tenancy_with_BOS.md)
- [BOS Workflows](boot_orchestration/BOS_Workflows.md)
- [BOS Components](boot_orchestration/Components.md)
      - [Component Status](boot_orchestration/Component_Status.md)
- [BOS Session Templates](boot_orchestration/Session_Templates.md)
      - [Manage a Session Template](boot_orchestration/Manage_a_Session_Template.md)
      - [Create a Session Template to Boot Compute Nodes with CPS](boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_CPS.md)
      - [Create a Session Template to Boot Compute Nodes with SBPS](boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md)
      - [Boot UANs](boot_orchestration/Boot_UANs.md)
- [BOS Sessions](boot_orchestration/Sessions.md)
      - [Manage a BOS Session](boot_orchestration/Manage_a_BOS_Session.md)
      - [View the Status of a BOS Session](boot_orchestration/View_the_Status_of_a_BOS_Session.md)
      - [Limit the Scope of a BOS Session](boot_orchestration/Limit_the_Scope_of_a_BOS_Session.md)
      - [Stage Changes with BOS](boot_orchestration/Stage_Changes_with_BOS.md)
      - [Kernel Boot Parameters](boot_orchestration/Kernel_Boot_Parameters.md)
      - [Troubleshoot UAN Boot Issues](boot_orchestration/Troubleshoot_UAN_Boot_Issues.md)
      - [Determine Which BOS Session Booted A Node](boot_orchestration/Determine_Which_BOS_Session_Booted_A_Node.md)
- [BOS Options](boot_orchestration/Options.md)
- [Exporting and Importing BOS Data](boot_orchestration/Exporting_and_Importing_BOS_Data.md)
- [Exporting and Importing BSS Data](boot_orchestration/Exporting_and_Importing_BSS_Data.md)
- [Rolling Upgrades using BOS](boot_orchestration/Rolling_Upgrades.md)
- [BOS API](../api/bos.md)
- [Boot Script Service (BSS) API](../api/bss.md)
- [Compute Node Boot Sequence](boot_orchestration/Compute_Node_Boot_Sequence.md)
    - [Healthy Compute Node Boot Process](boot_orchestration/Healthy_Compute_Node_Boot_Process.md)
    - [Node Boot Root Cause Analysis](boot_orchestration/Node_Boot_Root_Cause_Analysis.md)
        - [Compute Node Boot Issue Symptom: Duplicate Address Warnings and Declined DHCP Offers in Logs](boot_orchestration/Compute_Node_Boot_Issue_Symptom_Duplicate_Address_Warnings_and_Declined_DHCP_Offers_in_Logs.md)
        - [Compute Node Boot Issue Symptom: Node is Not Able to Download the Required Artifacts](boot_orchestration/Compute_Node_Boot_Issue_Symptom_Node_is_Not_Able_to_Download_the_Required_Artifacts.md)
        - [Compute Node Boot Issue Symptom: Message About Invalid EEPROM Checksum in Node Console or Log](boot_orchestration/Compute_Node_Boot_Issue_Symptom_Message_About_Invalid_EEPROM_Checksum_in_Node_Console_or_Log.md)
        - [Boot Issue Symptom: Node HSN Interface Does Not Appear or Show Detected Links Detected](boot_orchestration/Boot_Issue_Symptom_Node_HSN_Interface_Does_Not_Appear_or_Shows_No_Link_Detected.md)
        - [Compute Node Boot Issue Symptom: Node Console or Logs Indicate that the Server Response has Timed Out](boot_orchestration/Boot_Issue_Symptom_Node_Console_or_Logs_Indicate_that_the_Server_Response_has_Timed_Out.md)
        - [Tools for Resolving Compute Node Boot Issues](boot_orchestration/Tools_for_Resolving_Boot_Issues.md)
        - [Troubleshoot Compute Node Boot Issues Related to Unified Extensible Firmware Interface (UEFI)](boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Unified_Extensible_Firmware_Interface_UEFI.md)
        - [Troubleshoot Compute Node Boot Issues Related to Dynamic Host Configuration Protocol (DHCP)](boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Dynamic_Host_Configuration_Protocol_DHCP.md)
        - [Troubleshoot Compute Node Boot Issues Related to the Boot Script Service](boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_the_Boot_Script_Service_BSS.md)
        - [Troubleshoot Compute Node Boot Issues Related to Trivial File Transfer Protocol (TFTP)](boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Related_to_Trivial_File_Transfer_Protocol_TFTP.md)
        - [Troubleshoot Compute Node Boot Issues Using Kubernetes](boot_orchestration/Troubleshoot_Compute_Node_Boot_Issues_Using_Kubernetes.md)
        - [Log File Locations and Ports Used in Compute Node Boot Troubleshooting](boot_orchestration/Log_File_Locations_and_Ports_Used_in_Compute_Node_Boot_Troubleshooting.md)
    - [Customize iPXE Binary Names](boot_orchestration/Customize_iPXE_Binary_Names.md)
    - [Edit the iPXE Embedded Boot Script](boot_orchestration/Edit_the_iPXE_Embedded_Boot_Script.md)
    - [Redeploy the iPXE and TFTP Services](boot_orchestration/Redeploy_the_IPXE_and_TFTP_Services.md)
    - [Upload Node Boot Information to Boot Script Service (BSS)](boot_orchestration/Upload_Node_Boot_Information_to_Boot_Script_Service_BSS.md)

## System power off procedures

Procedures required for a full power off of an HPE Cray EX system.

- [System Power Off Procedures](power_management/System_Power_Off_Procedures.md)

Additional links to power off sub-procedures provided for reference. Refer to the main procedure linked above before using any of these sub-procedures:

- [Prepare the System for Power Off](power_management/Prepare_the_System_for_Power_Off.md)
- [Shut Down and Power Off Managed Nodes](power_management/Shut_Down_and_Power_Off_Managed_Nodes.md)
- [Save Management Network Switch Configuration Settings](power_management/Save_Management_Network_Switch_Configurations.md)
- [Power Off Compute Cabinets](power_management/Power_Off_Compute_Cabinets.md) using PCS
- [Shut Down and Power Off the Management Kubernetes Cluster](power_management/Shut_Down_and_Power_Off_the_Management_Kubernetes_Cluster.md)
- [Power Off the External Lustre File System](power_management/Power_Off_the_External_Lustre_File_System.md)

## System power on procedures

Procedures required for a full power on of an HPE Cray EX system.

- [System Power On Procedures](power_management/System_Power_On_Procedures.md)

Additional links to power on sub-procedures provided for reference. Refer to the main procedure linked above before using any of these sub-procedures:

- [Power On and Start the Management Kubernetes Cluster](power_management/Power_On_and_Start_the_Management_Kubernetes_Cluster.md)
- [Power On Compute Cabinets](power_management/Power_On_Compute_Cabinets.md) using PCS
- [Power On the External Lustre File System](power_management/Power_On_the_External_Lustre_File_System.md)
- [Power On and Boot Managed Nodes](power_management/Power_On_and_Boot_Managed_Nodes.md)
- [Recover from a Liquid Cooled Cabinet EPO Event](power_management/Power_Control_Service/Recover_from_a_Liquid_Cooled_Cabinet_EPO_Event.md) using PCS

## Power management

HPE Cray System Management (CSM) software manages and controls power out-of-band through Redfish APIs.

- [Power Management](power_management/power_management.md)
- [Cray Advanced Platform Monitoring and Control (CAPMC)](power_management/Cray_Advanced_Platform_Monitoring_and_Control_CAPMC.md)
- [Power Control Service (PCS)](power_management/Power_Control_Service/Power_Control_Service_PCS.md)
- [Liquid Cooled Node Power Management](power_management/Liquid_Cooled_Node_Card_Power_Management.md)
    - [User Access to Compute Node Power Data](power_management/User_Access_to_Compute_Node_Power_Data.md)
- [Standard Rack Node Power Management](power_management/Standard_Rack_Node_Power_Management.md)
- [Node Card Power Management](power_management/Power_Control_Service/Node_Card_Power_Management.md)
- [Ignore Nodes with CAPMC](power_management/Ignore_Nodes_with_CAPMC.md)
- [Set the Turbo Boost Limit](power_management/Set_the_Turbo_Boost_Limit.md)
- [CAPMC API](../api/capmc.md)
- [PCS API](../api/power-control.md)

## Artifact management

Use the Ceph Object Gateway Simple Storage Service \(S3\) API to manage artifacts on the system.

- [Artifact Management](artifact_management/Artifact_Management.md)
- [Manage Artifacts with the Cray CLI](artifact_management/Manage_Artifacts_with_the_Cray_CLI.md)
- [Use S3 Libraries and Clients](artifact_management/Use_S3_Libraries_and_Clients.md)
- [Generate Temporary S3 Credentials](artifact_management/Generate_Temporary_S3_Credentials.md)

## Compute rolling upgrades

**NOTE** CRUS was deprecated in CSM 1.2.0 and removed in CSM 1.5.0. See the following links for more information:

- [Rolling Upgrades using BOS](boot_orchestration/Rolling_Upgrades.md)
- [Deprecated Features](../introduction/deprecated_features/README.md)

## Configuration management

The Configuration Framework Service \(CFS\) is available on systems for remote execution and configuration management of nodes and boot images.

- [Configuration Management](configuration_management/Configuration_Management.md)
    - [CFS Commands Cheat Sheet](configuration_management/CFS_Commands_Cheat_Sheet.md)
    - [CFS Flow Diagrams](configuration_management/CFS_Flow_Diagrams.md)
    - [CFS Global Options](configuration_management/CFS_Global_Options.md)
    - [Differences Between the V2 and V3 CFS APIs](configuration_management/Differences_Between_the_V2_and_V3_CFS_APIs.md)
    - [Paging CFS Records](configuration_management/Paging_CFS_Records.md)
    - [Automatic Configuration Management](configuration_management/Automatic_Configuration_Management.md)
    - [CFS Key Management](configuration_management/CFS_Key_Management.md)
- [CFS Configurations](configuration_management/CFS_Configurations.md)
- [CFS Sources](configuration_management/CFS_Sources.md)
- [CFS Components](configuration_management/CFS_Components.md)
- [CFS Sessions](configuration_management/CFS_Sessions.md)
    - [Create a Node Personalization CFS Session](configuration_management/Create_a_Node_Personalization_CFS_Session.md)
    - [Create an Image Customization CFS Session](configuration_management/Create_an_Image_Customization_CFS_Session.md)
    - [Set Limits for a Configuration Session](configuration_management/Set_Limits_for_a_Configuration_Session.md)
    - [Track the Status of a Session](configuration_management/Track_the_Status_of_a_Session.md)
    - [View Configuration Session Logs](configuration_management/View_Configuration_Session_Logs.md)
    - [Automatic Session Deletion with `session_ttl`](configuration_management/Automatic_Session_Deletion_with_session_ttl.md)
    - [CFS Session Inventory](configuration_management/CFS_Session_Inventory.md)
        - [Adding Additional Inventory](configuration_management/Adding_Additional_Inventory.md)
        - [Specifying Hosts and Groups](configuration_management/Specifying_Hosts_and_Groups.md)
    - [Ansible Execution Environments](configuration_management/Ansible_Execution_Environments.md)
        - [Ansible Log Collection](configuration_management/Ansible_Log_Collection.md)
        - [Configure Ansible](configuration_management/Configure_Ansible.md)
        - [Change the Ansible Verbosity](configuration_management/Change_the_Ansible_Verbosity.md)
        - [Enable Ansible Profiling](configuration_management/Enable_Ansible_Profiling.md)
- [Write Ansible Code for CFS](configuration_management/Write_Ansible_Code_for_CFS.md)
    - [Target Ansible Tasks for Image Customization](configuration_management/Target_Ansible_Tasks_for_Image_Customization.md)
- Specific Use Cases
    - [Accessing `sat bootprep` Files](configuration_management/Accessing_Sat_Bootprep_Files.md)
    - [Management Node Personalization](configuration_management/Management_Node_Personalization.md)
    - [Management Node Image Customization](configuration_management/Management_Node_Image_Customization.md)
- [Troubleshoot CFS Issues](configuration_management/Troubleshoot_CFS_Issues.md)
    - [Troubleshoot CFS Session Failed](configuration_management/Troubleshoot_CFS_Session_Failed.md)
    - [Troubleshoot CFS Session Failing to Complete](configuration_management/Troubleshoot_CFS_Session_Failing_to_Complete.md)
    - [Troubleshoot CFS Sessions Failing to Start](configuration_management/Troubleshoot_CFS_Sessions_Failing_to_Start.md)
- [Exporting and Importing CFS Data](configuration_management/Exporting_and_Importing_CFS_Data.md)
- [CFS API Details](../api/cfs.md)
- [Version Control Service \(VCS\)](configuration_management/Version_Control_Service_VCS.md)
    - [Git Operations](configuration_management/Git_Operations.md)
    - [VCS Branching Strategy](configuration_management/VCS_Branching_Strategy.md)
    - [Customize Configuration Values](configuration_management/Customize_Configuration_Values.md)
    - [Update the Privacy Settings for Gitea Configuration Content Repositories](configuration_management/Update_the_Privacy_Settings_for_Gitea_Configuration_Content_Repositories.md)
    - [Create and Populate a VCS Configuration Repository](configuration_management/Create_and_Populate_a_VCS_Configuration_Repository.md)

## Kubernetes

The system management components are broken down into a series of micro-services. Each service is independently deployable, fine-grained, and uses lightweight protocols.
As a result, the system's micro-services are modular, resilient, and can be updated independently. Services within the Kubernetes architecture communicate using REST APIs.

- [Kubernetes Architecture](kubernetes/Kubernetes.md)
- [About `kubectl`](kubernetes/About_kubectl.md)
    - [Configure `kubectl` Credentials to Access the Kubernetes APIs](kubernetes/Configure_kubectl_Credentials_to_Access_the_Kubernetes_APIs.md)
- [About Kubernetes Taints and Labels](kubernetes/About_Kubernetes_Taints_and_Labels.md)
- [Kubernetes Storage](kubernetes/Kubernetes_Storage.md)
- [Kubernetes Networking](kubernetes/Kubernetes_Networking.md)
- [Retrieve Cluster Health Information Using Kubernetes](kubernetes/Retrieve_Cluster_Health_Information_Using_Kubernetes.md)
- [Pod Resource Limits](kubernetes/Pod_Resource_Limits.md)
    - [Determine if Pods are Hitting Resource Limits](kubernetes/Determine_if_Pods_are_Hitting_Resource_Limits.md)
    - [Increase Pod Resource Limits](kubernetes/Increase_Pod_Resource_Limits.md)
    - [Increase Kafka Pod Resource Limits](kubernetes/Increase_Kafka_Pod_Resource_Limits.md)
- [About etcd](kubernetes/About_etcd.md)
    - [Check the Health of etcd Clusters](kubernetes/Check_the_Health_of_etcd_Clusters.md)
    - [Rebuild Unhealthy etcd Clusters](kubernetes/Rebuild_Unhealthy_etcd_Clusters.md)
    - [Backups for Etcd Clusters Running in Kubernetes](kubernetes/Backups_for_Etcd_Clusters_Running_in_Kubernetes.md)
    - [Create a Manual Backup of a Healthy Bare-Metal etcd Cluster](kubernetes/Create_a_Manual_Backup_of_a_Healthy_Bare-Metal_etcd_Cluster.md)
    - [Create a Manual Backup of a Healthy etcd Cluster](kubernetes/Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md)
    - [Restore an etcd Cluster from a Backup](kubernetes/Restore_an_etcd_Cluster_from_a_Backup.md)
    - [Repopulate Data in etcd Clusters When Rebuilding Them](kubernetes/Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md)
    - [Restore Bare-Metal etcd Clusters from an S3 Snapshot](kubernetes/Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md)
    - [Check for and Clear etcd Cluster Alarms](kubernetes/Check_for_and_Clear_etcd_Cluster_Alarms.md)
    - [Report the Endpoint Status for etcd Clusters](kubernetes/Report_the_Endpoint_Status_for_etcd_Clusters.md)
    - [Clear Space in an etcd Cluster Database](kubernetes/Clear_Space_in_an_etcd_Cluster_Database.md)
- [About Postgres](kubernetes/About_Postgres.md)
    - [Troubleshoot Postgres Database](kubernetes/Troubleshoot_Postgres_Database.md)
    - [Recover from Postgres WAL Event](kubernetes/Recover_from_Postgres_WAL_Event.md)
    - [Restore Postgres](kubernetes/Restore_Postgres.md)
    - [Disaster Recovery for Postgres](kubernetes/Disaster_Recovery_Postgres.md)
    - [View Postgres Information for System Databases](kubernetes/View_Postgres_Information_for_System_Databases.md)
- [`containerd`](kubernetes/Containerd.md)
- [Kubernetes Encryption](kubernetes/encryption/README.md)
- [Kyverno policy management](kubernetes/Kyverno.md)
- [Troubleshoot Kyverno configuration manually](security_and_authentication/Troubleshoot_Kyverno_Configuration_manually.md)
- [Troubleshoot Intermittent HTTP 503 Code Failures](kubernetes/Troubleshoot_Intermittent_503s.md)
- [TDS Lower CPU Requests](kubernetes/TDS_Lower_CPU_Requests.md)
- [Fix `Failed to start etcd` on Master NCN](kubernetes/Fix_Failed_to_start_etcd_on_Master.md)
- [Kubernetes and Bare Metal EtcD Certificate Renewal](kubernetes/Cert_Renewal_for_Kubernetes_and_Bare_Metal_EtcD.md)

## Package repository management

Repositories are added to systems to extend the system functionality beyond what is initially delivered. The Sonatype Nexus Repository Manager is the primary method for
repository management. Nexus hosts the Yum, Docker, raw, and Helm repositories for software and firmware content.

- [Package Repository Management](package_repository_management/Package_Repository_Management.md)
- [Package Repository Management with Nexus](package_repository_management/Package_Repository_Management_with_Nexus.md)
- [Manage Repositories with Nexus](package_repository_management/Manage_Repositories_with_Nexus.md)
- [Nexus Configuration](package_repository_management/Nexus_Configuration.md)
- [Nexus Deployment](package_repository_management/Nexus_Deployment.md)
- [Nexus Export and Restore](package_repository_management/Nexus_Export_and_Restore.md)
- [Restrict Admin Privileges in Nexus](package_repository_management/Restrict_Admin_Privileges_in_Nexus.md)
- [Repair Yum Repository Metadata](package_repository_management/Repair_Yum_Repository_Metadata.md)
- [Nexus Space Cleanup](package_repository_management/Nexus_Space_Cleanup.md)
- [Troubleshoot Nexus](package_repository_management/Troubleshoot_Nexus.md)

## Security and authentication

Mechanisms used by the system to ensure the security and authentication of internal and external requests.

- [System Security and Authentication](security_and_authentication/System_Security_and_Authentication.md)
- [Manage System Passwords](security_and_authentication/Manage_System_Passwords.md)
    - [Update NCN Passwords](security_and_authentication/Update_NCN_Passwords.md)
    - [Change Root Passwords for Compute Nodes](security_and_authentication/Change_Root_Passwords_for_Compute_Nodes.md)
    - Set NCN Image Root Password, SSH Keys, and Timezone
        - [Set NCN Image Root Password, SSH Keys, and Timezone on PIT Node](security_and_authentication/Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md)
        - [Set NCN Image Root Password, SSH Keys, and Timezone](security_and_authentication/Change_NCN_Image_Root_Password_and_SSH_Keys.md)
    - [Change EX Liquid-Cooled Cabinet Global Default Password](security_and_authentication/Change_EX_Liquid-Cooled_Cabinet_Global_Default_Password.md)
    - [Provisioning a Liquid-Cooled EX Cabinet CEC with Default Credentials](security_and_authentication/Provisioning_a_Liquid-Cooled_EX_Cabinet_CEC_with_Default_Credentials.md)
    - [Updating the Liquid-Cooled EX Cabinet Default Credentials after a CEC Password Change](security_and_authentication/Updating_the_Liquid-Cooled_EX_Cabinet_Default_Credentials_after_a_CEC_Password_Change.md)
    - [Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials](security_and_authentication/Update_Default_Air-Cooled_BMC_and_Leaf_BMC_Switch_SNMP_Credentials.md)
    - [Change Air-Cooled Node BMC Credentials](security_and_authentication/Change_Air-Cooled_Node_BMC_Credentials.md)
    - [Update Default ServerTech PDU Credentials used by the Redfish Translation Service](security_and_authentication/Update_Default_ServerTech_PDU_Credentials_used_by_the_Redfish_Translation_Service.md)
    - [Change Credentials on ServerTech PDUs](security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md)
    - [Add Root Service Account for Gigabyte Controllers](security_and_authentication/Add_Root_Service_Account_for_Gigabyte_Controllers.md)
    - [Recovering from Mismatched BMC Credentials](security_and_authentication/Recovering_from_Mismatched_BMC_Credentials.md)
- [SSH Keys](security_and_authentication/SSH_Keys.md)
- [Authenticate an Account with the Command Line](security_and_authentication/Authenticate_an_Account_with_the_Command_Line.md)
- [Default Keycloak Realms, Accounts, and Clients](security_and_authentication/Default_Keycloak_Realms_Accounts_and_Clients.md)
    - [Certificate Types](security_and_authentication/Certificate_Types.md)
    - [Change Keycloak Token Lifetime](security_and_authentication/Change_Keycloak_Token_Lifetime.md)
    - [Change the Keycloak Admin Password](security_and_authentication/Change_the_Keycloak_Admin_Password.md)
    - [Create a Service Account in Keycloak](security_and_authentication/Create_a_Service_Account_in_Keycloak.md)
    - [Retrieve the Client Secret for Service Accounts](security_and_authentication/Retrieve_the_Client_Secret_for_Service_Accounts.md)
    - [Get a Long-Lived Token for a Service Account](security_and_authentication/Get_a_Long-lived_Token_for_a_Service_Account.md)
    - [Access the Keycloak User Management UI](security_and_authentication/Access_the_Keycloak_User_Management_UI.md)
    - [Create Internal User Accounts in the Keycloak Shasta Realm](security_and_authentication/Create_Internal_User_Accounts_in_the_Keycloak_Shasta_Realm.md)
    - [Delete Internal User Accounts in the Keycloak Shasta Realm](security_and_authentication/Delete_Internal_User_Accounts_from_the_Keycloak_Shasta_Realm.md)
    - [Create Internal Groups in the Keycloak Shasta Realm](security_and_authentication/Create_Internal_Groups_in_the_Keycloak_Shasta_Realm.md)
    - [Remove Internal Groups from the Keycloak Shasta Realm](security_and_authentication/Remove_Internal_Groups_from_the_Keycloak_Shasta_Realm.md)
    - [Remove the Email Mapper from the LDAP User Federation](security_and_authentication/Remove_the_Email_Mapper_from_the_LDAP_User_Federation.md)
    - [Re-Sync Keycloak Users to Compute Nodes](security_and_authentication/Resync_Keycloak_Users_to_Compute_Nodes.md)
    - [Keycloak Operations](security_and_authentication/Keycloak_Operations.md)
    - [Configure Keycloak for LDAP/AD authentication](security_and_authentication/Configure_Keycloak_for_LDAPAD_Authentication.md)
    - [Configure the RSA Plugin in Keycloak](security_and_authentication/Configure_the_RSA_Plugin_in_Keycloak.md)
    - [Preserve Username Capitalization for Users Exported from Keycloak](security_and_authentication/Preserve_Username_Capitalization_for_Users_Exported_from_Keycloak.md)
    - [Change the LDAP Server IP Address for Existing LDAP Server Content](security_and_authentication/Change_the_LDAP_Server_IP_Address_for_Existing_LDAP_Server_Content.md)
    - [Change the LDAP Server IP Address for New LDAP Server Content](security_and_authentication/Change_the_LDAP_Server_IP_Address_for_New_LDAP_Server_Content.md)
    - [Remove the LDAP User Federation from Keycloak](security_and_authentication/Remove_the_LDAP_User_Federation_from_Keycloak.md)
    - [Add LDAP User Federation](security_and_authentication/Add_LDAP_User_Federation.md)
    - [Keycloak User Management with `kcadm.sh`](security_and_authentication/Keycloak_User_Management_with_Kcadm.md)
    - [Keycloak User Localization](security_and_authentication/Keycloak_User_Localization.md)
    - [Create a Backup of the Keycloak Postgres Database](security_and_authentication/Create_a_Backup_of_the_Keycloak_Postgres_Database.md)
- [Public Key Infrastructure \(PKI\)](security_and_authentication/Public_Key_Infrastructure_PKI.md)
    - [PKI Certificate Authority \(CA\)](security_and_authentication/PKI_Certificate_Authority_CA.md)
    - [Make HTTPS Requests from Sources Outside the Management Kubernetes Cluster](security_and_authentication/Make_HTTPS_Requests_from_Sources_Outside_the_Management_Kubernetes_Cluster.md)
    - [Transport Layer Security \(TLS\) for Ingress Services](security_and_authentication/Transport_Layer_Security_for_Ingress_Services.md)
    - [PKI Services](security_and_authentication/PKI_Services.md)
    - [HashiCorp Vault](security_and_authentication/HashiCorp_Vault.md)
    - [Backup and Restore Vault Clusters](security_and_authentication/Backup_and_Restore_Vault_Clusters.md)
    - [Troubleshoot Common Vault Cluster Issues](security_and_authentication/Troubleshoot_Common_Vault_Cluster_Issues.md)
- [API Authorization](security_and_authentication/API_Authorization.md)
- [Retrieve an Authentication Token](security_and_authentication/Retrieve_an_Authentication_Token.md)
- [Manage Sealed Secrets](security_and_authentication/Manage_Sealed_Secrets.md)
- [Audit Logs](security_and_authentication/Audit_Logs.md)
- [Cray STS Token Generator API](../api/sts.md)
- [Configure root user on HPE iLO BMCs](security_and_authentication/Configure_root_user_on_HPE_iLO_BMCs.md)

## Resiliency

HPE Cray EX systems are designed so that system management services \(SMS\) are fully resilient and that there is no single point of failure.

- [Resiliency](resiliency/Resiliency.md)
- [Resilience of System Management Services](resiliency/Resilience_of_System_Management_Services.md)
- [Restore System Functionality if a Kubernetes Worker Node is Down](resiliency/Restore_System_Functionality_if_a_Kubernetes_Worker_Node_is_Down.md)
- [Recreate `StatefulSet` Pods on Another Node](resiliency/Recreate_StatefulSet_Pods_on_Another_Node.md)
- [Resiliency Testing Procedure](resiliency/Resiliency_Testing_Procedure.md)

## ConMan

ConMan is a tool used for connecting to remote consoles and collecting console logs. These node logs can then be used for various administrative purposes, such as
troubleshooting node boot issues.

- [ConMan](conman/ConMan.md)
- [Access Compute Node Logs](conman/Access_Compute_Node_Logs.md)
- [Access Console Log Data Via the System Monitoring Framework (SMF)](conman/Access_Console_Log_Data_Via_the_System_Monitoring_Framework_SMF.md)
- [Manage Node Consoles](conman/Manage_Node_Consoles.md)
- [Log in to a Node Using ConMan](conman/Log_in_to_a_Node_Using_ConMan.md)
- [Establish a Serial Connection to NCNs](conman/Establish_a_Serial_Connection_to_NCNs.md)
- [Disable ConMan After System Software Installation](conman/Disable_ConMan_After_System_Software_Installation.md)
- [Console Services Troubleshooting Guide](conman/Console_Services_Troubleshooting_Guide.md)
- [Troubleshoot ConMan Blocking Access to a Node BMC](conman/Troubleshoot_ConMan_Blocking_Access_to_a_Node_BMC.md)
- [Troubleshoot ConMan Failing to Connect to a Console](conman/Troubleshoot_ConMan_Failing_to_Connect_to_a_Console.md)
- [Troubleshoot ConMan Asking for Password on SSH Connection](conman/Troubleshoot_ConMan_Asking_for_Password_on_SSH_Connection.md)
- [Troubleshoot Console Node Pod Stuck in Terminating State](conman/Troubleshoot_ConMan_Node_Pod_Stuck_Terminating.md)
- [Complete Reset of the Console Services](conman/Complete_Reset_of_the_Console_Services.md)

## Utility storage

Ceph is the utility storage platform that is used to enable pods to store persistent data. It is deployed to provide block, object, and file storage to the management
services running on Kubernetes, as well as for telemetry data coming from the compute nodes.

- [Utility Storage](utility_storage/Utility_Storage.md)
- [Collect Information about the Ceph Cluster](utility_storage/Collect_Information_About_the_Ceph_Cluster.md)
- [Manage Ceph Services](utility_storage/Manage_Ceph_Services.md)
- [Adjust Ceph Pool Quotas](utility_storage/Adjust_Ceph_Pool_Quotas.md)
- [Add Ceph OSDs](utility_storage/Add_Ceph_OSDs.md)
- [Shrink Ceph OSDs](utility_storage/Shrink_Ceph_OSDs.md)
- [Ceph Health States](utility_storage/Ceph_Health_States.md)
- [Ceph Deep Scrubs](utility_storage/Ceph_Deep_Scrubs.md)
- [Ceph Daemon Memory Profiling](utility_storage/Ceph_Daemon_Memory_Profiling.md)
- [Ceph Service Check Script Usage](utility_storage/Ceph_Service_Check_Script_Usage.md)
- [Ceph Orchestrator Usage](utility_storage/Ceph_Orchestrator_Usage.md)
- [Ceph Storage Types](utility_storage/Ceph_Storage_Types.md)
- [`ceph-upgrade-tool` Usage](utility_storage/Ceph_upgrade_tool_Usage.md)
- [Dump Ceph Crash Data](utility_storage/Dump_Ceph_Crash_Data.md)
- [Identify Ceph Latency Issues](utility_storage/Identify_Ceph_Latency_Issues.md)
- [Cephadm Reference Material](utility_storage/Cephadm_Reference_Material.md)
- [Adding a Ceph Node to the Ceph Cluster](utility_storage/Add_Ceph_Node.md)
- [Shrink the Ceph Cluster](utility_storage/Remove_Ceph_Node.md)
- [Alternate Storage Pools](utility_storage/Alternate_Storage_Pools.md)
- [Restore Nexus Data After Data Corruption](utility_storage/Restore_Corrupt_Nexus.md)
- [Troubleshoot Failure to Get Ceph Health](utility_storage/Troubleshoot_Failure_to_Get_Ceph_Health.md)
- [Troubleshoot a Down OSD](utility_storage/Troubleshoot_a_Down_OSD.md)
- [Troubleshoot Ceph OSDs Not Being Created on Disks](utility_storage/Troubleshoot_Ceph_OSDs_Not_Created.md)
- [Troubleshoot Ceph OSDs Reporting Full](utility_storage/Troubleshoot_Ceph_OSDs_Reporting_Full.md)
- [Troubleshoot System Clock Skew](utility_storage/Troubleshoot_System_Clock_Skew.md)
- [Troubleshoot an Unresponsive S3 Endpoint](utility_storage/Troubleshoot_an_Unresponsive_S3_Endpoint.md)
- [Troubleshoot Ceph-Mon Processes Stopping and Exceeding Max Restarts](utility_storage/Troubleshoot_Ceph-Mon_Processes_Stopping_and_Exceeding_Max_Restarts.md)
- [Troubleshoot Pods Multi-Attach Error](utility_storage/Troubleshoot_Pods_Multi-Attach_Error.md)
- [Troubleshoot Large Object Map Objects in Ceph Health](utility_storage/Troubleshoot_Large_Object_Map_Objects_in_Ceph_Health.md)
- [Troubleshoot Failure of RGW Health Check](utility_storage/Troubleshoot_RGW_Health_Check_Fail.md)
- [Troubleshoot Ceph MDS Client Connectivity Issues](utility_storage/Troubleshoot_Ceph_FS_Client_Connectivity_issues.md)
- [Troubleshooting Ceph MDS Reporting Slow Requests and Failure on Client](utility_storage/Troubleshoot_Ceph_MDS_reporting_slow_requests_and_failure_on_client.md)
- [Troubleshoot Ceph image with tag:`<none>`](utility_storage/Troubleshoot_ceph_image_with_none_tag.md)
- [Troubleshoot Ceph Services Not Starting After a Server Crash](utility_storage/Troubleshoot_Ceph_Services_Not_Starting.md)
- [Troubleshoot `HEALTH_ERR` Module `devicehealth` has failed table Device already exists](utility_storage/Troubleshoot_HEALTH_ERR_Module_devicehealth.md)
- [Troubleshoot Insufficient Standby MDS Daemons Available](utility_storage/Troubleshoot_Insufficient_Standby_MDS_Daemons_Available.md)
- [Troubleshoot S3FS Mount Issues](utility_storage/Troubleshoot_S3FS_Mounts.md)
- [Fixing incorrect number of PG Issues](utility_storage/Troubleshoot_Pools_Have_Many_More_Objects_Per_Pg_Than_Average.md)

## System management health

Enable system administrators to assess the health of their system. Operators need to quickly and efficiently troubleshoot system issues as they occur and be
confident that a lack of issues indicates the system is operating normally.

- [System Management Health](system_management_health/System_Management_Health.md)
- [System Management Health Checks and Alerts](system_management_health/System_Management_Health_Checks_and_Alerts.md)
- [Access System Management Health Services](system_management_health/Access_System_Management_Health_Services.md)
- [Configure Prometheus Email Alert Notifications](system_management_health/Configure_Prometheus_Email_Alert_Notifications.md)
- [Grafana Dashboards by Component](system_management_health/Grafana_Dashboards_by_Component.md)
    - [Troubleshoot Grafana Dashboard](system_management_health/Troubleshoot_Grafana_Dashboard.md)
- [Remove Kiali](system_management_health/Remove_Kiali.md)
- [`prometheus-kafka-adapter` errors during installation](system_management_health/Prometheus_Kafka_Error.md)
- [`grok-exporter` errors during installation](system_management_health/Grok-Exporter_Error.md)
- [Troubleshoot Prometheus Alerts](system_management_health/Troubleshoot_Prometheus_Alerts.md)
- [Configure UAN Node Exporter](system_management_health/uan_node_exporter_configs.md)

## System Layout Service (SLS)

The System Layout Service \(SLS\) holds information about the system design, such as the physical locations of network hardware, compute nodes, and cabinets. It also
stores information about the network, such as which port on which switch should be connected to each compute node.

- [System Layout Service (SLS)](system_layout_service/System_Layout_Service_SLS.md)
- [Dump SLS Information](system_layout_service/Dump_SLS_Information.md)
- [Load SLS Database with Dump File](system_layout_service/Load_SLS_Database_with_Dump_File.md)
- [Add Liquid-Cooled Cabinets to SLS](system_layout_service/Add_Liquid-Cooled_Cabinets_To_SLS.md)
- [Add UAN CAN IP Addresses to SLS](system_layout_service/Add_UAN_CAN_IP_Addresses_to_SLS.md)
- [Update SLS with UAN Aliases](system_layout_service/Update_SLS_with_UAN_Aliases.md)
- [Add an alias to a service](system_layout_service/Add_an_alias_to_a_service.md)
- [Create a Backup of the SLS Postgres Database](system_layout_service/Create_a_Backup_of_the_SLS_Postgres_Database.md)
- [Restore SLS Postgres Database from Backup](system_layout_service/Restore_SLS_Postgres_Database_from_Backup.md)
- [Restore SLS Postgres without an Existing Backup](system_layout_service/Restore_SLS_Postgres_without_an_Existing_Backup.md)
- [SLS API](../api/sls.md)

## System configuration service

The System Configuration Service \(SCSD\) allows administrators to set various BMC and controller parameters. These parameters are typically set during discovery, but
this tool enables parameters to be set before or after discovery. The operations to change these parameters are available in the Cray CLI under the `scsd` command.

- [System Configuration Service](system_configuration_service/System_Configuration_Service.md)
- [Configure BMC and Controller Parameters with SCSD](system_configuration_service/Configure_BMC_and_Controller_Parameters_with_scsd.md)
- [Manage Parameters with the SCSD Service](system_configuration_service/Manage_Parameters_with_the_scsd_Service.md)
- [Set BMC Credentials](system_configuration_service/Set_BMC_Credentials.md)
- [SCSD API](../api/scsd.md)

## Hardware State Manager (HSM)

Use the Hardware State Manager \(HSM\) to monitor and interrogate hardware components in the HPE Cray EX system, tracking hardware state and inventory information, and
making it available via REST queries and message bus events when changes occur.

- [Hardware State Manager (HSM)](hardware_state_manager/Hardware_State_Manager.md)
- [Hardware Management Services (HMS) Locking API](hardware_state_manager/Hardware_Management_Services_HMS_Locking_API.md)
    - [Lock and Unlock Management Nodes](hardware_state_manager/Lock_and_Unlock_Management_Nodes.md)
    - [Manage HMS Locks](hardware_state_manager/Manage_HMS_Locks.md)
- [Component Groups and Partitions](hardware_state_manager/Component_Groups_and_Partitions.md)
    - [Manage Component Groups](hardware_state_manager/Manage_Component_Groups.md)
    - [Component Group Members](hardware_state_manager/Component_Group_Members.md)
    - [Manage Component Partitions](hardware_state_manager/Manage_Component_Partitions.md)
    - [Component Partition Members](hardware_state_manager/Component_Partition_Members.md)
    - [Component Memberships](hardware_state_manager/Component_Memberships.md)
- [Hardware State Manager (HSM) State and Flag Fields](hardware_state_manager/Hardware_State_Manager_HSM_State_and_Flag_Fields.md)
- [HSM Roles and Subroles](hardware_state_manager/HSM_Roles_and_Subroles.md)
- [Add an NCN to the HSM Database](hardware_state_manager/Add_an_NCN_to_the_HSM_Database.md)
- [Add a Switch to the HSM Database](hardware_state_manager/Add_a_Switch_to_the_HSM_Database.md)
- [Create a Backup of the HSM Postgres Database](hardware_state_manager/Create_a_Backup_of_the_HSM_Postgres_Database.md)
- [Restore HSM Postgres from a Backup](hardware_state_manager/Restore_HSM_Postgres_from_Backup.md)
- [Restore HSM Postgres without a Backup](hardware_state_manager/Restore_HSM_Postgres_without_a_Backup.md)
- [Set BMC Management Role](hardware_state_manager/Set_BMC_Management_Role.md)
- [HSM API](../api/smd.md)
- [Heartbeat Tracker Daemon (HBTD) API](../api/hbtd.md)
- [Hardware Management Notification Fanout Daemon (HMNFD) API](../api/hmnfd.md)

## Hardware Management (HM) collector

The Hardware Management (HM) Collector is used to collect telemetry and Redfish events from hardware in the system.

- [Adjust HM Collector resource limits and requests](hmcollector/adjust_hmcollector_resource_limits_requests.md)

## HPE Power Distribution Unit (PDU)

Procedures for managing and setting up HPE PDUs.

- [HPE PDU Admin Procedure](hpe_pdu/hpe_pdu_admin_procedures.md)

## Node management

Monitor and manage compute nodes (CNs) and non-compute nodes (NCNs) used in the HPE Cray EX system.

- [Node Management](node_management/Node_Management.md)
- [Node Management Workflows](node_management/Node_Management_Workflows.md)
- [Rebuild NCNs](node_management/Rebuild_NCNs/Rebuild_NCNs.md)
    - [Identify Nodes and Update Metadata](node_management/Rebuild_NCNs/Identify_Nodes_and_Update_Metadata.md)
    - [Prepare Storage Nodes](node_management/Rebuild_NCNs/Prepare_Storage_Nodes.md)
    - [Power Cycle and Rebuild Nodes](node_management/Rebuild_NCNs/Power_Cycle_and_Rebuild_Nodes.md)
    - [Adding a Ceph Node to the Ceph Cluster](node_management/Rebuild_NCNs/Re-add_Storage_Node_to_Ceph.md)
    - [Customize PCIe Hardware](node_management/Customize_PCIe_Hardware.md)
    - [Customize Disk Hardware](node_management/Customize_Disk_Hardware.md)
    - [Validate Boot Loader](node_management/Rebuild_NCNs/Validate_Boot_Loader.md)
    - [Validate Storage Node](node_management/Rebuild_NCNs/Post_Rebuild_Storage_Node_Validation.md)
    - [Final Validation Steps](node_management/Rebuild_NCNs/Final_Validation_Steps.md)
- [Reboot NCNs](node_management/Reboot_NCNs.md)
    - [Check and Set the `metalno-wipe` Setting on NCNs](node_management/Check_and_Set_the_metalno-wipe_Setting_on_NCNs.md)
- [Enable Nodes](node_management/Enable_Nodes.md)
- [Disable Nodes](node_management/Disable_Nodes.md)
- [Find Node Type and Manufacturer](node_management/Find_Node_Type_and_Manufacturer.md)
- [Add Additional Air-Cooled Cabinets to a System](node_management/Add_additional_Air-Cooled_Cabinets_to_a_System.md)
- [Add Additional Liquid-Cooled Cabinets to a System](node_management/Add_additional_Liquid-Cooled_Cabinets_to_a_System.md)
- [Updating Cabinet Routes on Management NCNs](node_management/Updating_Cabinet_Routes_on_Management_NCNs.md)
- [Move a liquid-cooled blade within a System](node_management/Move_a_liquid-cooled_blade_within_a_System.md)
    - [Removing a Liquid-cooled blade from a System](node_management/Removing_a_Liquid-cooled_blade_from_a_System.md)
    - [Removing a Liquid-cooled blade from a System Using SAT](node_management/Removing_a_Liquid-cooled_blade_from_a_System_Using_SAT.md)
    - [Adding a Liquid-cooled blade to a System](node_management/Adding_a_Liquid-cooled_blade_to_a_System.md)
    - [Adding a Liquid-cooled blade to a System Using SAT](node_management/Adding_a_Liquid-cooled_blade_to_a_System_Using_SAT.md)
- [Add a Standard Rack Node](node_management/Add_a_Standard_Rack_Node.md)
    - [Removing a Standard rack node from a System](node_management/Removing_a_Standard_Node_from_a_System.md)
    - [Replace a Standard rack node from a System](node_management/Replace_a_Standard_Rack_Node.md)
    - [Move a Standard Rack Node](node_management/Move_a_Standard_Rack_Node.md)
    - [Move a Standard Rack Node (Same Rack/Same HSN Ports)](node_management/Move_a_Standard_Rack_Node_SameRack_SameHSNPorts.md)
    - [Verify Node Removal](node_management/Verify_Node_Removal.md)
- [Clear Space in Root File System on Worker Nodes](node_management/Clear_Space_in_Root_File_System_on_Worker_Nodes.md)
- [Troubleshoot Issues with Redfish Endpoint `DiscoveryCheck` for Redfish Events from Nodes](node_management/Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md)
- [Reset Credentials on Redfish Devices](node_management/Reset_Credentials_on_Redfish_Devices_for_Reinstallation.md)
- [Access and Update Settings for Replacement NCNs](node_management/Access_and_Update_the_Settings_for_Replacement_NCNs.md)
- [Change Settings for HMS Collector Polling of Air Cooled Nodes](node_management/Change_Settings_for_HMS_Collector_Polling_of_Air_Cooled_Nodes.md)
- [Use the Physical KVM](node_management/Use_the_Physical_KVM.md)
- [Launch a Virtual KVM on Gigabyte Nodes](node_management/Launch_a_Virtual_KVM_on_Gigabyte_Nodes.md)
- [Launch a Virtual KVM on Intel Nodes](node_management/Launch_a_Virtual_KVM_on_Intel_Nodes.md)
- [Change Java Security Settings](node_management/Change_Java_Security_Settings.md)
- [Configuration of NCN Bonding](node_management/Configuration_of_NCN_Bonding.md)
    - [Troubleshoot Interfaces with IP Address Issues](node_management/Troubleshoot_Interfaces_with_IP_Address_Issues.md)
- [Troubleshoot Loss of Console Connections and Logs on Gigabyte Nodes](node_management/Troubleshoot_Loss_of_Console_Connections_and_Logs_on_Gigabyte_Nodes.md)
- [Check the BMC Failover Mode](node_management/Check_the_BMC_Failover_Mode.md)
- [Update Compute Node Mellanox HSN NIC Firmware](node_management/Update_Compute_Node_Mellanox_HSN_NIC_Firmware.md)
- [TLS Certificates for Redfish BMCs](node_management/TLS_Certificates_for_Redfish_BMCs.md)
    - [Add TLS Certificates to BMCs](node_management/Add_TLS_Certificates_to_BMCs.md)
- [Dump a Non-Compute Node](node_management/Dump_a_Non-Compute_Node.md)
- [Enable Passwordless Connections to Liquid Cooled Node BMCs](node_management/Enable_Passwordless_Connections_to_Liquid_Cooled_Node_BMCs.md)
    - [View BIOS Logs for Liquid Cooled Nodes](node_management/View_BIOS_Logs_for_Liquid_Cooled_Nodes.md)
- [Configure NTP on NCNs](node_management/Configure_NTP_on_NCNs.md)
- [Swap a Compute Blade with a Different System](node_management/Swap_a_Compute_Blade_with_a_Different_System.md)
- [Swap a Compute Blade with a Different System Using SAT](node_management/Swap_a_Compute_Blade_with_a_Different_System_Using_SAT.md)
- [Replace a Compute Blade](node_management/Replace_a_Compute_Blade.md)
- [Replace a Compute Blade Using SAT](node_management/Replace_a_Compute_Blade_Using_SAT.md)
- [Update the Gigabyte Node BIOS Time](node_management/Update_the_Gigabyte_Node_BIOS_Time.md)
- [S3FS Usage Guidelines](node_management/S3FS_Usage_and_Guidelines.md)
- [Defragment NID Numbering](node_management/Defragment_NID_Numbering.md)
- [Repurpose a Compute Node as a UAN](node_management/Repurpose_Compute_as_UAN.md)
- [Clear Gigabyte CMOS](node_management/clear_gigabyte_cmos.md)
- [Set Gigabyte Node BMC to Factory Defaults](node_management/Set_Gigabyte_Node_BMC_to_Factory_Defaults.md)
- [NCN Network Troubleshooting](node_management/NCN_Network_Troubleshooting.md)
- [NCN Drive Identification](node_management/NCN_Identify_Drives_Using_ledctl.md)
- [Manual Wipe Procedures](node_management/Wipe_NCN_Disks.md)
- [Build NCN Images Locally](node_management/Build_NCN_Images_Locally.md)
- [NCN Lifecycle Service (NLS) API](../api/nls.md)
- [Enable IPMI access on HPE iLO BMCs](node_management/Enable_ipmi_access_on_HPE_iLO_BMCs.md)
- [Update the HPE Node BIOS Time](node_management/Update_the_HPE_Node_BIOS_Time.md)
- [Switch PXE Boot from Onboard NIC to PCIe](node_management/Switch_PXE_Boot_From_Onboard_NICs_to_PCIe.md)
- [NCN NIC Replacement](node_management/NCN_NIC_Replacement.md)

## Network

Overview of the several different networks supported by the HPE Cray EX system.

- [Network](network/Network.md)
- [Access to System Management Services](network/Access_to_System_Management_Services.md)
- [Default IP Address Ranges](network/Default_IP_Address_Ranges.md)
- [Connect to the HPE Cray EX Environment](network/Connect_to_the_HPE_Cray_EX_Environment.md)
- [Connect to Switch over USB-Serial Cable](network/Connect_to_Switch_Over_USB_Serial_Cable.md)
- [Create a CSM Configuration Upgrade Plan](network/Create_a_CSM_Configuration_Upgrade_Plan.md)
- [Gateway Testing](network/Gateway_Testing.md)

### Management network

HPE Cray EX systems can have network switches in many roles: spine switches, leaf switches, `LeafBMC` switches, and CDU switches. Newer systems have HPE Aruba switches,
while older systems have Dell and Mellanox switches. Switch IP addresses are generated by `Cray Site Init` (CSI).

- [HPE Cray EX Management Network Installation and Configuration Guide](network/management_network/README.md)
    - [Aruba Installation and Configuration](network/management_network/aruba/README.md)
    - [Dell Installation and Configuration](network/management_network/dell/README.md)
    - [Mellanox Installation and Configuration](network/management_network/mellanox/README.md)
- [Update Management Network Firmware](network/management_network/firmware/update_management_network_firmware.md)
- [BICAN switch configuration](network/management_network/bican_switch_configuration.md)
- [Bonded UAN Configuration](network/management_network/bonded_uan.md)

### Customer accessible networks (CMN/CAN/CHN)

The customer accessible networks \(CMN/CAN/CHN\) provide access from outside the customer network to services, NCNs, and User Access Nodes \(UANs\) in the system.

- [Customer Accessible Networks](network/customer_accessible_networks/Customer_Accessible_Networks.md)
- [Externally Exposed Services](network/customer_accessible_networks/Externally_Exposed_Services.md)
- [Connect to the CMN and CAN](network/customer_accessible_networks/Connect_to_the_CMN_CAN.md)
- [BI-CAN Aruba/Arista Configuration](network/customer_accessible_networks/bi-can_arista_aruba_config.md)
- [MetalLB Peering with Arista Edge Router](network/customer_accessible_networks/bi-can_arista_metallb_peering.md)
- [CAN/CMN with Dual-Spine Configuration](network/customer_accessible_networks/Dual_Spine_Configuration.md)
- [Troubleshoot CMN Issues](network/customer_accessible_networks/Troubleshoot_CMN_Issues.md)

### Dynamic Host Configuration Protocol (DHCP)

The DHCP service on the HPE Cray EX system uses the Internet Systems Consortium \(ISC\) Kea tool. Kea provides more robust management capabilities for DHCP servers.

- [DHCP](network/dhcp/DHCP.md)
- [Troubleshoot DHCP Issues](network/dhcp/Troubleshoot_DHCP_Issues.md)
- [DHCP boot file customization](network/dhcp/Customize_boot_file.md)

### Domain Name Service (DNS)

The central DNS infrastructure provides the structural networking hierarchy and datastore for the system.

- [DNS](network/dns/DNS.md)
- [Manage the DNS Unbound Resolver](network/dns/Manage_the_DNS_Unbound_Resolver.md)
- [Enable `ncsd` on UANs](network/dns/Enable_ncsd_on_UANs.md)
- [PowerDNS Configuration](network/dns/PowerDNS_Configuration.md)
- [PowerDNS Migration Guide](network/dns/PowerDNS_migration.md)
- [Troubleshoot Common DNS Issues](network/dns/Troubleshoot_Common_DNS_Issues.md)
- [Troubleshoot PowerDNS](network/dns/Troubleshoot_PowerDNS.md)

### External DNS

External DNS, along with the Customer Management Network \(CMN\), Border Gateway Protocol \(BGP\), and MetalLB, makes it simpler to access the HPE Cray EX API and system
management services. Services are accessible directly from a laptop without needing to tunnel into a non-compute node \(NCN\) or override /etc/hosts settings.

- [External DNS](network/external_dns/External_DNS.md)
- [External DNS `csi config init` Input Values](network/external_dns/External_DNS_csi_config_init_Input_Values.md)
- [Update the `cmn-external-dns` Value Post-Installation](network/external_dns/Update_the_cmn-external-dns_Value_Post-Installation.md)
- [Ingress Routing](network/external_dns/Ingress_Routing.md)
- [External DNS Failing to Discover Services Workaround](network/external_dns/External_DNS_Failing_to_Discover_Services_Workaround.md)
- [Troubleshoot Connectivity to Services with External IP addresses](network/external_dns/Troubleshoot_Systems_Not_Provisioned_with_External_IP_Addresses.md)
- [Troubleshoot DNS Configuration Issues](network/external_dns/Troubleshoot_DNS_Configuration_Issues.md)

### MetalLB in BGP-mode

MetalLB is a component in Kubernetes that manages access to `LoadBalancer` services from outside the Kubernetes cluster. There are `LoadBalancer` services on the Node
Management Network \(NMN\), Hardware Management Network \(HMN\), and Customer Access Network \(CAN\).

MetalLB can run in either `Layer2-mode` or `BGP-mode` for each address pool it manages. `BGP-mode` is used for the NMN, HMN, and CAN. This enables true load balancing
\(`Layer2-mode` does failover, not load balancing\) and allows for a more robust layer 3 configuration for these networks.

- [MetalLB in BGP-Mode](network/metallb_bgp/MetalLB_in_BGP-Mode.md)
- [MetalLB Configuration](network/metallb_bgp/MetalLB_Configuration.md)
- [Check BGP Status and Reset Sessions](network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md)
- [Troubleshoot Services without an Allocated IP Address](network/metallb_bgp/Troubleshoot_Services_without_an_Allocated_IP_Address.md)
- [Troubleshoot BGP not Accepting Routes from MetalLB](network/metallb_bgp/Troubleshoot_BGP_not_Accepting_Routes_from_MetalLB.md)

## Spire

Spire provides the ability to authenticate nodes and workloads, and to securely distribute and manage their identities along with the credentials associated with them.

- [Restore Spire Postgres without a Backup](spire/Restore_Spire_Postgres_without_a_Backup.md)
- [Troubleshoot Spire Failing to Start on NCNs](spire/Troubleshoot_Spire_Failing_to_Start_on_NCNs.md)
- [Update Spire Intermediate CA Certificate](spire/Update_Spire_Intermediate_CA_Certificate.md)
- [Xname Validation](spire/xname_validation.md)
- [Restore Missing Spire Meta-Data](spire/Restore_Missing_Spire_Metadata.md)
- [Create a Backup of the Spire Postgres Database](spire/Create_a_backup_of_the_Spire_Postgres_Database.md)

## Update firmware with FAS

The Firmware Action Service (FAS) provides an interface for managing firmware versions of Redfish-enabled hardware in the system. FAS interacts with the Hardware State
Manager (HSM), device data, and image data in order to update firmware.

See [Update Firmware with FAS](firmware/Update_Firmware_with_FAS.md) for a list components that are upgradable with FAS. Refer to the HPC Firmware Pack (HFP) product
stream to update firmware on other components.

- [Update Firmware with FAS](firmware/Update_Firmware_with_FAS.md)
- [Using the `FASUpdate` Script](firmware/FASUpdate_Script.md)
- [FAS CLI](firmware/FAS_CLI.md)
- [FAS API](../api/firmware-action.md)
- [FAS Filters](firmware/FAS_Filters.md)
- [FAS Recipes and Procedures](firmware/FAS_Use_Cases.md)
- [FAS Recipes](firmware/FAS_Recipes.md)
- [FAS Admin Procedures](firmware/FAS_Admin_Procedures.md)
- [Upload Olympus BMC Recovery Firmware into TFTP Server](firmware/Upload_Olympus_BMC_Recovery_Firmware_into_TFTP_Server.md)
- [Updating Firmware on `m001`](firmware/Updating_Firmware_m001.md)
- [Updating Firmware without FAS](firmware/Updating_Firmware_without_FAS.md)
- [Update iLO 5 firmware above `v2.78`](firmware/FAS_Update_iLO5_2.78.md)

## System Admin Toolkit (SAT)

The System Admin Toolkit (SAT) is a command-line interface that can assist administrators with
common tasks, such as troubleshooting and querying information about the HPE Cray EX System, system
boot and shutdown, replacing hardware components, and more. In CSM 1.3 and newer, the `sat` command
is available on the Kubernetes NCNs without installing the SAT product stream.

Starting in CSM 1.6.0, SAT is fully included in CSM. There is no longer a separate SAT product
stream to install. SAT 2.6 releases, which accompanied CSM 1.5, are the last releases of SAT as a
separate product.

- [System Admin Toolkit (SAT)](system_admin_toolkit/README.md)

## Install and Upgrade Framework (IUF)

The Install and Upgrade Framework (IUF) provides a CLI and API which automates operations required to install, upgrade
and deploy non-CSM product content onto an HPE Cray EX system. Each product distribution includes an `iuf-product-manifest.yaml`
file which IUF uses to determine what operations are needed to install, upgrade, and deploy the product.

- [Install and Upgrade Framework (IUF)](iuf/IUF.md)
- [Install and Upgrade Observability Framework](observability/Observability.md)
- [Using the Argo UI](argo/Using_the_Argo_UI.md)
- [Using Argo Workflows](argo/Using_Argo_Workflows.md)

## Backup and recovery

Information on how to perform backups of individual services or the entire system, and how to restore from
these backups.

- [System Recovery](System_Recovery/System_Recovery.md)

### Backup and recovery: etcd

- [Create a Manual Backup of a Healthy Bare-Metal etcd Cluster](kubernetes/Create_a_Manual_Backup_of_a_Healthy_Bare-Metal_etcd_Cluster.md)
- [Create a Manual Backup of a Healthy etcd Cluster](kubernetes/Create_a_Manual_Backup_of_a_Healthy_etcd_Cluster.md)
- [Restore an etcd Cluster from a Backup](kubernetes/Restore_an_etcd_Cluster_from_a_Backup.md)
- [Repopulate Data in etcd Clusters When Rebuilding Them](kubernetes/Repopulate_Data_in_etcd_Clusters_When_Rebuilding_Them.md)
- [Restore Bare-Metal etcd Clusters from an S3 Snapshot](kubernetes/Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md)

### Backup and recovery: Postgres

- [Restore Postgres](kubernetes/Restore_Postgres.md)
- [Disaster Recovery for Postgres](kubernetes/Disaster_Recovery_Postgres.md)

### Backup and recovery: Nexus

- [Nexus Export and Restore](package_repository_management/Nexus_Export_and_Restore.md)
- [Restore Nexus Data After Data Corruption](utility_storage/Restore_Corrupt_Nexus.md)
- [Nexus Service Recovery](package_repository_management/Nexus_Service_Recovery.md)

### Backup and recovery: Keycloak

- [Create a Backup of the Keycloak Postgres Database](security_and_authentication/Create_a_Backup_of_the_Keycloak_Postgres_Database.md)
- [Keycloak Service Recovery](security_and_authentication/Keycloak_Service_Recovery.md)

### Backup and recovery: Vault

- [Backup and Restore Vault Clusters](security_and_authentication/Backup_and_Restore_Vault_Clusters.md)
- [Vault Service Recovery](security_and_authentication/Vault_Service_Recovery.md)

### Backup and recovery: SLS

- [Create a Backup of the SLS Postgres Database](system_layout_service/Create_a_Backup_of_the_SLS_Postgres_Database.md)
- [Restore SLS Postgres Database from Backup](system_layout_service/Restore_SLS_Postgres_Database_from_Backup.md)
- [Restore SLS Postgres without an Existing Backup](system_layout_service/Restore_SLS_Postgres_without_an_Existing_Backup.md)

### Backup and recovery: HSM

- [Create a Backup of the HSM Postgres Database](hardware_state_manager/Create_a_Backup_of_the_HSM_Postgres_Database.md)
- [Restore HSM Postgres from a Backup](hardware_state_manager/Restore_HSM_Postgres_from_Backup.md)
- [Restore HSM Postgres without a Backup](hardware_state_manager/Restore_HSM_Postgres_without_a_Backup.md)

### Backup and recovery: Spire

- [Create a Backup of the Spire Postgres Database](spire/Create_a_backup_of_the_Spire_Postgres_Database.md)
- [Restore Spire Postgres without a Backup](spire/Restore_Spire_Postgres_without_a_Backup.md)
- [Spire Service Recovery](spire/Spire_Service_Recovery.md)

### Backup and recovery: Version Control Service (VCS)

- [Backup and restore data](configuration_management/Version_Control_Service_VCS.md#backup-and-restore-data)

### Backup and recovery: Boot Orchestration Service (BOS)

- [Exporting and Importing BOS Data](boot_orchestration/Exporting_and_Importing_BOS_Data.md)

### Backup and recovery: Boot Script Service (BSS)

- [Exporting and Importing BSS Data](boot_orchestration/Exporting_and_Importing_BSS_Data.md)

### Backup and recovery: Configuration Management Service (CFS)

- [Exporting and Importing CFS Data](configuration_management/Exporting_and_Importing_CFS_Data.md)

### Backup and recovery: Image Management Service (IMS)

- [Exporting and Importing IMS Data](image_management/Exporting_and_Importing_IMS_Data.md)

### Backup and recovery: Workload managers

- [PBS Service Recovery](System_Recovery/PBS_Service_Recovery.md)
- [Slurm Service Recovery](System_Recovery/Slurm_Service_Recovery.md)

## Multi-tenancy

- [Multi-tenancy Support](multi-tenancy/Overview.md)
- [Cray Hierarchical Namespace Controller (HNC) Manager](multi-tenancy/CrayHncManager.md)
- [Tenant Administrator Configuration](multi-tenancy/TenantAdminConfig.md)
- [Creating a Tenant](multi-tenancy/Create_a_Tenant.md)
- [Modifying a Tenant](multi-tenancy/Modify_a_Tenant.md)
- [Removing a Tenant](multi-tenancy/Remove_a_Tenant.md)
- [Slurm Operator](multi-tenancy/SlurmOperator.md)
- [Tenant and Partition Management System (TAPMS) Overview](multi-tenancy/Tapms.md)
- [TAPMS Tenant Status API](../api/tapms-operator.md)
- [Global Tenant Hooks](multi-tenancy/GlobalTenantHooks.md)
- [Example Workflow](multi-tenancy/ExampleWorkflow.md)
