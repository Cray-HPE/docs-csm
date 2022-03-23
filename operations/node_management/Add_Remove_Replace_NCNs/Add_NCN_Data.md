# Add NCN Data

## Description

Add NCN data to System Layout Service (SLS), Boot Script Service (BSS) and Hardware State Manager (HSM)  as needed to add an NCN.

Scenarios where this procedure is applicable:
1. Adding a Management NCN that has not previously been in the system before:
   - Add an additional NCN to an existing cabinet
   - Add an NCN that is being replaced by another NCN of the same type and in the same slot
   - Adding a new NCN that to replace a NCN removed from the system in to a new location

2. Adding a Management NCN that has been previously present in the system before:
   - Adding an NCN that was previously removed from the system to move it to a new location

## Procedure
1.  Retrieve an API token:
    ```bash
    ncn-m# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
            -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
            | jq -r '.access_token')
    ```

2.  Collect the following information from the NCN:
    1.  Determine the xname of the NCN by referring to the HMN of the systems SHCD if it has not been determined yet yet.

        Sample row from the HMN tab of a SHCD:
        | Source (J20)    | Source Rack (K20) | Source Location (L20) | (M20) | Parent (N20) | (O20)| Source Port (P20) | Destination (Q20) | Destination Rack (R20) | Destination Location (S20) | (T20) | Destination Port (U20) |
        | --------------- | ----------------- | --------------------- | ----- | ------------ | ---- | ----------------- | ----------------- | ---------------------- | -------------------------- | ----- | ---------------------- |
        | wn01            | x3000             | u04                   | -     |              |      | j3                | sw-smn01          | x3000                  | u14                        | -     | j48                    |

        Node xname format: xXcCsSbBnN

        |   |                | SHCD Column to reference | Description
        | - | -------------- | ------------------------ | ----------- 
        | X | Cabinet number | SourceRack (K20)         | The Cabinet or rack number containing the Management NCN.
        | C | Chassis number |                          | For air-cooled nodes the chassis is 0.
        | S | Slot/Rack U    | Source Location (L20)    | The Slot of the node is determined by the bottom most rack U that node occupies.
        | B | BMC number     |                          | For Management NCNs the BMC number is 0.
        | N | Node number    |                          | For Management NCNs the Node number is 0.


        ```bash
        ncn-m# export XNAME=x3000c0s4b0n0
        ```
    
    2.  Determine the NCN BMC xname by removing the trailing `n0` from the NCN node xname:
        ```bash
        ncn-m# export BMC_XNAME=x3000c0s4b0
        ```

    3.  Determine the xname of the MgmtSwitchConnector (switch port of the management switch the BMC is connected to). This is not required for ncn-m001, as its BMC is typically connected to the site network.

        Sample row from the HMN tab of a SHCD:
        | Source (J20)    | Source Rack (K20) | Source Location (L20) | (M20) | Parent (N20) | (O20)| Source Port (P20) | Destination (Q20) | Destination Rack (R20) | Destination Location (S20) | (T20) | Destination Port (U20) |
        | --------------- | ----------------- | --------------------- | ----- | ------------ | ---- | ----------------- | ----------------- | ---------------------- | -------------------------- | ----- | ---------------------- |
        | wn01            | x3000             | u04                   | -     |              |      | j3                | sw-smn01          | x3000                  | u14                        | -     | j48                    |

        MgmtSwitchConnector Xname format: xXcCwWjJ
        |   |                    | SHCD Column to reference   | Description
        | - | ------------------ | -------------------------- | ----
        | X | Cabinet number     | Destination Rack (R20)     | The Cabinet or rack number containing the Management NCN. 
        | C | Chassis number     |                            | For air-cooled management switches the chassis is 0.
        | W | Slot/Rack U        | Destination Location (S20) | The Slot/Rack U that the management switch occupies.
        | J | Switch port number | Destination Port (U20)     | The switch port on the switch that the NCN BMC is cabled to.

        ```bash
        ncn-m# export MGMT_SWITCH_CONNECTOR=x3000c0w14j48
        ```

    4.  Determine the xname of the management switch xname by removing the trailing `jJ` from the MgmtSwitchConnector xname:
        ```bash
        ncn-m# export MGMT_SWITCH=x3000c0w14
        ```

    5.  Perform a dry-run of allocating IP addresses for the NCN:
        ```bash
        ./add_management_ncn.py allocate-ips \
            --xname $XNAME \
            --alias $NODE
        ```

    6.  Allocate IP addresses for the NCN in SLS and HSM by adding the `--perform-changes` argument to the command ran in the previous step:

        ```bash
        ./add_management_ncn.py allocate-ips \
            --xname $XNAME \
            --alias $NODE \
            --perform-changes
        ```

    7.  Configure network
        > TODO Placeholder
    
    8.  Collect the BMC MAC Address.
        -   If the NCN was previously in the system recall the record BMC MAC Address recorded from the [Remove NCN Data](Remove_NCN_Data.md) procedure.
        -   If the BMC is reachable by IP, then ipmitool can be used to determine the MAC Address of the BMC:

            For HPE and Gigabyte BMCs:
            ```bash
            ncn-m# export LAN=1
            ```
           
            For Intel BMCs:
            ```bash
            ncn-m# export LAN=3
            ```

            Query the BMC to determine its MAC Address:
            ```bash
            ncn-m# export USERNAME=root
            ncn-m# export IPMI_PASSWORD=changeme
            ncn-m# ipmitool -I lanplus -U $USERNAME -E -H ${NODE}-mgmt lan print $LAN | grep "MAC Address"
            ```

        -   Alternatively view the MAC Address table on the management switch the BMC is cabled to.
            
            1.  Determine the alias of the management switch the BMC is connected to:
                ```bash
                ncn-m# cray sls hardware describe $MGMT_SWITCH --format json | jq .ExtraProperties.Aliases[] -r
                ```

                Example output:
                ```              
                sw-leaf-001
                ```

            2.  SSH into the management switch the BMC is connected to:
                ```
                ssh admin@sw-leaf-001.hmn
                ```

            3.  Locate the switch port the BMC is connected to record the MAC Address. 

                TODO need to explain that the 1/1/39 needs to change.

                __Dell Management Switch__
                ```
                sw-leaf-001# show mac address-table | grep ethernet1/1/39
                ```

                ```
                4	a4:bf:01:65:68:54	dynamic		ethernet1/1/39
                ```

                __Aruba Management Switch__
                ```
                sw-leaf-001# show mac-address-table | include 1/1/39
                ```

                ```
                a4:bf:01:65:68:54    4        dynamic                   1/1/39
                ```

        1.  Set the `BMC_MAC` environment variable with the BMC MAC Address:  
            ```bash
            export BMC_MAC=a4:bf:01:65:68:54
            ```

    9.  Collect NCN MAC Addresses for the following interfaces if they are present. Depending on the hardware present not all of the following interfaces will be present. The collected MAC addresses will be later used in this procedure with the add_management_ncn.py script.

        Depending on the hardware present in the NCN not all of these interfaces may not present.
        -   NCNs will have either 1 or 2 management PCIe NIC cards (2 or 4 PCIe NIC ports). 
        -   It is expected that only worker NCNs have HSN Interfaces.

        __NCN with a single PCIe card (1 card with 2 ports)__
        | Interface | CLI Flag      | Required MAC Address     | Description
        | --------- | ------------- | ------------------------ | ----------
        | mgmt0     | `--mac-mgmt0` | Required                 | First MAC Address of Bond 1
        | mgmt1     | `--mac-mgmt1` | Required                 | Second MAC Address of Bond 0
        | hsn0      | `--mac-hsn0`  | Required for Worker NCNs | MAC Address of the first High Speed Network NIC. Master and Storage NCNs do not have HSN NICs.
        | hsn1      | `--mac-hsn1`  | Optional for Worker NCNs | MAC Address of the second High Speed Network NIC. Master and Storage NCNs do not have HSN NICs.
        | lan0      | `--mac-lan0`  | Optional                 | MAC Address for the first non bond or HSN related interface.
        | lan1      | `--mac-lan1`  | Optional                 | MAC Address for the second non bond or HSN related interface.
        | lan2      | `--mac-lan2`  | Optional                 | MAC Address for the third non bond or HSN related interface.
        | lan3      | `--mac-lan3`  | Optional                 | MAC Address for the forth non bond or HSN related interface.

        __NCN with a dual PCIe cards (2 cards with 2 ports each for 4 ports total)__
        | Interface | CLI Flag      | Required MAC Address     | Description
        | --------- | ------------- | ------------------------ | ----------
        | mgmt0     | `--mac-mgmt0` | Required                 | First MAC Address of Bond 1
        | mgmt1     | `--mac-mgmt1` | Required                 | First MAC Address of Bond 1
        | mgmt2     | `--mac-mgmt2` | Required                 | Second MAC Address of Bond 0
        | mgmt3     | `--mac-mgmt3` | Required                 | Second MAC address of Bond 1
        | hsn0      | `--mac-hsn0`  | Required for Worker NCNs | MAC Address of the first High Speed Network NIC. Master and Storage NCNs do not have HSN NICs.
        | hsn1      | `--mac-hsn1`  | Optional for Worker NCNs | MAC Address of the second High Speed Network NIC. Master and Storage NCNs do not have HSN NICs.
        | lan0      | `--mac-lan0`  | Optional                 | MAC Address for the first non bond or HSN related interface.
        | lan1      | `--mac-lan1`  | Optional                 | MAC Address for the second non bond or HSN related interface.
        | lan2      | `--mac-lan2`  | Optional                 | MAC Address for the third non bond or HSN related interface.
        | lan3      | `--mac-lan3`  | Optional                 | MAC Address for the forth non bond or HSN related interface.

        
        1.  **If the NCN added was previously in the system**, then these MAC addresses can be retrieved backup files generated by the [Remove NCN Data](Remove_NCN_Data.md) procedure.

            ```bash
            ncn-m# cat /tmp/remove_management_ncn/$XNAME/bss-bootparameters-$XNAME.json | jq .[].params -r | tr " " "\n" | grep ifname
            ```

            Sample output for a worker node with a single management PCIe NIC card:
            ```
            ifname=hsn0:50:6b:4b:23:9f:7c
            ifname=lan1:b8:59:9f:d9:9d:e9
            ifname=lan0:b8:59:9f:d9:9d:e8
            ifname=mgmt0:a4:bf:01:65:6a:aa
            ifname=mgmt1:a4:bf:01:65:6a:ab
            ```

            Using the sample output from above we can derive the following CLI flags for a worker NCN:
            | Interface | MAC Address         | CLI Flag
            | --------- | ------------------- | -------- 
            | mgmt0     | `a4:bf:01:65:6a:aa` | `--mac-mgmt0=a4:bf:01:65:6a:aa`
            | mgmt1     | `a4:bf:01:65:6a:ab` | `--mac-mgmt1=a4:bf:01:65:6a:ab`
            | lan0      | `b8:59:9f:d9:9d:e8` | `--mac-lan0=b8:59:9f:d9:9d:e8`
            | lan1      | `b8:59:9f:d9:9d:e9` | `--mac-lan1=b8:59:9f:d9:9d:e9`
            | hsn0      | `50:6b:4b:23:9f:7c` | `--mac-hsn0=50:6b:4b:23:9f:7c`

        2. **Otherwise** the NCN MAC addresses need to be collected using [Collect NCN MAC Addresses](Collect_NCN_MAC_Addresses.md) procedure.
  
