# Removing a Standard rack node from a System

This procedure will remove one or more air-cooled standard node from an HPE Cray EX system.

This procedure is applicable for the following types of standard rack nodes:

* Single node chassis (DL325, DL385, etc...)
* Dual node chassis (Apollo 6500 XL645d, etc...)
* Quad dense node chassis (Gigabyte compute node chassis)

## Prerequisites

* The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).
* Knowledge of whether Data Virtualization Service (DVS) is operating over the Node Management Network (NMN) or the High Speed Network (HSN).
* The Slingshot fabric must be configured with the desired topology for desired state of the blades in the system.
* The System Layout Service (SLS) must have the desired HSN configuration.
* Check the status of the HSN and record link status before the procedure.

## Procedure

### Step 1: Retrieve an API token

1. (`ncn-mw#`) Retrieve an API token.

    ```bash
    export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                -d client_id=admin-client \
                -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

### Step 2: Power down node

1. Use the workload manager (WLM) to drain running jobs from the affected nodes on the blade.

    Refer to the vendor documentation for the WLM for more information.

1. (`ncn#`) Use Boot Orchestration Services (BOS) to shut down the affected nodes in the source blade.

    In this example, `x9000c3s0` is the source blade. Specify the appropriate component name (xname) and BOS
    template for the node type in the following command.

    ```bash
    BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
    cray bos v1 session create --template-uuid $BOS_TEMPLATE --operation shutdown --limit x9000c3s0b0n0,x9000c3s0b0n1,x9000c3s0b1n0,x9000c3s0b1n1
    ```

### Step 3: Remove Data from SLS and HSM

1. (`ncn#`) Set `NODE_XNAME` environment variable with the nodes xname:

    ```bash
    NODE_XNAME=x3000c0s19b0n0
    ```

1. (`ncn#`) Verify the node to be removed is powered off:

    ```bash
    cray capmc get_xname_status create --xnames "${NODE_XNAME}" --format toml
    ```

    Expected output:

    ```toml
    e = 0
    err_msg = ""
    off = [ "x3000c0s19b0n0",]
    ```

1. (`ncn#`) **If the node being removed is an UAN**, then remove the IP address reservation for the node in the `CAN` or `CHN` networks.

    **Node** If the UAN is being replaced within the same rack slot, then this step can be skipped.

   1. Perform a dry-run:

        ```bash
        /usr/share/doc/csm/scripts/operations/node_management/allocate_uan_ip.py allocate-uan-ip \
            --xname "${NODE_XNAME}"
        ```  

        Example output:

        ```text
        ncn-m001:~/rsjostrand/scripts # ./allocate_uan_ip.py  deallocate-uan-ip --xname x3000c0s19b0n0
        Called:  GET https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s19b0n0 with params None
                Pass x3000c0s19b0n0 exists in SLS
                Pass node x3000c0s19b0n0 has expected node Role of Application
                Pass node x3000c0s19b0n0 has expected SubRole of UAN
                Pass node x3000c0s19b0n0 has alias of uan01
        WARNING: Gateway not in Subnet for uai_macvlan (possibly supernetting).
        Called:  GET https://api-gw-service-nmn.local/apis/sls/v1/networks with params None
                Removing existing UAN node IP Reservation in subnet bootstrap_dhcp of network CAN: {'Name': 'uan01', 'IPAddress': '10.102.4.144', 'Comment': 'x3000c0s19b0n0'}
                Skipping network CHN as it does not exist in SLS
        Updating CAN network in SLS with updated IP reservations
        Skipping due to dry run!
        ```

      1. Apply changes to SLS:

        ```bash
        /usr/share/doc/csm/scripts/operations/node_management/allocate_uan_ip.py deallocate-uan-ip \
            --xname "${NODE_XNAME}" \
            --perform-changes
        ```

        Example output:

        ```text
        Called:  GET https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s19b0n0 with params None
                Pass x3000c0s19b0n0 exists in SLS
                Pass node x3000c0s19b0n0 has expected node Role of Application
                Pass node x3000c0s19b0n0 has expected SubRole of UAN
                Pass node x3000c0s19b0n0 has alias of uan01
        WARNING: Gateway not in Subnet for uai_macvlan (possibly supernetting).
        Called:  GET https://api-gw-service-nmn.local/apis/sls/v1/networks with params None
                Removing existing UAN node IP Reservation in subnet bootstrap_dhcp of network CAN: {'Name': 'uan01', 'IPAddress': '10.102.4.144', 'Comment': 'x3000c0s19b0n0'}
                Skipping network CHN as it does not exist in SLS
        Updating CAN network in SLS with updated IP reservations
        Called:  PUT https://api-gw-service-nmn.local/apis/sls/v1/networks/CAN with params None
                ```

