# Remove the LDAP User Federation from Keycloak

Use the Keycloak UI or Keycloak REST API to remove the LDAP user federation from Keycloak.

Removing user federation is useful if the LDAP server was decommissioned or if the administrator would like to make changes to the Keycloak configuration using the Keycloak user localization tool.

### Prerequisites

LDAP user federation is currently configured in Keycloak.

### Procedure

Follow the steps in only one of the sections below depending on if it is preferred to use the Keycloak REST API or Keycloak administration console UI.


#### Use the Keycloak Administration Console UI

1.  Log in to the administration console.

    See [Access the Keycloak User Management UI](Access_the_Keycloak_User_Management_UI.md) for more information.

2.  Click on **User Federation** under the Configure header of the navigation panel on the left side of the page.

3.  Click on the **Delete** button on the line for the LDAP provider in the User Federation table.


#### Use the Keycloak REST API

1. Create a function to get a token as a Keycloak master administrator.

    ```bash
    MASTER_USERNAME=$(kubectl get secret -n services keycloak-master-admin-auth -ojsonpath='{.data.user}' | base64 -d)
    MASTER_PASSWORD=$(kubectl get secret -n services keycloak-master-admin-auth -ojsonpath='{.data.password}' | base64 -d)

    function get_master_token {
      curl -ks -d client_id=admin-cli -d username=$MASTER_USERNAME -d password=$MASTER_PASSWORD -d grant_type=password https://api-gw-service-nmn.local/keycloak/realms/master/protocol/openid-connect/token | python -c "import sys.json; print json.load(sys.stdin)['access_token']"
    }
    ```

2. Get the component ID for the LDAP user federation.

    ```bash
    ncn-w001# COMPONENT_ID=$(curl -s -H "Authorization: Bearer $(get_master_token)" \
    https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/components \
    | jq -r '.[] | select(.providerId=="ldap").id')

    ncn-w001# echo $COMPONENT_ID
    57817383-e4a0-4717-905a-ea343c2b5722
    ```

3.  Delete the LDAP user federation by performing a DELETE operation on the LDAP resource.

    The HTTP status code should be 204.

    ```bash
    ncn-w001# curl -i -XDELETE -H "Authorization: Bearer $(get_master_token)" \
    https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/components/$COMPONENT_ID
    HTTP/2 204
    ...
    ```

