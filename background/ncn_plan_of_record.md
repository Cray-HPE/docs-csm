# NCN Plan of Record

This document outlines the hardware necessary to meet CSM's Plan of Record (PoR). This serves as the
**minimum, necessary** pieces required per each server in the management plane.

1. If the system's NICs do not align to the PoR NICs outlined below (e.g. Onboard NICs are used
   instead of PCIe), then
   follow [Customize PCIe Hardware](../operations/node_management/Customize_PCIe_Hardware.md) before
   booting the NCN(s).
1. If there are more disks than what is listed below in the PoR for disks, then
   follow [Customize Disk Hardware](../operations/node_management/Customize_Disk_Hardware.md) before
   booting the NCN(s).

* [Disks](#disks)
* [NICs](#nics)
  * [Kubernetes Masters](#kubernetes-masters)
  * [Kubernetes Workers](#kubernetes-workers)
  * [Ceph Storage](#ceph-storage)

## Disks

A minimum size[^1] is denoted for each disk

| Minimum Size (bytes) | Quantity | Purpose                    | NCN Role(s)                                      |
|---------------------:|---------:|:---------------------------|:-------------------------------------------------|
|       `375809638400` |  `2`[^2] | Operating System RAID[^3]  | `k8s-masters`, `k8s-workers`, and `storage-ceph` |
|       `375809638400` |      `1` | `etcd`                     | `k8s-masters`                                    |
|      `1048576000000` |      `1` | `containerd` and `kubelet` | `k8s-workers`                                    |

> ***NOTE*** Storage-CEPH nodes require disks for CEPH OSDs; we recommend using `6x` `1.92TiB` disks
> for this purpose. It is important to note that neither the quantity nor a minimum size is enforced
> for these disks, the Storage-CEPH installer will consume any and all disks that do not have a
> partition table and that are locally attached to the node.

[^1]: Size is compared using `-ge` (`>=`); a disk must be equal or larger to the minimum size for it
to be applicable for the denoted purpose.
[^2]: The number of disks needed is configurable,
see [`metal.disks`](https://github.com/Cray-HPE/dracut-metal-mdsquash/blob/main/README.adoc#metaldisks)
[^3]: The RAID is configurable,
see [`metal.md-level`](https://github.com/Cray-HPE/dracut-metal-mdsquash/blob/main/README.adoc#metalmd-level)

## NICs

### Kubernetes Masters

> **`NOTE:`** The 2nd port on each card is unused/empty (reserved for future use).

* *Management Network:* `2x` PCIe cards, with 1 or 2 heads/ports each for a total of 4 ports split
  between two PCIe cards

### Kubernetes Workers

> **`NOTE:`** There is no PCIe redundancy for the management network for worker NCNs. The only
> redundancy set up for workers is port redundancy.

* *Management Network:* `1x` PCIe card with 2 heads/ports for a total of 2 ports dedicated to a
  single PCIe card
* *High-Speed Network:* `1x` PCIe card capable of `100Gbps` (e.g. ConnectX-5 or Cassini), with 1 or
  2 heads/ports

### Ceph Storage

> **`NOTE:`** The 2nd port on each card is filled but not configured (reserved for future use).

* *Management Network:* `2x` PCIe cards, each with two heads/ports for a total of four ports split
  between two PCIe cards
