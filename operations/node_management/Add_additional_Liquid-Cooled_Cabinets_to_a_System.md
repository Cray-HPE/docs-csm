# Add additional Liquid-Cooled Cabinets to a System

This top level procedure outlines the process for adding additional liquid-cooled cabinets to a currently installed system. 

## Prerequisites
- The System's SHCD file has been updated with the new cabinets and cabling changes.
- The new cabinets have been cabled up to the system, and the system's cabling has been validated to be correct.
- Follow the procedure [Create a Backup of the SLS Postgres Database](../system_layout_service/Create_a_Backup_of_the_SLS_Postgres_Database.md).
- Follow the procedure [Create a Backup of the HSM Postgres Database](../hardware_state_manager/Create_a_Backup_of_the_HSM_Postgres_Database.md).
- Backup running-config on all management switches.
- Export switch backup to CSM R&D.

## Procedure
1. Perform procedures in [Add Liquid-Cooled Cabinets to SLS](../system_layout_service/Add_Liquid-Cooled_Cabinets_To_SLS.md).

2. Reconfigure management network:
   1. Obtain updated switch configs from CSM R&D.
   2. Verify/Update current configuration on management network switches.
   3. Verify new switches are at factory defaults.
   4. Upgrade new switch firmware.
   5. Load switch configs onto new switches.
   6. Rack and cable new switches.
   7. Power on new switches.

3. Perform procedures in [Updating Cabinet Routes on Management NCNs](Updating_Cabinet_Routes_on_Management_NCNs.md).

4.  Verify new hardware has been discovered by performing the [Hardware State Manager Discovery Validation](../validate_csm_health.md#hms-smd-discovery-validation) procedure. 
    After the management network has been reconfigured, it may take up to 10 minutes for the hardware in the new cabinets to become discovered.

5.  Perform procedures in [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md) to validate BIOS and BMC firmware levels in the new nodes, and perform updates as needed with FAS.
    > Slingshot Switches are updated with procedures from the *Slingshot Operations Guide*.

6.  Continue on to the *Slingshot Operations Guide* to bring up the additional cabinets.  

    **NOTE:** Placeholder: Provide a link to the procedure once ready.
