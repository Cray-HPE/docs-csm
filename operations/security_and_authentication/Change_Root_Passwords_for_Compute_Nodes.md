# Change Root Passwords for Compute Nodes

Update the root password on the system for compute nodes.

Changing the root password at least once is a recommended best practice for system security.

### Prerequisites

The initial root password for compute nodes are not set. Use this procedure to set the initial and any subsequent password changes required.

### Procedure

1.  Get an encrypted value for the new password.

    Use the passwd command to update the password and get the new passwd hash. The command will generate an encrypted value.

    In the following example, mypasswd-example is the new password set by the admin, and demonstration is an example salt value, which is also configured by the admin. Refer to the `openssl` man pages for more information.

    ```bash
    # openssl passwd -6 -salt demonstration
    Password: mypasswd-example
    $6$demonstration$gbSD0NlKb2QTo7NRu/pUn4zTNjk5yhSysTS1tUruNIfbROX/a5H92T7CF8fovhORUkOtPrLUpGXmbqIEMmvrh/
    ```

    Save the returned encrypted value to be used in the next step to configure the override of compute nodes password.

2.  Use the encrypted value returned in the previous step to override the default passwords for compute nodes.

    Refer to [Customize Configuration Values](../configuration_management/Customize_Configuration_Values.md) for more information.

