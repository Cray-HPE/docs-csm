# Configure Administrative Access

There are several operations which configure administrative access to different parts of the system.
Ensuring that the `cray` CLI can be used by administrative credentials enables use of many management
services via commands. The management nodes can be locked from accidental manipulation by the
`cray capmc` and `cray fas` commands when the intent is to work on the entire system except the
management nodes. The `cray scsd` command can change the SSH keys, NTP server, syslog server, and
BMC/controller passwords.

## Topics

   1. [Configure Keycloak Account](#configure_keycloak_account)
   1. [Configure the Cray Command Line Interface (cray CLI)](#configure_cray_cli)
   1. [Set Management Role on the BMCs of Management Nodes](#set_bmc_management_role)
   1. [Lock Management Nodes](#lock_management_nodes)
   1. [Configure BMC and Controller Parameters with SCSD](#configure_with_scsd)
   1. [Configure Non-compute Nodes with CFS](#configure-ncns)
   1. [Upload Olympus BMC Recovery Firmware into TFTP server](#cray_upload_recovery_images)
   1. [Next Topic](#next-topic)

   **NOTE:** The procedures in this section of installation documentation are intended to be done in order, even though the topics are
   administrative or operational procedures. The topics themselves do not have navigational links to the next topic in the sequence.

## Details

   <a name="configure_keycloak_account"></a>

   1. Configure Keycloak Account

      Upcoming steps in the installation workflow require an account to be configured in Keycloak for
      authentication. This can be either a local Keycloak account or an external Identity Provider (IdP),
      such as LDAP. Having an account in Keycloak with administrative credentials enables the use of many
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
   <a name="set_bmc_management_role"></a>
   1. Set Management Role on the BMCs of Management Nodes

      The BMCs that control management nodes will not have been marked with the *Management* role in HSM. It is important
      to mark them with the *Management* role so they can be easily included in the locking/unlocking operations required
      as protections for FAS and CAPMC actions.
      **Set BMC Management Roles Now!**

      See [Set BMC Management Role](../operations/hardware_state_manager/Set_BMC_Management_Role.md)

      For more info on the importance of locking these components, see [Lock Management Nodes](#lock_management_nodes).

   <a name="lock_management_nodes"></a>

   1. Lock Management Nodes

      The management nodes are unlocked at this point in the installation. Locking the management nodes and their BMCs will
      prevent actions from FAS to update their firmware or CAPMC to power off or do a power reset. Doing any of these by
      accident will take down a management node. If the management node is a Kubernetes master or worker node, this can have
      serious negative effects on system operation.

      If a single node is taken down by mistake, it is possible that things will recover. However, if all management
      nodes are taken down, or all Kubernetes worker nodes are taken down by mistake, the system is dead and has to be
      completely restarted.
      **Lock the management nodes now!**

      Run the `lock_management_nodes.py` script to lock all management nodes and their BMCs that are not already locked:

      ```bash
      ncn# /opt/cray/csm/scripts/admin_access/lock_management_nodes.py
      ```

      The return value of the script is 0 if locking was successful. Otherwise, a non-zero return means that manual intervention may be needed to lock the nodes and their BMCs.

      For more information see [Lock and Unlock Nodes](../operations/hardware_state_manager/Lock_and_Unlock_Management_Nodes.md)
   <a name="configure_with_scsd"></a>
   1. Configure BMC and Controller Parameters with SCSD

      **NOTE:** If there are no liquid-cooled cabinets present in the HPE Cray EX system, then this step can be skipped.

      The System Configuration Service (SCSD) allows administrators to set various BMC and controller parameters for
      components in liquid-cooled cabinets. At this point in the install, SCSD should be used to set the
      SSH key in the node controllers (BMCs) to enable troubleshooting. If any of the nodes fail to power
      down or power up as part of the compute node booting process, it may be necessary to look at the logs
      on the BMC for node power down or node power up.

      See [Configure BMC and Controller Parameters with SCSD](../operations/system_configuration_service/Configure_BMC_and_Controller_Parameters_with_scsd.md)
   <a name="configure-ncns"></a>
   1. Configure Non-compute Nodes with CFS

      Non-compute Nodes (NCN) need to be configured after booting for administrative access, security, and other
      purposes. The [Configuration Framework Service (CFS)](../operations/configuration_management/Configuration_Management.md)
      is used to apply post-boot configuration in a decoupled, layered manner. Individual software products including
      CSM provide one or more layers of configuration in a process called "NCN personalization".

      See [Configure Non-Compute Nodes with CFS](../operations/CSM_product_management/Configure_Non-Compute_Nodes_with_CFS.md)
   <a name="cray_upload_recovery_images"></a>
   1. Upload Olympus BMC Recovery Firmware into TFTP server

      The Olympus hardware (NodeBMCs, ChassisBMCs, RouterBMCs) needs to have recovery firmware loaded to the cray-tftp server in case the BMC loses its firmware.
      The BMCs are configured to load a recovery firmware from a TFTP server.
      This procedure does not modify any BMC firmware, but only stages the firmware on the TFTP server for download in the event it is needed.

      This step requires the CSM software, Cray CLI, and HPC Firmware Pack (HFP) to be installed.
      If these are not currently installed, then this step will need to be skipped and run later in the install process.

      See [Load Olympus BMC Recovery Firmware into TFTP server](../operations/firmware/Upload_Olympus_BMC_Recovery_Firmware_into_TFTP_Server.md)
   <a name="next-topic"></a>
   1. Next Topic

      After completing the operational procedures above which configure administrative access, the next step is to validate the health of management nodes and CSM services.

      See [Validate CSM Health](index.md#validate_csm_health)
