# Collecting NCN MAC Addresses

This procedure will detail how to collect the NCN MAC addresses from an HPE Cray EX system.
The MAC addresses needed for the Bootstrap MAC, Bond0 MAC0, and Bond0 MAC1 columns 
in `ncn_metadata.csv` will be collected. This data will feed into the cloud-init metadata.

The Bootstrap MAC address will be used for identification of this node during the early part of the PXE boot process before the bonded interface can be established.

The `Bond0 MAC0` and `Bond0 MAC1` are the MAC addresses for the physical interfaces that the node will use for the various VLANs.
`Bond0 MAC0` and `Bond0 MAC1` should be on the different network cards in order to establish redundancy for a failed network card.
On the other hand, this is not an absolute requirement. If the node has only a single network card, then this will force `MAC1` and `MAC0` to reside on the same physical card; this will still produce a valid configuration.

## Topics

- [Procedure: iPXE Consoles](#procedure-ipxe-consoles)
   - [MAC Collection](#mac-collection)
- [Procedure: Serial Consoles](#procedure-serial-consoles)

The easy way to do this leverages the NIC-dump provided by the metal-ipxe package.

> The alternative is to use serial cables (or SSH) to collect the MACs from the switch ARP tables, this can become exponentially difficult for large systems.
> If this is the only way, please proceed to the bottom of this page.

## Procedure: iPXE Consoles

This procedure is faster for those with the LiveCD (CRAY Pre-Install Toolkit). It can be used to quickly
boot-check nodes to dump network device information without an operating system. This works by accessing the PCI Configuration Space.

### MAC Collection

1. (`pit#`) Shim the boot so nodes bail after dumping their network devices.

    > **`NOTE`** Removing the iPXE script will prevent network booting. Be aware that the 
    > nodes may disk boot. This will prevent the nodes from continuing to boot and end in undesired states.

    ```bash
    mv -v /var/www/boot/script.ipxe /var/www/boot/script.ipxe.bak
    ```

1. (`pit#`) Verify consoles are active with `conman -q`. The following command lists all nodes that ConMan is configured for,

    ```bash
    conman -q
    ```

1. (`pit#`) Set the nodes to PXE boot and (re)start them.

    ```bash
    export USERNAME=root
    read -s IPMI_PASSWORD
    ```

   ```bash 
   export IPMI_PASSWORD
   grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev pxe options=persistent
   grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev pxe options=efiboot
   grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
   sleep 10
   grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on
   ```

1. (`pit#`) Wait for the nodes to netboot. You can follow them with ConMan - the `-m` option follows the console output in read-only mode or the `-j` option joins an interactive console session. The available node names were listed in step 2 above. The boot usually starts in less than 3 minutes and log data should start flowing through ConMan, speed depends on how quickly your nodes POST. To see a ConMan help screen for all supported escape sequences use `&?`.

   ```bash
   conman -m ncn-m002-mgmt
   ```

1. (`pit#`) Exit ConMan by typing `&.` (e.g. press `&` followed by a `.` (sequentially))

   ```bash
   &.
   ```

1. (`pit#`) Print off what has been found in the console logs, this snippet will omit duplicates from multiple boot attempts:

    ```bash
    for file in /var/log/conman/*; do
        echo $file
        grep -Eoh '(net[0-9] MAC .*)' $file | sort -u | grep PCI && echo -----
    done
    ```

1. (`pit#`) Examine the output from `grep` to identify the MAC address that make up Bond0 for each management NCN. Use the lowest value MAC address per PCIe card.

    > Example: One PCIe card with two ports for a total of two ports per node.

    ```bash
    -----
    /var/log/conman/console.ncn-w003-mgmt
    net2 MAC b8:59:9f:d9:9e:2c PCI.DeviceID 1013 PCI.VendorID 15b3 <-bond0-mac0 (0x2c < 0x2d)
    net3 MAC b8:59:9f:d9:9e:2d PCI.DeviceID 1013 PCI.VendorID 15b3 <-bond0-mac1
    -----
    ```

    The above output identified MAC0 and MAC1 of the bond as b8:59:9f:d9:9e:2c and b8:59:9f:d9:9e:2d respectively.

    > Example: 2 PCIe cards with 2 ports each for a total of 4 ports per node.

    ```text
    -----
    /var/log/conman/console.ncn-w006-mgmt
    net0 MAC 94:40:c9:5f:b5:df PCI.DeviceID 8070 PCI.VendorID 1077 <-bond0-mac0 (0xdf < 0xe0)
    net1 MAC 94:40:c9:5f:b5:e0 PCI.DeviceID 8070 PCI.VendorID 1077 (future use)
    net2 MAC 14:02:ec:da:b9:98 PCI.DeviceID 8070 PCI.VendorID 1077 <-bond0-mac1 (0x98 < 0x99)
    net3 MAC 14:02:ec:da:b9:99 PCI.DeviceID 8070 PCI.VendorID 1077 (future use)
    -----
    ```

    The above output identified `MAC0` and `MAC1` of the bond as `94:40:c9:5f:b5:df` and `14:02:ec:da:b9:99` respectively.

1. (`pit#`) Collect the NCN MAC address for the PIT node. This information will be used to populate the MAC addresses for `ncn-m001`.

   ```bash
   cat /proc/net/bonding/bond0 | grep -i perm 
   ```
   
   For example, the following output should be seen (showing 2 different MACs)

      ```
      Permanent HW addr: b8:59:9f:c7:12:f2 <-bond0-mac0
      Permanent HW addr: b8:59:9f:c7:12:f3 <-bond0-mac1
      ```

1. (`pit#`) Update `ncn_metadata.csv` with the collected MAC addresses for Bond0 from all of the management NCNs.

    ```csv
    > **`NOTE`** Mind the index (3, 2, 1.... ; not 1, 2, 3).

    ```
    vim ncn_metadata.csv
    ```
   
    For each NCN update the corresponding row in `ncn_metadata` with the values for
    Bond0 MAC0 and Bond0 MAC1. The Bootstrap MAC should have the same value as the Bond0 MAC0.

    ```text
    Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
    x3000c0s9b0n0,Management,Worker,94:40:c9:37:77:26,b8:59:9f:c7:12:f2,b8:59:9f:c7:12:f2,b8:59:9f:c7:12:f3
                                                      ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^
                                                      bond0-mac0        bond0-mac0        bond0-mac1
    ```

1. (`pit#`) If the `script.ipxe` file was renamed in the first step of this procedure, restore it to its original location.

    ```bash
    mv -v /var/www/boot/script.ipxe.bak /var/www/boot/script.ipxe
    ```

## Procedure: Serial consoles

Pick out the MAC addresses for the `BOND` from both the `sw-spine-001` and `sw-spine-002` switches, following the [Collecting BMC MAC Addresses](collecting_bmc_mac_addresses.md) procedure.

> **`NOTE`** The node must be booted into an operating system in order for the `Bond` MAC addresses to appear on the spine switches.
>
> A PCIe card with dual-heads may go to either spine switch, meaning `MAC0` must be collected from
> `spine-01`. Refer to the cabling diagram or the actual rack (in-person).

1. Follow `Metadata BMC` on each spine switch that `port1` and `port2` of the bond are plugged into.

1. Usually the 2nd/3rd/4th/Nth MAC on the PCIe card will be a 0x1 or 0x2 deviation from the first port.

   Collection is quicker if this can be easily confirmed.
