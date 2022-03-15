# Add NCN Data

## Description

Add NCN data to System Layout Service (SLS), Hardware Management Services (HMS) and Boot Script Service (BSS) as needed to add an NCN.

Scenarios where this procedure is applicable:
1. Adding a Management NCN that has not previously been in the system before:
   - Add an additional NCN to an existing cabinet (requires ...)
   - Add an NCN that is being replaced by another NCN of the same type and in the same slot
   - Adding a new NCN that to replace a NCN removed from the system in to a new location

2. Adding a Management NCN that has been previously present in the system before:
   - Adding an NCN that was previously removed from the system to move it to a new location

## Perquisites

* If adding a NCN that was not previously in the system follow the [Access and Update the Settings for Replacement NCNs](../Access_and_Update_the_Settings_for_Replacement_NCNs.md).

* The NCN being added is currently rack and cabled into the system.

## Procedure
1.  Collect the following information from the NCN:
    1.  Determine the xname of the NCN by referring to the HMN of the systems SHCD if it has not been determined yet yet.

        Sample row from the HMN tab of a SHCD:
        | Source (J20)    | Source Rack (K20) | Source Location (L20) | (M20) | Parent (N20) | (O20)| Source Port (P20) | Destination (Q20) | Destination Rack (R20) | Destination Location (S20) | (T20) | Destination Port (U20) |
        | --------------- | ----------------- | --------------------- | ----- | ------------ | ---- | ----------------- | ----------------- | ---------------------- | -------------------------- | ----- | ---------------------- |
        | wn01            | x3000             | u04                   | -     |              |      | j3                | sw-smn01          | x3000                  | u14                        | -     | j48                    |

        Xname format: xXcCsSbBnN
        |   |                |                       | Description
        | - | -------------- | --------------------- | ----------- 
        | X | Cabinet number | SourceRack (K20)      |
        | C | Chassis number |                       | For River nodes the chassis is 0.
        | S | Slot/Rack U    | Source Location (L20) | The Slot of the node is determined by the bottom most rack U that node occupies.
        | B | BMC number     |                       | For Management NCNs the BMC number is 0.
        | N | Node number    |                       | For Management NCNs the Node number is 0.


        ```bash
        ncn-m# export XNAME=x3000c0s4b0n0
        ```

    2.  Determine the xname of the MgmtSwitchConnector (switch port of the management switch the BMC is connected to). This is not required for ncn-m001, as its BMC is typically connected to the site network.

        Sample row from the HMN tab of a SHCD:
        | Source (J20)    | Source Rack (K20) | Source Location (L20) | (M20) | Parent (N20) | (O20)| Source Port (P20) | Destination (Q20) | Destination Rack (R20) | Destination Location (S20) | (T20) | Destination Port (U20) |
        | --------------- | ----------------- | --------------------- | ----- | ------------ | ---- | ----------------- | ----------------- | ---------------------- | -------------------------- | ----- | ---------------------- |
        | wn01            | x3000             | u04                   | -     |              |      | j3                | sw-smn01          | x3000                  | u14                        | -     | j48                    |

        Xname format: xXcCwWjJ
        |   |                    |                            |
        | - | ------------------ | -------------------------- | ----
        | X | Cabinet number     | Destination Rack (R20)     |
        | C | Chassis number     |                            | For River management switches the chassis is 0.
        | W | Slot/Rack U        | Destination Location (S20) |
        | J | Switch port number | Destination Port (U20)     |

        ```bash
        ncn-m# export MGMT_SWITCH_CONNECTOR=x3000c0w14j48
        ```

    3.  Collect NCN MAC Addresses for the following interfaces if they are present. Depending on the hardware present not all of the following interfaces will be present.
        | Interface | Description
        | --------- | ----------
        | mgmt0     | First MAC Address of Bond 0
        | mgmt1     | First MAC Address of Bond 1
        | mgmt2     | Second MAC Address of Bond 0
        | mgmt3     | Second MAC address of Bond 1
        | hsn0      | MAC Address of the first Hight Speed Network NIC
        | hsn1      | MAC Address of the second Hight Speed Network NIC
        | lan0      | 
        | lan1      |

        Depending on the hardware present in the NCN not all of these interfaces may not present.
        -   NCNs will have either 2 or 4 management NIC ports.
        -   It is expected that only worker NCNs have HSN Interfaces.

        -   **If the NCN added was previously in the system**, then these MAC addresses can be retrieved backup files generated by the [Remove NCN Data](Remove_NCN_Data.md) procedure.

            ```bash
            ncn-m# cat /tmp/remove_management_ncn/$XNAME/bss-bootparameters-$XNAME.json | jq .[].params -r | tr " " "\n" | grep ifname
            ```

            Sample output:
            ```
            ifname=hsn0:50:6b:4b:23:9f:7c
            ifname=lan1:b8:59:9f:d9:9d:e9
            ifname=lan0:b8:59:9f:d9:9d:e8
            ifname=mgmt0:a4:bf:01:65:6a:aa
            ifname=mgmt1:a4:bf:01:65:6a:ab
            ```

            | Interface | MAC Address         | CLI Flag
            | --------- | ------------------- | -------- 
            | mgmt0     | `a4:bf:01:65:6a:aa` | `--bond0-mac0=a4:bf:01:65:6a:aa`
            | mgmt1     | `a4:bf:01:65:6a:ab` | `--bond0-mac1=a4:bf:01:65:6a:ab`
            | lan0      | `b8:59:9f:d9:9d:e8` | `--mac-lan0=b8:59:9f:d9:9d:e8`
            | lan1      | `b8:59:9f:d9:9d:e9` | `--mac-lan1=b8:59:9f:d9:9d:e9`
            | hsn0      | `50:6b:4b:23:9f:7c` | `--mac-hsn0=50:6b:4b:23:9f:7c`

        - Otherwise the MACs for the NCN needs to be collected from the NCN using [this procedure](TODO)
          

    4.  Collect the BMC MAC Address.
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
            
            TODO
            1.  SSH into the management switch the BMC is connected
            2.  View the MAC Address table on the switch 
            3.  Locate the switch port the BMC is connected to record the MAC Address
                ```
                sw-leaf-bmc-001# show mac address-table | grep ethernet1/1/39
                4	a4:bf:01:65:68:54	dynamic		ethernet1/1/39
                ```
  
