# NCN Plan of Record

This document outlines the hardware necessary to meet CSM's Plan of Record (PoR). This serves as the **minimum, necessary** pieces required per each server in the management plane.

1. If the system's NICs do not align to the PoR NICs outlined below (e.g. Onboard NICs are used instead of PCIe), then follow [Customize PCIe Hardware](../operations/node_management/customize_pcie_hardware.md) before booting the NCN(s).
1. If there are more disks than what is listed below in the PoR for disks, then follow [Customize Disk Hardware](../operations/node_management/customize_disk_hardware.md) before booting the NCN(s).

- [Masters NCNs](#masters-ncns)
  - [Disks](#master-disks)
  - [NICs](#master-nics)
- [Workers NCNs](#workers-ncns)
  - [Disks](#worker-disks)
  - [NICs](#worker-nics)
- [Storage NCNs](#storage-ncns)
  - [Disks](#storage-disks)
  - [NICs](#storage-nics)

<a name="non-compute-nodes"></a>

> **`NOTE:`** Several components below are necessary to provide redundancy in the event of hardware failure.

## Masters NCNs

### Master disks

- Operating System: 2 SSDs of equal size, and less than 500 GiB (524288000000 bytes)
- ETCD: 1 SSD smaller than 500 GiB (524288000000 bytes) (This disk will be fully encrypted with LUKS2)

### Master NICs

> **`NOTE:`** The 2nd port on each card is unused/empty (reserved for future use).

- Management Network: 2 PCIe cards, with 1 or 2 heads/ports each for a total of 4 ports split between two PCIe cards

## Workers NCNs

### Worker disks

- Operating System: 2 SSDs of equal size, and less than 500 GiB (524288000000 bytes)
- Ephemeral: 1 SSD larger than 1 TiB (1048576000000 bytes)

### Worker NICs

> **`NOTE:`** There is no PCIe redundancy for the management network for worker NCNs. The only redundancy set up for workers is port redundancy.

- Management Network: 1 PCIe card with 2 heads/ports for a total of 2 ports dedicated to a single PCIe card
- High-Speed Network: 1 PCIe card capable of 100 Gbps (e.g. ConnectX-5 or Cassini), with 1 or 2 heads/ports

## Storage NCNs

### Storage disks

- Operating System: 2 SSDs of equal size, and less than 500 GiB (524288000000 bytes)
- Ceph: 8 SSDs of any size

> **`NOTE:`** Any available disk that is not consumed by the operating system will be used for Ceph, but a node needs a minimum of 8 disks for making an ideal Ceph pool for CSM.

### Storage NICs

> **`NOTE:`** The 2nd port on each card is filled but not configured (reserved for future use).

- Management Network: 2 PCIe cards, each with 2 heads/ports for a total of 4 ports split between two PCIe cards
