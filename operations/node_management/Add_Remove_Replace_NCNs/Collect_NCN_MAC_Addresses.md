# Collect NCN MAC Addresses

## Description
This procedure can be used to to collect MAC addresses from the NCNs along with their assigned interface names for use with the [Add NCN Data](Add_NCN_Data.md) procedure. A temporary MAC address iPXE bootscript is put into place on the system to discover the MAC addresses of the NCNs with their associated interface name (such as mgmt0).

**WARNING** This procedure will temporally break the system's ability to properly boot nodes in the system.

## Procedure

1.  Put the MAC Address collection iPXE script in place:
    1.  Save a backup of the current ipxe BSS bootscript:
        ```bash
        ncn-m# kubectl -n services get cm cray-ipxe-bss-ipxe -o yaml > cray-ipxe-bss-ipxe.backup.yaml
        ```

    2.  Delete the cray-ipxe-bss-ipxe config map:
        ```bash
        ncn-m# kubectl -n services delete cm cray-ipxe-bss-ipxe
        ```
    
    3.  Put the MAC Address collection booscript into place:
        ```bash
        ncn-m# kubectl -n services create cm cray-ipxe-bss-ipxe --from-file=bss.ipxe=/usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/mac_collection_script.ipxe
        ```
    
    4.  Wait for the new iPXE binary to be built:
        ```bash
        ncn-m# kubectl -n services logs  -l app.kubernetes.io/name=cray-ipxe -c cray-ipxe -f
        ```

        The following output means the new ipxe binary has been built:
        ```
        2022-03-17 22:16:14,648 - INFO    - __main__ - Build completed.
        2022-03-17 22:16:14,653 - INFO    - __main__ - Newly created ipxe binary created: '/shared_tftp/ipxe.efi'
        ```
2.  Determine the BMC MAC address:
    > TODO make this the first step, so we require that the BMC MAC address is known before proceeding:
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

    3.  Locate the switch port the BMC is connected to record the MAC Address

        __Dell__
        ```
        sw-leaf-001# show mac address-table | grep ethernet1/1/39
        4	a4:bf:01:65:68:54	dynamic		ethernet1/1/39
        ```

        __Aruba__
        ```
        sw-leaf-001# show mac-address-table | include 1/1/39
        a4:bf:01:65:68:54    4        dynamic                   1/1/39
        ```

    4.  Set the `BMC_MAC` environment variable with the BMC MAC Address:  
        ```bash
        export BMC_MAC=a4:bf:01:65:68:54
        ```


3.  Power on node and collect MAC Addresses from the NCN:
    1.  Determine the BMC IP Address:
        ```bash
        ncn-m# cray hsm inventory ethernetInterfaces list --mac-address $BMC_MAC --format json
        [
            {
                "ID": "a4bf01656337",
                "Description": "",
                "MACAddress": "a4:bf:01:65:63:37",
                "LastUpdate": "2022-03-18T20:18:56.860271Z",
                "ComponentID": "",
                "Type": "",
                "IPAddresses": [
                    {
                        "IPAddress": "10.254.1.28"
                    }
                ]
            }
        ]
        ```

        ```bash
        ncn-m# export BMC_IP=10.254.1.28
        ```

    2.  Verify the NCN is off:
        ```bash
        ncn-m# export IPMI_PASSWORD=changeme
        ncn-m# ipmitool -I lanplus -U root -E -H $BMC_IP chassis power status
        ```

    3.  In another terminal capture the NCN's Serial Over Lan (SOL) console:
        ```bash
        ncn-m# export IPMI_PASSWORD=changeme
        ncn-m# export BMC_IP=10.254.1.28
        ncn-m# ipmitool -I lanplus -U root -E -H $BMC_IP sol activate
        ```

    4.  Power up the NCN:
        ```bash
        ncn-m# ipmitool -I lanplus -U root -E -H $BMC_IP chassis power on
        ```

    5.  Watch the NCN SOL console and wait for the following output to appear. The output below shows the mapping of MAC addresses to interfaces names (mgmt0, mgmt1, hsn0, lan0, etc..)
        ```
        ====DEVICE NAMING=======================================================
        net0 MAC b8:59:9f:d9:9d:a8
        net0 is mgmt0
        net1 MAC b8:59:9f:d9:9d:a9
        net1 is mgmt1
        MAC Address collection completed. Please power the node off now via ipmitool.
        ```

        | Interface | MAC Address         | CLI Flag
        | --------- | ------------------- | -------- 
        | mgmt0     | `b8:59:9f:d9:9d:a8` | `--mac-mgmt0=b8:59:9f:d9:9d:a8`
        | mgmt1     | `b8:59:9f:d9:9d:a9` | `--mac-mgmt1=b8:59:9f:d9:9d:a9`
        
    6.  Power off the NCN:
        ```bash
        ncn-m# ipmitool -I lanplus -U root -E -H $BMC_IP chassis power off
        ```

4. Restore existing iPXE bootscript:
   1.   Delete the cray-ipxe-bss-ipxe config map:
        ```bash
        ncn-m# kubectl -n services delete cm cray-ipxe-bss-ipxe
        ```
    
    1.  Put the MAC Address collection booscript into place:
        ```bash
        ncn-m# kubectl -n services create cm cray-ipxe-bss-ipxe --from-file=bss.ipxe=/usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/mac_collection_script.ipxe
        ```
    
    2.  Wait for the new iPXE binary to be built:
        ```bash
        ncn-m# kubectl -n services logs  -l app.kubernetes.io/name=cray-ipxe -c cray-ipxe -f
        ```

        The following output means the new ipxe binary has been built. Make sure the timestamp in the logs is fairly recent:
        ```
        2022-03-17 22:16:14,648 - INFO    - __main__ - Build completed.
        2022-03-17 22:16:14,653 - INFO    - __main__ - Newly created ipxe binary created: '/shared_tftp/ipxe.efi'
        ```