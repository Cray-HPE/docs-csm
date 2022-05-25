# Authenticate an Account with the Command Line

Retrieve a token to authenticate to the Cray CLI using the command line. If the Cray CLI is needed before localization occurs and Keycloak is setup, an administrator can use this procedure to authenticate to the Cray CLI.

### Procedure

1.  Retrieve the Kubernetes secret to be used for authentication.

    ```bash
    ncn-w001# ADMIN_SECRET=$(kubectl get secrets admin-client-auth -ojsonpath='{.data.client-secret}' | base64 -d);
    ```

2.  Modify the setup-token.json file so it is readable only by `root`.

    ```bash
    ncn-w001# touch /tmp/setup-token.json
    ncn-w001# chmod 600 /tmp/setup-token.json
    ```

3.  Retrieve a token for the new Keycloak account.

    ```bash
    ncn-w001# curl -s -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$ADMIN_SECRET \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token > /tmp/setup-token.json;
    ```

4.  Set up the new account with the authenticated token.

    ```bash
    ncn-w001# export CRAY_CREDENTIALS=/tmp/setup-token.json;
    ```

