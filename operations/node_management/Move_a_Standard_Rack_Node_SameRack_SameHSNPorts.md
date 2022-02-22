## Move a Standard Rack Node \(Same Rack/Same HSN Ports\)

This procedure move standard rack UAN or compute node to a different location and uses the same Slingshot switch ports and management network ports.

Update the location-based xname for a standard rack node within the system.

If a node has an incorrect xname based on its physical location, then this procedure can utilized to correct the xname of the node without the need to physically moving the node. 

### Prerequisites

-   An authentication token has been retrieved.

    ```bash
    ncn-m001# function get_token () {
        curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'
    }
    ```

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   This procedure applies only to standard rack nodes. Liquid-cooled compute blades do not require the use of the MgmtSwitchConnector object in the System Layout Service \(SLS\) to perform discovery.
-   This procedure moves an application node or compute node to a different location in an HPE Cray standard rack.
-   The node must use the **same Slingshot switch switch ports**.
-   The node must use the **same management network switch ports**.

### Limitations

This procedure assumes there are no changes to the node high-speed network switch port or management network ports.

### Procedure

This procedure works with both application and compute nodes. This example moves a compute node in rack 3000 at U17 to U27 in the same rack.

1.  Shut down software and power off the node.

2.  Disconnect the power cables, management network cables, and high-speed network \(HSN\) cables.
    > If this procedure is being followed to correct a nodes xname, then this step can be skipped. 

3.  Move the node to the new location in the rack \(U27\), connect the management cables and HSN cables, but do not connect the power cables.
    > If this procedure is being followed to correct a nodes xname, then this step can be skipped. 

#### Update Node in the System Layout Service \(SLS\)

4.  Setup environment variables for the original node and node BMC xnames:
    
    ```bash
    ncn-m001# OLD_NODE_XNAME=x3000c0s17b1n0
    ncn-m001# echo $OLD_NODE_XNAME
    x3000c0s17b1n0
    ```

    ```bash
    ncn-m001# OLD_BMC_XNAME=$(echo $OLD_NODE_XNAME | egrep -o 'x[0-9]+c[0-9]+s[0-9]+b[0-9]+')
    ncn-m001# echo $OLD_BMC_XNAME
    x3000c0s17b1
    ```

5.  Setup environment variables for the new node and node BMC xnames:  
    
    ```bash
    ncn-m001# NEW_NODE_XNAME=x3000c0s27b1n0
    ncn-m001# echo $NEW_NODE_XNAME
    x3000c0s27b1n0
    ```

    ```bash
    ncn-m001# NEW_BMC_XNAME=$(echo $NEW_NODE_XNAME | egrep -o 'x[0-9]+c[0-9]+s[0-9]+b[0-9]+')
    ncn-m001# echo $NEW_BMC_XNAME
    x3000c0s27b1
    ```

6.  Update SLS with the node's new xname.
	1.  Get Node from SLS:
       
       ```bash
       ncn-m001# cray sls hardware describe "$OLD_NODE_XNAME" --format json > sls_node.original.json
       ```

       Sample contents of `sls_node.original.json`
       
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

    2.  Update SLS Node object with new xnames:
       
        ```bash
        ncn-m001# jq --arg NODE_XNAME "$NEW_NODE_XNAME" --arg BMC_XNAME "$NEW_BMC_XNAME" \
            '.Parent = $BMC_XNAME | .Xname = $NODE_XNAME' sls_node.original.json \
            > sls_node.json
        ```

        Expected content of `sls_node.original.json`:
        
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

    3.  Create new Node object in SLS:
        
        ```bash
        ncn-m001# curl -i -X POST -H "Authorization: Bearer $(get_token)" \
            https://api-gw-service-nmn.local/apis/sls/v1/hardware -d @sls_node.json
        ```
        > **NOTE:** If a 503 is returned, verify that get_token function has been defined.

        Expected output:
        
        ```
        HTTP/2 200 
        content-type: application/json
        date: Mon, 18 Oct 2021 20:30:02 GMT
        content-length: 42
        x-envoy-upstream-service-time: 71
        server: istio-envoy

        {"code":0,"message":"inserted new entry"}
        ```

    4.  Delete old Node object from SLS:
        
        ```bash
        ncn-m001# cray sls hardware delete $OLD_NODE_XNAME
        ```

        Expected output:
        
        ```
        code = 0
        message = "deleted entry and its descendants"
        ```

