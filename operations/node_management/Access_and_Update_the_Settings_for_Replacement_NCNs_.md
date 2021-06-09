## Access and Update Settings for Replacement NCNs

When a new NCN is added to the system as a hardware replacement, it might use the default admin username and password password.

Use this procedure to verify that the default BMC username admin and password password are set correctly after a replacement NCN is installed, cabled, and powered on.

All NCN BMCs must have root and initial0 credentials \(unless other custom credentials are set up\) for ipmitool access.

### Prerequisites

A new non-compute node \(NCN\) has been added to the system as a hardware replacement.

### Procedure

1.  Determine if root and intitial0 are configured on the BMC.

    ```bash
    # ipmitool -I lanplus -U root -P initial0 -H NCN_NODE-mgmt power status
    Error: Unable to establish IPMI v2 / RMCP+ session
    ```

2.  Connect to the BMC with the default login credentials.

    The following are the default login credentials:

    -   Username: admin
    -   Password: password
    
    ```bash
    # ipmitool -I lanplus -U admin -P password -H NCN_NODE-mgmt power status
    Chassis Power is on
    ```

    **Troubleshooting:** Follow the steps below if the admin and password credentials aren't available:

    1.  Power cycle the replacement NCN.
    2.  Boot into Linux.
    3.  Use the factory reset command to regain access to the BMC admin and password login credentials.

        ```bash
        # ipmitool raw 0x32 0x66
        ```

3.  Determine if the root user is configured.

    In the example below, the root user does not exist yet.

    ```bash
    # ipmitool -I lanplus -U admin -P password -H NCN_NODE-mgmt user list 1
    ID  Name	 Callin  Link Auth  IPMI Msg   Channel Priv Limit
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

4.  Add the new root user.

    1.  Enable the creation of new credentials.

        ```bash
        # ipmitool -I lanplus -U admin -P password -H NCN_NODE-mgmt user enable 4
        ```

    2.  Set the new username to root.

        ```bash
        # ipmitool -I lanplus -U admin -P password -H NCN_NODE-mgmt user set name 4 root
        ```

    3.  Set the new password to initial0.

        ```bash
        # ipmitool -I lanplus -U admin -P password -H NCN_NODE-mgmt user set password 4 initial0
        ```

    4.  Grant user privileges to the new credentials.

        ```bash
        # ipmitool -I lanplus -U admin -P password -H NCN_NODE-mgmt user priv 4 4 1
        ```

    5.  Enable messaging for the identified slot and set the privilege level for that slot when it is accessed over LAN.

        ```bash
        # ipmitool -I lanplus -U admin -P password -H NCN_NODE-mgmt channel setaccess 1 4 callin=on ipmi=on link=on
        ```

    6.  Enable access to the serial over LAN \(SOL\) payload.

        ```bash
        # ipmitool -I lanplus -U admin -P password -H NCN_NODE-mgmt sol payload enable 1 4
        ```

5.  Verify the root credentials have been configured.

    ```bash
    # ipmitool -I lanplus -U admin -P password -H NCN_NODE-mgmt user list 1
    ID  Name	     Callin  Link Auth	IPMI Msg   Channel Priv Limit
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

6.  Confirm the new credentials can be used with ipmitool.

    The new credentials work if the command succeeds and generates output similar to the example below.

    ```bash
    # ipmitool -I lanplus -U root -P initial0 -H NCN_NODE-mgmt user list 1
    ID  Name	     Callin  Link Auth	IPMI Msg   Channel Priv Limit
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



