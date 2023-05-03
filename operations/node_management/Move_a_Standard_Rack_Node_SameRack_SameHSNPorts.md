# Move a Standard Rack Node \(Same Rack/Same HSN Ports\)

This procedure move standard rack UAN or compute node to a different location and uses the same Slingshot switch ports and management network ports.

Update the location-based component name (xname) for a standard rack node within the system.

If a node has an incorrect component name (xname) based on its physical location, then this procedure can be used to correct the component name (xname) of the node without the need to physically move the node.

## Prerequisites

- An authentication token has been retrieved.

   ```bash
   function get_token () {
       curl -s -S -d grant_type=client_credentials \
           -d client_id=admin-client \
           -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
           https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'
   }
   ```

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [configure the Cray CLI](../configure_cray_cli.md).
- This procedure applies only to standard rack nodes. Liquid-cooled compute blades do not require the use of the `MgmtSwitchConnector` object in the System Layout Service \(SLS\) to perform discovery.
- This procedure moves an application node or compute node to a different location in an HPE Cray standard rack.
- The node must use the **same Slingshot switch switch ports**.
- The node must use the **same management network switch ports**.

## Limitations

This procedure assumes there are no changes to the node high-speed network switch port or management network ports.

## Procedure

This procedure works with both application and compute nodes. This example moves a compute node in rack 3000 at U17 to U27 in the same rack.

1. Shut down software and power off the node.

1. Disconnect the power cables, management network cables, and high-speed network \(HSN\) cables.

    > If this procedure is being followed to correct a node's component name (xname), then this step can be skipped.

1. Move the node to the new location in the rack \(U27\), connect the management cables and HSN cables, but do not connect the power cables.

    > If this procedure is being followed to correct a node's component name (xname), then this step can be skipped.

### Update Node in the System Layout Service \(SLS\)

1. (`ncn-mw#`) Set up environment variables for the original node and node BMC component names (xnames).

    ```bash
    OLD_NODE_XNAME=x3000c0s17b1n0
    echo $OLD_NODE_XNAME
    ```

    Example output:

    ```text
    x3000c0s17b1n0
    ```

    ```bash
    OLD_BMC_XNAME=$(echo $OLD_NODE_XNAME | egrep -o 'x[0-9]+c[0-9]+s[0-9]+b[0-9]+')
    echo $OLD_BMC_XNAME
    ```

    Example output:

    ```text
    x3000c0s17b1
    ```

1. (`ncn-mw#`) Set up environment variables for the new node and node BMC component names (xnames).

    ```bash
    NEW_NODE_XNAME=x3000c0s27b1n0
    echo $NEW_NODE_XNAME
    ```

    Example output:

    ```text
    x3000c0s27b1n0
    ```

    ```bash
    NEW_BMC_XNAME=$(echo $NEW_NODE_XNAME | egrep -o 'x[0-9]+c[0-9]+s[0-9]+b[0-9]+')
    echo $NEW_BMC_XNAME
    ```

    Example output:

    ```text
    x3000c0s27b1
    ```

1. (`ncn-mw#`) Update SLS with the node's new component name (xname).

    1. Get node from SLS:

        ```bash
        cray sls hardware describe "$OLD_NODE_XNAME" --format json > sls_node.original.json
        ```

        Example contents of `sls_node.original.json`

        ```json
        {
          "Parent": "x3000c0s17b1",
          "Xname": "x3000c0s17b1n0",
          "Type": "comptype_node",
          "Class": "River",
          "TypeString": "Node",
          "LastUpdated": 1631829089,
          "LastUpdatedTime": "2021-09-16 21:51:29.997834 +0000 +0000",
          "ExtraProperties": {
              "Aliases": [
              "nid000001"
            ],
            "NID": 1,
            "Role": "Compute"
          }
        }
        ```

    1. Update the SLS node object with the new component names (xnames):

        ```bash
        jq --arg NODE_XNAME "$NEW_NODE_XNAME" --arg BMC_XNAME "$NEW_BMC_XNAME" \
            '.Parent = $BMC_XNAME | .Xname = $NODE_XNAME' sls_node.original.json \
            > sls_node.json
        ```

        Expected contents of `sls_node.original.json`:

        ```json
        {
          "Parent": "x3000c0s19b1",
          "Xname": "x3000c0s19b1n0",
          "Type": "comptype_node",
          "Class": "River",
          "TypeString": "Node",
          "LastUpdated": 1631829089,
          "LastUpdatedTime": "2021-09-16 21:51:29.997834 +0000 +0000",
          "ExtraProperties": {
              "Aliases": [
              "nid000001"
            ],
            "NID": 1,
            "Role": "Compute"
          }
        }
        ```

        > Only the fields `Parent` and `Xname` should have been updated.

    1. Create new node object in SLS:

        ```bash
        curl -i -X POST -H "Authorization: Bearer $(get_token)" \
            https://api-gw-service-nmn.local/apis/sls/v1/hardware -d @sls_node.json
        ```

        > **`NOTE`** If a 503 is returned, verify that `get_token` function has been defined.

        Expected output:

        ```text
        HTTP/2 200
        content-type: application/json
        date: Mon, 18 Oct 2021 20:30:02 GMT
        content-length: 42
        x-envoy-upstream-service-time: 71
        server: istio-envoy

        {"code":0,"message":"inserted new entry"}
        ```

    1. Delete old node object from SLS:

        ```bash
        cray sls hardware delete $OLD_NODE_XNAME --format toml
        ```

        Expected output:

        ```toml
        code = 0
        message = "deleted entry and its descendants"
        ```

