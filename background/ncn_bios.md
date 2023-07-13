# NCN BIOS

This page specifies the BIOS settings that are desirable for non-compute nodes (NCNs).

> **`NOTES`**
>
> - Any tunables on this page are in the interest of performance and stability. If either of those facets seem to be infringed by any of the content on this page, then contact HPE Cray for support.
> - The table below declares desired settings; unlisted settings should remain at vendor default. This table may be expanded as new settings are adjusted.
> - **PCIe** options can be found in [PCIe : Setting Expected Values](../operations/node_management/Switch_PXE_Boot_From_Onboard_NICs_to_PCIe.md#setting-expected-values).

| Common Name | Common Value | Description | Value Rationale |
| ----------- | ------------ | ----------- | --------------- |
| Intel® Hyper-Threading (HT) | `Enabled` | Enables two threads per physical core | Leverage the full performance of the CPU. The higher thread-count assists with parallel tasks within the processors. |
| Intel® Virtualization Technology (VT-x or VT) and AMD Virtualization Technology (AMD-V)| `Enabled` | Enables Virtual Machine extensions | Provides added CPU support for hypervisors and more for the virtualized plane within the system. |
| PXE Retry Count | `0` or `2` (see Rationale) | Boot re-attempts per boot option | For healthy networks, retries should not produce different results. For unhealthy or congested networks, `2` is recommended. |
| PXE Timeout | `5 Seconds` or less | PXE ROM maximum time for DHCP handshake to complete. | DHCP handshake should not take longer than 5 seconds. This timeout could be increased for unhealthy networks, but ideally should be 2-3 seconds. |
| Continuous Boot | `Disabled` | Whether the boot-group (e.g. all network devices, or all disk devices) should continuously retry | If enabled, it prevents failed network boots to disk boots to proceed to attempting a disk boot. |
