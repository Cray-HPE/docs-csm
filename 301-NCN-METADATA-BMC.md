# Collecting the BMC MAC Addresses

This guide will detail how to collect BMC MACs from a racked shasta system that have had their switches configured.

If you are here with an unconfigured switch, milage may vary.

## Requirements

1. Configured switch with SSH access _or_ unconfigured with COM access (serial-over-lan/DB-9)
2. Another file to record the collected BMC information.

## Procedure

1. Establish an SSH or [serial connection](303-NCN-METADATA-USB-SERIAL.md) to the leaf switch.
    > Note: These IPs are examples; 10.X.0.2 may or may not match your setup.
    ```bash
    # SSH over METAL MANAGEMENT
    pit:~ # ssh admin@10.1.0.2

    # SSH over NODE MANAGEMENT
    pit:~ # ssh admin@10.252.0.2

    # SSH over HARDWARE MANAGEMENT
    pit:~ # ssh admin@10.254.0.2  

    # or.. serial (device name will vary).
    pit:~ # minicom -b 115200 -D /dev/tty.USB1
    ```
2. If you know the ports of your BMCs, you can print out the MAC for those ports -or- if they exist on the same VLAN you should be able to dump the VLAN.
    > Syntax is for Onyx and DellEMC devices - please resort to your CLI usage (press `?` or `tab` to assist on-the-fly).

    If you know the VLAN ID:
    ```bash
    # DellOS 10
    sw-smn01# show mac address-table vlan 4 | except 1/1/52
    VlanId	Mac Address		Type		Interface
    4	00:1e:67:98:fe:2c	dynamic		ethernet1/1/11
    4	a4:bf:01:38:f0:b1	dynamic		ethernet1/1/27
    4	a4:bf:01:38:f1:44	dynamic		ethernet1/1/25
    4	a4:bf:01:48:1e:ac	dynamic		ethernet1/1/28
    4	a4:bf:01:48:1f:70	dynamic		ethernet1/1/31
    4	a4:bf:01:48:1f:e0	dynamic		ethernet1/1/26
    4	a4:bf:01:48:20:03	dynamic		ethernet1/1/30
    4	a4:bf:01:48:20:57	dynamic		ethernet1/1/29
    4	a4:bf:01:4d:d9:9a	dynamic		ethernet1/1/32
    ```
    If you know the interface and trunk:
    ```bash
    # DellOS 10
    sw-smn01# show mac address-table interface ethernet 1/1/32
    VlanId	Mac Address		Type		Interface
    4	a4:bf:01:4d:d9:9a	dynamic		ethernet1/1/32
    ```
    Print everything:
    ```bash
    # DellOS 10
    sw-smn01# show mac address-table
    VlanId	Mac Address		Type		Interface
    4	a4:bf:01:4d:d9:9a	dynamic		ethernet1/1/32
    ....
    # Onyx & Aruba
    sw-smn01# show mac-address-table

    ```
3. From the above output, pick out the initial 8 BMCs (minus however many managers have external BMC connections).
    > Tip: Mind the index (3, 2, 1.... ; not 1, 2, 3)
    ```
    Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
    x3000c0s9b0n0,Management,Storage,94:40:c9:37:77:26,94:40:c9:5f:b5:de,94:40:c9:5f:b5:de,14:02:ec:da:b9:98
                                     ^^^^^^^^^^^^^^^^^
    ```

The column heading must match that shown above for csi to correctly parse it.  You can take the file you've started and move onto [NCN Metadata BondX](302-NCN-METADATA-BONDX.md).
