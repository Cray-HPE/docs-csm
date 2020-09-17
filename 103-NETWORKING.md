# Networking

Non-computes and computes have different network interfaces, this page will talk about non-computes
but in the context of a metal stack.

| Name | Type | MTU |
| ---- | ---- | ---- |
| `mgmt0` | Slot 1 on the SMNET card. | 9000
| `mgmt1` | Slot 2 on the SMNET card, or slot 1 on the 2nd SMNET card. | 9000
| `bond0` | LACP Link Agg. of `mgmt0`. | 9000
| `lan0` | Externally facing interface. | 1500
| `lan1` | Yet-another externally facing interface, or anything (unused). | 1500
| `hsn0` | High-speed network interface. | 9000
| `hsnN+1` | Yet-another high-speed network interface. | 9000
| `vlan002` | Virtual LAN for managing nodes | 1500
| `vlan004` | Virtual LAN for managing hardware | 1500
| `vlan007` | Virtual LAN for the customer access network | 1500

