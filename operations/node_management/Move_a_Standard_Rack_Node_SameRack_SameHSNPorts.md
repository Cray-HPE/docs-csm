## Move a Standard Rack Node \(Same Rack/Same HSN Ports\)

This procedure move standard rack UAN or compute node to a different location and uses the same Slingshot switch ports and management network ports.

Update the location-based xname for a standard rack node within the system.

### Prerequisites

-   An authentication token has been retrieved.

    ```bash
    ncn-m001# function get_token () {
    ADMIN_SECRET=$(kubectl get secrets admin-client-auth -ojsonpath='{.data.client-secret}' | base64 -d)
    curl -s -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$ADMIN_SECRET 
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token 
    | python -c 'import sys, json; print json.load(sys.stdin)["access_token"]'
    }
    ```

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   This procedure applies only to standard rack nodes. Liquid-cooled compute blades do not require the use of the MgmtSwitchConnector object in the System Layout Service \(SLS\) to perform discovery.
-   This procedure moves a User Application Node \(UAN\) or compute node to a different location in an HPE Cray standard rack.
-   The node must use the **same Slingshot switch switch ports**.
-   The node must use the **same management network switch ports**.

### Limitations

This procedure assumes there are no changes to the node high-speed network switch port or management network ports.

### Procedure

1.  Shut down software and power off the node.

    This example moves the node in rack 3000 at U17 to U27 in the same rack.

2.  Disconnect the power cables, management network cables, and high-speed network \(HSN\) cables.

3.  Move the node to the new location in the rack \(U27\), connect the mangement cables and HSN cables, but do not connect the power cables.

#### Update Node in the System Layout Service \(SLS\)

4.  With the BMC powered off, update the node information in the SLS.

    1.  To update compute note information in the SLS, determine the compute node information for U17, and update the position in the SLS from U17 to U27.

        ```bash
        ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" \
        https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s17b1n0 | jq
            {
                "Parent": "x3000c0s17b1",
                "Xname": "**x3000c0s17b1n0**",
                "Type": "comptype_node",
                "Class": "River",
                "TypeString": "Node",
                "LastUpdated": 1611700611,
                "LastUpdatedTime": "2021-01-26 22:36:51.127166 +0000 +0000",
                "ExtraProperties": {
                    "Aliases": [
                        "nid000001"
                    ],
                    "NID": 1,
                    "Role": "Compute"
                }
            }
        ```

    2.  Update the `Parent`, `Xname` entries, and then specify the correct URL using the new xname for U27.

        ```bash
        ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" -X PUT --data '{
                "Parent": "x3000c0s27b1",
                "Xname": "x3000c0s27b1n0",
                "Type": "comptype_node",
                "Class": "River",
                "TypeString": "Node",
                "ExtraProperties": {
                    "Aliases": [
                        "nid000001"
                    ],
                    "NID": 1,
                    "Role": "Compute"
                }
            }' https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s27b1n0 | jq
        ```

    3.  To update a User Application Node \(UAN\) in the SLS, determine the information for U17 and update its position from U17 to U27.

        ```bash
        ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" \
        https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s17b1n0 | jq
            {
                "Parent": "x3000c0s17b1",
                "Xname": "x3000c0s17b1n0",
                "Type": "comptype_node",
                "Class": "River",
                "TypeString": "Node",
                "LastUpdated": 1611700611,
                "LastUpdatedTime": "2021-01-26 22:36:51.127166 +0000 +0000",
                "ExtraProperties": {
                    "Aliases": [
                        "uan04"
                    ],
                    "Role": "Application",
                    "SubRole": "UAN"
                }
            }
        ```

    4.  Update the `Parent`, `Xname` fields with the new xname and specify the new xname in the URL.

        ```bash
        ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" -X PUT --data '{
                "Parent": "x3000c0s27b0",
                "Xname": "x3000c0s27b0n0",
                "Type": "comptype_node",
                "Class": "River",
                "TypeString": "Node",
                "ExtraProperties": {
                    "Aliases": [
                        "uan04"
                    ],
                    "Role": "Application",
                    "SubRole": "UAN"
                }
            }' https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s27b1n0 | jq
        ```

    5.  Delete the U17 information from the SLS.

        ```bash
        ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" -X DELETE \
         https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s17b1n0
        ```

    6.  Determine the MgmtSwitchConnector xname for the U17 node \(x3000c0w14j36\) and update the MgmtSwitchConnector xname `NodeNics` array.

        ```bash
        ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" \
        https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0w14j36 | jq
            {
                "Parent": "x3000c0w14",
                "Xname": "x3000c0w14j36",
                "Type": "comptype_mgmt_switch_connector",
                "Class": "River",
                "TypeString": "MgmtSwitchConnector",
                "LastUpdated": 1611700611,
                "LastUpdatedTime": "2021-01-26 22:36:51.127166 +0000 +0000",
                "ExtraProperties": {
                    "NodeNics": [
                        "x3000c0s17b1"
                    ],
                    "VendorName": "1/1/36"
                }
            }
        ```

    7.  Modify the `NodeNics` array in the MgmtSwitchConnector to point to the node BMC xname for U27.

        ```bash
        ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" -X PUT --data '{
                "Parent": "x3000c0w14",
                "Xname": "x3000c0w14j36",
                "Type": "comptype_mgmt_switch_connector",
                "Class": "River",
                "TypeString": "MgmtSwitchConnector",
                "ExtraProperties": {
                    "NodeNics": [
                        "x3000c0s27b1"
                    ],
                    "VendorName": "1/1/36"
                }
            }' https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0w14j36 | jq
        ```

