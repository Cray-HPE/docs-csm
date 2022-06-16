# Dump SLS Information

Perform a dump of the System Layout Service \(SLS\) database and an encrypted dump of the credentials stored in Vault.

This procedure will create three files in the current directory \(private\_key.pem, public\_key.pem, sls\_dump.json\). These files should be kept in a safe and secure place as the private key can decrypt the encrypted passwords stored in the SLS dump file.

This procedure preserves the information stored in SLS when backing up or reinstalling the system.

### Prerequisites

This procedure requires administrative privileges.

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

2.  Generate a private and public key pair.

    Execute the following commands to generate a private and public key to use for the dump.

    ```bash
    ncn-m001# openssl genpkey -out private_key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
    ncn-w001# openssl rsa -in private_key.pem -outform PEM -pubout -out public_key.pem
    ```

    The above commands will create two files the private key private\_key.pem file and the public key public\_key.pem file.

    Make sure to use a new private and public key pair for each dump operation, and do not reuse an existing private and public key pair. The private key should be treated securely because it will be required to decrypt the SLS dump file when the dump is loaded back into SLS. Once the private key is used to load state back into SLS, it should be considered insecure.

3.  Perform the SLS dump.

    The SLS dump will be stored in the sls\_dump.json file. The sls\_dump.json and private\_key.pem files are required to perform the SLS load state operation.

    ```bash
    ncn-m001# curl -X POST \
    https://api-gw-service-nmn.local/apis/sls/v1/dumpstate \
    -H "Authorization: Bearer $(get_token)" \
    -F public_key=@public_key.pem > sls_dump.json
    ```