1. (`ncn-mw#`) Update `MgmtSwitchConnector` in SLS with the node BMC's new component name (xname):

    1. Get `MgmtSwitchConnector` object from SLS:

        ```bash
        cray sls search hardware list --node-nics "$OLD_BMC_XNAME" --format json > sls_MgmtSwitchConnector.original.json
        ```

        Example contents of `sls_MgmtSwitchConnector.original.json`:

        ```json
        [
          {
            "Parent": "x3000c0w22",
            "Xname": "x3000c0w22j33",
            "Type": "comptype_mgmt_switch_connector",
            "Class": "River",
            "TypeString": "MgmtSwitchConnector",
            "LastUpdated": 1631829089,
            "LastUpdatedTime": "2021-09-16 21:51:29.997834 +0000 +0000",
            "ExtraProperties": {
              "NodeNics": [
                "x3000c0s17b1"
              ],
              "VendorName": "ethernet1/1/33"
            }
          }
        ]
        ```

    1. Update `MgmtSwitchConnector` object with the new node BMC component name (xname):

        ```bash
        jq --arg BMC_XNAME "$NEW_BMC_XNAME" \
            '.[0] | .ExtraProperties.NodeNics = [ $BMC_XNAME ]' sls_MgmtSwitchConnector.original.json \
            > sls_MgmtSwitchConnector.json
        ```

        Expected contents of `sls_MgmtSwitchConnector.json`:

        ```json
        {
          "Parent": "x3000c0w22",
          "Xname": "x3000c0w22j33",
          "Type": "comptype_mgmt_switch_connector",
          "Class": "River",
          "TypeString": "MgmtSwitchConnector",
          "LastUpdated": 1631829089,
          "LastUpdatedTime": "2021-09-16 21:51:29.997834 +0000 +0000",
          "ExtraProperties": {
            "NodeNics": [
              "x3000c0s27b1"
            ],
            "VendorName": "ethernet1/1/33"
          }
        }
        ```

        > Only the `NodeNics` field should have been updated.

    1. Determine the component name (xname) of the `MgmtSwitchConnector`:

        ```bash
        MGMT_SWITCH_CONNECTOR_XNAME=$(jq -r .Xname sls_MgmtSwitchConnector.json)
        echo $MGMT_SWITCH_CONNECTOR_XNAME
        ```

        Example output:

        ```text
        x3000c0w22j36
        ```

    1. Update the `MgmtSwitchConnector` in SLS:

        ```bash
        curl -i -X PUT -H "Authorization: Bearer $(get_token)" \
            https://api-gw-service-nmn.local/apis/sls/v1/hardware/$MGMT_SWITCH_CONNECTOR_XNAME -d @sls_MgmtSwitchConnector.json
        ```

        Expected output:

        ```text
        HTTP/2 200
        content-type: application/json
        date: Mon, 18 Oct 2021 20:33:36 GMT
        content-length: 301
        x-envoy-upstream-service-time: 8
        server: istio-envoy

        {"Parent":"x3000c0w22","Xname":"x3000c0w22j36","Type":"comptype_mgmt_switch_connector","Class":"River","TypeString":"MgmtSwitchConnector","LastUpdated":1631829089,"LastUpdatedTime":"2021-09-16 21:51:29.997834 +0000 +0000","ExtraProperties":{"NodeNics":["x3000c0s21b4"],"VendorName":"ethernet1/1/36"}}
        ```

