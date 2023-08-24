# NCN NIC Replacement

This procedure is for readding a non-compute node (NCN) after NIC replacement. This is similar to the
[Replace NCN procedure](Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md#replace-ncn-procedure) but many of
the steps can be skipped because only the NIC and its MAC addresses changed.

* [Prerequisites](#prerequisites)
* [Procedure](#procedure)
  1. [Collect the new MAC addresses](#1-collect-the-new-mac-addresses)
  1. [Edit BSS boot parameters](#2-edit-bss-boot-parameters)
  1. [Clean up HSM](#3-clean-up-hsm)
  1. [Rebuild the NCN](#4-rebuild-the-ncn)

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

All activities required for site maintenance are complete.

The latest CSM documentation has been installed on the master nodes. See
[Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Procedure

### 1. Collect the new MAC addresses

This step of the NIC replacement procedure describes how to collect the required MAC addresses of the
interfaces of the new NCN NIC.

The new MAC addresses may be included on a sticker on the NIC card itself. If the new MAC addresses are
already known, continue to [Edit BSS boot parameters](#2-edit-bss-boot-parameters).

For more information about which MAC address belongs to each named interface, see
[NCN Networking](../../background/ncn_networking.md).

Follow the [Collect NCN MAC Addresses](Add_Remove_Replace_NCNs/Collect_NCN_MAC_Addresses.md) procedure.

### 2. Edit BSS boot parameters

1. (`ncn-m#`) Identify the MAC addresses in BSS that need to be replaced.

    These can be retrieved from the existing BSS boot parameters for the NCN. The MAC addresses that do not match
    those collected in the previous step are the ones that need to be updated. Take note of the MAC addresses being
    replaced they will be needed in the [Clean up HSM](#3-clean-up-hsm) step.

    (`ncn-m#`) Get the current boot parameters from BSS.

    ```screen
    export NCN_XNAME=x3004c0s26b0n0
    cray bss bootparameters list --hosts $NCN_XNAME  --format json | jq .[].params -r | tr " " "\n"  | grep ifname | sort
    ```

    Example output:

    ```screen
    ifname=mgmt0:14:02:ec:d9:7b:c8
    ifname=mgmt1:94:40:c9:5f:b6:5c
    ifname=sun0:14:02:ec:d9:7b:c9
    ifname=sun1:94:40:c9:5f:b6:5d
    ```

1. Update BSS with the new MAC addresses identified in [Collect the new MAC addresses](#1-collect-the-new-mac-addresses).

    1. (`ncn-m#`) Prepare the new boot parameters:

        ```screen
        PARAMS=$(cray bss bootparameters list --hosts $NCN_XNAME | jq .[].params)
        NEW_PARAMS=$(echo $PARAMS | \
                     sed 's/mgmt0:14:02:ec:d9:7b:c8/mgmt0:14:02:ec:dd:04:48/' | \
                     sed 's/mgmt1:94:40:c9:5f:b6:5c/mgmt1:5c:ed:8c:0c:0d:3e/' | \
                     sed 's/sun0:14:02:ec:d9:7b:c9/sun0:14:02:ec:dd:04:48/' | \
                     sed 's/sun1:94:40:c9:5f:b6:5c/sun1:5c:ed:8c:0c:0d:3f/')
        ```

        Example resulting boot parameters:

        ```text
        biosdevname=1 ifname=mgmt1:5c:ed:8c:0c:0d:3e ifname=mgmt0:14:02:ec:dd:04:48 ifname=sun1:5c:ed:8c:0c:0d:3f
        ifname=sun0:14:02:ec:dd:04:49 pcie_ports=native transparent_hugepage=never console=tty0
        console=ttyS0,115200 iommu=pt metal.server=s3://boot-images/ceph/0.3.59/rootfs metal.no-wipe=1
        ds=nocloud-net;s=http://10.92.100.81:8888/ rootfallback=LABEL=BOOTRAID initrd=initrd.img.xz
        root=live:LABEL=SQFSRAID rd.live.ram=0 rd.writable.fsimg=0 rd.skipfsck rd.live.overlay=LABEL=ROOTRAID
        rd.live.overlay.thin=1 rd.live.overlay.overlayfs=1 rd.luks rd.luks.crypttab=0 rd.lvm.conf=0 rd.lvm=1
        rd.auto=1 rd.md=1 rd.dm=0 rd.neednet=0 rd.md.waitclean=1 rd.multipath=0 rd.md.conf=1 rd.bootif=0
        hostname=ncn-s004 rd.net.timeout.carrier=120 rd.net.timeout.ifup=120 rd.net.timeout.iflink=120
        rd.net.timeout.ipv6auto=0 rd.net.timeout.ipv6dad=0 append nosplash quiet crashkernel=360M log_buf_len=1
        rd.retry=10 rd.shell ip=mgmt0:dhcp rd.peerdns=0 rd.net.dhcp.retry=5 psi=1 rd.live.squashimg=rootfs
        ```

    1. (`ncn-m#`) Update BSS:

        ```screen
        cray bss bootparameters update --hosts $NCN_XNAME --params "${NEW_PARAMS}"
        ```

### 3. Clean up HSM

1. (`ncn-m#`) Delete the old MAC addresses from Ethernet interfaces table in
   [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm).

    ```screen
    cray hsm inventory ethernetInterfaces delete 1402ecd97bc8
    cray hsm inventory ethernetInterfaces delete 9440c95fb65c
    cray hsm inventory ethernetInterfaces delete 1402ecd97bc9
    cray hsm inventory ethernetInterfaces delete 9440c95fb65d
    ```

1. (`ncn-m#`) Rediscover the NCN.

    ```screen
    export NCN_BMC=x3004c0s26b0
    cray hsm inventory discover create --xnames $NCN_BMC --format json
    ```

    Example output:

    ```json
    [
      {
        "URI": "/hsm/v1/Inventory/DiscoveryStatus/0"
      }
    ]
    ```

1. (`ncn-m#`) Wait for discovery to complete.

    ```screen
    cray hsm inventory redfishEndpoints describe $NCN_BMC --format json
    ```

    Example output when discovery is complete.

    ```json
    {
      "ID": "x3004c0s26b0",
      "Type": "NodeBMC",
      "Hostname": "",
      "Domain": "",
      "FQDN": "x3004c0s26b0",
      "Enabled": true,
      "UUID": "226fe468-fbbb-566d-b869-d2b915bf05a3",
      "User": "root",
      "Password": "",
      "RediscoverOnUpdate": true,
      "DiscoveryInfo": {
        "LastDiscoveryAttempt": "2023-08-03T02:16:25.556764Z",
        "LastDiscoveryStatus": "DiscoverOK",
        "RedfishVersion": "1.6.0"
      }
    }
    ```

1. (`ncn-m#`) Wait for KEA to populate the new HSM entries.

    ```screen
    cray hsm inventory ethernetInterfaces list --component-id $NCN_XNAME
    ```

### 4. Rebuild the NCN

Refer to the [Rebuild NCNs](Rebuild_NCNs/Rebuild_NCNs.md) procedure.
