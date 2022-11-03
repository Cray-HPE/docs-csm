# Change Root Passwords for Compute Nodes

Update the root password on the system for compute nodes.

Changing the root password at least once is a recommended best practice for system security.

## Prerequisites

The initial root password for compute nodes is not set. Use this procedure to initially set or later change the password.

## Procedure

1. (`ncn-mw#`) Get an encrypted value for the new password.

    Use the `passwd` command to update the password and get the encrypted hash of the new password.

    In the following example, `mypasswd-example` is the new password set by the administrator, and `demonstration` is an example salt value, which is also configured by the administrator.
    Refer to the `openssl` `man` pages for more information.

    ```bash
    openssl passwd -6 -salt demonstration
    ```

    It will prompt for the new password to be entered (it will not be echoed to the screen as seen below):

    ```text
    Password: mypasswd-example
    ```

    Example command output:

    ```text
    $6$demonstration$gbSD0NlKb2QTo7NRu/pUn4zTNjk5yhSysTS1tUruNIfbROX/a5H92T7CF8fovhORUkOtPrLUpGXmbqIEMmvrh/
    ```

    Save the output to be used in the next step to configure the override of compute nodes' password.

1. Override the default passwords for compute nodes.

    The output from the previous step is needed for this procedure. See
    [Customize Configuration Values](../configuration_management/Customize_Configuration_Values.md).
