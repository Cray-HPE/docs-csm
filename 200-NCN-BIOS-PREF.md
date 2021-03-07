# NCN BIOS Preferences

This page goes over desired NCN BIOS settings specifications.

For setting each one, please refer to the vendor manuals for the systems inventory.

### Spec.

> **`NOTE`** The table below declares desired settings; unlisted settings should remain at vendor-default. This table may be expanded as new settings are adjusted.


| Common Name | Common Value | Memo | Menu Location
| --- | --- | --- | --- |
| Intel® Hyper-Threading (e.g. HT) | `Enabled` | Enables two-threads per physical core. | Within the Processor or the PCH Menu.
| Intel® Virtualization Technology (e.g. VT-x, VT) and AMD Virtualization Technology (e.g. AMD-V)| `Enabled` | Enables Virtual Machine extensions. | Within the Processor or the PCH Menu.
| PXE Retry Count | 1 or 2 (default: 1) | Attempts done on a single boot-menu option (note: 2 should be set for systems with unsolved network congestion). | Within the Networking Menu, and then under Network Boot.

> **`NOTE`** **PCIe** options can be found in [PCIe : Setting Expected Values](304-NCN-PCIE-NET-BOOT-AND-RE-CABLE.md#setting-expected-values).

