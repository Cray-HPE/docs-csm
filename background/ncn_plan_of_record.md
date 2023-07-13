# NCN Plan of Record

This document outlines the hardware necessary to meet CSM's Plan of Record (PoR). This serves as the **minimum, necessary** pieces required per each server in the management plane.

1. If the system's NICs do not align to the PoR NICs outlined below (e.g. Onboard NICs are used instead of PCIe), then follow [Customize PCIe Hardware](../operations/node_management/Customize_PCIe_Hardware.md) before booting the NCN(s).
1. If there are more disks than what is listed below in the PoR for disks, then follow [Customize Disk Hardware](../operations/node_management/Customize_Disk_Hardware.md) before booting the NCN(s).

* [Disks](#disks)
* [Masters NCNs](#masters-ncns)
  * [Disks](#master-disks)
  * [NICs](#master-nics)
* [Workers NCNs](#workers-ncns)
  * [Disks](#worker-disks)
  * [NICs](#worker-nics)
* [Storage NCNs](#storage-ncns)
  * [Disks](#storage-disks)
  * [NICs](#storage-nics)

> **`NOTE:`** Several components below are necessary to provide redundancy in the event of hardware failure.

## Disks

Any of the disks may be used over the following buses:

* SAS
* SATA
* NVME

> ***NOTE*** USB is implicitly excluded during disk selection and wiping. The NCN's deployment code will wipe all disks if they are a RAID or in the above list.
> The manual wipes will exclude USB, but it is recommended to verify that the manual wipes are actually doing so.

The OS disks are chosen by selecting the smallest disks. Two disks are used for OS disks by default.

The number of OS disks can be modified by the [`metal.disks` kernel parameter](https://github.com/Cray-HPE/dracut-metal-mdsquash/blob/main/README.adoc#metaldisks).

## Masters NCNs

### Master disks

* *Operating System:* `2x` SSDs of equal size that are at least `500GiB` (`524288000000` bytes)
* *ETCD:* `1x` SSD that is at least `500GiB` (`524288000000 bytes`) (This disk will be fully encrypted with LUKS2)

### Master NICs

> **`NOTE:`** The 2nd port on each card is unused/empty (reserved for future use).

* *Management Network:* `2x` PCIe cards, with 1 or 2 heads/ports each for a total of 4 ports split between two PCIe cards

## Workers NCNs

### Worker disks

* *Operating System:* `2x` SSDs of equal size that are at least `500GiB` (524288000000 bytes)
* *Ephemeral:* `1x` SSD larger than or equal to `1TiB` (`1048576000000` bytes)

### Worker NICs

> **`NOTE:`** There is no PCIe redundancy for the management network for worker NCNs. The only redundancy set up for workers is port redundancy.

* *Management Network:* `1x` PCIe card with 2 heads/ports for a total of 2 ports dedicated to a single PCIe card
* *High-Speed Network:* `1x` PCIe card capable of `100Gbps` (e.g. ConnectX-5 or Cassini), with 1 or 2 heads/ports

## Storage NCNs

### Storage disks

* *Operating System:* `2x` SSDs of equal size that are at least `500GiB` (`524288000000 bytes`)
* *CEPH:* `8x` SSDs of any size

> **`NOTE:`** Any available disk that is not consumed by the operating system will be used for Ceph, but a node needs a minimum of 8 disks for making an ideal Ceph pool for CSM.

### Storage NICs

> **`NOTE:`** The 2nd port on each card is filled but not configured (reserved for future use).

* *Management Network:* `2x` PCIe cards, each with two heads/ports for a total of four ports split between two PCIe cards
