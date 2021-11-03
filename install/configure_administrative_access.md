# Configure Administrative Access

There are several operations which configure administrative access to different parts of the system.
Ensuring that the `cray` CLI can be used by administrative credentials enables use of many management
services via commands. The management nodes can be locked from accidental manipulation by the
`cray capmc` and `cray fas` commands when the intent is to work on the entire system except the
management nodes. The `cray scsd` command can change the SSH keys, NTP server, syslog server, and
BMC/controller passwords.

### Topics:

   1. [Configure Keycloak Account](#configure_keycloak_account)
   1. [Configure the Cray Command Line Interface (cray CLI)](#configure_cray_cli)
   1. [Lock Management Nodes](#lock_management_nodes)
   1. [Configure BMC and Controller Parameters with SCSD](#configure_with_scsd)
   1. [Manage a Configuration with CFS](#manage_a_configuration_with_CFS)
   1. [Upload Olympus BMC Recovery Firmware into TFTP server](#cray_upload_recovery_images)
   1. [Next Topic](#next-topic)

   Note: The procedures in this section of installation documentation are intended to be done in order, even though the topics are
   administrative or operational procedures. The topics themselves do not have navigational links to the next topic in the sequence.

## Details

   <a name="configure_keycloak_account"></a>
   1. Configure Keycloak Account

      Upcoming steps in the installation workflow require an account to be configured in Keycloak for
      authentication. This can be either a local keycloak account or an external Identity Provider (IdP),
      such as LDAP. Having an account in keycloak with administrative credentials enables the use of many
      management services via the `cray` command.

      See [Configure Keycloak Account](../operations/CSM_product_management/Configure_Keycloak_Account.md)
   <a name="configure_cray_cli"></a>
   1. Configure the Cray Command Line Interface (cray CLI)

      The `cray` command line interface (CLI) is a framework created to integrate all of the system management REST
      APIs into easily usable commands.

      Later procedures in the installation workflow use the `cray` command to interact with multiple services.
      The `cray` CLI configuration needs to be initialized for the Linux account. The Keycloak user who initializes the
      CLI configuration needs to be authorized for administrative actions.
   
      See [Configure the Cray Command Line Interface (cray CLI)](../operations/configure_cray_cli.md)
   <a name="lock_management_nodes"></a>
   1. Lock Management Nodes

      The management nodes are unlocked at this point in the installation. Locking them will prevent actions from FAS to
      update their firmware or CAPMC to power off or do a power reset. Doing any of these by accident will take down a
      management node. If the management node is a Kubernetes master or worker node, this can have serious negative effects
      on system operation.

      If a single node is taken down by mistake, it is possible that things will recover. However, if all management
      nodes are taken down, or all Kubernetes worker nodes are taken down by mistake, the system is dead and has to be
      completely restarted.
      **Lock the management nodes now!**
   
      
      Run the `lock_management_nodes.py` script to lock all management nodes that are not already locked:
      ```
      ncn# /opt/cray/csm/scripts/admin_access/lock_management_nodes.py
      ```

      The return value of the script is 0 if locking was successful. Otherwise, a non-zero return means that manual intervention may be needed to lock the nodes.

      For more inormation see [Lock and Unlock Nodes](../operations/hardware_state_manager/Lock_and_Unlock_Management_Nodes.md)
   <a name="configure_with_scsd"></a>
   1. Configure BMC and Controller Parameters with SCSD

      The System Configuration Service (SCSD) allows administrators to set various BMC and controller parameters for
      components in liquid-cooled cabinets. At this point in the install, SCSD should be used to set the
      SSH key in the node controllers (BMCs) to enable troubleshooting. If any of the nodes fail to power
      down or power up as part of the compute node booting process, it may be necessary to look at the logs
      on the BMC for node power down or node power up.

      Note: If there are no liquid-cooled cabinets present in the HPE Cray EX system, then this procedure can be skipped.

      See [Configure BMC and Controller Parameters with SCSD](../operations/system_configuration_service/Configure_BMC_and_Controller_Parameters_with_scsd.md)
   <a name="manage_a_configuration_with_CFS"></a>
   1. Manage a Configuration with CFS

      The Configuration Framework Service (CFS) is used to apply post-boot configuration to all types of nodes.
      Many of the software products installed on an HPE Cray EX system provide their own layer of configuration to be applied
      by CFS either pre-boot or post-boot. When this configuration is applied post-boot to the management nodes, it is called
      "NCN personalization". The CSM layer of configuration should be configured now, but this reference link does include
      information about the layers from other software products which are installed after CSM during a first time installation
      of software.

      See [Manage a Configuration with CFS](../operations/CSM_product_management/Manage_a_Configuration_with_CFS.md)
   <a name="cray_upload_recovery_images"></a>
   1. Upload Olympus BMC Recovery Firmware into TFTP server

      The Olympus hardware (NodeBMCs, ChassisBMCs, RouterBMCs) needs to have recovery firmware loaded to the cray-tftp server in case the BMC loses its firmware. The BMCs are configured to load a recovery firmware from a TFTP server. This procedure does not modify any BMC firmware, but only stages the firmware on the TFTP server for download in the event it is needed.

      See [Load Olympus BMC Recovery Firmware into TFTP server](../operations/firmware/Upload_Olympus_BMC_Recovery_Firmware_into_TFTP_Server.md)

   <a name="next-topic"></a>
   1. Next Topic

      After completing the operational procedures above which configure administrative access, the next step is to validate the health of management nodes and CSM services.

      See [Validate CSM Health](index.md#validate_csm_health)

