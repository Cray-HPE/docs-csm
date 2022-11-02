# Create Internal User Accounts in the Keycloak Shasta Realm

The following manual procedure can be used to create a user in the Keycloak `Shasta` realm. New accounts can be created with the Keycloak UI.

New administrator and user accounts are authenticated with Keycloak. Authenticated accounts are needed to use the Cray CLI.

## Prerequisites

This procedure assumes that the password for the Keycloak `admin` account is known. The Keycloak password is set during the software installation process.

(`ncn-mw#`) The password can be obtained with the following command:

```bash
kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} | base64 --decode
```

## Procedure

1. Log in to the administration console.

    See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md) for more information.

1. Click the `Add User` button.

1. Enter the user name and other attributes as required.

1. Click the `Save` button.

1. In the `Credentials` tab, enter a password for the user and change the temporary option from `ON` to `OFF`.

1. Click the `Reset Password` button.

1. Click the red `Change Password` button on the `Change Password` page.

1. Remove `Update Password` from the `Required User Actions` and on the user `Details` tab.

    This step allows the user to authenticate and get a token without first needing to change the administrator-supplied password.
    It does not prevent the user from changing the password. It is also acceptable to leave this setting, which means a password reset in Keycloak
    will be required before making a token request with this user account.

1. Click the `Save` button.

1. Create a user and group ID for this user.

    The User Access Service \(UAS\) requires these attributes. In the `Attributes` tab, performing the following steps for both the `uid` and `gid` attributes:

    1. Add the attribute name to the `Key` column and its value to the `Value` column.

    1. Click the `Add` button.

    1. Click the `Save` button at the bottom once both the `uid` and `gid` attributes have been added.

1. Optionally add other attributes.

    Other attributes can be added as needed by site-specific applications.

    User accounts need the following attributes defined in order to create a User Access Instance \(UAI\):

    - `gidNumber`
    - `homeDirectory`
    - `loginShell`
    - `uidNumber`

1. Click on the `Role Mappings` tab to grant the user authority.

    1. Click the `Client Roles` button.

    1. Select `Shasta`.

    1. Set the assigned role to either `admin` or `user`.

1. Verify that the user account has been created in the `Shasta` realm.

    This can be verified by performing one or more of the following checks:

    - Ensure that the new user is listed under `Manage Users` on the `Administration Console` page.
    - Retrieve a token for the user.
    - Log in to the Keycloak `Shasta` realm as the new user.
      - This verifies the account's validity and allows the user to reset their password.
      - This functionality is supported for internal Keycloak accounts only.

1. (`linux#`) Verify that the new local Keycloak account can authenticate to the Cray CLI.

    **NOTE**: Authorization with the Cray CLI is local to a host. The first time the CLI is used on a host where it has not been used before,
    it is first necessary to authenticate on that host. There is no provided mechanism to distribute CLI authorization across hosts.

    For additional information, see [Configure the Cray CLI](../configure_cray_cli.md).

    ```bash
    cray auth login --username USERNAME
    ```
