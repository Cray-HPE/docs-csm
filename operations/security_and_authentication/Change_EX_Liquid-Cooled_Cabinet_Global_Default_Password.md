# Change Cray EX Liquid-Cooled Cabinet Global Default Password

This procedure changes the global default credential on HPE Cray EX liquid-cooled cabinet embedded controllers (BMCs). The chassis management module (CMM) controller (cC), node controller, and Slingshot switch controller (sC) are generically referred to as "BMCs" in these procedures.

### Prerequisites

- The Cray command line interface (CLI) tool is initialized and configured on the system. See [Configure the Cray Command Line Interface (`cray` CLI)](../configure_cray_cli.md) for more information.
- Review procedures in [Manage System Passwords](Manage_System_Passwords.md).

### Procedure

1. If necessary, shut down compute nodes in each cabinet. Refer to [Shut Down and Power Off Compute and User Access Nodes](../power_management/Shut_Down_and_Power_Off_Compute_and_User_Access_Nodes.md).

   ```bash
   ncn-m001# sat bootsys shutdown --stage bos-operations \
   --bos-templates COS_SESSION_TEMPLATE
   ```
2. Perform procedures in [Provisioning a Liquid-Cooled EX Cabinet CEC with Default Credentials](Provisioning_a_Liquid-Cooled_EX_Cabinet_CEC_with_Default_Credentials.md).

3. Perform procedures in [Updating the Liquid-Cooled EX Cabinet Default Credentials after a CEC Password Change](Updating_the_Liquid-Cooled_EX_Cabinet_Default_Credentials_after_a_CEC_Password_Change.md).

4. To update Slingshot switch BMCs, refer to "Change Rosetta Login and Redfish API Credentials" in the *Slingshot Operations Guide (> 1.6.0)*.