1. (`ncn#`) Remove node data:

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/remove_standard_rack_node.sh "${NODE_XNAME}"
    ```

    Example output:

    ```text
    ==================================================
    Xname Summary
    ==================================================
    Node:          x3000c0s19b0n0
    NodeBMC:       x3000c0s19b0
    NodeEnclosure: x3000c0s19e0

    ==================================================
    Verifying BMC exists as a RedfishEndpoint in HSM
    ==================================================
    {
      "ID": "x3000c0s19b0",
      "Type": "NodeBMC",
      "Hostname": "x3000c0s19b0",
      "Domain": "",
      "FQDN": "x3000c0s19b0",
      "Enabled": true,
      "UUID": "92d4acf5-a95a-4908-97e7-cdd8d269f540",
      "User": "root",
      "Password": "",
      "MACAddr": "a4bf0138ed46",
      "RediscoverOnUpdate": true,
      "DiscoveryInfo": {
        "LastDiscoveryAttempt": "2022-09-05T16:09:57.620526Z",
        "LastDiscoveryStatus": "DiscoverOK",
        "RedfishVersion": "1.1.0"
      }
    }

    ==================================================
    Removing BMC Event subscriptions
    ==================================================
    Clearing subscriptions from NodeBMC x3000c0s19b0
    Retrieving BMC (x3000c0s19b0) credentials from SCSD
    {'Targets': [{'Xname': 'x3000c0s19b0', 'Username': 'root', 'Password': 'initial0', 'StatusCode': 200, 'StatusMsg': 'OK'}]}
    Retrieving Redfish Event subscriptions from the BMC: https://x3000c0s19b0/redfish/v1/EventService/Subscriptions
    No event subscriptions present!

    ==================================================
    Removing node data from SLS
    ==================================================
    Deleting MmgtSwitchConnector from SLS: x3000c0w25j37
    {
      "Parent": "x3000c0w25",
      "Xname": "x3000c0w25j37",
      "Type": "comptype_mgmt_switch_connector",
      "Class": "River",
      "TypeString": "MgmtSwitchConnector",
      "LastUpdated": 1662392014,
      "LastUpdatedTime": "2022-09-05 15:33:34.496642 +0000 +0000",
      "ExtraProperties": {
        "NodeNics": [
          "x3000c0s19b0"
        ],
        "VendorName": "ethernet1/1/37"
      }
    }
    code = 0
    message = "deleted entry and its descendants"

    Deleting Node from SLS: x3000c0s19b0n0
    {
      "Parent": "x3000c0s19b0",
      "Xname": "x3000c0s19b0n0",
      "Type": "comptype_node",
      "Class": "River",
      "TypeString": "Node",
      "LastUpdated": 1662392014,
      "LastUpdatedTime": "2022-09-05 15:33:34.496642 +0000 +0000",
      "ExtraProperties": {
        "Aliases": [
          "uan01"
        ],
        "Role": "Application",
        "SubRole": "UAN"
      }
    }
    code = 0
    message = "deleted entry and its descendants"


    ==================================================
    Removing node data from HSM
    ==================================================
    Deleting component from HSM State Components: x3000c0s19b0n0
    {
      "ID": "x3000c0s19b0n0",
      "Type": "Node",
      "State": "Off",
      "Flag": "OK",
      "Enabled": true,
      "Role": "Application",
      "SubRole": "UAN",
      "NID": 49168992,
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River"
    }
    code = 0
    message = "deleted 1 entry"

    Deleting component from HSM State Components: x3000c0s19b0
    {
      "ID": "x3000c0s19b0",
      "Type": "NodeBMC",
      "State": "Ready",
      "Flag": "OK",
      "Enabled": true,
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River"
    }
    code = 0
    message = "deleted 1 entry"

    Deleting component from HSM State Components: x3000c0s19e0
    {
      "ID": "x3000c0s19e0",
      "Type": "NodeEnclosure",
      "State": "Off",
      "Flag": "Warning",
      "Enabled": true,
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River"
    }
    code = 0
    message = "deleted 1 entry"

    Deleting Node MAC address: a4bf0138ed42
    {
      "ID": "a4bf0138ed42",
      "Description": "Missing interface 1, MAC computed via workaround",
      "MACAddress": "a4:bf:01:38:ed:42",
      "LastUpdate": "2022-09-05T16:09:57.641759Z",
      "ComponentID": "x3000c0s19b0n0",
      "Type": "Node",
      "IPAddresses": []
    }
    code = 0
    message = "deleted 1 entry"

    Deleting Node MAC address: a4bf0138ed43
    {
      "ID": "a4bf0138ed43",
      "Description": "Missing interface 2, MAC computed via workaround",
      "MACAddress": "a4:bf:01:38:ed:43",
      "LastUpdate": "2022-09-05T16:09:57.641759Z",
      "ComponentID": "x3000c0s19b0n0",
      "Type": "Node",
      "IPAddresses": []
    }
    code = 0
    message = "deleted 1 entry"

    Deleting BMC MAC address: a4bf0138ed46
    {
      "ID": "a4bf0138ed46",
      "Description": "",
      "MACAddress": "a4:bf:01:38:ed:46",
      "LastUpdate": "2022-09-05T16:06:10.381742Z",
      "ComponentID": "x3000c0s19b0",
      "Type": "NodeBMC",
      "IPAddresses": [
        {
          "IPAddress": "10.254.1.28"
        }
      ]
    }
    code = 0
    message = "deleted 1 entry"

    Deleting BMC MAC address: a4bf0138ed44
    {
      "ID": "a4bf0138ed44",
      "Description": "Network Interface on the Baseboard Management Controller",
      "MACAddress": "a4:bf:01:38:ed:44",
      "LastUpdate": "2022-09-05T16:09:57.641759Z",
      "ComponentID": "x3000c0s19b0",
      "Type": "NodeBMC",
      "IPAddresses": []
    }
    code = 0
    message = "deleted 1 entry"

    Deleting BMC MAC address: a4bf0138ed45
    {
      "ID": "a4bf0138ed45",
      "Description": "Network Interface on the Baseboard Management Controller",
      "MACAddress": "a4:bf:01:38:ed:45",
      "LastUpdate": "2022-09-05T16:09:57.641759Z",
      "ComponentID": "x3000c0s19b0",
      "Type": "NodeBMC",
      "IPAddresses": []
    }
    code = 0
    message = "deleted 1 entry"

    Deleting RedfishEndpoint from HSM: x3000c0s19b0
    {
      "ID": "x3000c0s19b0",
      "Type": "NodeBMC",
      "Hostname": "x3000c0s19b0",
      "Domain": "",
      "FQDN": "x3000c0s19b0",
      "Enabled": true,
      "UUID": "92d4acf5-a95a-4908-97e7-cdd8d269f540",
      "User": "root",
      "Password": "",
      "MACAddr": "a4bf0138ed46",
      "RediscoverOnUpdate": true,
      "DiscoveryInfo": {
        "LastDiscoveryAttempt": "2022-09-05T16:09:57.620526Z",
        "LastDiscoveryStatus": "DiscoverOK",
        "RedfishVersion": "1.1.0"
      }
    }
    code = 0
    message = "deleted 1 entry"
    ```

1. **Repeat for each** node being removed on the blade.

### Step 4: Remove Gigabyte CMC

**If removing an a Gigabyte dense compute node** remove the Gigabyte CMC data. **Otherwise, for other node types this step can be skipped**.

1. (`ncn#`) Set `CMC_XNAME` environment variable with the xname of the CMC.

    ```bash
    CMC_XNAME=x3000c0s17b999
    ```

