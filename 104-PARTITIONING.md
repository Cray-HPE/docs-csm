# Partitioning
> This page will receive updates, but for now see this confluence article: https://connect.us.cray.com/confluence/display/MTL/NCN+Partition+Scheme

## Partition Layout

- **Ephemeral**: a disk that is not in the systems RAID
- **BOOTRAID**: a RAID disk device in the system

| FS Label | Partitions | Nodes	| Device | Size on Disk | Work Order | Memo
| --- | --- | ---| --- | --- | --- | --- |
| `SQFSRAID` | `/squashfs_management` | All NCNs | `BOOTRAID (MIRROR)` | `100 GiB` | [CASM-1885](https://connect.us.cray.com/jira/browse/MTL-1885) |  squashfs should compress our images to about 1/3rd their uncompressed size. (20G → 6.6G)  On pepsi's ncn-w001, we're at ~20G of non-volatile data storage needed. |
| `ROOTRAID` | `/` | All NCNs | `BOOTRAID (MIRROR)` | Max/Remainder | Present since Shasta-Preview 1 | Partitions from 1.3 are not currently mounted. |
| `BOOTRAID` |	`/boot/efi` | All NCNs | `BOOTRAID (MIRROR)` | `500 MiB` | Present since Shasta-Preview 1 |
| `CONRUN` | `/run/containerd` | All K8s Managers & Workers | Ephemeral | `75 GiB` | [MTL-916](https://connect.us.cray.com/jira/browse/MTL-916) | On pepsi ncn-w001, we have less than 200G of operational storage for this. |
| `K8SETCD` | `/var/lib/etcd` | All K8s Managers | Ephemeral | `32 GiB` | [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPPET-338) | |
| `CONLIB` | `/var/lib/containerd` | All K8s Managers & Workers | Ephemeral | `25%` | [MTL-892](https://connect.us.cray.com/jira/browse/MTL-892) | |
| `K8SKUBE` | `/var/lib/kubelet` | All K8s Managers & Workers | Ephemeral | `25%` |  [MTL-892](https://connect.us.cray.com/jira/browse/MTL-892) | |
| `K8SEPH` | `/var/lib/cray/k8s_ephemeral` | ncn-w001, ncn-w002 | Ephemeral | Max/Remainder | [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |
| `CRAYINSTALL` | `/var/cray/vfat` | ncn-w001, ncn-w002 | Ephemeral | `12 GiB` |  [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |
| `CRAYVBIS` | `/var/cray/vbis` | ncn-w001, ncn-w002 | Ephemeral | `900 GiB` |  [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |
| `CRAYNFS` | `/var/lib/nfsroot/nmd` | ncn-w001, ncn-w002 | Ephemeral | `12 GiB` |  [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |

#### Shasta 1.4 TODOs:
> https://connect.us.cray.com/jira/browse/MTL-1108
> https://connect.us.cray.com/jira/browse/MTL-1146