# Access and Update Settings for Replacement NCNs

When a new NCN is added to the system as a hardware replacement, it might use the default credentials. Contact HPE Cray service to learn what these are.

Use this procedure to verify that the default BMC credentials are set correctly after a replacement NCN is installed, cabled, and powered on.

All NCN BMCs must have credentials set up for `ipmitool` access.

## Prerequisites

A new non-compute node \(NCN\) has been added to the system as a hardware replacement.

## Procedure

1. Ensure the the root user is configured on the NCN's BMC.
   1. **For HPE NCNs**, then follow [Configure root user on HPE iLO BMCs](../security_and_authentication/Configure_root_user_on_HPE_iLO_BMCs.md).
   1. **For Gigabyte NCNs**, then follow [Add Root Service Account for Gigabyte Controllers](../security_and_authentication/Add_Root_Service_Account_for_Gigabyte_Controllers.md).

1. **For HPE NCNs**, then verify IPMI access is enabled using the [Enable IPMI access on HPE iLO BMCs](Enable_ipmi_access_on_HPE_iLO_BMCs.md) procedure.

1. Verify the time is set correctly in the BIOS using one of the following procedures.
   1. **For HPE NCNs**, then follow [Update the HPE Node BIOS Time](Update_the_HPE_Node_BIOS_Time.md).
   1. **For Gigabyte NCNs**, then follow [Update the Gigabyte Node BIOS Time](Update_the_Gigabyte_Node_BIOS_Time.md).