2. Perform a dry run of the `add_management_ncn.py` script to determine if any validation failures occur:
   > Need an explanation of the CLI args
    ```bash
    ncn-m# cd /usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/
    ncn-m# ./add_management_ncn.py \
        --xname $XNAME \
        --alias $NODE \
        --bmc-mgmt-switch-connector $MGMT_SWITCH_CONNECTOR \
        --mac-hsn0 50:6b:4b:23:9f:7c \
        --bond0-mac0 a4:bf:01:65:6a:aa \
        --bond0-mac1 a4:bf:01:65:6a:ab \
        --mac-lan0 b8:59:9f:d9:9d:e8 \
        --mac-lan1 b8:59:9f:d9:9d:e9 \
        --mac-bmc TODO
    ```

3.  Run the `add_management_ncn.py` script to add the NCN to SLS, HSM and BSS:
    > TODO Use environment variables for xname and alias
    ```bash
    ncn-m# ./add_management_ncn.py \
        --xname $XNAME \
        --alias $NODE \
        --bmc-mgmt-switch-connector $MGMT_SWITCH_CONNECTOR \
        --mac-hsn0 50:6b:4b:23:9f:7c \
        --bond0-mac0 a4:bf:01:65:6a:aa \
        --bond0-mac1 a4:bf:01:65:6a:ab \
        --mac-lan0 b8:59:9f:d9:9d:e8 \
        --mac-lan1 b8:59:9f:d9:9d:e9 \
        --mac-bmc TODO \
        --perform-changes
    ```

4.  If the following was present at the end of the add_magement_ncn.py script output, then the NCN BMC was given an IP address via DHCP and is not at the expected IP address.
    Sample output when the BMC has an unexpected IP address.
    ```
    x3000c0s3b0n0 (ncn-m002) has been added to SLS/HSM/BSS
        WARNING The NCN BMC currently has the IP address: 10.254.1.20, and needs to have IP Address 10.254.1.13
    ```

    Restart the BMC to pick up the expected IP Address:
    ```bash
    ipmitool -U root -I lanplus -P initial0 -H 10.254.1.20 mc reset cold
    ```

5.  Verify the BMC is reachable at the expected IP address
    ```bash
    ncn-m# ping $NODE-mgmt
    ```

6.  Restart the REDS deployment:
    ```
    ncn-m# kubectl -n services rollout restart deployment cray-reds
    ```

    ```
    deployment.apps/cray-reds restarted
    ```

7.  Wait for REDS to restart:
    ```bash
    ncn-m## kubectl -n services rollout status  deployment cray-reds
    ```

    Example output:
    ```
    Waiting for deployment "cray-reds" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "cray-reds" rollout to finish: 1 old replicas are pending termination...
    deployment "cray-reds" successfully rolled out
    ```

8.  Wait for the NCN BMC to get discovered by HSM:
    ```bash
    ncn-m# export BMC_XNAME=x3000c0s38b0
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
    The RedfishEndpoint may cycle between DiscoveryStarted and HTTPsGetFailed before the endpoint becomes DiscoverOK. If the BMC is in HTTPSGetFailed for a long period of time verify the following to help determine the cause:
    - BMC is reachable at the expected IP address.
    - Credentials are correct

9.  Verify the NCN IPs are populated in HSM EthernetInterfaces using the mgmt0 MAC Address.
    ```bash
    ncn-m# export MGMT0_MAC="98:03:9b:bb:a9:94"
    ncn-m# cray hsm inventory ethernetInterfaces list --mac-address $MGMT0_MAC --format json
    ```

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
