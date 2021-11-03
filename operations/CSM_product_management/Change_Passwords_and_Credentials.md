## Change Passwords and Credentials

This is an overarching procedure to change all credentials managed by Cray System Management (CSM) in HPE Cray EX system to new values.

There are many passwords and credentials used in different contexts to manage the system. These can be changed as needed. Their initial settings are documented, so it is recommended to change them during or soon after a CSM software installation.

## Prerequisites

- Review procedures in [Manage System Passwords](../security_and_authentication/Manage_System_Passwords.md).

## Procedure

### 1. Change Hardware Credentials

1.  Perform procedures in [Change Cray EX Cabinet Global Default Password](../security_and_authentication/Change_EX_Cabinet_Global_Default_Password.md).

2.  Perform procedures in [Update Default Air-Cooled BMC and Leaf Switch SNMP Credentials](../security_and_authentication/Update_Default_Air-Cooled_BMC_and_Leaf_Switch_SNMP_Credentials.md).

3.  Perform procedures in [Change Air-Cooled Node BMC Credentials](../security_and_authentication/Change_Air-Cooled_Node_BMC_Credentials.md).

4.  Perform procedures in [Change SMNP Credentials on Leaf Switches](../security_and_authentication/Change_SMNP_Credentials_on_Leaf_Switches.md).

5.  Perform procedures in [Update Default ServerTech PDU Credentials used by the Redfish Translation Service (RTS)](../security_and_authentication/Update_Default_ServerTech_PDU_Credentials_used_by_the_Redfish_Translation_Service.md).

6.  Perform procedures in [Change Credentials on ServerTech PDUs](../security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md).

### 2. Change Node Credentials

1.  Perform the procedure in in section 8.1.1 "Update NCN Passwords" in the _HPE Cray EX System Administration Guide 1.4 S-8001_.

2.  Perform the procedure in section 8.1.2 "Change Root Passwords for Compute Nodes" in the _HPE Cray EX System Administration Guide 1.4 S-8001_.

### 3. Change Service Credentials

1. Perform the procedure in section 8.5.2 "Change the Keycloak Admin Password" in the _HPE Cray EX System Administration Guide 1.4 S-8001_.