# Create Internal Groups in the Keycloak Shasta Realm

Manually create a group in the Keycloak Shasta realm. New groups can be created with the Keycloak UI. On Shasta, Keycloak groups must have the cn and gidNumber attributes, otherwise the keycloak-users-localize tool will fail to export the groups.

New Keycloak groups can be used to group users for authentication.

### Prerequisites

-   This procedure assumes the user has already accessed Keycloak's user management interface. See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md)
-   This procedure assumes that the password for the Keycloak `admin` account is known. The Keycloak password is set during the software installation process. The password can be obtained using the following command:

    ```bash
    ncn-w001# kubectl get secret -n services keycloak-master-admin-auth \
    --template={{.data.password}} | base64 --decode
    ```


### Procedure

1.  Click the Groups text in the Manage section in the navigation area on the left side of the screen.

2.  Click the **New** button in the groups table header.

3.  Provide a unique name for the new group and click the **Save** button.

4.  Navigate to the **Attributes** tab.

5.  Add the cn attribute by setting the Key to cn, and the Value to the name of the group. Click the **Add** button on the row.

6.  Add the gidNumber attribute by setting the Key to gidNumber, and the Value to the gidNumber of the group. Click the **Add** button on the row.

7.  Click the **Save** button at the bottom of the page.


Once the groups are added to Keycloak, add users to the group and follow the instructions in [Re-Sync Keycloak Users to Compute Nodes](Resync_Keycloak_Users_to_Compute_Nodes.md) to update the groups on the compute nodes.

