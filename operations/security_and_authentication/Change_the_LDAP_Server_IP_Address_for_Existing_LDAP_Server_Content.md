# Change the LDAP Server IP Address for Existing LDAP Server Content

The IP address that Keycloak is using for the LDAP server can be changed. In the case where the new LDAP server has the same contents as the previous LDAP server,
edit the LDAP user federation to switch Keycloak to use the new LDAP server.

Refer to [Change the LDAP Server IP Address for New LDAP Server Content](Change_the_LDAP_Server_IP_Address_for_New_LDAP_Server_Content.md) if the LDAP server is being replaced by a different LDAP server that has different content.

## Prerequisites

The contents of the new LDAP server are the same as the previous LDAP server. For example, it is a replica or was restored from a backup.

## Procedure

Follow the steps in only one of the sections below:

- [Use the Keycloak administration console UI](#use-the-keycloak-administration-console-ui)
- [Use the Keycloak REST API](#use-the-keycloak-rest-api)

### Use the Keycloak administration console UI

1. Log in to the administration console.

    See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md) for more information.

1. Click on `User Federation` under the `Configure` header of the navigation panel on the left side of the page.

1. Click on the LDAP provider in the `User Federation` table.

    This will bring up a form to edit the LDAP user federation.

1. Change the `Connection URL` value in the LDAP user federation form to use the new IP address.

1. Click the `Save` button at the bottom of the form.

1. Click the `Synchronize all users` button.

    This may take a while depending on the number of users and groups in the LDAP server.

    When the synchronize process completes, the pop-up will show that the update was successful. There should be minimal or no changes because the contents of the servers are the same.

### Use the Keycloak REST API

1. (`ncn-mw#`) Create a function to get a token as a Keycloak master administrator.

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

1. (`ncn-mw#`) Get the component ID for the LDAP user federation.

    ```bash
    COMPONENT_ID=$(curl -s -H "Authorization: Bearer $(get_master_token)" https://${AUTH_FQDN}/keycloak/admin/realms/shasta/components \
        | jq -r '.[] | select(.providerId=="ldap").id')

    echo "${COMPONENT_ID}"
    ```

    Example output:

    ```text
    57817383-e4a0-4717-905a-ea343c2b5722
    ```

1. (`ncn-mw#`) Get the current representation of the LDAP user federation.

    ```bash
    curl -s -H "Authorization: Bearer $(get_master_token)" "https://${AUTH_FQDN}/keycloak/admin/realms/shasta/components/${COMPONENT_ID}" \
        | jq . > keycloak_ldap.json
    ```

    Example of output written to the file:

    ```json
    {
      "id": "57817383-e4a0-4717-905a-ea343c2b5722",
      "name": "shasta-user-federation-ldap",
      "providerId": "ldap",
      "providerType": "org.keycloak.storage.UserStorageProvider",
      "parentId": "09580343-fc55-4951-84ee-1c73b3a7ad29",
      "config": {
        "pagination": [
          "true"
        ],
        "fullSyncPeriod": [
          "-1"
        ],

        "[...]",

        "connectionUrl": [
          "ldap://10.248.0.59"
        ],

        "[...]"

    }
    ```

1. (`ncn-mw#`) Edit the `keycloak_ldap.json` file.

    Set the `connectionUrl` string to the new URL with the new IP address.

    ```bash
    vi keycloak_ldap.json
    ```

1. (`ncn-mw#`) Apply the updated `keycloak_ldap.json` file to the Keycloak server.

    The output should show that the response code is `HTTP/2 204`.

    ```bash
    curl -i -XPUT -H "Authorization: Bearer $(get_master_token)" -H "Content-Type: application/json" -d @keycloak_ldap.json \
        "https://${AUTH_FQDN}/keycloak/admin/realms/shasta/components/${COMPONENT_ID}"
    ```
