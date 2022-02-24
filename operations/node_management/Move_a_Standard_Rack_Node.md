## Move a Standard Rack Node

Update the location-based component name (xname) for a standard rack node within the system.

### Prerequisites

-   An authentication token has been retrieved.

    ```screen
    ncn# function get_token () {
        curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'
    }
    ```

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Procedure

1.  Set variables for the new and old component name (xname) locations.

    The `NEWPORT` variable is the component name (xname) of the port that the node BMC will be connected to after it is moved. The component name (xname) is typically something similar to `x3003c0w41j42`. The `OLDENDPOINT` variable is the component name (xname) of the BMC at its old location, for example, `x3006c0r41b0`.

    ```bash
    ncn# NEWPORT=x3003c0w41j42
    ncn# OLDENDPOINT=x3006c0r41b0
    ```

2.  Generate and upload new management switch port information to the System Layout Service \(SLS\) and save it to a file.

    This step may be skipped if this is a direct swap of nodes, where both the source and destination are already populated.

    1.  Query SLS to generate content for the new file.

        Query the old port in SLS and replace the old component name (xname) \(`x3000c0w31j31` in this example\) with the name of the current location of the hardware in the system.

        ```bash
        ncn# cray sls hardware describe x3000c0w31j31 --format json
        ```

        Example output:

        ```json
          {
            "TypeString": "MgmtSwitchConnector",
            "Parent": "x3000c0w31",
            "Type": "comptype_mgmt_switch_connector",
            "Xname": "x3000c0w31j31",
            "Class": "River",
            "ExtraProperties": {
              "NodeNics": [
                "x3000c0s24b0"
              ],
              "VendorName": "ethernet1/1/31"
            }
          }
        ```

    2.  Create the new file with the updated location of the node.

        The following is an example file. The `Parent`, `Xname`, `NodeNics`, and `VendorName` properties must be adjusted to match the new location of the node. The VendorName property may be obtained by logging into the switch that the node will be connected to.

        ```bash
        ncn# cat newport.json
          {
              "Parent": "x3003c0w41",
              "Xname": "x3003c0w41j42",
              "TypeString": "MgmtSwitchConnector",
              "Type": "comptype_mgmt_switch_connector",
              "Class": "River",
              "ExtraProperties": {
                "NodeNics": [
                  "x3004c0r42b0"
                ],
                "VendorName": "ethernet1/1/42"
              }
          }
        ```

3.  Upload the updated node settings captured in the new JSON file.

    Replace the `CUSTOM_FILE` value in the following command with the name of the file created in the previous step.

    ```bash
    ncn# curl -i -X PUT -H "Authorization: Bearer $(get_token)" \
    https://api-gw-service-nmn.local/apis/sls/v1/hardware/$NEWPORT -d @CUSTOM_FILE
    ```

4.  Delete the existing redfishEndpoint and ethernetInterfaces from the Hardware State Manager \(HSM\).

    ```bash
    ncn# cray hsm inventory redfishEndpoints delete $OLDENDPOINT
    message = "deleted 1 entry"
    code = 0

    ncn# for ID in $(cray hsm inventory ethernetInterfaces list \
    --format json | jq -r ".[] | select(.ComponentID==\"$OLDENDPOINT\").ID"); \
    do cray hsm inventory ethernetInterfaces delete $ID; done
    message = "deleted 1 entry"
    code = 0
    ```

