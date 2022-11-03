# Collecting NCN MAC Addresses

This procedure details how to collect the NCN MAC addresses from an HPE Cray EX system.
The MAC addresses needed for the `Bootstrap MAC`, `Bond0 MAC0`, and `Bond0 MAC1` columns
in `ncn_metadata.csv` will be collected. This data will feed into the `cloud-init` metadata.

The `Bootstrap MAC` address will be used for identification of this node during the early part of the PXE boot process,
before the bonded interface can be established.

`Bond0 MAC0` and `Bond0 MAC1` are the MAC addresses for the physical interfaces that the node will use for the various VLANs.
`Bond0 MAC0` and `Bond0 MAC1` should be on different network cards in order to establish redundancy for a failed network card.
On the other hand, this is not an absolute requirement. If the node has only a single network card, then this will force `MAC1` and `MAC0` to reside on the same physical card;
while not optimal, this will still produce a valid configuration.

## Topics

- [Procedure: iPXE consoles](#procedure-ipxe-consoles)
  - [MAC address collection](#mac-address-collection)
- [Procedure: Serial consoles](#procedure-serial-consoles)

The easy way to do this leverages the NIC dump provided by the `metal-ipxe` package on the LiveCD. This option is
outlined in [Procedure: iPXE consoles](#procedure-ipxe-consoles).

The alternative is to use serial cables (or SSH) to collect the MAC addresses from the switch ARP tables.
This can become exponentially difficult for large systems, and is not recommended. This option is outlined
in [Procedure: Serial consoles](#procedure-serial-consoles).

## Procedure: iPXE consoles

This procedure is faster for those with the LiveCD (CRAY Pre-Install Toolkit). It can be used to quickly
boot-check nodes to dump network device information without an operating system. This works by accessing the PCI configuration space.

### MAC address collection

1. (`pit#`) Modify the boot so that nodes stop network booting after dumping their network devices.

    > ***NOTE*** Removing the iPXE script will prevent network booting. Be aware that the
    > nodes may still disk boot.

    ```bash
    mv -v /var/www/boot/script.ipxe /var/www/boot/script.ipxe.bak
    ```

1. (`pit#`) Verify that consoles are active with `conman -q`.

    The following command lists all nodes that ConMan is configured to monitor.

    ```bash
    conman -q
    ```

1. (`pit#`) Set the nodes to PXE boot and restart them.

    1. Record the username for the NCN BMCs.

        ```bash
        USERNAME=root
        ```

    1. Record the password for this user.

        ```bash
        read -r -s -p "NCN BMC ${USERNAME} password: " IPMI_PASSWORD
        ```

    1. Set the nodes to PXE boot and restart them.

        ```bash
        export IPMI_PASSWORD
        grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} chassis bootdev pxe options=persistent
        grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} chassis bootdev pxe options=efiboot
        grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} power off
        sleep 10
        grep -oP "(${mtoken}|${stoken}|${wtoken})" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U "${USERNAME}" -E -H {} power on
        ```

1. (`pit#`) Wait for the nodes to network boot.

    This can be monitored using ConMan; the `-m` option follows the console output in read-only mode, and the `-j` option joins an interactive console session.
    The available node names were listed in step 2 above. The boot usually starts in less than 3 minutes. After that, log data should start flowing through ConMan; the
    speed depends on how quickly the nodes POST. To see a ConMan help screen for all supported escape sequences, use `&?`.

    ```bash
    conman -m ncn-m002-mgmt
    ```

1. (`pit#`) Exit ConMan.

    This is done by typing `&.` (that is, press and release `&`, then press and release `.`).

1. (`pit#`) Print off what has been found in the console logs.

    This snippet will omit duplicates from multiple boot attempts:

    ```bash
    for file in /var/log/conman/*; do
        echo ${file}
        grep -Eoh '(net[0-9] MAC .*)' "${file}" | sort -u | grep PCI && echo -----
    done
    ```

1. (`pit#`) Examine the output to identify `Bond0` MAC addresses for each NCN.

    Use the lowest value MAC address per PCIe card.

    > Example: One PCIe card with two ports, for a total of two ports per node.

    ```text
    -----
    /var/log/conman/console.ncn-w003-mgmt
    net2 MAC b8:59:9f:d9:9e:2c PCI.DeviceID 1013 PCI.VendorID 15b3 <-bond0-mac0 (0x2c < 0x2d)
    net3 MAC b8:59:9f:d9:9e:2d PCI.DeviceID 1013 PCI.VendorID 15b3 <-bond0-mac1
    -----
    ```

    The above output identifies `MAC0` and `MAC1` of the bond as `b8:59:9f:d9:9e:2c` and `b8:59:9f:d9:9e:2d`, respectively.

    > Example: Two PCIe cards with two ports each, for a total of four ports per node.

    ```text
    -----
    /var/log/conman/console.ncn-w006-mgmt
    net0 MAC 94:40:c9:5f:b5:df PCI.DeviceID 8070 PCI.VendorID 1077 <-bond0-mac0 (0xdf < 0xe0)
    net1 MAC 94:40:c9:5f:b5:e0 PCI.DeviceID 8070 PCI.VendorID 1077 (future use)
    net2 MAC 14:02:ec:da:b9:98 PCI.DeviceID 8070 PCI.VendorID 1077 <-bond0-mac1 (0x98 < 0x99)
    net3 MAC 14:02:ec:da:b9:99 PCI.DeviceID 8070 PCI.VendorID 1077 (future use)
    -----
    ```

    The above output identifies `MAC0` and `MAC1` of the bond as `94:40:c9:5f:b5:df` and `14:02:ec:da:b9:99`, respectively.

1. (`pit#`) Collect the NCN MAC address for the PIT node.

    This information will be used to populate the MAC addresses for `ncn-m001`.

    ```bash
    grep -i perm /proc/net/bonding/bond0
    ```

    For example:

    ```text
    Permanent HW addr: b8:59:9f:c7:12:f2 <-bond0-mac0
    Permanent HW addr: b8:59:9f:c7:12:f3 <-bond0-mac1
    ```

1. (`pit#`) Update `ncn_metadata.csv` with the collected MAC addresses for `Bond0` from all of the management NCNs.

    > **NOTE:** Each type of NCN (master, storage, and worker) are grouped together in the file and are listed in
    > **descending** numerical order within their group (for example, `ncn-s003` is listed directly before `ncn-s002`).

    For each NCN, update the corresponding row in `ncn_metadata` with the values for
    `Bond0 MAC0` and `Bond0 MAC1`. For `Bootstrap MAC`, copy the value from `Bond0 MAC0`.

    ```csv
    Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
    x3000c0s9b0n0,Management,Worker,94:40:c9:37:77:26,b8:59:9f:c7:12:f2,b8:59:9f:c7:12:f2,b8:59:9f:c7:12:f3
    ```

    ```text
                                                      ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^
                                                      bond0-mac0        bond0-mac0        bond0-mac1
    ```

1. (`pit#`) If the `script.ipxe` file was renamed in the first step of this procedure, then restore it to its original location.

    ```bash
    mv -v /var/www/boot/script.ipxe.bak /var/www/boot/script.ipxe
    ```

## Procedure: Serial consoles

Pick out the MAC addresses for the `Bond` from both the `sw-spine-001` and `sw-spine-002` switches, following the [Collecting BMC MAC Addresses](collecting_bmc_mac_addresses.md) procedure.

> **NOTE** The node must be booted into an operating system in order for the `Bond` MAC addresses to appear on the spine switches.
>
> A PCIe card with dual-heads may go to either spine switch, meaning `MAC0` must be collected from
> `spine-01`. Refer to the cabling diagram or the actual rack (in-person).

1. Follow `Metadata BMC` on each spine switch that `port1` and `port2` of the bond are plugged into.

1. Usually the 2nd/3rd/4th/Nth MAC address on the PCIe card will be a `0x1` or `0x2` deviation from the first port.

   Collection is quicker if this can be easily confirmed.
