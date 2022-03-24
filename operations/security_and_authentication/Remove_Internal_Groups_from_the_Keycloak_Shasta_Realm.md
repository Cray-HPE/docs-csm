# Remove Internal Groups from the Keycloak Shasta Realm

Remove a group in the Keycloak Shasta realm. Unused Keycloak groups can be removed.


### Prerequisites

-   This procedure assumes the user has already accessed Keycloak's user management interface. See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md) for more information.
-   This procedure assumes that the password for the Keycloak `admin` account is known. The Keycloak password is set during the software installation process. The password can be obtained using the following command:

    ```bash
    ncn-w001# kubectl get secret -n services keycloak-master-admin-auth \
    --template={{.data.password}} | base64 --decode
    ```

### Procedure

1.  Click the Groups text in the Manage section in the navigation area on the left side of the screen.

2.  Search for the group and select the group in the groups table.

3.  Click the **Delete** button at the top of the table.


Once the groups are removed from Keycloak, follow the instructions in [Re-Sync Keycloak Users to Compute Nodes](Resync_Keycloak_Users_to_Compute_Nodes.md) to update the groups on the compute nodes.

