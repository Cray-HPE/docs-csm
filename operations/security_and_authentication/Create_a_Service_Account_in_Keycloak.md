# Create a Service Account in Keycloak

Set up a Keycloak service account using the Keycloak administration console or the Keycloak REST API. A service account can be used to get a long-lived token that is used by automation tools.

In Keycloak, service accounts are associated with a client. See
[Service Accounts](https://www.keycloak.org/docs/latest/server_admin/#_service_accounts)
for more information from the Keycloak documentation.

## Procedure

Follow the steps in only one of the following sections, depending on if it is preferred to use the Keycloak REST API or the Keycloak administration console UI.

### Use the Keycloak administration console UI

1. Log in to the administration console.

   See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md) for more information.

1. Click **Clients** under the **Manage** header of the navigation panel on the left side of the page.

1. Click the **Create Client** button at the top-right of the **Clients** table.

   ![Add client in Keycloak](../../img/operations/Add_Client_in_Keycloak.png)

   1. Enter a `Client ID` for the new client.

      The `Client Protocol` must be `openid-connect` and the `Root URL` can be left blank.

   1. Click the **Next** button.

   1. Click the **Save** button.

1. Customize the new client.

   Once the client is created, a new screen is displayed with more details for the client.

   ![Keycloak client details](../../img/operations/Keycloak_Client_Details.png)

   1. Click on `Capability config` on the right side under `Jump to section`.

   1. Change `Client authentication` to `on`.

   1. Change `Service accounts role` to `On`.

   1. Change `Stand Flow Enabled` to `OFF`.

   1. Change `Direct Access Grants Enabled` to `OFF`.

   1. Click the **Save** button.

1. Assign a role to the client for authorization.

   ![Keycloak `admin-role` mapper](../../img/operations/Keycloak_Admin-role_Mapper.png)
   ![Keycloak `Client scopes` table](../../img/operations/Keycloak_client_scopes_table.png)

   1. Switch to the **Client scopes** tab for the new client.

   1. Click the entry that ends in `-dedicated`.

      In the image above, the example entry is `my-test-client-dedicated`.

   1. Click on `Add mapper` then on `By configuration`.

   1. Change the `Mapper Type` to `Hardcoded Role`.

   1. A table will pop up, and then click on `Hardcoded Role`.

   1. Enter a name.

      In the image above, the example name is `admin-role`.

   1. Click on `Select Role`.

   1. Click on the dropdown that says `Filter by realm roles` and select `Filter by clients`.

   1. Click on the role called `shasta admin`.

   1. Click the **Assign** button.

   1. Click on the **Save** button.

### Use the Keycloak REST API

1. (`ncn-mw#`) Create the `get_master_token` function to get a token as a Keycloak master administrator.

   ```bash
   MASTER_USERNAME=$(kubectl get secret -n services keycloak-master-admin-auth -ojsonpath='{.data.user}' | base64 -d)
   MASTER_PASSWORD=$(kubectl get secret -n services keycloak-master-admin-auth -ojsonpath='{.data.password}' | base64 -d)
   SITE_DOMAIN="$(craysys metadata get site-domain)"
   SYSTEM_NAME="$(craysys metadata get system-name)"
   AUTH_FQDN="auth.cmn.${SYSTEM_NAME}.${SITE_DOMAIN}"

   function get_master_token {
     curl -ks -d client_id=admin-cli -d username="${MASTER_USERNAME}" -d password="${MASTER_PASSWORD}" \
         -d grant_type=password "https://${AUTH_FQDN}/keycloak/realms/master/protocol/openid-connect/token" | \
     jq -r .access_token
   }
   ```

1. (`ncn-mw#`) Create the client by doing a POST call for a JSON object.

   The `clientId` should be changed to the name for the new service account.

   ```bash
   curl -is -H "Authorization: Bearer $(get_master_token)" -H "Content-Type: application/json" -d '
   {
     "clientId": "my-test-client",
     "standardFlowEnabled": false,
     "implicitFlowEnabled": false,
     "directAccessGrantsEnabled": false,
     "serviceAccountsEnabled": true,
     "publicClient": false,
     "protocolMappers": [
       {
         "name": "admin-role",
         "protocol": "openid-connect",
         "protocolMapper": "oidc-hardcoded-role-mapper",
         "consentRequired": false,
         "config": {
           "role": "shasta.admin"
         }
       }
     ]
   }
   ' \
   "https://${AUTH_FQDN}/keycloak/admin/realms/shasta/clients"
   ```

   Output similar to the following is expected:

   ```text
   HTTP/2 201
   location: https://auth.cmn.system1.us.cray.com/keycloak/admin/realms/shasta/clients/bd8084d2-08bf-45cb-ab94-ee81e39921be
   content-length: 0
   ```