### Remove previously discovered node data from HSM

1. (`ncn-mw#`) Remove previously discovered components from HSM:

    1. Remove Node component from HSM:

        ```bash
        cray hsm state components delete $OLD_NODE_XNAME
        ```

    1. Remove `NodeBMC` component from HSM:

        ```bash
        cray hsm state components delete $OLD_BMC_XNAME
        ```

    1. Remove `NodeEnclosure` component from HSM. The component name (xname) for a `NodeEnclosure` is similar to the node BMC component name (xname), but the `b` is replaced with a `e`.

        ```bash
        OLD_NODE_ENCLOSURE_XNAME=x3000c0s17e0
        cray hsm state components delete $OLD_NODE_ENCLOSURE_XNAME
        ```

1. (`ncn-mw#`) Delete the `NodeBMC`, Node NIC MAC addresses, and the Redfish endpoint for the U17 node from the HSM.

    1. Delete the Node MAC addresses from the HSM.

        ```bash
        for ID in $(cray hsm inventory ethernetInterfaces list --component-id $OLD_NODE_XNAME --format json | jq -r .[].ID); do
            echo "Deleting MAC address: $ID"
            cray hsm inventory ethernetInterfaces delete $ID;
        done
        ```

    1. Delete each `NodeBMC` MAC address from the Hardware State Manager \(HSM\) Ethernet interfaces table.

        ```bash
        for ID in $(cray hsm inventory ethernetInterfaces list --component-id $OLD_BMC_XNAME --format json | jq -r .[].ID); do
            echo "Deleting MAC address: $ID"
            cray hsm inventory ethernetInterfaces delete $ID;
        done
        ```

    1. Delete the Redfish endpoint for the removed node.

        ```bash
        cray hsm inventory redfishEndpoints delete $OLD_BMC_XNAME
        ```

1. Connect the power cables to the node to power on the BMC.

    > If this procedure is being followed to correct a node's component name (xname), then this step can be skipped.

1. Wait for 5 minutes for the BMC to power on and the node BMCs to be discovered.

1. (`ncn-mw#`) Verify the node BMC has been discovered by the HSM.

    ```bash
    cray hsm inventory redfishEndpoints describe $NEW_BMC_XNAME --format json
    ```

    Example output:

    ```json
    {
        "ID": "x3000c0s27b1",
        "Type": "NodeBMC",
        "Hostname": "x3000c0s27b1",
        "Domain": "",
        "FQDN": "x3000c0s27b1",
        "Enabled": true,
        "UUID": "e005dd6e-debf-0010-e803-b42e99be1a2d",
        "User": "root",
        "Password": "",
        "MACAddr": "b42e99be1a2d",
        "RediscoverOnUpdate": true,
        "DiscoveryInfo": {
            "LastDiscoveryAttempt": "2021-01-29T16:15:37.643327Z",
            "LastDiscoveryStatus": "DiscoverOK",
            "RedfishVersion": "1.7.0"
        }
    }
    ```

    - When `LastDiscoveryStatus` displays as `DiscoverOK`, then the node BMC has been successfully discovered.
    - If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
    - If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed` then an error occurred during the discovery process.
      - For `HTTPsGetFailed`, verify that the BMC is pingable by its component name (xname).
        - If the component name (xname) of the BMC is not resolvable, then more time may be needed for DNS to update.
        - If hostname does resolve, then issue a discovery request to HSM:

            ```bash
            cray hsm inventory discover create --xnames $NEW_BMC_XNAME
            ```

1. (`ncn-mw#`) Verify that the nodes are enabled in the HSM.

    ```bash
    cray hsm state components describe $NEW_NODE_XNAME --format toml
    ```

    Beginning of example output:

    ```toml
    Type = "Node"
    Enabled = true
    State = "Off"
    ```

1. (`ncn-mw#`) If necessary, enable the nodes in the HSM database \(in this example, the nodes are `x3000c0s27b[1-4]n0`\).

    ```bash
    cray hsm state components bulkEnabled update --enabled true --component-ids x3000c0s27b1n0,x3000c0s27b2n0,x3000c0s27b3n0,x3000c0s27b4n0
    ```

1. (`ncn-mw#`) Use boot orchestration to power on and boot the nodes.

    Specify the appropriate BOS template for the node type.

    ```bash
    cray bos v1 session create --template-uuid cle-VERSION \
        --operation reboot --limit x3000c0s27b1n0,x3000c0s27b2n0,x3000c0s27b3n0,x3000c0s27b4n0
    ```
