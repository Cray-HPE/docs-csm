# NCN Networking

Non-compute nodes and compute nodes have different network interfaces used for booting; this topic focuses on
the network interfaces for management nodes.

## Topics

* [NCN network interfaces](#ncn-network-interfaces)
* [Device naming](#device-naming)
* [Vendor and bus ID identification](#vendor-and-bus-id-identification)

## NCN network interfaces

The following table includes information about the different NCN network interfaces:

| Name | Type | MTU |
| ---- | ---- | ---- |
| `mgmt0` | Slot 1 on the SMNET card | 9000
| `mgmt1` | Slot 2 on the SMNET card or slot 1 on the second SMNET card | 9000
| `bond0` | LACP link aggregate of `mgmt0` and `mgmt1`, or `mgmt0` and `mgmt2` on dual-bonds (when `bond1` is present) | 9000
| `bond1` | LACP link aggregate of `mgmt1` and `mgmt3` | 9000
| `lan0` | Externally facing interface | 1500
| `lan1` | Another externally facing interface, or anything (unused) | 1500
| `hsn0` | High-Speed Network interface | 9000
| `hsnN+1` | Another high-speed network interface | 9000
| `vlan002` | Virtual LAN for managing nodes | 1500
| `vlan004` | Virtual LAN for managing hardware | 1500
| `vlan007` | Virtual LAN for the Customer Access Network | 1500

These interfaces can be observed on an NCN with the following command.

```bash
ncn# ip link
```

## Device naming

The underlying naming relies on [`biosdevname`](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-consistent_network_device_naming_using_biosdevname).
This helps conform device naming into a smaller set of possible names. It also helps reveal when driver issues occur; if an
administrator observes an interface with name that does not conform to this naming scheme, then this is an indication of a problem.

The MAC-based `udev` rules set the interfaces during initial boot in iPXE. When a node boots, iPXE will dump
the PCI buses and sort network interfaces into 3 buckets:

* `mgmt`: internal/management network connection
* `hsn`: high-speed connection
* `lan`: external/site connection

The source code for the rule generation is in `metal-ipxe`. Continue reading for technical information on the PCI configuration/reading.

## Vendor and bus ID identification

The initial boot of an NCN sets interface `udev` rules because it has no discovery method yet.

The information needed is:

* PCI **Vendor** IDs for devices/cards to be used on the Management network.
* PCI **Device** IDs for the devices/cards to be used on the High-Speed Network.

The 16-bit vendor ID is allocated by the PCI-SIG (Peripheral Component Interconnect Special Interest Group).

The information belongs to the first 4 bytes of the PCI header, and administrators can obtain it
by reading the PCI bus (for example, by using the `lspci` command).

```bash
ncn# lspci | grep -i ethernet
ncn# lspci | grep c6:00.0
```

The device and vendor IDs are used in iPXE for bootstrapping the nodes. This allows generators to
swap IDs out for certain systems until smarter logic can be added to `cloud-init`.

The following table includes popular vendor and device IDs.

> The numbers in bold are the defaults in `metal-ipxe`'s boot script.

| Vendor | Model | Device ID | Vendor ID |
| :---- | :---- | :-----: | :---------: |
| Intel Corporation | Ethernet Connection X722 | `37d2` | `8086` |
| Intel Corporation | 82576 | `1526` | `8086` |
| Mellanox Technologies | ConnectX-4 | `1013` | **`15b3`** |
| Mellanox Technologies | ConnectX-5 | **`1017`** | `15b3` |
| Giga-Byte | Intel Corporation I350 | `1521` | `8086` |
| QLogic Corporation | FastLinQ QL41000 | `8070` | **`1077`** |