1. (`ncn#`) Remove the Gigabyte CMC data.

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/remove_gigabyte_cmc.sh "${CMC_XNAME}"
    ```

    Example output:

    ```bash
    ==================================================
    Xname Summary
    ==================================================
    CMC: x3000c0s17b999

    ==================================================
    Removing CMC data from SLS
    ==================================================
    Verifying CMC exists in SLS hardware: x3000c0s17b999
    {
      "Parent": "x3000",
      "Xname": "x3000c0s17b999",
      "Type": "comptype_chassis_bmc",
      "Class": "River",
      "TypeString": "ChassisBMC",
      "LastUpdated": 1663264176,
      "LastUpdatedTime": "2022-09-15 17:49:36.469256 +0000 UTC"
    }
    CMC exists: x3000c0s17b999
    Deleting CMC from SLS: x3000c0s17b999
    {
      "Parent": "x3000",
      "Xname": "x3000c0s17b999",
      "Type": "comptype_chassis_bmc",
      "Class": "River",
      "TypeString": "ChassisBMC",
      "LastUpdated": 1663264176,
      "LastUpdatedTime": "2022-09-15 17:49:36.469256 +0000 UTC"
    }
    code = 0
    message = "deleted entry and its descendants"

    Deleting MgmtSwitchConnector from SLS: x3000c0w14j32
    {
      "Parent": "x3000c0w14",
      "Xname": "x3000c0w14j32",
      "Type": "comptype_mgmt_switch_connector",
      "Class": "River",
      "TypeString": "MgmtSwitchConnector",
      "LastUpdated": 1663264176,
      "LastUpdatedTime": "2022-09-15 17:49:36.469256 +0000 UTC",
      "ExtraProperties": {
        "NodeNics": [
          "x3000c0s17b999"
        ],
        "VendorName": "1/1/32"
      }
    }
    code = 0
    message = "deleted entry and its descendants"


    ==================================================
    Removing node data from HSM
    ==================================================
    Disabling Redfish Endpoint in HSM: x3000c0s17b999
    ID = "x3000c0s17b999"
    Type = "NodeBMC"
    Hostname = "x3000c0s17b999"
    Domain = ""
    FQDN = "x3000c0s17b999"
    Enabled = false
    UUID = "009ea76e-debf-0010-ef03-b42e99bdd255"
    User = "root"
    Password = ""
    MACAddr = "b42e99bdd255"
    RediscoverOnUpdate = true

    [DiscoveryInfo]
    LastDiscoveryAttempt = "2022-08-08T10:11:10.208211Z"
    LastDiscoveryStatus = "DiscoverOK"
    RedfishVersion = "1.7.0"

    Deleting component from HSM State Components: x3000c0s17b999
    {
      "ID": "x3000c0s17b999",
      "Type": "NodeBMC",
      "State": "Empty",
      "Flag": "OK",
      "Enabled": true,
      "NetType": "Sling",
      "Arch": "X86",
      "Class": "River"
    }
    code = 0
    message = "deleted 1 entry"

    Deleting CMC MAC address: b42e99bdd255
    {
      "ID": "b42e99bdd255",
      "Description": "",
      "MACAddress": "b4:2e:99:bd:d2:55",
      "LastUpdate": "2022-08-08T10:07:01.928963Z",
      "ComponentID": "x3000c0s17b999",
      "Type": "NodeBMC",
      "IPAddresses": [
        {
          "IPAddress": "10.254.1.42"
        }
      ]
    }
    code = 0
    message = "deleted 1 entry"

    Deleting CMC MAC address: 0234e854d178
    {
      "ID": "0234e854d178",
      "Description": "Ethernet Interface usb0",
      "MACAddress": "02:34:e8:54:d1:78",
      "LastUpdate": "2022-08-08T10:11:10.210893Z",
      "ComponentID": "x3000c0s17b999",
      "Type": "NodeBMC",
      "IPAddresses": []
    }
    code = 0
    message = "deleted 1 entry"

    Deleting RedfishEndpoint from HSM: x3000c0s17b999
    {
      "ID": "x3000c0s17b999",
      "Type": "NodeBMC",
      "Hostname": "x3000c0s17b999",
      "Domain": "",
      "FQDN": "x3000c0s17b999",
      "Enabled": false,
      "UUID": "009ea76e-debf-0010-ef03-b42e99bdd255",
      "User": "root",
      "Password": "",
      "MACAddr": "b42e99bdd255",
      "RediscoverOnUpdate": true,
      "DiscoveryInfo": {
        "LastDiscoveryAttempt": "2022-08-08T10:11:10.208211Z",
        "LastDiscoveryStatus": "DiscoverOK",
        "RedfishVersion": "1.7.0"
      }
    }
    code = 0
    message = "deleted 1 entry"
    ```

### Step 5: Remove the blade

The node can now be physically removed from the system.
