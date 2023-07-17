# NCN Mounts and Filesystems

The management non-compute nodes (NCNs) use drive storage for persistence and block storage. This page outlines
reference information for these disks, their partition tables, and their management.

* [Disk layout quick-reference tables](#disk-layout-quick-reference-tables)
* [OverlayFS and persistence](#overlayfs-and-persistence)
  * [`SQFSRAID` and `ROOTRAID` overlays](#sqfsraid-and-rootraid-overlays)
  * [Helpful commands](#helpful-commands)
  * [OverlayFS example](#overlayfs-examples)
    * [`mount` command](#mount-command)
    * [`losetup` command](#losetup-command)
    * [`lsblk` command](#lsblk-command)
  * [Persistent directories](#persistent-directories)
    * [Layering: Upper and lower directory](#layering-upper-and-lower-directory)
    * [Layering: Real world example](#layering-real-world-example)
  * [OverlayFS control](#overlayfs-control)
    * [Reset toggles](#reset-toggles)
    * [Reset on next boot](#reset-on-next-boot)
    * [Reset on every boot](#reset-on-every-boot)
    * [Re-sizing the persistent overlay](#re-sizing-the-persistent-overlay)
* [`metalfs`](#metalfs-service)
* [Old/retired FS labels](#oldretired-fs-labels)

## Disk layout quick-reference tables

The table below represents all recognizable FS labels on any given management node, varying slightly by node role (Kubernetes master or Kubernetes worker).

| Master | Worker | Storage | FS Label        | Partitions                    | Devices              |  Partition Size | OverlayFS | Notes                                                          |
| ------ | ------ | ------- | --------------- | ----------------------------- | -------------------- | --------------- | --------- | -------------------------------------------------------------- |
|   Yes  |  Yes   |   Yes   | `BOOTRAID`      | `/metal/recovery`             | RAID1: 2 small disks | 500 MiB         |    No     |                                                                |
|   Yes  |  Yes   |   Yes   | `SQFSRAID`      | `/run/initramfs/live`         | RAID1: 2 small disks | 25 GiB          |    Yes    |                                                                |
|   Yes  |  Yes   |   Yes   | `ROOTRAID`      | `/run/initramfs/overlayfs`    | RAID1: 2 small disks | 150 GiB         |    Yes    | The persistent image file is loaded from this partition[^1].   |
|   Yes  |  Yes   |   Yes   | `AUX`           | `/dev/md/AUX` _(Not Mounted)_ | RAID0: 2 small disks | 250 GiB         |    No     | Auxiliary RAID array for `cloud-init` to use.                  |
|   No   |   No   |   Yes   | `CEPHETC`       | `/etc/ceph`                   | LVM                  | 10 GiB          |    No     |                                                                |
|   No   |   No   |   Yes   | `CEPHVAR`       | `/var/lib/ceph`               | LVM                  | 60 GiB          |    No     |                                                                |
|   No   |   No   |   Yes   | `CONTAIN`       | `/run/containers`             | LVM                  | 60 GiB          |    No     |                                                                |
|   Yes  |  Yes   |   No    | `CRAYS3FSCACHE` | `/var/lib/s3fs_cache`         | LVM                  | 100 GiB         |    No     |                                                                |
|   No   |  Yes   |   No    | `CONRUN`        | `/run/containerd`             | Ephemeral            | 75 GiB          |    No     |                                                                |
|   No   |  Yes   |   No    | `CONLIB`        | `/run/lib-containerd`         | Ephemeral            | 25%             |    Yes    |                                                                |
|   Yes  |   No   |   No    | `ETCDLVM`       | `/run/lib-etcd`               | Ephemeral            | 32 GiB          |    Yes    |                                                                |
|   Yes  |   No   |   No    | `K8SLET`        | `/var/lib/kubelet`            | Ephemeral            | 25%             |    No     |                                                                |

[^1]:  When the image is loaded, the underlying drive is lazily unmounted (`umount -l`), so that it will close once the overlay closes.

The above table's rows with OverlayFS map their `Mount Paths` to the `Upper Directory` in the table below:

> The "OverlayFS Name" is the name used in `/etc/fstab` and seen in the output of `mount`.

| OverlayFS Name         | Upper Directory       | Lower Directory       |
| ---------------------- | --------------------- | --------------------- |
| `etcd_overlayfs`       | `/run/lib-etcd`       | `/var/lib/etcd`       |
| `containerd_overlayfs` | `/run/lib-containerd` | `/var/lib/containerd` |

> For notes on previous/old labels, see [Old/retired FS labels](#oldretired-fs-labels).

## OverlayFS and persistence

The overlays used on NCNs enable two critical functions:

* Changes to data and new data will persist between reboots.
* RAM (memory) is freed because the data is stored on block devices (SATA/PCIe).

There are a few overlays used for NCN image boots:

* `ROOTRAID` is the persistent root OverlayFS. It commits and saves all changes made to the running OS.
* `CONLIB` is a persistent OverlayFS for `containerd`. It commits and saves all new changes while allowing read-through to pre-existing data from the SquashFS.
* `ETCDK8S` is a persistent OverlayFS for etcd. It works like the `CONLIB` OverlayFS, but it exists in an encrypted LUKS2 partition.

### `SQFSRAID` and `ROOTRAID` overlays

* `/run/rootfsbase` is the SquashFS image itself.
* `/run/initramfs/live` is the SquashFS's storage array, where one or more SquashFS can be stored.
* `/run/initramfs/overlayfs` is the OverlayFS storage array, where the persistent directories are stored.
* `/run/overlayfs` and `/run/ovlwork` are symbolic links to `/run/initramfs/overlayfs/overlayfs-SQFSRAID-$(blkid -s UUID -o value /dev/disk/by-label/SQFSRAID)` and the neighboring "work" directory[^2].

[^2]: The "work" directory is where the operating system processes data. It is the interim where data passes between RAM and persistent storage.

### Helpful commands

| Commands              | Details                                         |
| --------------------  | ----------------------------------------------- |
| `lsblk`, `lsblk -f`   | Shows how the RAIDs and disks are mounted       |
| `losetup -a`          | Shows where the SquashFS is mounted from        |
| `mount \| grep ' / '` | Shows the overlay being layered on the SquashFS |

### OverlayFS examples

#### `mount` command

```bash
mount | grep  ' / '
```

Example output:

```text
LiveOS_rootfs on / type overlay (rw,relatime,lowerdir=/run/rootfsbase,upperdir=/run/overlayfs,workdir=/run/ovlwork)
```

```text
                                             ^^^R/O^SQUASHFS IMAGE^^^|^^^ R/W PERSISTENCE ^^^|^^^^^^INTERIM^^^^^^
```

#### `losetup` command

```bash
losetup -a
```

Example output:

```text
/dev/loop0: [2430]:100 (/run/initramfs/live/LiveOS/filesystem.squashfs)
```

#### `lsblk` command

Below is the layout of what a persistent system looks like.

```bash
lsblk
```

Example output:

```text
NAME                MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
loop0                 7:0    0   3.8G  1 loop  /run/rootfsbase
sda                   8:0    1 447.1G  0 disk
├─sda1                8:1    1   476M  0 part
│ └─md127             9:127  0   476M  0 raid1
├─sda2                8:2    1  92.7G  0 part
│ └─md126             9:126  0  92.6G  0 raid1 /run/initramfs/live
└─sda3                8:3    1 279.4G  0 part
  └─md125             9:125  0 279.3G  0 raid1 /run/initramfs/overlayfs
sdb                   8:16   1 447.1G  0 disk
├─sdb1                8:17   1   476M  0 part
│ └─md127             9:127  0   476M  0 raid1
├─sdb2                8:18   1  92.7G  0 part
│ └─md126             9:126  0  92.6G  0 raid1 /run/initramfs/live
└─sdb3                8:19   1 279.4G  0 part
  └─md125             9:125  0 279.3G  0 raid1 /run/initramfs/overlayfs
sdc                   8:32   1 447.1G  0 disk
└─ETCDLVM           254:0    0 447.1G  0 crypt
  └─etcdvg0-ETCDK8S 254:1    0    32G  0 lvm   /run/lib-etcd
```

Note that the above output means that persistent capacity is there, but administrators should beware of reset toggles on unfamiliar systems.
There are toggles to reset overlays that are, by default, toggled `off` (so that data persistence by default is safe, but one should
not assume). For more information, see [OverlayFS control](#overlayfs-control).

### Persistent directories

**Not all directories are persistent!**

Only the following directories are persistent _by default_:

* `/etc`
* `/home`
* `/root`
* `/run/containerd`
* `/run/lib-containerd`
* `/run/lib-etcd`
* `/run/lib/kubelet`
* `/srv`
* `/tmp`
* `/var`

This initial set is managed by dracut. When using a reset toggle, the above list is reset to the above default value. While more directories can be added to the list,
they will be eradicated when enabling a reset toggle. For more information, see [OverlayFS control](#overlayfs-control).

(`ncn-m#`) These are all provided through the overlay from `/run/overlayfs`:

```bash
cd /run/overlayfs && ls -l
```

Example output:

```text
total 0
drwxr-xr-x 8 root root 290 Oct 15 22:41 etc
drwxr-xr-x 3 root root  18 Oct 15 22:41 home
drwx------ 3 root root  39 Oct 13 16:53 root
drwxr-xr-x 3 root root  18 Oct  5 19:16 srv
drwxrwxrwt 2 root root  85 Oct 16 14:50 tmp
drwxr-xr-x 8 root root  76 Oct 13 16:52 var
```

> Remember: `/run/overlayfs` is a symbolic link to the real disk `/run/initramfs/overlayfs/*`.

#### Layering Upper and lower directory

The file system the user is working on is really two layered file systems (overlays).

* The lower layer (also called the lower directory) is the SquashFS image itself. It is read-only and provides all that is needed to run.
* The upper layer (also called the upper directory) is the OverlayFS. It is read-write, and does a bit-wise `xor` with the lower layer.
* Anything in the upper layer takes precedence by default.

> There are fancier options for overlays, such as multiple lower layers, copy-up (lower layer precedence),
> and opaque (removing a directory in the upper layer hides it in the lower layer). For details, see
> [Overlay Filesystem: `inode` properties](https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html#inode-properties).

#### Layering Real world example

Take `/root` for example.

(`ncn#`) The upper directory (the overlay) has these files:

```bash
ls -l /run/overlayfs/root/
```

Example output:

```text
total 4
-rw------- 1 root root 252 Nov  4 18:23 .bash_history
drwxr-x--- 4 root root  37 Nov  4 04:35 .kube
drwx------ 2 root root  29 Oct 21 21:57 .ssh
```

(`ncn#`) The lower directory (the SquashFS image) has these files:

```bash
ls -l /run/rootfsbase/root/
```

Example output:

```text
total 1
-rw------- 1 root root   0 Oct 19 15:31 .bash_history
drwxr-xr-x 2 root root   3 May 25  2018 bin
drwx------ 3 root root  26 Oct 21 22:07 .cache
drwx------ 2 root root   3 May 25  2018 .gnupg
drwxr-xr-x 4 root root  57 Oct 19 15:23 inst-sys
drwxr-xr-x 2 root root  33 Oct 19 15:33 .kbd
drwxr-xr-x 5 root root  53 Oct 19 15:34 spire
drwx------ 2 root root  70 Oct 21 21:57 .ssh
-rw-r--r-- 1 root root 172 Oct 26 15:25 .wget-hsts
```

Notice the following:

* The `.bash_history` file in the lower directory is 0 bytes, but it is 252 bytes in the upper directory.
* The `.kube` directory exists in the upper directory, but not the lower directory.

(`ncn#`) Keeping the above in mind, look at the contents of `/root` itself:

```bash
ls -l /root
```

Example output:

```text
total 5
-rw------- 1 root root 252 Nov  4 18:23 .bash_history
drwxr-xr-x 2 root root   3 May 25  2018 bin
drwx------ 3 root root  26 Oct 21 22:07 .cache
drwx------ 2 root root   3 May 25  2018 .gnupg
drwxr-xr-x 4 root root  57 Oct 19 15:23 inst-sys
drwxr-xr-x 2 root root  33 Oct 19 15:33 .kbd
drwxr-x--- 4 root root  37 Nov  4 04:35 .kube
drwxr-xr-x 5 root root  53 Oct 19 15:34 spire
drwx------ 1 root root  29 Oct 21 21:57 .ssh
-rw-r--r-- 1 root root 172 Oct 26 15:25 .wget-hsts
```

Notice the following:

* `.bash_history` matches the upper directory.
* The `.kube` directory exists here.

The take-away here is that any change done to `/root/` will persist through `/run/overlayfs/root` and will take precedence to the SquashFS image root.

### OverlayFS control

These features or toggles can be passed on the kernel command line to change the behavior of the OverlayFS.

#### Reset toggles

The overlay FS provides a few reset toggles to clear out the persistence directories without reinstall.

**The toggles require rebooting.**

#### Reset on next boot

The preferred way to reset persistent storage is to use the OverlayFS reset toggle.

Modify the boot command line on the PXE server, adding this

```bash
# Reset the overlay on boot
rd.live.overlay.reset=1
```

Once reset, if wanting to enable persistence again, then simply revert the change; the next reboot
will persist.

```bash
# Cease resetting the OverlayFS
rd.live.overlay.reset=0
```

#### Reset on every boot

There are two options one can leave enabled to accomplish this:

1. `rd.live.overlay.reset=1` will eradicate/recreate the overlay every reboot.
1. `rd.live.overlay.readonly=1` will clear the overlay on every reboot.

For long-term usage, `rd.live.overlay.readonly=1` should be added to the command line.

The `reset=1` toggle is usually used to fix a problematic overlay. For example, if one wants to refresh
and purge the overlay completely.

```bash
# Authorize METAL to purge
metal.no-wipe=0 rd.live.overlay.reset=1
```

> Note: `metal.no-wipe=1` does not protect against `rd.live.overlay.reset`. `metal.no-wipe` is not
> a feature of `dmsquash-live`.

#### Re-sizing the persistent overlay

* Default size: 300 GiB
* File system: XFS

The overlay can be resized to fit a variety of needs or use cases. The size is provided directly
on the command line. Any value can be provided, but it must be in **megabytes**.

If resetting the overlay on a deployed node, `rd.live.overlay.reset=1` must also be set.

It is recommended to set the size before deployment. There is a linkage between the `metal-dracut` module and the
`live-module` that makes this inflexible.

```bash
# Use a 300 GiB OverlayFS (default)
rd.live.overlay.size=307200

# Use a 1 TiB OverlayFS
rd.live.overlay.size=1000000
```

## `metalfs` Service

The `metalfs` `systemd` service will try to mount any metal-created partitions.

This runs against the `/run/initramfs/overlayfs/fstab.metal` when it exists. This file is dynamically created by most metal dracut modules.

(`ncn#`) The service will continuously attempt to mount the partitions. If problems arise, then stop the service:

```bash
systemctl stop metalfs
```

## Old/retired FS labels

This is a table of deprecated FS labels/partitions from Shasta 1.3 (no longer in Shasta 1.4 / CSM 0.9 and onwards).

| FS Label      | Partitions                    | Nodes                   | Device    | Size on Disk  |
| ------------- | ----------------------------- | ----------------------- | --------- | ------------- |
| `K8SKUBE`     | `/var/lib/kubelet`            | `ncn-w001`, `ncn-w002`  | Ephemeral | Max/Remainder |
| `K8SEPH`      | `/var/lib/cray/k8s_ephemeral` | `ncn-w001`, `ncn-w002`  | Ephemeral | Max/Remainder |
| `CRAYINSTALL` | `/var/cray/vfat`              | `ncn-w001`, `ncn-w002`  | Ephemeral | 12 GiB        |
| `CRAYVBIS`    | `/var/cray/vbis`              | `ncn-w001`, `ncn-w002`  | Ephemeral | 900 GiB       |
| `CRAYNFS`     | `/var/lib/nfsroot/nmd`        | `ncn-w001`, `ncn-w002`  | Ephemeral | 12 GiB        |
| `CRAYSDU`     | `/var/lib/sdu`                | All masters and workers | LVM       | 100 GiB       |
