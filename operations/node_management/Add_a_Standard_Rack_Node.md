
## Add a Standard Rack Node

These procedures are intended for trained technicians and support personnel only. Always follow ESD precautions when handling this equipment.

-   An authentication token has been retrieved.

    ```screen
    ncn-m001# function get_token () {
    ADMIN_SECRET=$(kubectl get secrets admin-client-auth -ojsonpath='{.data.client-secret}' | base64 -d)
    curl -s -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$ADMIN_SECRET 
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token 
    | python -c 'import sys, json; print json.load(sys.stdin)["access_token"]'
    }
    ```

The example is this procedure adds a User Access Node \(UAN\) or compute node to an HPE Cray standard rack system. This example adds a node to rack number 3000 at U27.

Procedures for updating the Hardware State Manager \(HSM\) or System Layout Service \(SLS\) are similar when adding additional compute nodes or User Application Nodes \(UANs\). The contents of the node object in the SLS are slightly different for each node type.

Refer to the OEM documentation for information about the node architecture, installation, and cabling.

For this procedure, a new object must be created in the SLS and modifications will be required to the Slingshot HSN topology.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Procedure

1.  Create a new node object in SLS.

    New node objects require the following information:

    -   `Parent`: xname of the new node's BMC
    -   `Xname`: xname of the new node
    -   `Role`: Either `Compute` or `Application`
    -   `Aliases`: Array of aliases for the node, for compute nodes, this is in the form of `nid0000`
    -   NID: The Node ID integer for the node, applies only to compute nodes.
    -   SubRole: Such as `UAN`, `Gateway`, or other valid HSM SubRoles
    -   If adding a compute node:

        ```screen
        ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST --data '{
                "Parent": "x3000c0s27b0",
                "Xname": "x3000c0s27b0n0",
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
            }' https://api-gw-service-nmn.local/apis/sls/v1/hardware | jq
        ```

    -   If adding a UAN:

        ```screen
        ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST --data '{
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
            }' https://api-gw-service-nmn.local/apis/sls/v1/hardware
        ```

2.  Create a new MgmtSwitchConnector object in SLS.

    The MgmtSwitchConnector connector is used by the hms-discovery job to determine which management switch port the node's BMC is connected to. The SLS requires the following information:

    -   The management switch port that the new node's BMC is connected to
    -   `Xname`: The xname for the MgmtSwitchConnector in the form of `xXcCwWjJ`
        -   `X` is the rack number
        -   `C` is the chassis \(standard racks are always chassis 0\)
        -   `W` is the rack U position of the management network leaf switch
        -   `J` is the switch port number
    -   `NodeNics`: The xname of the new node's BMC. This field is an array in the payloads below, but should only contain 1 element.
        -   `VendorName`: this field varies depending on the OEM for the management switch. For example, if the BMC is plugged into port 36 of the switch the following vendor names could apply:
        -   Aruba leaf switches use this format: `1/1/36`
        -   Dell leaf switches use this format: `ethernet1/1/36`
    ```screen
    ncn-m001# curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST --data '{
            "Parent": "x3000c0w14",
            "Xname": "x3000c0w14j36",
            "Type": "comptype_mgmt_switch_connector",
            "Class": "River",
            "TypeString": "MgmtSwitchConnector",
            "ExtraProperties": {
                "NodeNics": [
                    "x3000c0s27b0"
                ],
                "VendorName": "1/1/36"
            }
        }' https://api-gw-service-nmn.local/apis/sls/v1/hardware | jq
    ```

#### Install the Node Hardware in the Rack

3.  Install the new node hardware in the rack and connect power cables, HSN cables, and management network cables \(if it has not already been installed\).

    If the node was added before modifying the SLS, then the node's BMC should have been able to DHCP with Kea, and there will be an unknown MAC address in HSM Ethernet interfaces table.

    Refer to the OEM documentation for the node for information about the hardware installation and cabling.

#### Power on and Boot Compute Node

5.  Power on the node to boot the BMC.

6.  Wait for the hms-discovery cronjob to run, and for DNS to update.

    The hms-discovery cronjob will attempt to identity Node and BMC MAC addresses from the HSM Ethernet interfaces table with the connection information present in SLS to correctly identity the new node.

7.  After roughly 5-10 minutes the node's BMC should be discovered by the HSM, and the node's BMC can be resolved by using its xname in DNS.

    ```screen
    ncn-m001# ping x3000c0s27b0
    ```

8.  Verify that the nodes are enabled in the HSM.

    ```screen
    ncn-m001# cray hsm state components describe x3000c0s27b0n0
    Type = "Node"
    Enabled = **true** 
    State = "Off"
    . . .
    ```

    To verify the node BMC has been discovered by the HSM.

    ```screen
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

9.  Enable each node individually in the HSM database \(in this example, the nodes are `x3000c0s27b1n0-n3`\).

    ```screen
    ncn-m001# cray hsm state components enabled update --enabled true x3000c0s27b1n0
    ncn-m001# cray hsm state components enabled update --enabled true x3000c0s27b0n1
    ncn-m001# cray hsm state components enabled update --enabled true x3000c0s27b0n2
    ncn-m001# cray hsm state components enabled update --enabled true x3000c0s27b0n3
    ```

10. To force rediscovery of the components in rack 3000 \(standard racks are chassis 0\).

    ```screen
    ncn-m001# cray hsm inventory discover create --xnames x3000c0
    ```

11. Verify that discovery has completed.

    ```screen
    ncn-m001# cray hsm inventory redfishEndpoints describe x3000c0
    Type = "ChassisBMC"
    Domain = ""
    MACAddr = "02:13:88:03:00:00"
    Enabled = true
    Hostname = "x3000c0"
    RediscoverOnUpdate = true
    FQDN = "x3000c0"
    User = "root"
    Password = ""
    IPAddress = "10.104.0.76"
    ID = "x3000c0b0"
    
    [DiscoveryInfo]
    LastDiscoveryAttempt = "2020-09-03T19:03:47.989621Z"
    RedfishVersion = "1.2.0"
    LastDiscoveryStatus = **"DiscoverOK"**
    ```

12. Verify that the correct firmware versions for node BIOS, BMC, HSN NICs, GPUs, and so on.

13. If necessary, update the firmware.

    ```screen
    ncn-m001# cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
    ```

    See [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md).

14. Use the Boot Orchestration Service \(BOS\) to power on and boot the nodes.

    Use the appropriate BOS template for the node type.

    ```screen
    ncn-m001# cray bos v1 session create --template-uuid cle-VERSION \
    --operation reboot --limit x3000c0s27b0n0,x3000c0s27b0n1,x3000c0s27b0n2,x3000c0s27b00n3
    ```

15. Verify the chassis status LEDs indicate normal operation.



