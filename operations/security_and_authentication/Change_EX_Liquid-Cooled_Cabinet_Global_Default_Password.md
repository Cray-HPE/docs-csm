# Change Cray EX Liquid-Cooled Cabinet Global Default Password

This procedure changes the global default `root` credential on HPE Cray EX liquid-cooled cabinet embedded controllers (BMCs). The chassis management module (CMM) controller (cC), node controller (nC), and Slingshot switch controller (sC) are generically referred to as "BMCs" in these procedures.

## Prerequisites

- The Cray command line interface (CLI) tool is initialized and configured on the system. See [Configure the Cray Command Line Interface (`cray` CLI)](../configure_cray_cli.md) for more information.
- Review procedures in [Manage System Passwords](Manage_System_Passwords.md).

### Procedure

1. If necessary, shut down compute nodes in each cabinet. Refer to [Shut Down and Power Off Compute and User Access Nodes](../power_management/Shut_Down_and_Power_Off_Compute_and_User_Access_Nodes.md).

   ```screen
   ncn-m001# sat bootsys shutdown --stage bos-operations --bos-templates COS_SESSION_TEMPLATE
   ```

2. Disable the `hms-discovery` Kubernetes cron job.

   ```screen
    ncn-m001# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

3. Power off all compute slots in the cabinets the passwords are to be changed on.

   **Note**: If a chassis is not fully populated, specify each slot individually.

   Example showing fully populated cabinets 1000-1003:

   ```screen
   ncn-m001# cray capmc xname_off create --xnames x[1000-1003]c[0-7]s[0-7] --format json
   ```

   Check the power status:

   ```screen
   ncn-m001# cray capmc get_xname_status create --xnames x[1000-1003]c[0-7]s[0-7] --format json
   ```

   Continue when all compute slots are `Off`.

4. Perform the procedures in [Provisioning a Liquid-Cooled EX Cabinet CEC with Default Credentials](Provisioning_a_Liquid-Cooled_EX_Cabinet_CEC_with_Default_Credentials.md).

5. Perform the procedures in [Updating the Liquid-Cooled EX Cabinet Default Credentials after a CEC Password Change](Updating_the_Liquid-Cooled_EX_Cabinet_Default_Credentials_after_a_CEC_Password_Change.md).

6. To update Slingshot switch BMCs, refer to "Change Rosetta Login and Redfish API Credentials" in the *Slingshot Operations Guide (> 1.6.0)*.