3. Perform a dry run of the `add_management_ncn.py` script to determine if any validation failures occur:
    ```bash
    ncn-m# cd /usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/
    ncn-m# ./add_management_ncn.py ncn-data \
        --xname $XNAME \
        --alias $NODE \
        --bmc-mgmt-switch-connector $MGMT_SWITCH_CONNECTOR \
        --mac-bmc $BMC_MAC \
        --mac-mgmt0 a4:bf:01:65:6a:aa \
        --mac-mgmt1 a4:bf:01:65:6a:ab \
        --mac-hsn0 50:6b:4b:23:9f:7c \
        --mac-lan0 b8:59:9f:d9:9d:e8 \
        --mac-lan1 b8:59:9f:d9:9d:e9
    ```
    > For each MAC Address/interfaces that was collected from the NCN append them to the command above

4.  Run the `add_management_ncn.py` script to add the NCN to SLS, HSM and BSS by adding the `--perform-changes` argument to the command ran in the previous step:
    ```bash
    ncn-m# ./add_management_ncn.py ncn-data \
        --xname $XNAME \
        --alias $NODE \
        --bmc-mgmt-switch-connector $MGMT_SWITCH_CONNECTOR \
        --mac-bmc $BMC_MAC \
        --mac-mgmt0 a4:bf:01:65:6a:aa \
        --mac-mgmt1 a4:bf:01:65:6a:ab \
        --mac-hsn0 50:6b:4b:23:9f:7c \
        --mac-lan0 b8:59:9f:d9:9d:e8 \
        --mac-lan1 b8:59:9f:d9:9d:e9 \
        --perform-changes
    ```

    Example output:
    ```
    ...
    x3000c0s3b0n0 (ncn-m002) has been added to SLS/HSM/BSS
        WARNING The NCN BMC currently has the IP address: 10.254.1.20, and needs to have IP Address 10.254.1.13

        =================================
        Management NCN IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        HMN     | 10.254.1.14
        MTL     | 10.1.1.7
        NMN     | 10.252.1.9
        CAN     | 10.102.4.10

        =================================
        Management NCN BMC IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        HMN     | 10.254.1.13
    ```