#### Delete the Node NIC MAC Addresses in the HSM

6.  Delete the `NodeBMC`, `Node` NIC MAC addresses, and the Redfish endpoint for the U17 node from th HSM.

    1.  Determine the `NodeBMC` MAC addresses.

        Query HSM to determine the `NodeBMC` MAC addresses associated with the server in cabinet 3000, chassis 0, U27. \(A standard rack is chassis 0\).

        ```bash
        ncn-m001# cray hsm inventory ethernetInterfaces list --component-id x3000c0s27b0 --format json
          [
                {
                    "ID": "**b42e99be1a2d**",
                    "Description": "",
                    "MACAddress": "b4:2e:99:be:1a:2d",
                    "LastUpdate": "2021-01-26T22:39:12.844268Z",
                    "ComponentID": "x3000c0s27b0",
                    "Type": "**NodeBMC**",
                    "IPAddresses": [
                        {
                            "IPAddress": "10.254.1.26"
                        }
                    ]
                },
                {
                    "ID": "**6296643ef4c8**",
                    "Description": "Ethernet Interface usb0",
                    "MACAddress": "62:96:64:3e:f4:c8",
                    "LastUpdate": "2021-01-26T22:43:10.593193Z",
                    "ComponentID": "x3000c0s27b0",
                    "Type": "**NodeBMC**",
                    "IPAddresses": []
                }
            ]
        ```

    2.  Delete each `NodeBMC` MAC address from the Hardware State Manager \(HSM\) Ethernet interfaces table.

        ```bash
        ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2d
        ncn-m001# cray hsm inventory ethernetInterfaces delete 6296643ef4c8
        ```

    3.  Delete the `Node` MAC addresses from the HSM.

        Query HSM to determine the `Node` MAC addresses associated with the server in cabinet 3000, U27, node 0.

        ```bash
        ncn-m001# cray hsm inventory ethernetInterfaces list \
        --component-id x3000c0s27b0n0 --format json
            [
                {
                    "ID": "**b42e99be1a2b**",
                    "Description": "Ethernet Interface Lan1",
                    "MACAddress": "b4:2e:99:be:1a:2b",
                    "LastUpdate": "2021-01-27T00:07:08.658927Z",
                    "ComponentID": "x3000c0s27b0n0",
                    **"Type": "Node"**,
                    "IPAddresses": [
                    {
                        "IPAddress": "10.252.1.26"
                    }
                    ]
                },
                {
                    "ID": "**b42e99be1a2c**",
                    "Description": "Ethernet Interface Lan2",
                    "MACAddress": "b4:2e:99:be:1a:2c",
                    "LastUpdate": "2021-01-26T22:43:10.593193Z",
                    "ComponentID": "x3000c0s27b0n0",
                    **"Type": "Node"**,
                    "IPAddresses": []
                }
            ]
        ```

    4.  Delete each `Node` MAC addresses from the HSM.

        ```bash
        ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2b
        ncn-m001# cray hsm inventory ethernetInterfaces delete b42e99be1a2c
        ```

    5.  Delete the Redfish endpoint for the removed node.

7.  Connect the power cables to the node to power on the BMC.

8.  Wait for 3-5 minutes for power on and the node BMCs to be discovered.

9.  Verify the node BMC has been discovered by the HSM.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x3000c0s27b0 --format json
        {
            "ID": "x3000c0s27b0",
            "Type": "NodeBMC",
            "Hostname": "x3000c0s27b0",
            "Domain": "",
            "FQDN": "x3000c0s27b0",
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
  
10. Verify that the nodes are enabled in the HSM.

    ```bash
    ncn-m001# cray hsm state components describe x3000c0s27b0n0
    Type = "Node"
    Enabled = **true** 
    State = "Off"
    . . .
    ```

11. If necessary, enable each node individually in the HSM database \(in this example, the nodes are `x3000c0s27b0n0-n3`\).

    ```bash
    ncn-m001# cray hsm state components enabled update --enabled true x3000c0s27b0n0
    ncn-m001# cray hsm state components enabled update --enabled true x3000c0s27b0n1
    ncn-m001# cray hsm state components enabled update --enabled true x3000c0s27b0n2
    ncn-m001# cray hsm state components enabled update --enabled true x3000c0s27b0n3
    ```

12. Use boot orchestration to power on and boot the nodes.

    Specify the appropriate BOS template for the node type.

    ```bash
    ncn-m001# cray bos v1 session create --template-uuid cle-VERSION \
    --operation reboot --limit x3000c0s27b0n0,x3000c0s27b0n1,x3000c0s27b0n2,x3000c0s27b0n3
    ```