7.  Update MgmtSwitchConnector in SLS with the node BMC's new xname:

    1.  Get MgmtSwitchConnector object from SLS:
        
        ```bash
        ncn-m001# cray sls search hardware list --node-nics "$OLD_BMC_XNAME" --format json > sls_MgmtSwitchConnector.original.json
        ```

        Sample contents of `sls_MgmtSwitchConnector.original.json`
        
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

    2.  Update MgmtSwitchConnector object with the new node BMC xname:
        
        ```bash
        ncn-m001# jq --arg BMC_XNAME "$NEW_BMC_XNAME" \
            '.[0] | .ExtraProperties.NodeNics = [ $BMC_XNAME ]' sls_MgmtSwitchConnector.original.json \
            > sls_MgmtSwitchConnector.json
        ```

        Expected content of `sls_MgmtSwitchConnector.json`:
        
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

    3.  Determine the xname of the MgmtSwitchConnector:
        
        ```bash
        ncn-m001# MGMT_SWITCH_CONNECTOR_XNAME=$(jq -r .Xname sls_MgmtSwitchConnector.json)
        ncn-m001# echo $MGMT_SWITCH_CONNECTOR_XNAME
        x3000c0w22j36
        ```

    4.  Update the MgmtSwitchConnector in SLS:
        
        ```bash
        ncn-m001# curl -i -X PUT -H "Authorization: Bearer $(get_token)" \
            https://api-gw-service-nmn.local/apis/sls/v1/hardware/$MGMT_SWITCH_CONNECTOR_XNAME -d @sls_MgmtSwitchConnector.json
        ```

        Expected output:
        
        ```
        HTTP/2 200 
        content-type: application/json
        date: Mon, 18 Oct 2021 20:33:36 GMT
        content-length: 301
        x-envoy-upstream-service-time: 8
        server: istio-envoy

        {"Parent":"x3000c0w22","Xname":"x3000c0w22j36","Type":"comptype_mgmt_switch_connector","Class":"River","TypeString":"MgmtSwitchConnector","LastUpdated":1631829089,"LastUpdatedTime":"2021-09-16 21:51:29.997834 +0000 +0000","ExtraProperties":{"NodeNics":["x3000c0s21b4"],"VendorName":"ethernet1/1/36"}}
        ```

#### Remove previously discovered node data from HSM

8.  Remove previously discovered components from HSM:

    Remove Node component from HSM:
    
    ```bash
    ncn-m001# cray hsm state components delete $OLD_NODE_XNAME
    ```

    Remove NodeBMC component from HSM:
    
    ```bash
    ncn-m001# cray hsm state components delete $OLD_BMC_XNAME
    ```

    Remove NodeEnclosure component form HSM. The xname for a NodeEnclosure is similar to the node BMC xname, but the `b` is replaced with a `e`.
    
    ```bash
    ncn-m001# OLD_NODE_ENCLOSURE_XNAME=x3000c0s17e0
    ncn-m001# cray hsm state components delete $OLD_NODE_ENCLOSURE_XNAME
    ```

9.  Delete the `NodeBMC`, `Node` NIC MAC addresses, and the Redfish endpoint for the U17 node from th HSM.

    1.  Delete the `Node` MAC addresses from the HSM.

        ```bash
        ncn-m001# for ID in $(cray hsm inventory ethernetInterfaces list --component-id $OLD_NODE_XNAME --format json | jq -r .[].ID); do
            echo "Deleting MAC address: $ID"
            cray hsm inventory ethernetInterfaces delete $ID; 
        done
        ```

    2.  Delete each `NodeBMC` MAC address from the Hardware State Manager \(HSM\) Ethernet interfaces table.

        ```bash
        ncn-m001# for ID in $(cray hsm inventory ethernetInterfaces list --component-id $OLD_BMC_XNAME --format json | jq -r .[].ID); do
            echo "Deleting MAC address: $ID"
            cray hsm inventory ethernetInterfaces delete $ID; 
        done
        ```

    3.  Delete the Redfish endpoint for the removed node.
        
        ```bash
        ncn-m001# cray hsm inventory redfishEndpoints delete $OLD_BMC_XNAME
        ```

10. Connect the power cables to the node to power on the BMC.
    > If this procedure is being followed to correct a nodes xname, then this step can be skipped. 

11. Wait for 5 minutes for power on and the node BMCs to be discovered.
    ```bash
    ncn-m001# sleep 300 
    ```

12. Verify the node BMC has been discovered by the HSM.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe $NEW_BMC_XNAME --format json
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

    -   When `LastDiscoveryStatus` displays as `DiscoverOK`, the node BMC has been successfully discovered.
    -   If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
    -   If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed` then an error occurred during the discovery process.
        -   For `HTTPsGetFailed`, verify that the BMC is pingable by its xname. If the xname of the BMC is not resolveable it, more time may be needed for DNS to update.

            If hostname it does resolve, issue a discovery request to HSM:
            
            ```bash
            ncn-m001# cray hsm inventory discover create --xnames $NEW_BMC_XNAME
            ```

13. Verify that the nodes are enabled in the HSM.

    ```bash
    ncn-m001# cray hsm state components describe $NEW_NODE_XNAME
    Type = "Node"
    Enabled = true
    State = "Off"
    . . .
    ```

14. If necessary, enable the nodes in the HSM database \(in this example, the nodes are `x3000c0s27b[1-4]n0`\).

    ```bash
    ncn-m001# cray hsm state components bulkEnabled update --enabled true --component-ids x3000c0s27b1n0,x3000c0s27b2n0,x3000c0s27b3n0,x3000c0s27b4n0
    ```

15. Use boot orchestration to power on and boot the nodes.

    Specify the appropriate BOS template for the node type.

    ```bash
    ncn-m001# cray bos v1 session create --template-uuid cle-VERSION \
    --operation reboot --limit x3000c0s27b1n0,x3000c0s27b2n0,x3000c0s27b3n0,x3000c0s27b4n0
    ```


