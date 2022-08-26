# Dump SLS Information

Perform a dump of the System Layout Service \(SLS\) database.

This procedure will create the file `sls_dump.json` in the current directory.

This procedure preserves the information stored in SLS when backing up or reinstalling the system.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. (`ncn-mw#`) Use the `get_token` function to retrieve a token to validate requests to the API gateway.

    ```bash
    function get_token () {
        curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'
    }
    ```

1. (`ncn-mw#`) Perform the SLS dump.

    The SLS dump will be stored in the `sls_dump.json` file. The `sls_dump.json` file is required to perform the SLS load state operation.

    ```bash
    curl -X GET \
    https://api-gw-service-nmn.local/apis/sls/v1/dumpstate \
    -H "Authorization: Bearer $(get_token)" \
    > sls_dump.json
    ```