5.  **If the following was present** at the end of the add_management_ncn.py script output, then the NCN BMC was given an IP address via DHCP and is not at the expected IP address.
    Sample output when the BMC has an unexpected IP address.
    ```
    x3000c0s3b0n0 (ncn-m002) has been added to SLS/HSM/BSS
        WARNING The NCN BMC currently has the IP address: 10.254.1.20, and needs to have IP Address 10.254.1.13
    ```

    Restart the BMC to pick up the expected IP Address:
    ```bash
    ncn-m# export IPMI_PASSWORD=changeme
    ncn-m# ipmitool -U root -I lanplus -E -H 10.254.1.20 mc reset cold
    ncn-m# sleep 60
    ```

6.  Verify the BMC is reachable at the expected IP address
    ```bash
    ncn-m# ping $NODE-mgmt
    ```

7.  Restart the REDS deployment:
    ```
    ncn-m# kubectl -n services rollout restart deployment cray-reds
    ```

    Expected output:
    ```
    deployment.apps/cray-reds restarted
    ```

8.  Wait for REDS to restart:
    ```bash
    ncn-m# kubectl -n services rollout status  deployment cray-reds
    ```

    Expected output:
    ```
    Waiting for deployment "cray-reds" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "cray-reds" rollout to finish: 1 old replicas are pending termination...
    deployment "cray-reds" successfully rolled out
    ```

