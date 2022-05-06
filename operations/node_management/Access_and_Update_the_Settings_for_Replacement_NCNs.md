# Access and Update Settings for Replacement NCNs

When a new NCN is added to the system as a hardware replacement, it might use the default credentials. Contact HPE Cray service to learn what these are.

Use this procedure to verify that the default BMC credentials are set correctly after a replacement NCN is installed, cabled, and powered on.

All NCN BMCs must have credentials set up for `ipmitool` access.

## Prerequisites

A new non-compute node \(NCN\) has been added to the system as a hardware replacement.

## Procedure

1. Determine if `ipmitool` access is configured for root on the BMC.

    > `read -s` is used to enter the password in order to prevent it from being echoed to the screen or saved in the shell history.

    ```bash
    ncn# read -s IPMI_PASSWORD
    ncn# export IPMI_PASSWORD
    ncn# ipmitool -I lanplus -U root -E -H NCN_NODE-mgmt power status
    ```

    Example output:

    ```text
    Error: Unable to establish IPMI v2 / RMCP+ session
    ```

1. Connect to the BMC with the default login credentials. Contact service for the default credentials.
    > Default credentials for the Administrator user on HPE NCNs can be found on the serial label pull out tab attached to the server. See [this page for more information](https://support.hpe.com/hpesc/public/docDisplay?docId=sf000046874en_us&docLocale=en_US).
    > `read -s` is used to enter the password in order to prevent it from being echoed to the screen or saved in the shell history.

    ```bash
    ncn# USERNAME=defaultuser
    ncn# read -s IPMI_PASSWORD
    ncn# export IPMI_PASSWORD
    ncn# ipmitool -I lanplus -U $USERNAME -E -H NCN_NODE-mgmt power status
    ```

    Example output:

    ```text
    Chassis Power is on
    ```

    **Troubleshooting:** Follow the steps below if the credentials are not available:

    1. Troubleshoot Gigabyte NCNs.
       1. Power cycle the replacement NCN.
       2. Boot into Linux.
       3. Use the factory reset command to regain access to the BMC login credentials.

           ```bash
           linux# ipmitool raw 0x32 0x66
           ```

    2. Troubleshoot HPE NCNs.

        **Coming soon**

1. Determine if the root user is configured.

    In the example below, the root user does not exist yet.

    ```bash
    ncn# ipmitool -I lanplus -U $USERNAME -E -H NCN_NODE-mgmt user list 1
    ```

    Example output:

    ```text
    ID  Name        Callin  Link Auth  IPMI Msg   Channel Priv Limit
    1               false   false      true       ADMINISTRATOR
    2   admin       false   false      true       ADMINISTRATOR
    3   ADMIN       false   false      true       ADMINISTRATOR
    4               true    false      false      NO ACCESS
    5               true    false      false      NO ACCESS
    6               true    false      false      NO ACCESS
    7               true    false      false      NO ACCESS
    8               true    false      false      NO ACCESS
    9               true    false      false      NO ACCESS
    10              true    false      false      NO ACCESS
    11              true    false      false      NO ACCESS
    12              true    false      false      NO ACCESS
    13              true    false      false      NO ACCESS
    14              true    false      false      NO ACCESS
    15              true    false      false      NO ACCESS
    16              true    false      false      NO ACCESS
    ```

1. Add the new root user.

    1. Enable the creation of new credentials.

        ```bash
        ncn# ipmitool -I lanplus -U $USERNAME -E -H NCN_NODE-mgmt user enable 4
        ```

    2. Set the new username to `root`.

        ```bash
        ncn# ipmitool -I lanplus -U $USERNAME -E -H NCN_NODE-mgmt user set name 4 root
        ```

    3. Set the new password.

        ```bash
        ncn# ipmitool -I lanplus -U $USERNAME -E -H NCN_NODE-mgmt user set password 4 <BMC root password>
        ```

    4. Grant user privileges to the new credentials.

        ```bash
        ncn# ipmitool -I lanplus -U $USERNAME -E -H NCN_NODE-mgmt user priv 4 4 1
        ```

    5. Enable messaging for the identified slot and set the privilege level for that slot when it is accessed over LAN.

        ```bash
        ncn# ipmitool -I lanplus -U $USERNAME -E -H NCN_NODE-mgmt channel setaccess 1 4 callin=on ipmi=on link=on
        ```

    6. Enable access to the serial over LAN \(SOL\) payload.

        ```bash
        ncn# ipmitool -I lanplus -U $USERNAME -E -H NCN_NODE-mgmt sol payload enable 1 4
        ```

1. Verify the root credentials have been configured.

    ```bash
    ncn# ipmitool -I lanplus -U $USERNAME -E -H NCN_NODE-mgmt user list 1
    ```

    Example output:

    ```text
    ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
    1                    false   false      true       ADMINISTRATOR
    2   admin            false   false      true       ADMINISTRATOR
    3   ADMIN            false   false      true       ADMINISTRATOR
    4   root             true    true       true       ADMINISTRATOR
    5                    true    false      false      NO ACCESS
    6                    true    false      false      NO ACCESS
    7                    true    false      false      NO ACCESS
    8                    true    false      false      NO ACCESS
    9                    true    false      false      NO ACCESS
    10                   true    false      false      NO ACCESS
    11                   true    false      false      NO ACCESS
    12                   true    false      false      NO ACCESS
    13                   true    false      false      NO ACCESS
    14                   true    false      false      NO ACCESS
    15                   true    false      false      NO ACCESS
    16                   true    false      false      NO ACCESS
    ```

1. Confirm the new credentials can be used with `ipmitool`.

    The new credentials work if the command succeeds and generates output similar to the example below.

    ```bash
    ncn# ipmitool -I lanplus -U root -E -H NCN_NODE-mgmt user list 1
    ```

    Example output:

    ```text
    ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
    1                    false   false      true       ADMINISTRATOR
    2   admin            false   false      true       ADMINISTRATOR
    3   ADMIN            false   false      true       ADMINISTRATOR
    4   root             true    true       true       ADMINISTRATOR
    5                    true    false      false      NO ACCESS
    6                    true    false      false      NO ACCESS
    7                    true    false      false      NO ACCESS
    8                    true    false      false      NO ACCESS
    9                    true    false      false      NO ACCESS
    10                   true    false      false      NO ACCESS
    11                   true    false      false      NO ACCESS
    12                   true    false      false      NO ACCESS
    13                   true    false      false      NO ACCESS
    14                   true    false      false      NO ACCESS
    15                   true    false      false      NO ACCESS
    16                   true    false      false      NO ACCESS
    ```

1. Verify the time is set correctly in the BIOS

    Please refer to the [Ensure Time Is Accurate Before Deploying NCNs](../../install/deploy_management_nodes.md#ensure-time-is-accurate-before-deploying-ncns) procedure.
