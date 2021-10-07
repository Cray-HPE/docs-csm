# Non-Compute Node BIOS

This page denotes BIOS settings that are desirable for non-compute nodes.

> **`NOTE`** Any tunables in this page are in the interest of performance and stability. If either of those facets seem to be infringed by any of the content on this page, please contact Cray System Management for reconciliation.

> **`NOTE`** The table below declares desired settings; unlisted settings should remain at vendor-default. This table may be expanded as new settings are adjusted.


| Common Name | Common Value | Description | Value Rationale | Common Menu Location
   | --- | --- | --- | --- | --- |
| Intel® Hyper-Threading (e.g. HT) | `Enabled` | Enables two-threads per physical core. | Leverage the full performance of the CPU, the higher thread-count assists with parallel tasks within the processor(s). | Within the Processor or the PCH Menu.
| Intel® Virtualization Technology (e.g. VT-x, VT) and AMD Virtualization Technology (e.g. AMD-V)| `Enabled` | Enables Virtual Machine extensions. | Provides added CPU support for hypervisors and more for the virtualized plane within Shasta. | Within the Processor or the PCH Menu.
| PXE Retry Count | 0 | Attempts done on a single boot-menu option (note: 2 should be set for systems with unsolved network congestion). | If networking is working nominally, then the interface either works or does not. Retrying the same NIC should not work, if it does then there are networking problems that need to be addressed. | Within the Networking Menu, and then under Network Boot.
| PXE Timeout | 5 Seconds (or less, never more) | The time that the PXE ROM will wait for a DHCP handshake to complete before moving on to the next boot device. | If DHCP is working nominally, then the DHCP handshake should not take longer than 5 seconds. This timeout could be increased where networking faults cannot be reconciled, but ideally this should be tuned to 3 or 2 seconds. |
| Continuous Boot | `Disabled` | Whether boot-group (e.g. all network devices, or all disk devices) should continuously retry. This prevents fall-through to the fallback disks. | We want deterministic nodes in Shasta, if the boot fails the first tier we want the node to try the next tier of boot mediums before failing at a shell or menu for intervention. |

> **`NOTE`** **PCIe** options can be found in [PCIe : Setting Expected Values](../install/switch_pxe_boot_from_onboard_nic_to_pcie.md#setting-expected-values).
