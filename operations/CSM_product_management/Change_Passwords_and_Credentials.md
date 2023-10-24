# Change Passwords and Credentials

This is an overarching procedure to change all credentials managed by Cray System Management (CSM) in HPE Cray EX system to new values.

There are many passwords and credentials used in different contexts to manage the system. These can be changed as needed. Their initial settings are documented,
so it is recommended to change them during or soon after a CSM software installation.

## Prerequisites

- Review procedures in [Manage System Passwords](../security_and_authentication/Manage_System_Passwords.md).

## Procedure

1. Change hardware credentials
    1. [Change Cray EX Liquid-Cooled Cabinet Global Default Password](../security_and_authentication/Change_EX_Liquid-Cooled_Cabinet_Global_Default_Password.md)
    1. [Update Default Air-Cooled BMC and Leaf Switch SNMP Credentials](../security_and_authentication/Update_Default_Air-Cooled_BMC_and_Leaf_Switch_SNMP_Credentials.md)
    1. [Change Air-Cooled Node BMC Credentials](../security_and_authentication/Change_Air-Cooled_Node_BMC_Credentials.md)
    1. [Change SNMP Credentials on Leaf Switches](../security_and_authentication/Change_SNMP_Credentials_on_Leaf_Switches.md)
    1. [Update Default ServerTech PDU Credentials used by the Redfish Translation Service (RTS)](../security_and_authentication/Update_Default_ServerTech_PDU_Credentials_used_by_the_Redfish_Translation_Service.md)
    1. [Change Credentials on ServerTech PDUs](../security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md)
1. Change node credentials
    1. [Update NCN Passwords](../security_and_authentication/Update_NCN_Passwords.md)
    1. [Change Root Passwords for Compute Nodes](../security_and_authentication/Change_Root_Passwords_for_Compute_Nodes.md)
1. Change service credentials
    1. [Change the Keycloak Admin Password](../security_and_authentication/Change_the_Keycloak_Admin_Password.md)
