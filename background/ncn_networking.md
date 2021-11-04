# NCN Networking

Non-compute nodes and compute nodes have different network interfaces used for booting, this topic focuses on
the network interfaces for management nodes.

### Topics:

   * [NCN Network Interfaces](#ncn-network-interfaces)
   * [Device Naming](#device-naming)
   * [Vendor and Bus ID Identification](#vendor-and-bus-id-identification)

## Details

<a name="ncn-network-interfaces"></a>
### NCN Network Interfaces

The following table includes information about the different NCN network interfaces:

| Name | Type | MTU |
| ---- | ---- | ---- |
| `mgmt0` | Port 1 Slot 1 on the SMNET card. | 9000
| `mgmt1` | Port 1 Slot 2 on the SMNET card. | 9000
| `bond0` | LACP Link Agg. of `mgmt0` and `mgmt1`. | 9000
| `bond0.nmn0` | Virtual LAN for managing nodes | 1500
| `bond0.hmn0` | Virtual LAN for managing hardware | 1500
| `bond0.can0` | Virtual LAN for the customer access network | 1500
| `sun0` | Port 2 Slot 2 on the SMNET card. | 9000
| `sun1` | Port 2 Slot 2 on the SMNET card. | 9000
| `bond1` | LACP Link Agg. of `sun0` and `sun1`. | 9000
| `bond1.sun0` | Virtual LAN for the storage utility network | 9000
| `lan0` | Externally facing interface (DHCP). | 1500
| `lan1` | Yet-another externally facing interface, or anything (unused). | 1500
| `hsn0` | High-speed network interface. | 9000
| `hsnN+1` | Yet-another high-speed network interface. | 9000

These interfaces can be observed on a live NCN with the following command.

   ```bash
   ncn# ip link
   ```

<a name="device-naming"></a>
#### Device Naming

The underlying naming relies on [BIOSDEVNAME](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-consistent_network_device_naming_using_biosdevname), this helps conform device naming into a smaller
set of possible names. It also helps show us when driver issues occur, if a non-BIOSDEVNAME interface appears
 then METAL can/should receive a triage report/bug.

The MAC based `udev` rules set the interfaces during initial boot in iPXE. When a node boots, iPXE will dump
the PCI busses and sort network interfaces into 3 buckets:

   * `mgmt`: internal/management network connection
   * `sun`: internal/storage network connection
   * `hsn`: high-speed connection
   * `lan`: external/site-connection

The source code for the rule generation is in [metal-ipxe][1], but for technical information on the PCI configuration/reading please read on.

<a name="vendor-and-bus-id-identification"></a>
### Vendor and Bus ID Identification

The initial boot of an NCN sets interface `udev` rules because it has no discovery method yet.

The information needed is:
- PCI **Vendor** IDs for devices/cards to be used on the Management network.
- PCI **Device** IDs for the devices/cards to be used on the High-Speed Network.

The 16-bit Vendor ID is allocated by the PCI-SIG (Peripheral Component Interconnect Special Interest Group).

The information belongs to the first 4 bytes of the PCI header, and admin can obtain it
 using `lspci` or your preferred method for reading the PCI bus.

```bash
lspci | grep -i ethernet
lspci | grep c6:00.0
```

The Device and Vendor IDs are used in iPXE for bootstrapping the nodes, this allows generators to
swap IDs out for certain systems until smarter logic can be added to cloud-init.

The following table includes popular vendor and device IDs.

> The bolded numbers are the defaults that live in `metal-ipxe`'s boot script.

| Vendor | Model | Device ID | Vendor ID |
| :---- | :---- | :-----: | :---------: |
| Intel Corporation | Ethernet Connection X722 | `37d2` | `8086` |
| Intel Corporation | 82576 | `1526` | `8086` |
| Mellanox Technologies | ConnectX-4 | `1013` | **`15b3`** |
| Mellanox Technologies | ConnectX-5 | **`1017`** | `15b3` |
| Giga-Byte | Intel Corporation I350 | `1521` | `8086` |
| QLogic Corporation | FastLinQ QL41000 | `8070` | **`1077`** |
