# Add additional Liquid-Cooled Cabinets to a System

> TODO This is for a installed systems

## Prerequisites
- The new cabinets have been cabled up to the system 
- Fabric template has been updated. Maybe do it at the end?

## Procedure
1.  Perform procedures in [Add Liquid-Cooled Cabinets to SLS](../system_layout_service/Add_Liquid-Cooled_Cabinets_To_SLS.md)

2.  Perform procedures in [Updating Cabinet Routes on Management NCNs](Updating_Cabinet_Routes_on_Management_NCNs.md)

3.  Reconfigure management network

4.  Verify new hardware has been discovered by performing the [Hardware State Manager Discovery Validation](../validate_csm_health.md#hms-smd-discovery-validation) procedure.

5.  Perform procedures in [Update Firmware with FAS](../operations/firmware/Update_Firmware_with_FAS.md) to validate BIOS and BMC firmware levels in the new nodes, and perform updates as needed by 

6.  Slingshot stuff