# Authenticate an Account with the Command Line

Retrieve a token to authenticate to the Cray CLI using the command line. If the Cray CLI is needed before localization occurs and Keycloak is setup, an administrator can use this procedure to authenticate to the Cray CLI.

## Procedure

1. Retrieve the Kubernetes secret to be used for authentication.

    ```bash
    ncn-mw# ADMIN_SECRET=$(kubectl get secrets admin-client-auth -ojsonpath='{.data.client-secret}' | base64 -d)
    ```

1. Create the `setup-token.json` file and modify it to be readable only by `root`.

    ```bash
    ncn-mw# touch /tmp/setup-token.json && chmod 600 /tmp/setup-token.json
    ```

1. Retrieve a token for the new Keycloak account.

    ```bash
    ncn-mw# curl -s -d grant_type=client_credentials -d client_id=admin-client -d client_secret="${ADMIN_SECRET}" \
                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token > /tmp/setup-token.json
    ```

1. Set up the new account with the authenticated token.

    ```bash
    ncn-mw# export CRAY_CREDENTIALS=/tmp/setup-token.json
    ```
