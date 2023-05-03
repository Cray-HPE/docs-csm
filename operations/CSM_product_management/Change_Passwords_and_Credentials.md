# Change Passwords and Credentials

This is an overarching procedure to change all credentials managed by Cray System Management (CSM) in HPE Cray EX system to new values.

There are many passwords and credentials used in different contexts to manage the system. These can be changed as needed. Their initial settings are documented, so it is recommended to change them during or soon after a CSM software installation.

## Prerequisites

- Review procedures in [Manage System Passwords](../security_and_authentication/Manage_System_Passwords.md).

## Procedure

### 1. Change Hardware Credentials

1. Perform procedures in [Change Cray EX Liquid-Cooled Cabinet Global Default Password](../security_and_authentication/Change_EX_Liquid-Cooled_Cabinet_Global_Default_Password.md).

2. Perform procedures in [Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials](../security_and_authentication/Update_Default_Air-Cooled_BMC_and_Leaf_BMC_Switch_SNMP_Credentials.md).

3. Perform procedures in [Change Air-Cooled Node BMC Credentials](../security_and_authentication/Change_Air-Cooled_Node_BMC_Credentials.md).

4. Perform procedures in [Configuring SNMP in CSM](../../operations/network/management_network/configure_snmp.md).

5. Perform procedures in [Update Default ServerTech PDU Credentials used by the Redfish Translation Service (RTS)](../security_and_authentication/Update_Default_ServerTech_PDU_Credentials_used_by_the_Redfish_Translation_Service.md).

6. Perform procedures in [Change Credentials on ServerTech PDUs](../security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md).

### 2. Change Node Credentials

1. Perform procedures in [Update NCN Passwords](../security_and_authentication/Update_NCN_Passwords.md).

2. Perform procedures in [Change Root Passwords for Compute Nodes](../security_and_authentication/Change_Root_Passwords_for_Compute_Nodes.md).

### 3. Change Service Credentials

1. Perform procedures in [Change the Keycloak Admin Password](../security_and_authentication/Change_the_Keycloak_Admin_Password.md).
