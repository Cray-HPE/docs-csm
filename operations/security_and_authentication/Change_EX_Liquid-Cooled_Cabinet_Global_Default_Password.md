# Change Cray EX Liquid-Cooled Cabinet Global Default Password

This procedure changes the global default `root` credential on HPE Cray EX liquid-cooled cabinet
embedded controllers (BMCs). The chassis management module (CMM) controller (cC), node controller
(nC), and Slingshot switch controller (sC) are generically referred to as "BMCs" in these
procedures.

## Prerequisites

- The Cray command line interface (CLI) tool is initialized and configured on the system. See [Configure the Cray Command Line Interface (`cray` CLI)](../configure_cray_cli.md) for more information.
- Review procedures in [Manage System Passwords](Manage_System_Passwords.md).

## Procedure

1. (`ncn-mw#`) If necessary, shut down compute nodes in each cabinet. Refer to [Shut Down and Power Off Managed Nodes](../power_management/Shut_Down_and_Power_Off_Managed_Nodes.md).

   ```screen
   sat bootsys shutdown --stage bos-operations --bos-templates COS_SESSION_TEMPLATE
   ```

1. (`ncn-mw#`) Disable the `hms-discovery` Kubernetes cron job.

   ```screen
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

1. (`ncn-mw#`) Power off all compute slots in the cabinets the passwords are to be changed on.

   > **`NOTE`**: If a chassis is not fully populated, specify each slot individually.

   Example showing fully populated cabinets 1000-1003:

   ```screen
   cray power transition off --xnames x[1000-1003]c[0-7]s[0-7]
   ```

   Check the power status:

   ```screen
   cray power status list --xnames x[1000-1003]c[0-7]s[0-7]
   ```

   Continue when all compute slots are `Off`.

1. Perform the procedures in [Provisioning a Liquid-Cooled EX Cabinet CEC with Default Credentials](Provisioning_a_Liquid-Cooled_EX_Cabinet_CEC_with_Default_Credentials.md).

1. Perform the procedures in [Updating the Liquid-Cooled EX Cabinet Default Credentials after a CEC Password Change](Updating_the_Liquid-Cooled_EX_Cabinet_Default_Credentials_after_a_CEC_Password_Change.md).

1. To update Slingshot switch BMCs, refer to "Change Rosetta Login and Redfish API Credentials" in the *Slingshot Operations Guide (> 1.6.0)*.
