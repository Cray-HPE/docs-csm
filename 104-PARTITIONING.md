# Partitioning
> This page will receive updates, but for now see this confluence article: https://connect.us.cray.com/confluence/display/MTL/NCN+Partition+Scheme

- **Ephemeral**: a disk that is not in the systems RAID
- **BOOTRAID**: a RAID disk device in the system

| FS Label | Partitions | Nodes	| Device | Size on Disk | Work Order | Memo
| --- | --- | ---| --- | --- | --- | --- |
| `SQFSRAID` | `/squashfs_management` | All NCNs | `BOOTRAID (MIRROR)` | `100 GiB` | [CASM-1885](https://connect.us.cray.com/jira/browse/MTL-1885) |  squashfs should compress our images to about 1/3rd their uncompressed size. (20G → 6.6G)  On pepsi's ncn-w001, we're at ~20G of non-volatile data storage needed. |
| `ROOTRAID` | `/` | All NCNs | `BOOTRAID (MIRROR)` | Max/Remainder | Present since Shasta-Preview 1 | Partitions from 1.3 are not currently mounted. |
| `CONRUN` | `/run/containerd` | All K8s Managers & Workers | Ephemeral | `75 GiB` | [MTL-916](https://connect.us.cray.com/jira/browse/MTL-916) | On pepsi ncn-w001, we have less than 200G of operational storage for this. |
| `K8SETCD` | `/var/lib/etcd` | All K8s Managers | Ephemeral | `32 GiB` | [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPPET-338) | |
| `CONLIB` | `/var/lib/containerd` | All K8s Managers & Workers | Ephemeral | `25%` | [MTL-892](https://connect.us.cray.com/jira/browse/MTL-892) | |
| `K8SKUBE` | `/var/lib/kubelet` | All K8s Managers & Workers | Ephemeral | `25%` |  [MTL-892](https://connect.us.cray.com/jira/browse/MTL-892) | |

These labels/partitions are deprecated in Shasta 1.4+:

| FS Label | Partitions | Nodes	| Device | Size on Disk | Work Order | Memo
| --- | --- | ---| --- | --- | --- | --- |
| `BOOTRAID` |	`/boot/efi` | All NCNs | `BOOTRAID (MIRROR)` | `500 MiB` | Present since Shasta-Preview 1 |
| `K8SEPH` | `/var/lib/cray/k8s_ephemeral` | ncn-w001, ncn-w002 | Ephemeral | Max/Remainder | [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |
| `CRAYINSTALL` | `/var/cray/vfat` | ncn-w001, ncn-w002 | Ephemeral | `12 GiB` |  [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |
| `CRAYVBIS` | `/var/cray/vbis` | ncn-w001, ncn-w002 | Ephemeral | `900 GiB` |  [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |
| `CRAYNFS` | `/var/lib/nfsroot/nmd` | ncn-w001, ncn-w002 | Ephemeral | `12 GiB` |  [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |

## Run-time Partition Layout

A booted NCN's disk layout could look like this:

```bash
# Worker node; 2 small SSDs, 1 large SSD
ncn-w002:~ # lsblk
NAME                MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
loop0                 7:0    0   256M  0 loop
loop1                 7:1    0   256M  0 loop
loop2                 7:2    0   3.1G  1 loop  /run/rootfsbase
loop3                 7:3    0   256M  0 loop  /run/initramfs/overlayfs
loop4                 7:4    0  29.3G  0 loop
└─live-overlay-pool 254:0    0   293G  0 dm
loop5                 7:5    0   293G  0 loop
└─live-overlay-pool 254:0    0   293G  0 dm
sda                   8:0    0 447.1G  0 disk
├─sda1                8:1    0  93.1G  0 part
│ └─md127             9:127  0  93.1G  0 raid1 /run/initramfs/live
└─sda2                8:2    0   354G  0 part
  └─md126             9:126  0   354G  0 raid1
sdb                   8:16   0 447.1G  0 disk
├─sdb1                8:17   0  93.1G  0 part
│ └─md127             9:127  0  93.1G  0 raid1 /run/initramfs/live
└─sdb2                8:18   0   354G  0 part
  └─md126             9:126  0   354G  0 raid1
sdc                   8:32   0   1.8T  0 disk
```

In the above snippet:
> The `mdXXX` numbers are chosen at random by the operating system.
- `md127` is the (mirror) RAID-1 for holding the squashFS images. 
- `md126` is the (mirror) RAID-1 for the root overlay.

