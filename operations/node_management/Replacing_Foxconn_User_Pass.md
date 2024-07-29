# Replacing `Foxconn` Username and Passwords in Vault

`Foxconn` (Paradise) nodes may be shipped with a different default username and password then the system password.
Because of the difference in user/password, these nodes will not be able to be discovered.
Vault needs to be updated with the `Foxconn` username and password using the `FoxconnUserPass.py` script or manually.

## Procedure using the `FoxconnUserPass.py` script

1. (`ncn-mw#`) Set up API token.

    ```bash
    export TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. (`ncn-mw#`) Set helper variable.

    ```bash
    DOCS_DIR=/usr/share/doc/csm/scripts
    ```

1. (`ncn-mw#`) Run the `Foxconn` update script

    ```bash
    $DOCS_DIR/operations/hardware_state_manager/FoxconnUserPass.py
    ```

    This will ask for the BMC username and password for the Paradise nodes.
    The scirpt will look for undiscovered nodes, if it finds a `Foxconn` node, update vault with correct credentials.

1. (`ncn-mw#`) Wait 10+ minutes for changes to take affect and nodes to be discovered.  To check nodes which have failed to be discovered:

   ```bash
   cray hsm inventory redfishEndpoints list --format json | jq '.[] | .[] | select (.DiscoveryInfo.LastDiscoveryStatus!="DiscoverOK")'
   ```

## Manual procedure to update credentials in vault

1. (`ncn-mw#`) Use the Cray CLI to update vault through HSM (replace `BMC_xname` with the xname of the BMC, `Foxconn_user` with the `Foxconn` default username, and `Foxconn_pass` with the `Foxconn` default password):
    NOTE: `BMC_xname` needs to be in the line twice

   ```bash
   cray hsm inventory redfishEndpoints update BMC_xname -id BMC_xname --user Foxconn_user --password Foxconn_pass
   ```
