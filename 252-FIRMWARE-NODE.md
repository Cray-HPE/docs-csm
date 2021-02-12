# Node Firmware

This page details the minium specification for nodes and their components (such as PCIe cards).

> **`NOTE`** New items may be added to this page over time.

## Servers

| Vendor | Model | Version |
| :--- | :--- | ---: |
| HPE | A41 DL325 Gen10 | [10/18/2019 2.30][1] | 
| HPE | A42 DL385 Gen10+ | [10/31/2020 1.38][2] | 
| HPE | A43 DL325 Gen10+ | [10/31/2020 1.38][2] | 
| Intel | S2600WFT | [02.01.0012][3] |
| Gigabyte | MZ32-AR0-00 | [12.84][4] |

[1]: https://support.hpe.com/hpsc/swd/public/detail?swItemId=MTX-ba30df44427f4e099b2f652829
[2]: https://downloadcenter.intel.com/download/29753/Intel-Server-Board-S2600WF-Family-BIOS-and-Firmware-Update-Package-for-UEFI
[3]: https://support.hpe.com/hpsc/swd/public/detail?swItemId=MTX_5ed1b5a914b844caab3780d293
[4]: https://pubs.cray.com/bundle/Gigabyte_Node_Firmware_Update_Guide_S-8010/page/About_the_Gigabyte_Node_Firmware_Update_Guide.html

#### Vendor Upgrade Refences

- [HPE (iLO) Upgrades](#marvell-upgrades)
- [Intel Upgrades](#mellanox-upgrades)
- [Gigabyte Upgrades](#mellanox-upgrades)


##### HPE (iLO) Upgrades

> **THIS IS A STUB** There are no instructions on this page, this page is place-holder.

##### Intel Upgrades

> **THIS IS A STUB** There are no instructions on this page, this page is place-holder.

##### Gigabyte Upgrades

> **THIS IS A STUB** There are no instructions on this page, this page is place-holder.

## PCIe Cards

| Vendor | Model | PSID | Version |
| :--- | :--- | --- | ---: |
| Marvell | QL41232HQCU-HC | | [08.50.78][5] | 
| Mellanox | MCX416A-BCAT | `MT_2130111027` | [12.28.2006][8] |
| Mellanox | MCX515A-CCAT | `MT_0000000011` | [16.28.4000][6] |
| Mellanox | MCX515A-CCAT | `MT_0000000591` | [16.28.4000][7] |

> Note: The Mellanox firmware can be updated to minimum spec. using `mlxfwmanager`. The `mlxfwmanager` will fetch updates from online, or it can use a local file (or local web server such as http://pit/).


#### Vendor Upgrade Refences

- [Marvell Upgrades](#marvell-upgrades)
- [Mellanox Upgrades](#mellanox-upgrades)

##### Marvell Upgrades

> **THIS IS A STUB** There are no instructions on this page, this page is place-holder.

##### Mellanox Upgrades

Shasta 1.4 NCNs are # Print name and current state; on an NCN or on the liveCD.

###### Requirement: Enable Tools

MST needs to be started for the tools to work.

```bash
linux:~ # mst status
Starting MST (Mellanox Software Tools) driver set
Loading MST PCI module - Success
Loading MST PCI configuration module - Success
Create devices
Unloading MST PCI module (unused) - Success
```

###### Check Current Firmware

Print out the current firmware versions or all Mellanox cards:

```bash
linux:~ # mlxfwmanager
Querying Mellanox devices firmware ...

Device #1:
----------

  Device Type:      ConnectX5
  Part Number:      MCX515A-CCA_Ax
  Description:      ConnectX-5 EN network interface card; 100GbE single-port QSFP28; PCIe3.0 x16; tall bracket; ROHS R6
  PSID:             MT_0000000011
  PCI Device Name:  /dev/mst/mt4119_pciconf0
  Base GUID:        ec0d9a03007da71e
  Base MAC:         ec0d9a7da71e
  Versions:         Current        Available
     FW             16.26.4012     N/A
     PXE            3.5.0805       N/A
     UEFI           14.19.0017     N/A

  Status:           No matching image found

Device #2:
----------

  Device Type:      ConnectX4
  Part Number:      MCX416A-BCA_Ax
  Description:      ConnectX-4 EN network interface card; 40GbE dual-port QSFP28; PCIe3.0 x16; ROHS R6
  PSID:             MT_2130111027
  PCI Device Name:  /dev/mst/mt4115_pciconf0
  Base GUID:        506b4b030013982e
  Base MAC:         506b4b13982e
  Versions:         Current        Available
     FW             12.26.4012     N/A
     PXE            3.5.0805       N/A
     UEFI           14.19.0017     N/A

  Status:           No matching image found

```

###### Upgrade from the LiveCD

If the LiveCD is reachable, firmware can be downloaded for local install:

```bash
curl -O http://pit/fw/pcie/firmware.img
mlxfwmanager -u -i ./firmware.img
```

###### Upgrade from the Internet

If external queries can be made by the node, it can update firmware from the Internet:

```bash
mlxfwmanager -u --online
```

[5]: https://www.marvell.com/products/hpe/hpe-industry-standard-adapters.html
[6]: http://15.213.147.156/HPC_Fabric/Mellanox/Mellanox%20HDR/ConnectX-6%20EN%20network%20interface%20card%20100GbE%20single-port%20QSFP28%20MCX515A-CCAT%20(Cray%20E1000)/
[7]: http://15.213.147.156/HPC_Fabric/Mellanox/Mellanox%20EDR/HPE%20Ethernet%20100Gb%201-port%20QSFP28%20MCX515A-CCAT%20PCIe3%20x16%20Adapter%20P313246-H21%20(Oku)/16.28.4000%20GA/
[8]: https://www.mellanox.com/support/firmware/connectx4en
