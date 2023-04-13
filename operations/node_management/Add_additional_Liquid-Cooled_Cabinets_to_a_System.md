# Add Additional Liquid-Cooled Cabinets to a System

This top level procedure outlines the process for adding additional liquid-cooled cabinets to a currently installed system.

## Prerequisites

- The system's SHCD file has been updated with the new cabinets and cabling changes.
- The new cabinets have been cabled to the system, and the system's cabling has been validated to be correct.
- Follow the procedure [Create a Backup of the SLS Postgres Database](../system_layout_service/Create_a_Backup_of_the_SLS_Postgres_Database.md).
- Follow the procedure [Create a Backup of the HSM Postgres Database](../hardware_state_manager/Create_a_Backup_of_the_HSM_Postgres_Database.md).

## Procedure

1. Perform procedures in [Add Liquid-Cooled Cabinets to SLS](../system_layout_service/Add_Liquid-Cooled_Cabinets_To_SLS.md).

1. Perform procedures in [Updating Cabinet Routes on Management NCNs](Updating_Cabinet_Routes_on_Management_NCNs.md).

1. Reconfigure management network.

    1. Validate SHCD with CANU.
    1. Validate cabling with CANU.
    1. Generate new switch configurations with CANU and updated SLS.
    1. Review generated switch configurations.
    1. Apply switch configurations.
    1. Update CEC VLAN (if required).

    For more information on CANU, see the [CANU `v1.6.5` documentation](https://github.com/Cray-HPE/canu/blob/1.6.5/readme.md).

    **DISCLAIMER:** This procedure is for standard Mountain cabinet network configurations and does not account for any site customizations that have been made to the management network.
    Site administrators and support teams are responsible for knowing the customizations in effect in Shasta/CSM and configuring CANU to respect them when generating new network configurations.

    See examples of using CANU custom switch configurations and examples of other CSM features that require custom configurations in the following documentation:

    - [Manual Switch Configuration Example](../network/management_network/manual_switch_config.md)
    - [Custom Switch Configuration Example](https://github.com/Cray-HPE/canu/blob/7e0cb58b6253b4c02be1bd420a619befab1f33ca/docs/network_configuration_and_upgrade/custom_config.md)

1. Verify that new hardware has been discovered.

    Perform the [Hardware State Manager Discovery Validation](../validate_csm_health.md#22-hardware-state-manager-discovery-validation) procedure.

    After the management network has been reconfigured, it may take up to 10 minutes for the hardware in the new cabinets to become discovered.

1. Validate BIOS and BMC firmware levels in the new nodes.

    Perform the procedures in [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md). Perform updates as needed with FAS.

    > Slingshot switches are updated with procedures from the *HPE Slingshot Operations Guide*.

1. Configure BMC and controller parameters with SCSD

    The System Configuration Service (SCSD) allows administrators to set various BMC and controller parameters for
    components in liquid-cooled cabinets. At this point SCSD should be used to set the
    SSH key in the node controllers (BMCs) to enable troubleshooting. If any of the nodes fail to power
    down or power up as part of the compute node booting process, it may be necessary to look at the logs
    on the BMC for node power down or node power up.

    See [Configure BMC and Controller Parameters with SCSD](../system_configuration_service/Configure_BMC_and_Controller_Parameters_with_scsd.md).

1. Continue on to the *HPE Slingshot Operations Guide* to bring up the additional cabinets.
