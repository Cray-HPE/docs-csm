# Dump SLS Information

Perform a dump of the System Layout Service \(SLS\) database.

This procedure preserves the information stored in SLS when backing up or reinstalling the system.
It will create the file, `sls_dump.json`, in the current directory.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. Use the get\_token function to retrieve a token to validate requests to the API gateway.

    ```bash
    ncn-m001# function get_token () {
        curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'
    }
    ```

2. Perform the SLS dump.

    The SLS dump will be stored in the `sls_dump.json` file.

    ```bash
    ncn-m001# curl -X GET \
    https://api-gw-service-nmn.local/apis/sls/v1/dumpstate \
    -H "Authorization: Bearer $(get_token)" > sls_dump.json
    ```
