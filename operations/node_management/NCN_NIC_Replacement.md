# NCN NIC Replacement

This procedure is for readding a non-compute node (NCN) after NIC replacement. This is similar to the
[Replace NCN procedure](Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md#replace-ncn-procedure) but many of
the steps can be skipped because only the NIC and its MAC addresses changed.

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

All activities required for site maintenance are complete.

The latest CSM documentation has been installed on the master nodes. See
[Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Procedure

### Collect the New MAC Addresses

This step of the NIC replacement procedure describes how to collect the required MAC addresses of the
interfaces of the new NCN NIC.

The new MAC addresses may be included on a sticker on the NIC card itself. If the new MAC addresses are
already known, continue to [Edit BSS Boot Parameters](#edit-bss-boot-parameters).

For more information about which MAC address belongs to each named interface, see
[NCN networking for more information](../../background/ncn_networking.md)

1. Follow the [Collect NCN MAC Addresses](Add_Remove_Replace_NCNs/Collect_NCN_MAC_Addresses.md) procedure.

### Edit BSS Boot Parameters

1. Identify the MAC addresses in BSS that need to be replaced. These can be retrieved from the existing BSS
boot parameters for the NCN. The MAC addresses that don't match those collected in the previous step are the
ones that need to be updated. Take note of the MAC addresses being replaced they will be needed in the
[Clean Up HSM](#clean-up-hsm) step.

    ```screen
    ncn-m001:~ # export NCN_XNAME=x3004c0s26b0n0
    ncn-m001:~ # cray bss bootparameters list --hosts $NCN_XNAME  --format json | jq .[].params -r | tr " " "\n"  | grep ifname | sort
    ifname=mgmt0:14:02:ec:d9:7b:c8
    ifname=mgmt1:94:40:c9:5f:b6:5c
    ifname=sun0:14:02:ec:d9:7b:c9
    ifname=sun1:94:40:c9:5f:b6:5d
    ```

2. Update BSS with the new MAC addresses identified in
[Collect the New MAC Addresses](#collect-the-new-mac-addresses).

    ```screen
    ncn-m001:~ # PARAMS=$(cray bss bootparameters list --hosts $NCN_XNAME | jq .[].params)
    ncn-m001:~ # NEW_PARAMS=$(echo $PARAMS | \
    sed 's/mgmt0:14:02:ec:d9:7b:c8/mgmt0:14:02:ec:dd:04:48/' | \
    sed 's/mgmt1:94:40:c9:5f:b6:5c/mgmt1:5c:ed:8c:0c:0d:3e/' | \
    sed 's/sun0:14:02:ec:d9:7b:c9/sun0:14:02:ec:dd:04:48/' | \
    sed 's/sun1:94:40:c9:5f:b6:5c/sun1:5c:ed:8c:0c:0d:3f/')
    ncn-m001:~ # echo $NEW_PARAMS
    biosdevname=1 ifname=mgmt1:5c:ed:8c:0c:0d:3e ifname=mgmt0:14:02:ec:dd:04:48 ifname=sun1:5c:ed:8c:0c:0d:3f ifname=sun0:14:02:ec:dd:04:49 pcie_ports=native transparent_hugepage=never console=tty0 console=ttyS0,115200 iommu=pt metal.server=s3://boot-images/ceph/0.3.59/rootfs metal.no-wipe=1 ds=nocloud-net;s=http://10.92.100.81:8888/ rootfallback=LABEL=BOOTRAID initrd=initrd.img.xz root=live:LABEL=SQFSRAID rd.live.ram=0 rd.writable.fsimg=0 rd.skipfsck rd.live.overlay=LABEL=ROOTRAID rd.live.overlay.thin=1 rd.live.overlay.overlayfs=1 rd.luks rd.luks.crypttab=0 rd.lvm.conf=0 rd.lvm=1 rd.auto=1 rd.md=1 rd.dm=0 rd.neednet=0 rd.md.waitclean=1 rd.multipath=0 rd.md.conf=1 rd.bootif=0 hostname=ncn-s004 rd.net.timeout.carrier=120 rd.net.timeout.ifup=120 rd.net.timeout.iflink=120 rd.net.timeout.ipv6auto=0 rd.net.timeout.ipv6dad=0 append nosplash quiet crashkernel=360M log_buf_len=1 rd.retry=10 rd.shell ip=mgmt0:dhcp rd.peerdns=0 rd.net.dhcp.retry=5 psi=1 rd.live.squashimg=rootfs
    ncn-m001:~ # cray bss bootparameters update --hosts $NCN_XNAME --params "${NEW_PARAMS}"
    ```

### Clean Up HSM

1. Delete the old MAC addresses from HSM's ethernet interfaces table.

    ```screen
    ncn-m001:~ # cray hsm inventory ethernetInterfaces delete 1402ecd97bc8
    ncn-m001:~ # cray hsm inventory ethernetInterfaces delete 9440c95fb65c
    ncn-m001:~ # cray hsm inventory ethernetInterfaces delete 1402ecd97bc9
    ncn-m001:~ # cray hsm inventory ethernetInterfaces delete 9440c95fb65d
    ```

2. Rediscover the NCN.

    ```screen
    ncn-m001:~ # export NCN_BMC=x3004c0s26b0
    ncn-m001:~ # cray hsm inventory discover create --xnames $NCN_BMC
    [
      {
        "URI": "/hsm/v1/Inventory/DiscoveryStatus/0"
      }
    ]
    ncn-m001:~ # cray hsm inventory redfishEndpoints describe $NCN_BMC
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

3. Wait for KEA to populate the new HSM entries.

    ```screen
    ncn-m001:~ # cray hsm inventory ethernetInterfaces list --component-id $NCN_XNAME
    ```

### Rebuild the NCN

1. Follow the procedure found here, [Rebuild NCNs](Rebuild_NCNs/Rebuild_NCNs.md), to rebuild the NCN.
