# Create Internal User Accounts in the Keycloak Shasta Realm

The following manual procedure can be used to create a user in the Keycloak `Shasta` realm. New accounts can be created with the Keycloak UI.

New admin and user accounts are authenticated with Keycloak. Authenticated accounts are needed to use the Cray CLI.

### Prerequisites

-   This procedure assumes the user has already accessed Keycloak's user management interface. See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md) for more information.
-   This procedure assumes that the password for the Keycloak `admin` account is known. The Keycloak password is set during the software installation process. The password can be obtained using the following command:

    ```bash
    ncn-w001# kubectl get secret -n services keycloak-master-admin-auth \
    --template={{.data.password}} | base64 --decode
    ```

### Procedure

1.  Click the **Add User** button.

2.  Enter the user name and other attributes as required.

3.  Click the **Save** button.

4.  On the **Credentials** tab enter a password for the user and change temporary option from **ON** to **OFF**.

5.  Click the **Reset** Password button.

6.  Click the red **Change Password** button on the Change password page.

7.  Remove **Update Password** from the **Required User Actions** and on the user **Details** tab.

    This step allows the user to authenticate and get a token without first needing to change the admin supplied password. It does not prevent the user from changing the password. The other option is to leave this setting requiring a password reset in Keycloak before making a token request.

8.  Select the **Save** button.

9.  Create a user and group ID for this user on the **Attributes** tab by performing the following steps for both the `uid` and `gid` attributes:

    1.  Add the attribute name to the **Key** column and its value to the **Value** column.

    2.  Click the **Add** button.

    3.  Select the **Save** button at the bottom once both the `uid` and `gid` attributes have been added.

    In addition, other attributes can be added as needed by site-specific applications. The User Access Service \(UAS\) requires these attributes.

    User accounts need the following attributes defined to create a User Access Instance \(UAI\):

    -   gidNumber
    -   homeDirectory
    -   loginShell
    -   uidNumber

10. Click on the **Role Mappings** tab to grant the user authority.

    1.  Click the **Client Roles** button.

    2.  Select **shasta**.

    3.  Set the assigned role to either admin or user.

11. Verify that the user account has been created in the `Shasta` realm using one or more of the following:

    -   Ensure that the new user is listed under **Manage Users** on the **Administration Console** page.
    -   Retrieve a token for the user.
    -   Log in to the Keycloak `Shasta` realm as the new user, which would verify the account's validity and allow the user to reset their password. This functionally is supported for internal Keycloak accounts only.

12. Verify that the new local Keycloak account can authenticate to the Cray CLI.

    ```bash
    ncn-w001# cray auth login --username USERNAME
    Password:
    Success!
    ```

**Authorization Is Local to a Host:** whenever you are using the CLI (`cray` command) on a host (e.g. a workstation or NCN) where it has not been used before, it is necessary to authenticate on that host using `cray auth login`. There is no mechanism to distribute CLI authorization amongst hosts.
