# Collect NCN MAC Addresses

## Description
This procedure can be used to to collect MAC addresses from the NCNs along with their assigned interface names for use with the [Add NCN Data](Add_NCN_Data.md) procedure. A temporary MAC address collection iPXE bootscript is put into place on the system to discover the MAC addresses of the NCNs with their associated interface name (such as mgmt0).

**WARNING** This procedure will temporally break the system's ability to properly boot nodes in the system.

## Procedure
1.  Verify the BMC_MAC environment variable is set.
    ```bash
    ncn-m# echo $BMC_IP
    ```

2.  Put the MAC Address collection iPXE script in place:
    1.  Save a backup of the current iPXE BSS bootscript:
        ```bash
        ncn-m# kubectl -n services get cm cray-ipxe-bss-ipxe -o yaml > cray-ipxe-bss-ipxe.backup.yaml
        ```

    2.  Delete the cray-ipxe-bss-ipxe ConfigMap:
        ```bash
        ncn-m# kubectl -n services delete cm cray-ipxe-bss-ipxe
        ```
    
    3.  Put the MAC Address collection iPXE booscript into place:
        ```bash
        ncn-m# kubectl -n services create cm cray-ipxe-bss-ipxe --from-file=bss.ipxe=/usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/mac_collection_script.ipxe
        ```
    
    4.  Wait for the updated iPXE binary to be built:
        ```bash
        ncn-m# sleep 30
        ncn-m# kubectl -n services logs -l app.kubernetes.io/name=cray-ipxe -c cray-ipxe -f
        ```

        The following output means the new iPXE binary has been built. Make sure the timestamp in the logs are fairly recent:
        ```
        2022-03-17 22:16:14,648 - INFO    - __main__ - Build completed.
        2022-03-17 22:16:14,653 - INFO    - __main__ - Newly created ipxe binary created: '/shared_tftp/ipxe.efi'
        ```

3.  Power on node and collect MAC Addresses from the NCN:
    1.  Verify the NCN is off:
        ```bash
        ncn-m# export IPMI_PASSWORD=changeme
        ncn-m# ipmitool -I lanplus -U root -E -H $BMC_IP chassis power status
        ```

    2.  In another terminal capture the NCN's Serial Over Lan (SOL) console:
        ```bash
        ncn-m# export BMC_IP=10.254.1.20
        ncn-m# export IPMI_PASSWORD=changeme
        ncn-m# ipmitool -I lanplus -U root -E -H $BMC_IP sol activate
        ```

        > Note when disconnecting from the IPMI SOL console you can perform the key sequence `~~.` to exit ipmitool without exiting your SSH session. 

    4.  Set the PXE/efiboot option:

        ```bash
        ncn-m# ipmitool -I lanplus -U root -E -H $BMC_IP chassis bootdev pxe options=efiboot
        ```

    3.  Power on the NCN:
        ```bash
        ncn-m# ipmitool -I lanplus -U root -E -H $BMC_IP chassis power on
        ```

    4.  Watch the NCN SOL console and wait for the following output to appear. The output below shows the mapping of MAC addresses to interfaces names (mgmt0, mgmt1, hsn0, lan0, etc).
        ```
        ====DEVICE NAMING=======================================================
        net0 MAC ec:0d:9a:d4:2b:d8
        net0 is hsn0
        net1 MAC 98:03:9b:bb:a9:94
        net1 is mgmt0
        net2 MAC 98:03:9b:bb:a9:95
        net2 is mgmt1
        MAC Address collection completed. Please power the node off now via ipmitool.
        ```

        Using the above output from the MAC Collection iPXE script we can derive the following add_management_ncn.py CLI arguments.

        | Interface | MAC Address         | CLI Flag
        | --------- | ------------------- | -------- 
        | mgmt0     | `98:03:9b:bb:a9:94` | `--mac-mgmt0=98:03:9b:bb:a9:94`
        | mgmt1     | `98:03:9b:bb:a9:95` | `--mac-mgmt1=98:03:9b:bb:a9:95`
        | hsn0      | `ec:0d:9a:d4:2b:d8` | `--mac-hsn0=ec:0d:9a:d4:2b:d8`
        
    5.  Power off the NCN:
        ```bash
        ncn-m# ipmitool -I lanplus -U root -E -H $BMC_IP chassis power off
        ```

4. Restore existing iPXE bootscript:
   1.   Delete the cray-ipxe-bss-ipxe config map:
        ```bash
        ncn-m# kubectl -n services delete cm cray-ipxe-bss-ipxe
        ```
    
    1.  Put the original iPXE bootscript into place:
        ```bash
        ncn-m# kubectl -n services apply -f cray-ipxe-bss-ipxe.backup.yaml
        ```
    
    2.  Wait for the updated iPXE binary to be built:
        ```bash
        ncn-m# sleep 30
        ncn-m# kubectl -n services logs -l app.kubernetes.io/name=cray-ipxe -c cray-ipxe -f
        ```

        The following output means the updated iPXE binary has been built. Make sure the timestamp in the logs are fairly recent:
        ```
        2022-03-17 22:16:14,648 - INFO    - __main__ - Build completed.
        2022-03-17 22:16:14,653 - INFO    - __main__ - Newly created ipxe binary created: '/shared_tftp/ipxe.efi'
        ```
