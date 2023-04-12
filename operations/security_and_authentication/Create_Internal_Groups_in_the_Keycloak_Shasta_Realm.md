# Create Internal Groups in the Keycloak Shasta Realm

Manually create a group in the Keycloak `Shasta` realm. New groups can be created with the Keycloak UI. In CSM, Keycloak groups must have the `cn` and `gidNumber` attributes,
otherwise the `keycloak-users-localize` tool will fail to export the groups.

New Keycloak groups can be used to group users for authentication.

## Prerequisites

This procedure assumes that the password for the Keycloak `admin` account is known. The Keycloak password is set during the software installation process.

(`ncn-mw#`) The password can be obtained with the following command:

```bash
kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} | base64 --decode
```

## Procedure

1. Log in to the administration console.

    See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md) for more information.

1. Click the `Groups` text in the `Manage` section in the navigation area on the left side of the screen.

1. Click the `Create Group` button in the groups table header.

1. Provide a unique name for the new group and click the `Save` button.

1. Click on the group you wish to manage.

1. Navigate to the `Attributes` tab.

1. Add the `cn` attribute.

    1. Set the `Key` to `cn`.

    1. Set the `Value` to the name of the group.

    1. Click the `Save` button on the bottom.

1. Add the `gidNumber` attribute.

    1. Set the `Key` to `gidNumber`.

    1. Set the `Value` to the `gidNumber` of the group.

    1. Click the `Save` button on the bottom.

Once the groups are added to Keycloak, add users to the groups and follow the instructions in
[Re-Sync Keycloak Users to Compute Nodes](Resync_Keycloak_Users_to_Compute_Nodes.md) in order to update the groups on the compute nodes.
