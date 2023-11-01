# Remove the LDAP User Federation from Keycloak

Use the Keycloak UI or Keycloak REST API to remove the LDAP user federation from Keycloak.

Removing user federation is useful if the LDAP server was decommissioned or if the administrator would like to make changes to the Keycloak configuration using the Keycloak user localization tool.

## Prerequisites

LDAP user federation is currently configured in Keycloak.

## Procedure

Follow the steps in only one of the sections below:

- [Use the Keycloak administration console UI](#use-the-keycloak-administration-console-ui)
- [Use the Keycloak REST API](#use-the-keycloak-rest-api)

### Use the Keycloak administration console UI

1. Log in to the administration console.

    See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md) for more information.

1. Click on `User Federation` under the `Configure` header of the navigation panel on the left side of the page.

1. Click on the three dots on the LDAP provider then the `Delete` button.

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
    COMPONENT_ID=$(curl -s -H "Authorization: Bearer $(get_master_token)" \
            "https://${AUTH_FQDN}/keycloak/admin/realms/shasta/components" \
        | jq -r '.[] | select(.providerId=="ldap").id')

    echo "${COMPONENT_ID}"
    ```

    Example output:

    ```text
    57817383-e4a0-4717-905a-ea343c2b5722
    ```

1. (`ncn-mw#`) Delete the LDAP user federation by performing a `DELETE` operation on the LDAP resource.

    ```bash
    curl -i -XDELETE -H "Authorization: Bearer $(get_master_token)" "https://${AUTH_FQDN}/keycloak/admin/realms/shasta/components/${COMPONENT_ID}"
    ```

    If the operation is successful, then the expected HTTP status code is 204. In this case, the command output should begin with the following line:

    ```text
    HTTP/2 204
    ```
