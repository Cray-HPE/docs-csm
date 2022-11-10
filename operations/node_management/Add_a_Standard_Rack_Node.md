# Add a Standard Rack Node

These procedures are intended for trained technicians and support personnel only. Always follow ESD precautions when handling this equipment.

The example is this procedure adds a User Access Node \(UAN\) or compute node to an HPE Cray standard rack system. This example adds a node to rack number 3000 at U27.

Procedures for updating the Hardware State Manager \(HSM\) or System Layout Service \(SLS\) are similar when adding additional compute nodes or User Application Nodes \(UANs\). The contents of the node object in the SLS are slightly different
for each node type.

Refer to the OEM documentation for information about the node architecture, installation, and cabling.

For this procedure, a new object must be created in the SLS and modifications will be required to the Slingshot HSN topology.

## Prerequisites

* The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).
* Knowledge of whether DVS is operating over the Node Management Network (NMN) or the High Speed Network (HSN).
* Blade is being added to an existing liquid-cooled cabinet in the system.
* The Slingshot fabric must be configured with the desired topology for desired state of the blades in the system.
* The System Layout Service (SLS) must have the desired HSN configuration.
* Check the status of the high-speed network (HSN) and record link status before the procedure.

## Procedure

### Step 1: Update SLS with node information

1. (`ncn#`) Retrieve an authentication token.

     ```bash
    export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
                 -d client_id=admin-client \
                 -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                 https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
     ```

