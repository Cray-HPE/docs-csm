# Networking

Non-computes and computes have different network interfaces, this page will talk about non-computes
but in the context of a metal stack.

| Name | Type | MTU |
| ---- | ---- | ---- |
| `mgmt0` | Slot 1 on the SMNET card. | 9000
| `mgmt1` | Slot 2 on the SMNET card, or slot 1 on the 2nd SMNET card. | 9000
| `bond0` | LACP Link Agg. of `mgmt0` and `mgmt1`, or `mgmt0` and `mgmt2` on dual-bonds (when `bond1` is present). | 9000
| `bond1` | LACP Link Agg. of `mgmt1` and `mgmt3`. | 9000
| `lan0` | Externally facing interface. | 1500
| `lan1` | Yet-another externally facing interface, or anything (unused). | 1500
| `hsn0` | High-speed network interface. | 9000
| `hsnN+1` | Yet-another high-speed network interface. | 9000
| `vlan002` | Virtual LAN for managing nodes | 1500
| `vlan004` | Virtual LAN for managing hardware | 1500
| `vlan007` | Virtual LAN for the customer access network | 1500

These interfaces can be observed on a live NCN (using `ip link` on the command line).

#### Device Naming / udev

The underlying naming relies on [BIOSDEVNAME][1], this helps conform device naming into a smaller
set of possible names. It also helps show us when driver issues occur, if a non-BIOSDEVNAME interface appears
 then METAL can/should receive a triage report/bug.

MAC Based udev rules during initial boot in iPXE. When a node boots, iPXE will dump the PCI busses and sort
network interfaces into 3 buckets:
- `mgmt`: internal/management network connection
- `hsn`: high-speed connection
- `lan`: external/site-connection

The source code for the rule generation is in [metal-ipxe][1], but for technical information on the PCI configuration/reading please read on.

# Vendor and Bus ID Identification

The initial boot of an NCN sets interface udev rules since it has no discovery methood yet.

The information needed is:
- PCI **Vendor** IDs for devices/cards to be used on the Management network.
- PCI **Device** IDs for the devices/cards to be used on the High-Speed Network.

>  The 16-bit Vendor ID is allocated by the PCI-SIG (Peripheral Component Interconnect
  Special Interest Group).

![PCI Configuration Space](https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Pci-config-space.svg/600px-Pci-config-space.svg.png)

The information belonds to the first 4 bytes of the PCI header, and admin can obtain it
 using `lspci` or your preferred method for reading the PCI bus.

### Collection Example
```bash
lspci | grep -i ethernet
lspci | grep c6:00.0
```
### Popular Vendor ID and Device ID Table

These are commononly found in Cray computers.

The Device and Vendor IDs are used in iPXE for bootstrapping the nodes, this allows genertors to
swap IDs out for certain systems until smarter logic can be added to cloud-init.

> The bolded numbers are the defaults that live in [metal-ipxe's boot script.](https://stash.us.cray.com/projects/MTL/repos/ipxe/browse/boot/script.ipxe).

| Vendor | Model | Device ID | Vendor ID |
| :---- | :---- | :-----: | :---------: |
| Intel Corporation | Ethernet Connection X722 | `37d2` | `8086` |
| Intel Corporation | 82576 | `1526` | `8086` |
| Mellanox Technologies | ConnectX-4 | `1013` | **`15b3`** |
| Mellanox Technologies | ConnectX-5 | **`1017`** | `15b3` |
| Giga-Byte | Intel Corporation I350 | `1521` | `8086` |
| QLogic Corporation | FastLinQ QL41000 | `8070` | **`1077`** |

[1]: https://stash.us.cray.com/projects/MTL/repos/ipxe/browse/boot/script.ipxe
