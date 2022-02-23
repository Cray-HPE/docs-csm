
## Add a Standard Rack Node

These procedures are intended for trained technicians and support personnel only. Always follow ESD precautions when handling this equipment.

-   An authentication token has been retrieved.

    ```bash
    ncn-m001# function get_token () {
        curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token'
    }
    ```

The example is this procedure adds a User Access Node \(UAN\) or compute node to an HPE Cray standard rack system. This example adds a node to rack number 3000 at U27.

Procedures for updating the Hardware State Manager \(HSM\) or System Layout Service \(SLS\) are similar when adding additional compute nodes or User Application Nodes \(UANs\). The contents of the node object in the SLS are slightly different for each node type.

Refer to the OEM documentation for information about the node architecture, installation, and cabling.

For this procedure, a new object must be created in the SLS and modifications will be required to the Slingshot HSN topology.

### Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Procedure

1.  Create a new node object in SLS.

    New node objects require the following information:

    -   `Parent`: component name (xname) of the new node's BMC
    -   `Xname`: component name (xname) of the new node
    -   `Role`: Either `Compute` or `Application`
    -   `Aliases`: Array of aliases for the node, for compute nodes, this is in the form of `nid0000`
    -   NID: The Node ID integer for the node, applies only to compute nodes.
    -   SubRole: Such as `UAN`, `Gateway`, or other valid HSM SubRoles
    -   If adding a compute node:

        ```bash
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

        ```bash
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
    -   `Xname`: The component name (xname) for the MgmtSwitchConnector in the form of `xXcCwWjJ`
        -   `X` is the rack number
        -   `C` is the chassis \(standard racks are always chassis 0\)
        -   `W` is the rack U position of the management network leaf switch
        -   `J` is the switch port number
    -   `NodeNics`: The component name (xname) of the new node's BMC. This field is an array in the payloads below, but should only contain 1 element.
        -   `VendorName`: this field varies depending on the OEM for the management switch. For example, if the BMC is plugged into port 36 of the switch the following vendor names could apply:
        -   Aruba leaf switches use this format: `1/1/36`
        -   Dell leaf switches use this format: `ethernet1/1/36`
    ```bash
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

7.  After roughly 5-10 minutes the node's BMC should be discovered by the HSM, and the node's BMC can be resolved by using its component name (xname) in DNS.

    ```bash
    ncn-m001# ping x3000c0s27b0
    ```

8. Verify that discovery has completed. The 

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x3000c0s27b0
    ```

    Example output:

    ```
    ID = "x3000c0s2b0"
    Type = "NodeBMC"
    Hostname = ""
    Domain = ""
    FQDN = "x3000c0s27b0"
    Enabled = true
    UUID = "990150e5-03bc-58b5-b986-cfd418d5778b"
    User = "root"
    Password = ""
    RediscoverOnUpdate = true

    [DiscoveryInfo]
    LastDiscoveryAttempt = "2021-10-20T21:19:32.332521Z"
    RedfishVersion = "1.6.0"
    LastDiscoveryStatus = **"DiscoverOK"**
    ```

    - When `LastDiscoveryStatus` displays as `DiscoverOK`, the node BMC has been successfully discovered.
    - If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
    - If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed`, then an error has
      occurred during the discovery process.

9.  Verify that the nodes are enabled in the HSM.

    ```bash
    ncn-m001# cray hsm state components describe x3000c0s27b0n0
    ```

    Example output:

    ```
    Type = "Node"
    Enabled = **true**
    State = "Off"
    . . .
    ```

    To verify the node BMC has been discovered by the HSM.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints describe x3000c0s27b0 --format json
    ```

    Example output:

    ```
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

    - When `LastDiscoveryStatus` displays as `DiscoverOK`, the node BMC has been successfully discovered.
    - If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
    - If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed` then an error occurred during the discovery process.

10. Enable the nodes in the HSM database \(in this example, the nodes are `x3000c0s27b1n0-n3`\).

    ```
    ncn-m001# cray hsm state components bulkEnabled update --enabled true \
    --component-ids x3000c0s27b1n0,x3000c0s27b1n1,x3000c0s27b1n2,x3000c0s27b1n3
    ```

11. Verify that the correct firmware versions for node BIOS, BMC, HSN NICs, GPUs, and so on.

12. If necessary, update the firmware.

    ```bash
    ncn-m001# cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
    ```

    See [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md).

13. Use the Boot Orchestration Service \(BOS\) to power on and boot the nodes.

    Use the appropriate BOS template for the node type.

    ```bash
    ncn-m001# cray bos v1 session create --template-uuid cle-VERSION \
    --operation reboot --limit x3000c0s27b0n0,x3000c0s27b0n1,x3000c0s27b0n2,x3000c0s27b00n3
    ```

14. Verify the chassis status LEDs indicate normal operation.



