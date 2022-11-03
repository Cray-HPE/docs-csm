# Delete Internal User Accounts in the Keycloak Shasta Realm

Manually delete a user account in the Keycloak `Shasta` realm. User accounts are maintained via the Keycloak user management UI.

Removing an account from Keycloak is a good way to revoke admin or user privileges.

## Prerequisites

This procedure assumes that the password for the Keycloak `admin` account is known. The Keycloak password is set during the software installation process.

(`ncn-mw#`) The password can be obtained with the following command:

```bash
kubectl get secret -n services keycloak-master-admin-auth --template={{.data.password}} | base64 --decode
```

## Procedure

1. Access the Keycloak user management interface.

    See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md).

1. Navigate to the `Users` tab.

1. Search for the username or ID of the account that is being deleted.

1. Click the `Delete` button in the `Actions` column of the table to remove the desired account.
