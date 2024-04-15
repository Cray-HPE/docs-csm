# Collect NCN MAC Addresses

This procedure can be used to to collect MAC addresses from the NCNs along with their assigned interface names for use with the [Add NCN Data](Add_NCN_Data.md) procedure.
A temporary MAC address collection iPXE bootscript is put into place on the system to discover the MAC addresses of the NCNs, along with their associated interface names (such as `mgmt0`).

**WARNING** This procedure will temporarily break the system's ability to properly boot nodes in the system.

## Prerequisites

This procedure must be performed on a master or worker NCN that has the latest CSM documentation installed.
See [Check for latest documentation](../../../update_product_stream/README.md#check-for-latest-documentation).

## Procedure

1. (`ncn-mw#`) Verify that the `BMC_IP` environment variable is set.

    ```bash
    echo ${BMC_IP}
    ```

1. (`ncn-mw#`) Put the MAC address collection iPXE script in place.

    1. Save a backup of the current iPXE BSS bootscript.

        ```bash
        kubectl -n services get cm cray-ipxe-bss-ipxe -o yaml > cray-ipxe-bss-ipxe.backup.yaml
        ```

    1. Delete the `cray-ipxe-bss-ipxe` Kubernetes ConfigMap.

        ```bash
        kubectl -n services delete cm cray-ipxe-bss-ipxe
        ```

    1. Put the MAC address collection iPXE boot script into place.

        ```bash
        kubectl -n services create cm cray-ipxe-bss-ipxe --from-file=bss.ipxe=/usr/share/doc/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/mac_collection_script.ipxe
        ```

    1. Take note of the last timestamp in the `cray-ipxe` log.

        ```bash
        kubectl -n services logs -l app.kubernetes.io/instance=cms-ipxe
        ```

    1. Wait for the updated iPXE binary to be built.

        ```bash
        sleep 30
        kubectl -n services logs -l app.kubernetes.io/instance=cms-ipxe -f
        ```

        The following output means that a new iPXE binary has been built:

        ```text
        2022-03-17 22:16:14,648 - INFO    - __main__ - Build completed.
        2022-03-17 22:16:14,653 - INFO    - __main__ - Newly created ipxe binary created: '/shared_tftp/ipxe.efi'
        ```

        Wait for a build notification message with a timestamp that is more recent than the timestamp recorded in the previous step.

1. (`ncn-mw#`) Power on node and collect MAC addresses from the NCN.

    1. Verify that the NCN is off.

        > `read -s` is used in order to prevent the password from being echoed to the screen or saved in the shell history.

        ```bash
        read -r -s -p "${BMC_IP} root password: " IPMI_PASSWORD
        export IPMI_PASSWORD
        ipmitool -I lanplus -U root -E -H "${BMC_IP}" chassis power status
        ```

    1. In another terminal, capture the NCN's Serial Over Lan (SOL) console.

        > `read -s` is used in order to prevent the password from being echoed to the screen or saved in the shell history.

        ```bash
        BMC_IP=BMC_IP_ADDRESS
        read -r -s -p "${BMC_IP} root password: " IPMI_PASSWORD
        export IPMI_PASSWORD
        ipmitool -I lanplus -U root -E -H "${BMC_IP}" sol activate
        ```

        > When disconnecting from the IPMI SOL console, use the key sequence `~~.` to exit `ipmitool` without exiting the SSH session.

    1. Set the PXE `efiboot` option.

        ```bash
        ipmitool -I lanplus -U root -E -H "${BMC_IP}" chassis bootdev pxe options=efiboot
        ```

    1. Power on the NCN.

        ```bash
        ipmitool -I lanplus -U root -E -H "${BMC_IP}" chassis power on
        ```

    1. Watch the NCN SOL console and wait for the following output to appear.

        The output below shows the mapping of MAC addresses to interface names (`mgmt0`, `mgmt1`, `hsn0`, `lan0`, etc.).

        ```text
        ====DEVICE NAMING=======================================================
        net0 MAC ec:0d:9a:d4:2b:d8
        net0 is hsn0
        net1 MAC 98:03:9b:bb:a9:94
        net1 is mgmt0
        net2 MAC 98:03:9b:bb:a9:95
        net2 is mgmt1
        MAC Address collection completed. Please power the node off now via ipmitool.
        ```

        Using the above output from the MAC collection iPXE script, derive the following `add_management_ncn.py` script arguments:

        | Interface | MAC Address         | CLI Flag                        |
        |-----------|---------------------|---------------------------------|
        | `mgmt0`   | `98:03:9b:bb:a9:94` | `--mac-mgmt0=98:03:9b:bb:a9:94` |
        | `mgmt1`   | `98:03:9b:bb:a9:95` | `--mac-mgmt1=98:03:9b:bb:a9:95` |
        | `hsn0`    | `ec:0d:9a:d4:2b:d8` | `--mac-hsn0=ec:0d:9a:d4:2b:d8`  |

   1. Power off the NCN.

        ```bash
        ipmitool -I lanplus -U root -E -H "${BMC_IP}" chassis power off
        ```

1. (`ncn-mw#`) Restore the original iPXE bootscript.

    1. Delete the `cray-ipxe-bss-ipxe` Kubernetes ConfigMaps.

        ```bash
        kubectl -n services delete cm cray-ipxe-bss-ipxe
        ```

    1. Put the original iPXE bootscript into place.

        ```bash
        cp -v cray-ipxe-bss-ipxe.backup.yaml cray-ipxe-bss-ipxe.yaml
        yq d -i cray-ipxe-bss-ipxe.yaml metadata.resourceVersion
        yq d -i cray-ipxe-bss-ipxe.yaml metadata.uid
        kubectl -n services apply -f cray-ipxe-bss-ipxe.yaml
        ```

    1. Take note of the last timestamp in the `cray-ipxe` log.

        ```bash
        kubectl -n services logs -l app.kubernetes.io/name=cray-ipxe -c cray-ipxe
        ```

    1. Wait for the updated iPXE binary to be built.

        ```bash
        sleep 30
        kubectl -n services logs -l app.kubernetes.io/name=cray-ipxe -c cray-ipxe -f
        ```

        The following output means that a new iPXE binary has been built.

        ```text
        2022-03-17 22:16:14,648 - INFO    - __main__ - Build completed.
        2022-03-17 22:16:14,653 - INFO    - __main__ - Newly created ipxe binary created: '/shared_tftp/ipxe.efi'
        ```

        Wait for a build notification message with a timestamp that is more recent than the timestamp recorded in the previous step.
