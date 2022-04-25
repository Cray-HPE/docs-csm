# Plan of Record

This document outlines the hardware necessary to meet CSM's Plan of Record (PoR). This serves as the **minimum, necessary** pieces required per each server in the management plane.

1. If the system's NICs do not align to the PoR NICs outlined below (e.g. Onboard NICs are used instead of PCIe), then follow [Customize PCIe Hardware](../operations/node_management/customize_pcie_hardware.md) before booting the NCN(s).
1. If there are more disks than what is listed below in the PoR for disks, then follow [Customize Disk Hardware](../operations/node_management/customize_disk_hardware.md) before booting the NCN(s).

## Table of Contents

* [Non-Compute Nodes](#non-compute-nodes)
    * [Masters NCNs](#masters-ncns)
        * [Disks](#master-disks)
        * [NICs](#master-nics)
    * [Workers NCNs](#workers-ncns)
        * [Disks](#worker-disks)
        * [NICs](#worker-nics)
    * [Storage NCNs](#storage-ncns)
        * [Disks](#storage-disks)
        * [NICs](#storage-nics)


<a name="non-compute-nodes"></a>
# Non-Compute Nodes

> **`NOTE:`** Several components below are necessary to provide redundancy in the event of hardware failure.

<a name="masters-ncns"></a>
## Masters NCNs

<a name="master-disks"></a>
#### Master Disks

- _Operating System:_ 2x SSDs of equal size, and less than 500GiB (524288000000 bytes)
- _ETCD:_ 1x SSD smaller than 500GiB (524288000000 bytes) (This disk will be fully encrypted with LUKS2)

<a name="master-nics"></a>
#### Master NICs

> **`NOTE:`** The 2nd port on each card is unused/empty (reserved for future use).

- _Management Network:_ 2x PCIe cards, with 1 or 2 heads/ports each for a total of 4 ports split between two PCIe cards

<a name="workers-ncns"></a>
## Workers NCNs

<a name="worker-disks"></a>
#### Worker Disks

- _Operating System:_ 2x SSDs of equal size, and less than 500GiB (524288000000 bytes)
- _Ephemeral:_ 1x SSD larger than 1TiB (1048576000000 bytes)

<a name="worker-nics"></a>
#### Worker NICs

> **`NOTE:`** There is no PCIe redundancy for the management network for worker NCNs. The only redundancy set up for workers is port redundancy.

- _Management Network:_ 1x PCIe card with 2 heads/ports for a total of 2 ports dedicated to a single PCIe card
- _High-Speed Network:_ 1x PCIe card capable of 100Gbps (e.g. ConnectX-5 or Cassini), with 1 or 2 heads/ports

<a name="storage-ncns"></a>
## Storage NCNs

<a name="storage-disks"></a>
#### Storage Disks

- _Operating System:_ 2x SSDs of equal size, and less than 500GiB (524288000000 bytes)
- _CEPH:_ 8x SSDs of any size

> **`NOTE:`** Any available disk that is not consumed by the operating system will be used for CEPH, but a node needs a minimum of 8 disks for making an ideal CEPH pool for CSM.

<a name="storage-nics"></a>
#### Storage NICs

> **`NOTE:`** The 2nd port on each card is filled but not configured (reserved for future use).

- _Management Network:_ 2x PCIe cards, each with 2 heads/ports for a total of 4 ports split between two PCIe cards