1. (`ncn#`) Create a new node object in SLS.

    New node objects require the following information:
    * `Xname`: The component name (xname) for the Node in the form of `xXcCsSbBnN`
      * `xX`: where `X` is the cabinet or rack identification number.
      * `cC`: where `C` is the chassis identification number.
        * If the node is within an air-cooled cabinet, then this should be `0`.
        * If the node is within an air-cooled chassis in an EX2500 cabinet, then this should be `4`.
      * `sS`: where `S` is the lowest slot the node chassis occupies.
      * `bB`: where `B` is the ordinal of the node BMC. This should be `0`.
      * `nN`: where `N` is the ordinal of the node This should be `0`.

    * `Role`: `Compute` or `Application`.
    * `Aliases`: Array of aliases for the node. For compute nodes, this is in the form of `nid000000`
    * NID: The Node ID integer for the node. This applies only to compute nodes.
    * SubRole: Such as `UAN`, `Gateway`, or other valid HSM SubRoles.
        > (`ncn#`) Valid HSM SubRoles can be viewed with the following command. To add additional sub roles to HSM refer to [Add Custom Roles and Subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md#add-custom-roles-and-subroles).
        >
        > ```bash
        > cray hsm service values subrole list --format toml
        > ```
        >
        > Example output:
        >
        > ```toml
        > SubRole = [ "Visualization", "UserDefined", "Master", "Worker", "Storage", "UAN", "Gateway", "LNETRouter",]
        > ```

    * (`ncn#`) If adding a compute node:

        ```bash
        NID=1
        ALIAS=nid000001
        jq -n --arg ALIAS "${ALIAS}" --arg NID "${NID}" '{
            Aliases:[$ALIAS],
            NID: $NID, 
            Role: "Compute"
        }' | tee node_extraproperties.json  
        ```

        Expected output:

        ```json
        {
          "Aliases": [
            "nid000001"
          ],
          "NID": "1",
          "Role": "Compute"
        }
        ```

    * (`ncn#`) If adding a application node:

        ```bash
        SUB_ROLE=UAN
        ALIAS=uan04
        jq -n --arg ALIAS "${ALIAS}" --arg SUB_ROLE "${SUB_ROLE}" '{
            Aliases:[$ALIAS],
            Role: "Application",
            SubRole: $SUB_ROLE
        }' | tee node_extraproperties.json  
        ```

        Expected output:

        ```bash
        {
          "Aliases": [
            "uan04"
          ],
          "Role": "Application",
          "SubRole": "UAN"
        }
        ```

    Create the new object in SLS.

    ```bash
    NODE_XNAME=x3000c0s27b0n0
    cray sls hardware create --xname "${NODE_XNAME}" --class River --extra-properties "$(cat node_extraproperties.json)"
    ```

1. (`ncn#`) Create a new `MgmtSwitchConnector` object in SLS.

    The `MgmtSwitchConnector` connector is used by the `hms-discovery` job to determine which management switch port is connected to the node's BMC. The SLS requires the following information:

    * The management switch port that is connected to the new node's BMC
    * `Xname`: The component name (xname) for the `MgmtSwitchConnector` in the form of `xXcCwWjJ`
      * `xX`: where `X` is the cabinet or rack identification number.
      * `cC`: where `C` is the chassis identification number.
        * If the destination `LeafBMC` switch is within a standard rack, then this should be `0`
        * If the destination `LeafBMC` switch is located within an air-cooled chassis in an EX2500 cabinet, then this should be `4`
      * `wW`: where `W` is the rack U position of the management network leaf switch
      * `jJ`: where `J` is the switch port number

    * `NodeNics`: The component name (xname) of the new node's BMC; this field is an array in the payloads below, but should only contain one element
      * `VendorName`: This field varies depending on the OEM for the management switch; for example, if the BMC is plugged into switch port 36, then the following vendor names could apply:
      * Aruba leaf switches use this format: `1/1/36`
      * Dell leaf switches use this format: `ethernet1/1/36`

    1. Build up the hardware extra properties:

        ```bash
        BMC_XNAME=$(echo "${NODE_XNAME}" | grep -E -o 'x[0-9]+c[0-9]+s[0-9]+b[0-9]+')
        VENDOR_NAME="1/1/36"
        jq -n --arg BMC_XNAME "${BMC_XNAME}" --arg VENDOR_NAME "${VENDOR_NAME}" '{
            NodeNics: [$BMC_XNAME],
            VendorName: $VENDOR_NAME
        }' | tee mgmt_switch_connector_extraproperties.json
        ```

        Expected output:

        ```json
        {
          "NodeNics": [
            "x3000c0s27b0"
          ],
          "VendorName": "1/1/36"
        }
        ```

    1. Create the new object in SLS.

        ```bash
        MGMT_SWITCH_CONNECTOR_XNAME=x3000c0w14j36
        cray sls hardware create --xname "${MGMT_SWITCH_CONNECTOR_XNAME}" --class River --extra-properties "$(cat mgmt_switch_connector_extraproperties.json)"
        ```

1. (`ncn#`) **If adding a UAN application node**, then remove the IP address reservation for the node in the `CAN` or `CHN` networks.

    **Node** If the UAN is being replaced within the same rack slot, then this step can be skipped.

    1. Perform a dry-run:

        ```bash
        /usr/share/doc/csm/scripts/operations/node_management/allocate_uan_ip.py allocate-uan-ip \
            --xname "${NODE_XNAME}"
        ```  

        Example output:

        ```text
        Performing validation checks against SLS
        Called:  GET https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s19b0n0 with params None
                Pass x3000c0s19b0n0 exists in SLS
                Pass node x3000c0s19b0n0 has expected node Role of Application
                Pass node x3000c0s19b0n0 has expected SubRole of UAN
                Pass node x3000c0s19b0n0 has alias of uan01
        WARNING: Gateway not in Subnet for uai_macvlan (possibly supernetting).
        Called:  GET https://api-gw-service-nmn.local/apis/sls/v1/networks with params None
                Allocating UAN node IP address in network CAN
                Allocated IP 10.102.4.144 on the CAN network
                Pass x3000c0s19b0n0 (uan01) does not currently exist in SLS Networks
                Pass allocated IPs for UAN Node x3000c0s19b0n0 (uan01) are not currently in use in SLS Networks
                Skipping network CHN as it does not exist in SLS
        Performing validation checks against HSM
        Called:  GET https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces with params {'IPAddress': IPAddress('10.102.4.144')}
                Pass CHN IP address 10.102.4.144 is not currently in use in HSM Ethernet Interfaces
        Adding UAN IP reservation to bootstrap_dhcp subnet in the CAN network
        {
          "Name": "uan01",
          "IPAddress": "10.102.4.144",
          "Comment": "x3000c0s19b0n0"
        }
        Updating CAN network in SLS with updated IP reservations
        Skipping due to dry run!

        IP Addresses have been allocated for x3000c0s19b0n0 (uan01) and been added to SLS
                Network | IP Address
                --------|-----------
                CAN     | 10.102.4.144
        ```

    1. Apply changes to SLS:

        ```bash
        /usr/share/doc/csm/scripts/operations/node_management/allocate_uan_ip.py allocate-uan-ip \
            --xname "${NODE_XNAME}" \
            --perform-changes
        ```

        Example output:

        ```text
        Performing validation checks against SLS
        Called:  GET https://api-gw-service-nmn.local/apis/sls/v1/hardware/x3000c0s19b0n0 with params None
                Pass x3000c0s19b0n0 exists in SLS
                Pass node x3000c0s19b0n0 has expected node Role of Application
                Pass node x3000c0s19b0n0 has expected SubRole of UAN
                Pass node x3000c0s19b0n0 has alias of uan01
        WARNING: Gateway not in Subnet for uai_macvlan (possibly supernetting).
        Called:  GET https://api-gw-service-nmn.local/apis/sls/v1/networks with params None
                Allocating UAN node IP address in network CAN
                Allocated IP 10.102.4.144 on the CAN network
                Pass x3000c0s19b0n0 (uan01) does not currently exist in SLS Networks
                Pass allocated IPs for UAN Node x3000c0s19b0n0 (uan01) are not currently in use in SLS Networks
                Skipping network CHN as it does not exist in SLS
        Performing validation checks against HSM
        Called:  GET https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/EthernetInterfaces with params {'IPAddress': IPAddress('10.102.4.144')}
                Pass CHN IP address 10.102.4.144 is not currently in use in HSM Ethernet Interfaces
        Adding UAN IP reservation to bootstrap_dhcp subnet in the CAN network
        {
          "Name": "uan01",
          "IPAddress": "10.102.4.144",
          "Comment": "x3000c0s19b0n0"
        }
        Updating CAN network in SLS with updated IP reservations
        Called:  PUT https://api-gw-service-nmn.local/apis/sls/v1/networks/CAN with params None

        IP Addresses have been allocated for x3000c0s19b0n0 (uan01) and been added to SLS
                Network | IP Address
                --------|-----------
                CAN     | 10.102.4.144
        ```

1. **Repeat for each** node present in the blade.

### Step 3: Update SLS with CMC information

**If adding an a Gigabyte dense compute node**, then add the Gigabyte CMC data. **Otherwise, for other node types this step can be skipped**.

1. (`ncn#`) Set `CMC_XNAME` environment variable with the xname of the CMC.

   The xname for the CMC in the form of `xXcCsSbB`
      * `xX`: where `X` is the cabinet or rack identification number.
      * `cC`: where `C` is the chassis identification number.
        * If the node is within an air-cooled cabinet, then this should be `0`.
        * If the node is within an air-cooled chassis in an EX2500 cabinet, then this should be `4`.
      * `sS`: where `S` is the lowest slot the node chassis occupies.
      * `bB`: where `B` is the ordinal of the node BMC. This should be `999`.

    ```bash
    CMC_XNAME=x3000c0s17b999
    ```

1. (`ncn#`) Create a new CMC object in SLS.

    Create the new object in SLS.

    ```bash
    cray sls hardware create --xname "${CMC_XNAME}" --class River
    ```

1. (`ncn#`) Create a new `MgmtSwitchConnector` object in SLS.

    The `MgmtSwitchConnector` connector is used by the `hms-discovery` job to determine which management switch port is connected to the node's BMC. The SLS requires the following information:

    * The management switch port that is connected to the new node's BMC
    * `Xname`: The component name (xname) for the `MgmtSwitchConnector` in the form of `xXcCwWjJ`
      * `xX`: where `X` is the cabinet or rack identification number.
      * `cC`: where `C` is the chassis identification number.
        * If the destination `LeafBMC` switch is within a standard rack, then this should be `0`
        * If the destination `LeafBMC` switch is located within an air-cooled chassis in an EX2500 cabinet, then this should be `4`
      * `wW`: where `W` is the rack U position of the management network leaf switch
      * `jJ`: where `J` is the switch port number

    * `NodeNics`: The component name (xname) of the new node's BMC; this field is an array in the payloads below, but should only contain one element
      * `VendorName`: This field varies depending on the OEM for the management switch; for example, if the BMC is plugged into switch port 36, then the following vendor names could apply:
      * Aruba leaf switches use this format: `1/1/37`
      * Dell leaf switches use this format: `ethernet1/1/37`

    1. Build up the hardware extra properties:

        ```bash
        VENDOR_NAME="1/1/37"
        jq -n --arg CMC_XNAME "${CMC_XNAME}" --arg VENDOR_NAME "${VENDOR_NAME}" '{
            NodeNics: [$CMC_XNAME],
            VendorName: $VENDOR_NAME
        }' | tee cmc_mgmt_switch_connector_extraproperties.json
        ```

        Expected output:

        ```json
        {
          "NodeNics": [
            "x3000c0s17b999"
          ],
          "VendorName": "1/1/37"
        }
        ```

    1. Create the new object in SLS.

        ```bash
        CMC_MGMT_SWITCH_CONNECTOR_XNAME=x3000c0w14j37
        cray sls hardware create --xname "${CMC_MGMT_SWITCH_CONNECTOR_XNAME}" --class River --extra-properties "$(cat cmc_mgmt_switch_connector_extraproperties.json)"
        ```

### Step 4: Install the node hardware in the rack

1. Install the new node hardware in the rack and connect power cables, HSN cables, and management network cables \(if it has not already been installed\).

    If the node was added before modifying the SLS, then the node's BMC should have been able to DHCP with Kea, and there will be an unknown MAC address in the HSM Ethernet interfaces table.

    Refer to the OEM documentation for the node for information about the hardware installation and cabling.

### Step 5: Update management network

Follow the [Added Hardware](../network/management_network/added_hardware.md) procedure in the Management network documentation.

### Step 6: Discover the Node BMC

1. When the node was installed into the rack the node will have powered on, and have started to attempt to DHCP.

1. Wait for the `hms-discovery` cronjob to run, and for DNS to update.

    The `hms-discovery` cronjob will attempt to correctly identity the new node by comparing node and BMC MAC addresses from the HSM Ethernet interfaces table with the connection information present in SLS.

1. (`ncn#`) Set `NODE_XNAME` to the xname of the node.

    ```bash
    NODE_XNAME=x3000c0s27b0n0
    BMC_XNAME=$(echo "${NODE_XNAME}" | grep -E -o 'x[0-9]+c[0-9]+s[0-9]+b[0-9]+')
    ```

1. (`ncn#`) After roughly 5-10 minutes, the node's BMC should be discovered by the HSM, and the node's BMC can be resolved by using its component name (xname) in DNS.

    ```bash
    ping "${BMC_XNAME}"
    ```

1. (`ncn#`) Verify that discovery has completed.

    ```bash
    cray hsm inventory redfishEndpoints describe "${BMC_XNAME}" --format toml
    ```

    Example output:

    ```toml
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
    LastDiscoveryStatus = "DiscoverOK"
    ```

    * When `LastDiscoveryStatus` displays as `DiscoverOK`, the node BMC has been successfully discovered.
    * If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
    * If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed`, then an error has
      occurred during the discovery process.

1. (`ncn#`) Verify that the node BMC has been discovered by the HSM.

    ```bash
    cray hsm inventory redfishEndpoints describe "${BMC_XNAME}" --format json
    ```

    Example output:

    ```json
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

    * When `LastDiscoveryStatus` displays as `DiscoverOK`, the node BMC has been successfully discovered.
    * If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
    * If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed` then an error occurred during the discovery process.

1. (`ncn#`) Verify that the node are enabled in the HSM.

    ```bash
    cray hsm state components describe "${NODE_XNAME}" --format toml
    ```

    Example output (truncated):

    ```toml
    Type = "Node"
    Enabled = true
    State = "Off"
    ```

1. (`ncn#`) Enable the nodes in the HSM database.

     In this example, the nodes are `x3000c0s27b1n0` - `x3000c0s27b1n3`.

    ```bash
    cray hsm state components bulkEnabled update --enabled true \
        --component-ids "${NODE_XNAME}"
    ```

1. **Repeat for each** node present in the blade.

### Step 7: Discover the CMC

1. (`ncn#`) Set `CMC_XNAME` environment variable with the xname of the CMC.

    ```bash
    CMC_XNAME=x3000c0s17b999
    ```

1. (`ncn#`) After roughly 5-10 minutes, the node's BMC should be discovered by the HSM, and the node's BMC can be resolved by using its component name (xname) in DNS.

    ```bash
    ping "${CMC_XNAME}"
    ```

1. (`ncn#`) Verify that discovery has completed.

    ```bash
    cray hsm inventory redfishEndpoints describe "${CMC_XNAME}" --format toml
    ```

    Example output:

    ```toml
    ID = "x3000c0s3b0"
    Type = "NodeBMC"
    Hostname = ""
    Domain = ""
    FQDN = "x3000c0s3b0"
    Enabled = true
    UUID = "fe1ce24e-f3cc-42d9-990b-6a23b7279562"
    User = "root"
    Password = ""
    RediscoverOnUpdate = true

    [DiscoveryInfo]
    LastDiscoveryAttempt = "2022-09-12T15:33:24.317016Z"
    LastDiscoveryStatus = "DiscoverOK"
    RedfishVersion = "1.7.0"
    ```

    * When `LastDiscoveryStatus` displays as `DiscoverOK`, the node BMC has been successfully discovered.
    * If the last discovery state is `DiscoveryStarted` then the BMC is currently being inventoried by HSM.
    * If the last discovery state is `HTTPsGetFailed` or `ChildVerificationFailed`, then an error has
      occurred during the discovery process.

### Step 8: Update firmware

1. Verify that the correct firmware versions are present for node BIOS, BMC, HSN NICs, GPUs, and so on.

1. (`ncn#`) If necessary, update the firmware.

    ```bash
    cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
    ```

    See [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md).

### Step 9: Power on and boot the node

1. Update workload manager configuration to include any newly added compute nodes to the system.

   * **If Slurm is the installed workload manager**, then see section *10.3.1 Add a New or Configure an Existing Slurm Template* in the *`HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX Systems (S-8003)`* to regenerate the Slurm
      configuration to include any new compute nodes added to the system.
   * **If PBS Pro is the installed workload manager**: *Coming soon*

1. (`ncn#`) Use the Boot Orchestration Service \(BOS\) to power on and boot the nodes.

    Use the appropriate BOS template for the node type.

    ```bash
    cray bos session create --template-uuid cle-VERSION \
        --operation reboot --limit x3000c0s27b0n0,x3000c0s27b0n1,x3000c0s27b0n2,x3000c0s27b00n3
    ```

## Troubleshooting

### Check DVS

**These troubleshooting steps are applicable when DVS is operating over the NMN network, and not the HSN network.**

There should be a `cray-cps` pod (the broker), three `cray-cps-etcd` pods and their waiter, and at least one `cray-cps-cm-pm` pod.
Usually there are two `cray-cps-cm-pm` pods, one on `ncn-w002` and one on `ncn-w003` and other worker nodes.

1. (`ncn-mw#`) Verify that the `cray-cps` pods on worker nodes are `Running`.

    ```bash
    kubectl get pods -Ao wide | grep cps
    ```

    Example output:

    ```text
    services   cray-cps-75cffc4b94-j9qzf    2/2  Running   0   42h 10.40.0.57  ncn-w001
    services   cray-cps-cm-pm-g6tjx         5/5  Running   21  41h 10.42.0.77  ncn-w003
    services   cray-cps-cm-pm-kss5k         5/5  Running   21  41h 10.39.0.80  ncn-w002
    services   cray-cps-etcd-knt45b8sjf     1/1  Running   0   42h 10.42.0.67  ncn-w003
    services   cray-cps-etcd-n76pmpbl5h     1/1  Running   0   42h 10.39.0.49  ncn-w002
    services   cray-cps-etcd-qwdn74rxmp     1/1  Running   0   42h 10.40.0.42  ncn-w001
    services   cray-cps-wait-for-etcd-jb95m 0/1  Completed
    ```

1. (`ncn-w#`) SSH to each worker node running CPS/DVS, and run ensure that there are no recurring `"DVS: merge_one"` error messages as shown.

    The error messages indicate that DVS is detecting an IP address change for one of the client nodes.

    ```bash
    dmesg -T | grep "DVS: merge_one"
    ```

    Example output that shows the IP address for `x3000c0s19b1n0` has changed its NMN IP address from `10.252.0.26` to `10.252.0.33`:

    ```text
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#351: New node map entry does not match the existing entry
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#353:   nid: 8 -> 8
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#355:   name: 'x3000c0s19b1n0' -> 'x3000c0s19b1n0'
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#357:   address: '10.252.0.26@tcp99' -> '10.252.0.33@tcp99'
    [Tue Jul 21 13:09:54 2020] DVS: merge_one#358:   Ignoring.
    ```

1. (`ncn-mw#`) **If the `"DVS: merge_one"` error messages is shown**, then the IP address of the node needs to be corrected. This will prevent the need to reload DVS.

    1. Set the following environment variables based on the output collected in the previous step.

        ```bash
        NODE_XNAME=x3000c0s19b1n0
        CURRENT_IP_ADDRESS=10.252.0.33
        DESIRED_IP_ADDRESS=10.252.0.26
        ```

    1. Determine the HSM EthernetInterface entry holding onto the desired IP address.

        ```bash
        cray hsm inventory ethernetInterfaces list --ip-address "${DESIRED_IP_ADDRESS}" --output toml
        ```

        * **If no EthernetInterfaces are found**, then continue on to the next step.

            Example output:

            ```bash
            results = []
            ```

        * **If an EthernetInterface is found**, then it needs to be removed from HSM.

            Example output:

            ```toml
            [[results]]
            ID = "b42e99dfecf0"
            Description = "Ethernet Interface Lan2"
            MACAddress = "b4:2e:99:df:ec:f0"
            LastUpdate = "2022-08-08T10:10:57.527819Z"
            ComponentID = "x3000c0s17b2n0"
            Type = "Node"
            [[results.IPAddresses]]
            IPAddress = "10.252.1.26"
            ```

            1. Record the returned `ID` value into the `EI_ID` environment variable.

                ```bash
                OLD_EI_ID=b42e99dfecf0
                ```

            1. Delete the EthernetInterfaces from HSM.

                ```bash
                cray hsm inventory ethernetInterfaces delete ${OLD_EI_ID}
                ```

    1. Determine the HSM EthernetInterface entry holding onto the current IP address.

        ```bash
        cray hsm inventory ethernetInterfaces list --component-id "${NODE_XNAME}" --ip-address "${CURRENT_IP_ADDRESS}" --output toml
        ```

        Example output:

        ```toml
        [[results]]
        ID = "b42e99dff35f"
        Description = "Ethernet Interface Lan1"
        MACAddress = "b4:2e:99:df:f3:5f"
        LastUpdate = "2022-08-18T16:38:21.13173Z"
        ComponentID = "x3000c0s17b1n0"
        Type = "Node"
        [[results.IPAddresses]]
        IPAddress = "10.252.1.69"
        ```

        Record the returned `ID` value into the `EI_ID` environment variable.

        ```bash
        CURRENT_EI_ID=b42e99dff35f
        ```

    1. Update the EthernetInterface to have the desired IP address:

        ```bash
        cray hsm inventory ethernetInterfaces update "$CURRENT_EI_ID" --component-id "${NODE_XNAME}" --ip-addresses--ip-address "${DESIRED_IP_ADDRESS}"
        ```

1. Reboot the node.

1. (`nid#`) SSH to the node and check each DVS mount.

    ```bash
    mount | grep dvs | head -1
    ```

    Example output:

    ```text
    /var/lib/cps-local/0dbb42538e05485de6f433a28c19e200 on /var/opt/cray/gpu/nvidia-squashfs-21.3 type dvs (ro,relatime,blksize=524288,statsfile=/sys/kernel/debug/dvs/mounts/1/stats,attrcache_timeout=14400,cache,nodatasync,noclosesync,retry,failover,userenv,noclusterfs,killprocess,noatomic,nodeferopens,no_distribute_create_ops,no_ro_cache,loadbalance,maxnodes=1,nnodes=6,nomagic,hash_on_nid,hash=modulo,nodefile=/sys/kernel/debug/dvs/mounts/1/nodenames,nodename=x3000c0s6b0n0:x3000c0s5b0n0:x3000c0s4b0n0:x3000c0s9b0n0:x3000c0s8b0n0:x3000c0s7b0n0)
    ```

### Check the HSN for the affected nodes

1. (`ncn-mw#`) Determine the pod name for the Slingshot fabric manager pod and check the status of the fabric.

    ```bash
    kubectl exec -it -n services $(kubectl get pods --all-namespaces |grep slingshot | awk '{print $2}') -- fmn_status
    ```

#### Check for duplicate IP address entries

1. (`ncn#`) Retrieve an authentication token.

     ```bash
    TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
                 -d client_id=admin-client \
                 -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                 https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
     ```

1. (`ncn#`) Check for duplicate IP address entries in the Hardware State Management Database (HSM).

    Duplicate entries will cause DNS operations to fail.

    1. Verify that each node hostname resolves to one IP address.

        ```bash
        nslookup x1005c3s0b0n0
        ```

        Example output with one IP address resolving:

        ```text
        Server:         10.92.100.225
        Address:        10.92.100.225#53

        Name:   x1005c3s0b0n0
        Address: 10.100.0.26
        ```

    1. Reload the Kea configuration.

        ```bash
        curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" -d '{ "command": "config-reload",  "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea |jq
        ```

        If there are no duplicate IP addresses within HSM, then the following response is expected:

        ```json
        [
            {
            "result": 0,
            "text": "Configuration successful."
            }
        ]
        ```

        If there is a duplicate IP address in the HSM, then an error message similar to the message below will be returned.

        ```text
        [{'result': 1, 'text': "Config reload failed: configuration error using file '/usr/local/kea/cray-dhcp-kea-dhcp4.conf': 
        failed to add new host using the HW address '00:40:a6:83:50:a4 and DUID '(null)' to the IPv4 subnet id '0' for the 
        address 10.100.0.105: There's already a reservation for this address"}]
        ```

1. (`ncn#`) Check for active DHCP leases.

    If there are no DHCP leases, then there is a configuration error.

    ```bash
    curl -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
        -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
    ```

    Example output with no active DHCP leases:

    ```json
    [
      {
        "arguments": {
          "leases": []
        },
        "result": 3,
        "text": "0 IPv4 lease(s) found."
      }
    ]
    ```

1. (`ncn#`) If there are duplicate entries in the HSM as a result of this procedure (`10.100.0.105` in this example), then delete the duplicate entry.

    1. Show the `EthernetInterfaces` for the duplicate IP address:

       ```bash
       cray hsm inventory ethernetInterfaces list --ip-address 10.100.0.105 --format json | jq
       ```

       Example output for an IP address that is associated with two MAC addresses:

       ```json
       [
         {
           "ID": "0040a68350a4",
           "Description": "Node Maintenance Network",
           "MACAddress": "00:40:a6:83:50:a4",
           "IPAddress": "10.100.0.105",
           "LastUpdate": "2021-08-24T20:24:23.214023Z",
           "ComponentID": "x1005c3s0b0n0",
           "Type": "Node"
         },
         {
           "ID": "0040a683639a",
           "Description": "Node Maintenance Network",
           "MACAddress": "00:40:a6:83:63:9a",
           "IPAddress": "10.100.0.105",
           "LastUpdate": "2021-08-27T19:15:53.697459Z",
           "ComponentID": "x1005c3s0b0n0",
           "Type": "Node"
         }
       ]
       ```

    1. Delete the older entry.

       ```bash
       cray hsm inventory ethernetInterfaces delete 0040a68350a4
       ```

1. (`ncn#`) Check DNS.

    ```bash
    nslookup 10.100.0.105
    ```

    Example output:

    ```text
    105.0.100.10.in-addr.arpa        name = nid001032-nmn.
    105.0.100.10.in-addr.arpa        name = nid001032-nmn.local.
    105.0.100.10.in-addr.arpa        name = x1005c3s0b0n0.
    105.0.100.10.in-addr.arpa        name = x1005c3s0b0n0.local.
    ```
