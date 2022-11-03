# Add NCN Data

## Topics

* [Description](#description)
* [Prerequisites](#prerequisites)
* [Procedure](#procedure)
  * [Collect information from the NCN](#collect-information-from-the-ncn)
    * [Saving/reloading](#savingreloading)
  * [Collect MAC addresses from the NCN](#collect-mac-addresses-from-the-ncn)
    * [Swapping/moving an NCN](#swappingmoving-an-ncn)
    * [Adding a new NCN](#adding-a-new-ncn)
* [Next step](#next-step)

## Description

Add NCN data to the System Layout Service (SLS), Boot Script Service (BSS), and Hardware State Manager (HSM) as needed, in order to add an NCN to the system.

Scenarios where this procedure is applicable:

* Adding a management NCN that has not previously been in the system:
  * Add an additional NCN to an existing cabinet
  * Add an NCN that is replacing another NCN of the same type and in the same slot
  * Add a new NCN that replaces an NCN removed from the system in a different location
* Adding a management NCN that has been present in the system previously:
  * Add an NCN that was previously removed from the system to move it to a new location

## Prerequisites

* The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../../configure_cray_cli.md).
* The latest CSM documentation is installed on the system. See [Check for latest documentation](../../../update_product_stream/README.md#check-for-latest-documentation).

## Procedure

1. (`ncn-mw#`) Retrieve an API token:

    ```bash
    export TOKEN=$(curl -s -S -d grant_type=client_credentials \
                    -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
                    -o jsonpath='{.data.client-secret}' | base64 -d` \
                    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
                    | jq -r '.access_token')
    ```

### Collect information from the NCN

1. (`ncn-mw#`) Determine the component name (xname) of the NCN, if it has not been determined yet, by
   referring to the HMN tab of the system's SHCD spreadsheet.

   *Sample row from the `HMN` tab of an SHCD file:*

   | Source (J20)    | Source Rack (K20) | Source Location (L20) | (M20) | Parent (N20) | (O20)| Source Port (P20) | Destination (Q20) | Destination Rack (R20) | Destination Location (S20) | (T20) | Destination Port (U20) |
   |:---------------:|:-----------------:|:---------------------:|:-----:|:------------:|:----:|:-----------------:|:-----------------:|:----------------------:|:--------------------------:|:-----:|:----------------------:|
   | `wn01`          | `x3000`           | `u04`                 | `-`   |              |      | `j3`              | `sw-smn01`        | `x3000`                | `u14`                      | `-`   | `j48`                  |

   > The `Source` name for a worker NCN would be in the format `wn01`; master NCNs have format `mn01` and storage NCNs have format `sn01`.

   Node xname format: `xXcCsSbBnN`

   |   |                | SHCD Column to Reference | Description
   | - | -------------- | ------------------------ | -----------
   | X | Cabinet number | Source Rack (K20)        | The Cabinet or rack number containing the Management NCN.
   | C | Chassis number |                          | For air-cooled nodes within a standard rack, the chassis is `0`. If the air-cooled node is within an air-cooled chassis in an EX2500 cabinet, then this should be `4`.
   | S | Slot/Rack U    | Source Location (L20)    | The Slot of the node is determined by the bottom most rack U that node occupies.
   | B | BMC number     |                          | For Management NCNs the BMC number is 0.
   | N | Node number    |                          | For Management NCNs the Node number is 0.

    ```bash
    XNAME=x3000c0s4b0n0
    ```

1. (`ncn-mw#`) **Skip if adding `ncn-m001`:** Determine the NCN BMC xname by removing the trailing
   `n0` from the NCN xname:

    ```bash
    BMC_XNAME=x3000c0s4b0
    ```

1. (`ncn-mw#`) **Skip if adding `ncn-m001`:** Determine the xname of the `MgmtSwitchConnector`
   (the switch port of the management switch that the BMC is connected to). This is not required
   for `ncn-m001`, because its BMC is typically connected to the
   site network.

   *Sample row from the HMN tab of an SHCD:*

   | Source (J20)    | Source Rack (K20) | Source Location (L20) | (M20) | Parent (N20) | (O20)| Source Port (P20) | Destination (Q20) | Destination Rack (R20) | Destination Location (S20) | (T20) | Destination Port (U20) |
   |:---------------:|:-----------------:|:---------------------:|:-----:|:------------:|:----:|:-----------------:|:-----------------:|:----------------------:|:--------------------------:|:-----:|:----------------------:|
   | `wn01`          | `x3000`           | `u04`                 | `-`   |              |      | `j3`              | `sw-smn01`        | `x3000`                | `u14`                      | `-`   | `j48`                  |

   `MgmtSwitchConnector` xname format: `xXcCwWjJ`

   |   |                    | SHCD Column to Reference   | Description
   | - | ------------------ | -------------------------- | ----
   | X | Cabinet number     | Destination Rack (R20)     | The Cabinet or rack number containing the management NCN.
   | C | Chassis number     | | For air-cooled management switches within standard racks, the chassis is `0`. If the air-cooled management switch is within an air-cooled chassis in an EX2500 cabinet, then this should be `4`.
   | W | Slot/Rack U        | Destination Location (S20) | The Slot/Rack U that the management switch occupies.
   | J | Switch port number | Destination Port (U20)     | The switch port on the switch that the NCN BMC is cabled to.

    ```bash
    MGMT_SWITCH_CONNECTOR=x3000c0w14j48
    ```

1. (`ncn-mw#`) **Skip if adding `ncn-m001`:** Determine the xname of the management switch by removing the trailing `jJ` from the `MgmtSwitchConnector` xname.

    ```bash
    MGMT_SWITCH=x3000c0w14
    ```

1. (`ncn-mw#`) **Skip if adding `ncn-m001`:** Collect the BMC MAC address.

   > ***NOTES***
   >
   > * If the NCN was previously in the system, recall the BMC MAC address recorded from the [Remove NCN Data](Remove_NCN_Data.md) procedure.
   > * Alternatively, view the MAC address table on the management switch that the BMC is cabled to.

    1. (`ncn-mw#`) Determine the alias of the management switch that is connected to the BMC.

        ```bash
        cray sls hardware describe "${MGMT_SWITCH}" --format json | jq .ExtraProperties.Aliases[] -r
        ```

       Example output:

        ```text
        sw-leaf-bmc-001
        ```

    1. (`ncn-mw#`) SSH into the management switch that is connected to the BMC.

        ```bash
        ssh admin@sw-leaf-bmc-001.hmn
        ```

    1. (`sw-leaf-bmc#`) Locate the switch port that the BMC is connected to and record its MAC address.

       > In the commands below, change the value of `1/1/39` to match the BMC's actual switch port number
       > (the BMC switch port number is the `J` value in the in the `MgmtSwitchConnector` xname `xXwWjJ`).
       > For example:
       > A `MgmtSwitchConnector` xname of `x3000c0w14j39`, the switch port number would be `39`.
       > In this case,`1/1/39` would be used instead of `1/1/48` in the following commands (`j39=1/1/39`).

        * Dell Management Switch

            ```console
            show mac address-table | grep 1/1/48
            ```

          Example output:

            ```text
            4    a4:bf:01:65:68:54    dynamic        1/1/48
            ```

        * Aruba Management Switch

            ```console
            show mac-address-table | include 1/1/48
            ```

          Example output:

            ```text
            a4:bf:01:65:68:54    4        dynamic                   1/1/48
            ```

1. (`ncn-mw#`) **Skip if adding `ncn-m001`:** Set the `BMC_MAC` environment variable to the BMC MAC address.

    ```bash
    BMC_MAC=a4:bf:01:65:68:54
    ```

1. (`ncn-mw#`) **Skip if adding `ncn-m001`:** Determine the current IP address of the NCN BMC.

    1. Query Kea for the BMC MAC address to determine its current IP address.

        ```bash
        BMC_IP=$(curl -sk -H "Authorization: Bearer ${TOKEN}" -X POST -H "Content-Type: application/json" \
                     -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' \
                     https://api-gw-service-nmn.local/apis/dhcp-kea |
                     jq --arg BMC_MAC "${BMC_MAC}" \
                         '.[].arguments.leases[] | select(."hw-address" == $BMC_MAC)."ip-address"' -r)
        echo ${BMC_IP}
        ```

        Example output:

        ```text
        10.254.1.26
        ```

        > ***Troubleshooting***
        > If the MAC addresses of the BMC are not present in Kea, then check for the following items:
        >
        > 1. Verify that the BMC is powered up and has an active connection to the network.
        > 1. Verify that the BMC is set to DHCP instead of a static IP address.

    1. (`ncn-mw#`) Ping the BMC to see if it is reachable.

        ```bash
        ping "${BMC_IP}"
        ```

1. (`ncn-mw#`) **Perform this step if adding `ncn-m001`, otherwise skip:** Set the `BMC_IP` environment variable to the current IP address or hostname of the BMC. This is not the allocated HMN address for the BMC of `ncn-m001`.

    ```bash
    BMC_IP=10.0.0.10
    ```

1. (`ncn-mw#`) **Perform this step if adding `ncn-m001`, otherwise skip:** At this point the BMC is reachable at a known IP addresses. If adding an NCN that was not previously in the system, then follow the
  [Access and Update the Settings for Replacement NCNs](../Access_and_Update_the_Settings_for_Replacement_NCNs.md) procedure.

#### Saving/Reloading

1. (`ncn-mw#`) Save the currently collected values to a loadable script for reloading.

    ```bash
    mkdir -pv /metal/recovery/scratch
    cat << EOF > /metal/recovery/scratch/${NODE}-env-vars.sh
    #!/bin/bash
    export BMC_XNAME=${BMC_XNAME}
    export BMC_MAC=${BMC_MAC}
    export NODE=${NODE}
    export MGMT_SWITCH_CONNECTOR=${MGMT_SWITCH_CONNECTOR}
    export XNAME=${XNAME}
    EOF 
    ```

1. (`ncn-mw#`) if resuming this procedure, reload the values.

    ```bash
    NODE=ncn-w004
    . "/metal/recovery/scratch/${NODE}-env.vars.sh"
    ```

### Collect MAC addresses from the NCN

The collected MAC addresses will be used with the `add_management_ncn.py` script.

Depending on the hardware present in the NCN, not all of these interfaces may be present. See
[NCN networking for more information](../../../background/ncn_networking.md).

* NCNs will have either two or four management network interfaces split between two PCIe cards for
  redundancy, and will utilize only **two** of their available ports (port 1 of each PCIe card).
* Kubernetes Worker NCNs will have high-speed network (HSN) interfaces in addition to their management network interfaces.
* Storage NCNs have `bond1` members (`sun0` and `sun1`), but only if they have four NICs (port 2 of each PCIe card).

> ***NOTE*** In rare cases, where a PCIe redundancy goal could not be met, an NCN may be observed using two ports off a single PCIe card.
> The plan of record design (as detailed in the [plan of record page](../../../background/ncn_plan_of_record.md)) is to have PCIe redundancy
> in the event that an entire PCIe card fails, the network will still stay up until maintenance can be performed properly. In the event that a single
> PCIe card is used, use the first table below as a reference.

*NCN with a single PCIe card (two cards with one port each for two ports total):*

| Interface   | CLI Flag      | Required MAC Address     | Description
|:----------- |:--------------| ------------------------ |:----------
| `mgmt0`     | `--mac-mgmt0` | Required                 | First MAC address for the MGMT network bond (`bond0`).
| `mgmt1`     | `--mac-mgmt1` | Required                 | Second MAC address for the MGMT network bond (`bond0`).
| `hsn0`      | `--mac-hsn0`  | Required for Worker NCNs | MAC address of the first HSN NIC.
| `hsn1`      | `--mac-hsn1`  | Optional for Worker NCNs | MAC address of the second HSN NIC.
| `lan0`      | `--mac-lan0`  | Optional                 | MAC address for the first site-network.
| `lan1`      | `--mac-lan1`  | Optional                 | MAC address for the second site-network.
| `lan2`      | `--mac-lan2`  | Optional                 | MAC address for the third site-network.
| `lan3`      | `--mac-lan3`  | Optional                 | MAC address for the forth site-network.

*NCN with a dual PCIe cards (two cards with two ports each for four ports total):*

| Interface   | CLI Flag      | Required MAC Address     | Description
|:----------- |:--------------| ------------------------ |:----------
| `mgmt0`     | `--mac-mgmt0` | Required                 | First MAC address for the MGMT network bond (`bond0`).
| `mgmt1`     | `--mac-mgmt1` | Required                 | Second MAC address for the MGMT network bond (`bond0`).
| `sun0`      | `--mac-sun0`  | Required for Storage NCNs| First MAC address for the SUN network bond (`bond1`).
| `sun1`      | `--mac-sun1`  | Required for Storage NCNs| Second MAC address for the SUN network bond (`bond1`).
| `hsn0`      | `--mac-hsn0`  | Required for Worker NCNs | MAC address of the first High Speed Network NIC.
| `hsn1`      | `--mac-hsn1`  | Optional for Worker NCNs | MAC address of the second High Speed Network NIC.
| `lan0`      | `--mac-lan0`  | Optional                 | MAC address for the first site-network.
| `lan1`      | `--mac-lan1`  | Optional                 | MAC address for the second site-network.
| `lan2`      | `--mac-lan2`  | Optional                 | MAC address for the third site-network.
| `lan3`      | `--mac-lan3`  | Optional                 | MAC address for the forth site-network.

1. See [swapping/moving an NCN](#swappingmoving-an-ncn) or [adding a new NCN](#adding-a-new-ncn) depending on the current course of action.

#### Swapping/Moving an NCN

**If the NCN being added is being moved to a new location in the system**, then these MAC addresses
can be retrieved from backup files generated by the [Remove NCN Data](Remove_NCN_Data.md) procedure.

1. Recall the previous node xname of the NCN being added:

    ```bash
    PREVIOUS_XNAME=REPLACE_WITH_OLD_XNAME
    ```

1. Retrieve the MAC address for the NCN from the backup files:

    ```bash
    cat "/tmp/remove_management_ncn/${PREVIOUS_XNAME}/bss-bootparameters-${PREVIOUS_XNAME}.json" |
        jq .[].params -r | tr " " "\n" | grep ifname
    ```

    Example output for a worker node with a single management PCIe NIC card:

    ```text
    ifname=hsn0:50:6b:4b:23:9f:7c
    ifname=lan1:b8:59:9f:d9:9d:e9
    ifname=lan0:b8:59:9f:d9:9d:e8
    ifname=mgmt0:a4:bf:01:65:6a:aa
    ifname=mgmt1:a4:bf:01:65:6a:ab
    ```

1. Using the example output from above, derive the following CLI flags for a worker NCN:

    | Interface | MAC Address         | CLI Flag
    |:--------- |:-------------------:|:--------
    | `mgmt0`   | `a4:bf:01:65:6a:aa` | `--mac-mgmt0=a4:bf:01:65:6a:aa`
    | `mgmt1`   | `a4:bf:01:65:6a:ab` | `--mac-mgmt1=a4:bf:01:65:6a:ab`
    | `lan0`    | `b8:59:9f:d9:9d:e8` | `--mac-lan0=b8:59:9f:d9:9d:e8`
    | `lan1`    | `b8:59:9f:d9:9d:e9` | `--mac-lan1=b8:59:9f:d9:9d:e9`
    | `hsn0`    | `50:6b:4b:23:9f:7c` | `--mac-hsn0=50:6b:4b:23:9f:7c`

#### Adding a new NCN

The NCN MAC addresses need to be collected using the [Collect NCN MAC Addresses](Collect_NCN_MAC_Addresses.md) procedure.

### Add the NCN to BSS, HSM, and SLS

1. (`ncn-mw#`) Perform a dry run of the `add_management_ncn.py` script in order to determine if any validation failures occur:

   > ***NOTE*** Update the following command with the MAC addresses and interfaces that were collected from the NCN.

    * For any NCN that does not have a site-link (e.g. `ncn-m001`):

        ```bash
        cd /usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/
        ./add_management_ncn.py ncn-data \
            --xname "${XNAME}" \
            --alias "${NODE}" \
            --bmc-mgmt-switch-connector "${MGMT_SWITCH_CONNECTOR}" \
            --mac-bmc "${BMC_MAC}" \
            --mac-mgmt0 a4:bf:01:65:6a:aa \
            --mac-mgmt1 a4:bf:01:65:6a:ab \
            --mac-hsn0 50:6b:4b:23:9f:7c \
            --mac-lan0 b8:59:9f:d9:9d:e8 \
            --mac-lan1 b8:59:9f:d9:9d:e9
        ```

    * For any NCN with a site-link (e.g. `ncn-m001`), omit the `--bmc-mgmt-switch-connector` and `--mac-bmc` arguments:

        ```bash
        cd /usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/
        ./add_management_ncn.py ncn-data \
            --xname "${XNAME}" \
            --alias "${NODE}" \
            --mac-mgmt0 a4:bf:01:65:6a:aa \
            --mac-mgmt1 a4:bf:01:65:6a:ab \
            --mac-lan0 b8:59:9f:d9:9d:e8 \
            --mac-lan1 b8:59:9f:d9:9d:e9
        ```

1. (`ncn-mw#`) Run the `add_management_ncn.py` script again, adding the `--perform-changes` argument to the command run in the previous step:

   > ***NOTE*** Depending on the networking configuration of the system the CMN or CAN networks
   > may not be present in SLS network data. No IP addresses will be allocated for networks
   > that do not exist in SLS.

    For example:

    ```bash
    ./add_management_ncn.py ncn-data \
        --xname "${XNAME}" \
        --alias "${NODE}" \
        --bmc-mgmt-switch-connector "${MGMT_SWITCH_CONNECTOR}" \
        --mac-bmc "${BMC_MAC}" \
        --mac-mgmt0 a4:bf:01:65:6a:aa \
        --mac-mgmt1 a4:bf:01:65:6a:ab \
        --mac-hsn0 50:6b:4b:23:9f:7c \
        --mac-lan0 b8:59:9f:d9:9d:e8 \
        --mac-lan1 b8:59:9f:d9:9d:e9 \
        --perform-changes
    ```

    Example output:

    ```text
    ...
    x3000c0s3b0n0 (ncn-m002) has been added to SLS/HSM/BSS
        WARNING The NCN BMC currently has the IP address: 10.254.1.20, and needs to have IP address 10.254.1.13

        =================================
        Management NCN IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        CMN     | 10.103.11.42
        CAN     | 10.102.4.10
        HMN     | 10.254.1.14
        MTL     | 10.1.1.7
        NMN     | 10.252.1.9

        =================================
        Management NCN BMC IP Allocation
        =================================
        Network | IP Address
        --------|-----------
        HMN     | 10.254.1.13
    ```

    > ***Troubleshooting***
    >
    > If the following text is present at the end of the `add_management_ncn.py` script output,
    > then the BMC is not using the assigned IP address. This happens because the BMC requests an IP
    > prior to the NCN data being added, and now that we have added data we need to align the BMC.
    >
    > * Sample output when the BMC has an unexpected IP address.
    >
    > ```text
    > x3000c0s3b0n0 (ncn-m002) has been added to SLS/HSM/BSS
    >     WARNING The NCN BMC currently has the IP address: <$BMC_IP>, and needs to have IP address X.Y.Z.W
    > ```
    >
    > * Restart the BMC to pick up the expected IP address:
    >
    > > `read -s` is used to read the password in order to prevent it from being echoed to the screen or recorded in the shell history.
    >
    > ```bash
    > read -r -s -p "BMC root password: " IPMI_PASSWORD
    > export IPMI_PASSWORD
    > ipmitool -U root -I lanplus -E -H "${BMC_IP}" mc reset cold
    > sleep 60
    > ```

1. (`ncn-mw#`) **Skip if adding `ncn-m001`:** Verify that the BMC is reachable at the expected IP address.

    ```bash
    ping "${NODE}-mgmt"
    ```

   > ***NOTE*** Wait five minutes for Kea and the HSM to sync. If `ping` continues to fail, then re-run the previous step to restart the BMC.

1. (`ncn-mw#`) Restart the REDS deployment.

    ```bash
    kubectl -n services rollout restart deployment cray-reds
    ```

    Expected output:

    ```text
    deployment.apps/cray-reds restarted
    ```

1. (`ncn-mw#`) Wait for REDS to restart.

    ```bash
    kubectl -n services rollout status  deployment cray-reds
    ```

    Expected output:

    ```text
    Waiting for deployment "cray-reds" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "cray-reds" rollout to finish: 1 old replicas are pending termination...
    deployment "cray-reds" successfully rolled out
    ```

1. (`ncn-mw#`) **Skip if adding `ncn-m001`:** Wait for the NCN BMC to get discovered by HSM.

   > ***NOTE*** If the BMC of `ncn-m001` is connected to the site network,
   > then the BMC will not be discovered, because it is not connected via the HMN network.

    ```bash
    watch -n 0.2 "cray hsm inventory redfishEndpoints describe '${BMC_XNAME}' --format json"
    ```

    Wait until the `LastDiscoveryAttempt` field is `DiscoverOK`:

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

    > ***Discovery troubleshooting***
    >
    > The `redfishEndpoint` may cycle between `DiscoveryStarted` and `HTTPsGetFailed` before the endpoint becomes `DiscoverOK`.
    > If the BMC is in `HTTPSGetFailed` for a long period of time, then the following steps may help to determine the cause:
    >
    > 1. (`ncn-mw#`) Verify that the xname of the BMC resolves in DNS.
    >
    >    ```bash
    >    nslookup ${BMC_XNAME}
    >    ```
    >
    >    Expected output:
    >
    >    ```text
    >    Server:    10.92.100.225
    >    Address:   10.92.100.225#53
    >
    >    Name:    x3000c0s38b0.hmn
    >    Address: 10.254.1.13
    >    ```
    >
    > 1. (`ncn-mw#`) Verify that the BMC is reachable at the expected IP address.
    >
    >    ```bash
    >    ping "${NODE}-mgmt"
    >    ```
    >
    > 1. (`ncn-mw#`) Verify that the BMC Redfish `v1/Managers` endpoint is reachable.
    >
    >    ```curl
    >    curl -fk -u root:$IPMI_PASSWORD https://${BMC_XNAME}/redfish/v1/Managers
    >    ```

1. (`ncn-mw#`) Verify that the NCN exists under HSM State Components.

    ```bash
    cray hsm state components describe "${XNAME}" --format toml
    ```

    Example output:

    ```toml
    ID = "x3000c0s11b0n0"
    Type = "Node"
    State = "Off"
    Flag = "OK"
    Enabled = true
    Role = "Management"
    SubRole = "Worker"
    NID = 100006
    NetType = "Sling"
    Arch = "X86"
    Class = "River"
    ```

## Next step

Proceed to [Update Firmware](Update_Firmware.md) or return to the main
[Add, Remove, Replace, or Move NCNs](Add_Remove_Replace_NCNs.md) page.
