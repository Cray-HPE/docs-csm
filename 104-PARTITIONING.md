# Partitioning
> This page will receive updates, but for now see this confluence article: https://connect.us.cray.com/confluence/display/MTL/NCN+Partition+Scheme

- **Ephemeral**: a disk that is not in the systems RAID
- **BOOTRAID**: a RAID disk device in the system

| FS Label | Partitions | Nodes	| Device | Size on Disk | Work Order | Memo
| --- | --- | ---| --- | --- | --- | --- |
| `BOOTRAID` |	`/boot/efi` | All NCNs | `BOOTRAID (MIRROR)` | `500 MiB` | Present since Shasta-Preview 1 |
| `SQFSRAID` | `/run/initramfs/live` | All NCNs | `BOOTRAID (MIRROR)` | `100 GiB` | [CASM-1885](https://connect.us.cray.com/jira/browse/MTL-1885) |  squashfs should compress our images to about 1/3rd their uncompressed size. (20G → 6.6G)  On pepsi's ncn-w001, we're at ~20G of non-volatile data storage needed. |
| `ROOTRAID` | Background | All NCNs | `BOOTRAID (MIRROR)` | Max/Remainder | Present since Shasta-Preview 1 | The persistent image file is loaded from this partition, when the image file is loaded the underlying drive is lazily unmounted (`umount -l`) so that when the overlay closes the disk follows suit. |
| `CONRUN` | `/run/containerd` | All K8s Managers & Workers | Ephemeral | `75 GiB` | [MTL-916](https://connect.us.cray.com/jira/browse/MTL-916) | On pepsi ncn-w001, we have less than 200G of operational storage for this. |
| `K8SETCD` | `/var/lib/etcd` | All K8s Managers | Ephemeral | `32 GiB` | [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPPET-338) | |
| `CONLIB` | `/var/lib/containerd` | All K8s Managers & Workers | Ephemeral | `25%` | [MTL-892](https://connect.us.cray.com/jira/browse/MTL-892) | |
| `K8SKUBE` | `/var/lib/kubelet` | All K8s Managers & Workers | Ephemeral | `25%` |  [MTL-892](https://connect.us.cray.com/jira/browse/MTL-892) | |

These labels/partitions are deprecated in Shasta 1.4+:

| FS Label | Partitions | Nodes	| Device | Size on Disk | Work Order | Memo
| --- | --- | ---| --- | --- | --- | --- |
| `K8SEPH` | `/var/lib/cray/k8s_ephemeral` | ncn-w001, ncn-w002 | Ephemeral | Max/Remainder | [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |
| `CRAYINSTALL` | `/var/cray/vfat` | ncn-w001, ncn-w002 | Ephemeral | `12 GiB` |  [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |
| `CRAYVBIS` | `/var/cray/vbis` | ncn-w001, ncn-w002 | Ephemeral | `900 GiB` |  [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |
| `CRAYNFS` | `/var/lib/nfsroot/nmd` | ncn-w001, ncn-w002 | Ephemeral | `12 GiB` |  [CASMPET-338](https://connect.us.cray.com/jira/browse/CASMPET-338) [CASMPET-342](https://connect.us.cray.com/jira/browse/CASMPET-342) | No longer mounted/used in shasta-1.4 |


# Overlay File-Systems

There are a few overlays used for NCN image boots.

1. The Ephemeral SquashFS Overlay
2. The Persistent OverlayFS


You can see the used overlays with `losetup -a`. Here we see our thin overlays for meta (loop2) and data (loop3), 
along with our squashFS image (loop0) and its personal/coupled persistent overlayFS (loop1):
```bash
ncn-m002:~ # losetup -a
/dev/loop1: [2431]:103 (/LiveOS/overlay-SQFSRAID-7c00c2a2-12c9-42a3-b1d4-b2d24806143a)
/dev/loop2: [0025]:21753 (/run/initramfs/thin-overlay/meta)
/dev/loop0: [2430]:100 (/run/initramfs/live/LiveOS/ncn-m002.squashfs)
/dev/loop3: [0025]:15485 (/run/initramfs/thin-overlay/data)
```

Ultimately you can find more information for customizing the overlay right off [dracut live manual](https://manpages.debian.org/testing/dracut-core/dracut.cmdline.7.en.html#Booting_live_images).

## Ephemeral SquashFS Overlay

The squashFS images for 1.4 are loaded from local disk, any changes done to the running image are
lost on reboot.

## Persistent OverlayFS

Alongside the squashFS overlay is a persistent overlayFS. This overlay resides as a file on the
`ROOTRAID` within a subdirectory matchimg the value of `rd.live.dir` (default: `/LiveOS`).

This overlayFS provides persistence across reboots, allowing the squashFS overlay to upgrade while
the node retains data.

Not all directories are persistent.

#### Persistent Directories

Only the following directories are persistent:

- `etc`
- `home`
- `root`
- `srv`
- `tmp`
- `var`

These are all provided through the Overlay from `/run/overlayfs`:
```bash
ncn-m001:/run/overlayfs # ls -l
total 0
drwxr-xr-x 8 root root 290 Oct 15 22:41 etc
drwxr-xr-x 3 root root  18 Oct 15 22:41 home
drwx------ 3 root root  39 Oct 13 16:53 root
drwxr-xr-x 3 root root  18 Oct  5 19:16 srv
drwxrwxrwt 2 root root  85 Oct 16 14:50 tmp
drwxr-xr-x 8 root root  76 Oct 13 16:52 var
```

These are mounted in the `upperdir` of the LiveOS overlay, wehre the `lowerdir` is the squashFS image's original contents. 

You can see upper and lower directories by inspecting `mount` for all rootfs:

```bash
ncn-m002:~ # mount | grep root
/dev/loop0 on /run/rootfsbase type squashfs (ro,relatime)
LiveOS_rootfs on / type overlay (rw,relatime,lowerdir=/run/rootfsbase,upperdir=/run/overlayfs,workdir=/run/ovlwork)
```

## Erasing the Persistent Storage

The overlayFS is persistent by default, that is it will not reset itself on reboot. There are two 
toggles at the users disposal for resetting the overlay.

### Standard Resetting overlay Contents

The preferred way to reset persistent storage is to use the overlayFS reset toggle.

Modify the boot command line on the PXE server, adding this

```bash
# Reset the overlay on boot
rd.live.overlay.reset=1
```

Once reset, you may want to enable persistence again. Simply revert your change and the next reboot
will persist.

```bash
# Cease resetting the overlayFS
rd.live.overlay.reset=0
```

### Purging the overlayFS

To nuke the overlayFS file itself, you must set two-keys on the kernel commandline and reboot the node.

```
# Authorize METAL to purge
metal.no-wipe=0 rd.live.overlay.reset=1
```

> Note: `metal.no-wipe=1` does not protect against `rd.live.overlay.reset`, `metal.no-wipe` is not
> a feature of dmsquash-live.

## Re-sizing the Persistent Overlay

- Default Size: 300 GiB
- File System: XFS

The overlay can be resized to fit a variety of needs or use cases. The size is provided directly
on the command line. Any value can be provided, but it must be in *megabytes*.

```bash
# Use a 300 GiB overlayFS (default)
rd.live.overlay.size=307200

# Use a 1 TiB overlayFS
rd.live.overlay.size=1000000
``` 

## Thin Overlay Feature

The persistent overlayFS leverages newer, "thin" overlays that support discards and that will
free blocks that are not claimed by the file system. This means that memory is free/released
when the filesystem does not claim it anymore.

Thin overlays can be disabled, and instead classic DM Snapshots can be used to manage the overlay. This
will use more RAM. It is not recommended, since dmraid is not included in the initrd.

```shell script
# Enable (default)
rd.live.overlay.thin=1

# Disable (not recommended; undesirable RAM waste)
rd.live.overlay.thin=0
```

## Read-Only Persistent Storage

Read-only mode will clear any changes done to the system on reboot. The overlayFS upper directory is
overlayed atop a read-only lower directory. The changes made to the live upperdir will occlude the 
lowerdir until reboot.

> This is different from `reset`, where the overlay gets recreated instead of reverted.

The persistent overlayFS is still mounted, despite not showing in the `lsblk` output below..
```bash
ncn-w002:~ # lsblk
NAME                MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
loop0                 7:0    0   3.1G  1 loop  /run/rootfsbase
loop1                 7:1    0   256M  1 loop  /run/initramfs/overlayfs
loop2                 7:2    0    30G  0 loop
└─live-overlay-pool 254:0    0   300G  0 dm
loop3                 7:3    0   300G  0 loop
└─live-overlay-pool 254:0    0   300G  0 dm
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

We can see that we still have an `upperdir`, and that it provides the same directories.

```
ncn-w002:~ # losetup -a
/dev/loop1: [2430]:100 (/LiveOS/overlay-SQFSRAID-6ef9f6eb-1f0c-48fa-b94c-2706180869f7)
/dev/loop2: [0025]:21631 (/run/initramfs/thin-overlay/meta)
/dev/loop0: [2431]:100 (/run/initramfs/live/LiveOS/ncn-w002.squashfs)
/dev/loop3: [0025]:35889 (/run/initramfs/thin-overlay/data)
```

Notice how the `LiveOS_rootfs` `lowerdir` is named "`overlayfs-r`", but we still also have our familiar overlayFS from read-write. This
is expected.
 
```bash
ncn-w002:~ # mount | grep root
/dev/loop0 on /run/rootfsbase type squashfs (ro,relatime)
LiveOS_rootfs on / type overlay (rw,relatime,lowerdir=/run/overlayfs-r:/run/rootfsbase,upperdir=/run/overlayfs,workdir=/run/ovlwork)
```

```bash
ncn-w002:~ #  ls -l /run/overlayfs-r/
total 4
drwxr-xr-x 10 root root 4096 Oct 19 09:55 etc
drwxr-xr-x  3 root root   18 Oct 19 09:55 home
drwx------  3 root root   39 Oct 16 19:41 root
drwxr-xr-x  3 root root   18 Oct 12 16:37 srv
drwxrwxrwt  2 root root   85 Oct 19 10:09 tmp
drwxr-xr-x  8 root root   76 Oct 16 19:40 var
ncn-w002:~ #  ls -l /run/overlayfs
total 0
drwxr-xr-x 5 root root 120 Oct 19 09:55 etc
drwx------ 2 root root  60 Oct 16 19:41 root
drwxrwxrwt 3 root root  60 Oct 19 10:22 tmp
drwxr-xr-x 6 root root 120 Oct 16 19:40 var
```

## Read-Write OverlayFS

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