9.  Wait for the NCN BMC to get discovered by HSM:
    ```bash
    ncn-m# watch -n 0.2 "cray hsm inventory redfishEndpoints describe $BMC_XNAME --format json" 
    ```

    Wait until the LastDiscoveryAttempt field is DiscoverOK:
    ```json
    {
        "ID": "x3000c0s38b0",
        "Type": "NodeBMC",
        "Hostname": "",
        "Domain": "",
        "FQDN": "x3000c0s38b0",
        "Enabled": true,
        "UUID": "cc48551e-ec22-4bef-b8a3-bb3261749a0d",
        "User": "root",
        "Password": "",
        "RediscoverOnUpdate": true,
        "DiscoveryInfo": {
            "LastDiscoveryAttempt": "2022-02-28T22:54:08.496898Z",
            "LastDiscoveryStatus": "DiscoverOK",
            "RedfishVersion": "1.7.0"
        }
    }
    ```
    
    __Discovery troubleshooting__
    The RedfishEndpoint may cycle between DiscoveryStarted and HTTPsGetFailed before the endpoint becomes DiscoverOK. If the BMC is in HTTPSGetFailed for a long period of time verify the following to help determine the cause:
    -   Verify the xname of the BMC resolves in DNS:
        ```bash
        ncn-m# nslookup x3000c0s38b0
        ```

        Expected output:
        ```
        Server:		10.92.100.225
        Address:	10.92.100.225#53

        Name:	x3000c0s38b0.hmn
        Address: 10.254.1.13
        ```
    
    -   Verify the BMC is reachable at the expected IP address:
        ```bash
        ncn-m# ping $NODE-mgmt
        ```

    -   Verify the BMC is configured with the expected:
        ```bash
        ncn-m# curl -k -u root:changeme https://x3000c0s38b0/redfish/v1/Managers
        ```

10. Verify the NCN IPs are populated in HSM EthernetInterfaces using the mgmt0 MAC Address.
    ```bash
    ncn-m# export MGMT0_MAC="98:03:9b:bb:a9:94"
    ncn-m# cray hsm inventory ethernetInterfaces list --mac-address $MGMT0_MAC --format json
    ```

    Expected output:
    ```json
    [
        {
            "ID": "98039bbba994",
            "Description": "",
            "MACAddress": "98:03:9b:bb:a9:94",
            "LastUpdate": "2022-03-09T23:17:18.262772Z",
            "ComponentID": "x3000c0s7b0n0",
            "Type": "Node",
            "IPAddresses": [
                {
                    "IPAddress": "10.252.1.11"
                }
            ]
        }
    ]
    ```
