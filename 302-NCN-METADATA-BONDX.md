# Collecting NCN MAC Addresses

This procedure will detail how to collect the NCN MAC addresses from a Shasta system.  After completing this procedure,
you will have the MAC addresses needed for the Bootstrap MAC, Bond0 MAC0, and Bond0 MAC1 columns in `ncn_metadata.csv`.

The Bootstrap Mac address will be used for identification of this node during the early part of the PXE boot process before the bonded interface can be established.
The Bond0 MAC0 and Bond0 MAC1 are the MAC addressess for the physical interfaces that your node will use for the various VLANs.
The Bond0 MAC0 and Bond0 MAC1 should be on the different network cards to establish redundancy for a failed network card.
On the other hand, if the node has only a single network card, then MAC1 and MAC0 will still produce a valid configuration if they do reside on the same physical card.

#### Sections

- [Procedure: iPXE](#procedure-ipxe-consoles)
   - [Requirements](#requirements)
   - [MAC Collection](#mac-collection)
- [Procedure: Serial consoles](#procedure-serial-consoles)

The easy way to do this leverages the NIC-dump provided by the metal-ipxe package. This page will walk-throuogh
booting NCNs and collecting their MACs from the conman console logs.
> The alternative is to use serial cables (or SSH) to collect the MACs from the switch ARP tables, this can become exponentially difficult for large systems.
> If this is the only way, please proceed to the bottom of this page.

## Procedure: iPXE Consoles

This procedure is faster for those with the LiveCD (CRAY Pre-Install Toolkit) it can be used to quickly
boot-check nodes to dump network device information without an OS. This works by accessing the PCI Configuration Space.

#### Requirements

> If CSI does not work due to requiring a file, please file a bug. By default, dnsmasq
> and conman are already running on the LiveCD but bond0 needs to be configured, dnsmasq needs to
> serve/listen over bond0, and conman needs the BMC information.

1. LiveCD dnsmasq is configured for the bond0/metal network (NMN/HMN/CAN do not matter)
2. BMC MAC addresses already collected
3. LiveCD conman is configured for each BMC (`conman -q` to see consoles)

For help with either of those, see [LiveCD Setup](004-CSM-REMOTE-LIVECD.md).

#### MAC Collection

1. (optional) shim the boot so nodes bail after dumping their netdevs. Removing the iPXE script will prevent network booting but beware of disk-boots.
will prevent the nodes from continuing to boot and end in undesired states.
    ```bash
    pit# mv /var/www/boot/script.ipxe /var/www/boot/script.ipxe.bak
    ```
2. Verify consoles are active with `conman -q`,
    ```bash
    pit# conman -q
    ncn-m002-mgmt
    ncn-m003-mgmt
    ncn-s001-mgmt
    ncn-s002-mgmt
    ncn-s003-mgmt
    ncn-w001-mgmt
    ncn-w002-mgmt
    ncn-w003-mgmt
    ```

3. Now set the nodes to PXE boot and (re)start them.
    ```bash
    pit# export username=root
    pit# export IPMI_PASSWORD=
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} chassis bootdev pxe options=efiboot,persistent
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power off
    pit# sleep 10
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power on
    ```
4. Now wait for the nodes to netboot. You can follow them with `conman -j ncn-*id*-mgmt` (use `conman -q` to see ). This takes less than 3 minutes, speed depends on how quickly your nodes POST.
5. Print off what's been found in the console logs, this snippet will omit duplicates from multiple boot attempts:
    ```bash
    pit# for file in /var/log/conman/*; do
        echo $file
        grep -Eoh '(net[0-9] MAC .*)' $file | sort -u | grep PCI && echo -----
    done
    ```
6. From the output you must fish out 2 MACs to use for bond0, and 2 more to use for bond1 based on your topology. **The `Bond0MAC0` must be the first port** of the first PCIe card, specifically the port connecting the NCN to the lower spine (e.g. if connected to spines01 and 02, this is going to sw-spine-001 - if connected to sw-spine-007 and sw-spine-008, then this is sw-spine-007). **The 2nd MAC for `bond0` is the first port of the 2nd PCIe card, or 2nd port of the first when only one card exists**.
    - Examine the output, you can use the table provided on [NCN Networking](103-NCN-NETWORKING.md) for referencing commonly seen devices.
    - Note that worker nodes also have the high-speed network cards. If you know these cards, you can filter their device IDs out from the above output using this snippet:
        ```bash
        pit# unset did # clear it if you used it.
        pit# did=1017 # ConnectX-5 example.
        pit# for file in /var/log/conman/*; do
            echo $file
            grep -Eoh '(net[0-9] MAC .*)' $file | sort -u | grep PCI | grep -Ev "$did" && echo -----
        done
        ```
    - Note to filter out onboard NICs, or site-link cards, you can omit their device IDs as well. Use the above snippet but add the other IDs:
      **this snippet prints out only mgmt MACs, the `did` is the HSN and onboard NICs that is being ignored.**
        ```bash
        pit# unset did # clear it if you used it.
        pit# did='(1017|8086|ffff)'
        pit# for file in /var/log/conman/*; do
            echo $file
            grep -Eoh '(net[0-9] MAC .*)' $file | sort -u | grep PCI | grep -Ev "$did" && echo -----
        done
        ```
7. Examine the output from `grep`, use the lowest value MAC address per PCIe card.
    > example: 1 PCIe card with 2 ports for a total of 2 ports per node.
    ```bash
    -----
    /var/log/conman/console.ncn-w003-mt
    net2 MAC b8:59:9f:d9:9e:2c PCI.DeviceID 1013 PCI.VendorID 15b3 <-bond0-mac0 (0x2c < 0x2d)
    net3 MAC b8:59:9f:d9:9e:2d PCI.DeviceID 1013 PCI.VendorID 15b3 <-bond0-mac1
    -----
    ```
    > example: 2 PCIe cards with 2 ports each for a total of 4 ports per node.
    ```bash
    -----
    /var/log/conman/console.ncn-w006-mgmt
    net0 MAC 94:40:c9:5f:b5:df PCI.DeviceID 8070 PCI.VendorID 1077 <-bond0-mac0 (0x38 < 0x39)
    net1 MAC 94:40:c9:5f:b5:e0 PCI.DeviceID 8070 PCI.VendorID 1077 (future use)
    net2 MAC 14:02:ec:da:b9:98 PCI.DeviceID 8070 PCI.VendorID 1077 <-bond0-mac1 (0x61f0 < 0x7104)
    net3 MAC 14:02:ec:da:b9:99 PCI.DeviceID 8070 PCI.VendorID 1077 (future use)
    -----
8. The above output identified MAC0 and MAC1 of the bond as 14:02:ec:df:9c:38 and 94:40:c9:c1:61:f0 respectively.
    > Tip: Mind the index (3, 2, 1.... ; not 1, 2, 3)
    ```
    Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
    x3000c0s9b0n0,Management,Worker,94:40:c9:37:77:26,14:02:ec:df:9c:38,14:02:ec:df:9c:38,94:40:c9:c1:61:f0
                                                      ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^
    ```

## Procedure: Serial Consoles

For this, you will need to double-back to [NCN Metadata BMC](301-NCN-METADATA-BMC.md) and pick out
the MACs for your BOND from each the sw-spine-001 and sw-spine-002 switch.

> Tip: A PCIe card with dual-heads may go to either spine switch, meaning MAC0 ought to be collected from
> spine-01. Please refer to your cabling diagram, or actual rack (in-person).

1. Follow "Metadata BMC" on each spine switch that port1 and port2 of the bond is plugged into.
2. Usually the 2nd/3rd/4th/Nth MAC on the PCIe card will be a 0x1 or 0x2 deviation from the first port. If you confirm this, then collection
is quicker.
