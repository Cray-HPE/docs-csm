# Remove Internal Groups from the Keycloak Shasta Realm

Remove a group in the Keycloak Shasta realm. Unused Keycloak groups can be removed.

## Prerequisites

This procedure assumes that the password for the Keycloak `admin` account is known. The Keycloak password is set during the software installation process.

(`ncn-mw#`) The password can be obtained using the following command:

```bash
kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} | base64 --decode
```

## Procedure

1. Open the Keycloak user management interface.

    See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md) for more information.

1. Click the `Groups` text in the `Manage` section in the navigation area on the left side of the screen.

1. Search for the group and select the group in the groups table.

1. Click the `Delete` button at the top of the table.

Once the groups are removed from Keycloak, follow the instructions in [Re-Sync Keycloak Users to Compute Nodes](Resync_Keycloak_Users_to_Compute_Nodes.md) to update the groups on the compute nodes.
