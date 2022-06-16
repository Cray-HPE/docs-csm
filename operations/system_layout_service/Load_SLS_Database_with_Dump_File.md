# Load SLS Database with Dump File

Load the contents of the SLS dump file to restore SLS to the state of the system at the time of the dump. This will upload and overwrite the current SLS database with the contents of the SLS dump file, and update Vault with the encrypted credentials.

Use this procedure to restore SLS data after a system re-install.

### Prerequisites

The System Layout Service \(SLS\) database has been dumped. See [Dump SLS Information](Dump_SLS_Information.md) for more information.

### Procedure


1.  Use the get\_token function to retrieve a token to validate requests to the API gateway.

    ```bash
    ncn-m001# function get_token () {
        curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'
    }
    ```

2.  Load the dump file into SLS.

    This will upload and overwrite the current SLS database with the contents of the posted file, as well as update the Vault with the encrypted credentials. The private key that was used to generate the SLS dump file is required.

    ```bash
    ncn-m001# curl -X POST \
    https://api-gw-service-nmn.local/apis/sls/v1/loadstate \
    -H "Authorization: Bearer $(get_token)" \
    -F sls_dump=@sls_dump.json \
    -F private_key=@private_key.pem
    ```

    After performing the load state operation, the private key should be considered insecure and should no longer be used.

