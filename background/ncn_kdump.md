# Kernel Dumps

* [What is `kdump`?](#what-is-kdump)
* [Usage](#usage)
  * [Configuration](#configuration)
  * [Dracut](#dracut)
  * [Enabling / disabling](#enabling--disabling)
* [Analyzing a dump](#analyzing-a-dump)
* [Troubleshooting](#troubleshooting)
  * [`kdump` has hung](#kdump-has-hung)
  * [Resetting `kdump`](#resetting-kdump)

## What is `kdump`?

At a high-level, `kdump` is a Linux tool that takes a dump of the system memory at the time of a crash for analysis.
This dump is taken on a local disk, or it can be taken on a network drive.

The dump can provide insight into the origin of the crash, which kernel modules were running and which may have attributed to the crash.

Taking a dump is only possible when a portion of memory is reserved for `kdump`, if the system goes down there is no way to
map which memory is free or in use. In the event of a crash, the Linux OS invokes `kexec` to load the `kdump` `initrd` into
the reserved memory space. This enables the system to continue running after a crash, during this time `kdump` provides tools
that enable taking a dump of everything loaded in memory.

The dumps are conventionally written to `/var/crash` for analysis on the same machine following a reboot (assuming it
doesn't crash again) or the disk can be relocated to a stable machine. If the dump is taken over the network, then analysis
can be done using that network drive.

For information on analyzing a dump, see [analyzing a dump](#analyzing-a-dump).

## Usage

This usage sections denotes how the non-compute nodes configure and configure `kdump`.

### Configuration

`kdump` is configured by the `/etc/sysconfig/kdump` file, this file controls various aspects of `kdump`
such as:

* The crash directory.
* The kernel parameters used in the `kdump` `initrd`.

### Dracut

For squashFS booted non-compute nodes, the `dracut-metal-mdsquash` module does some preparation for `kdump` by creating two symbolic links
in the [root overlay](./ncn_mounts_and_filesystems.md#overlayfs-and-persistence).

* `ls $(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/ROOTRAID)/boot` points to the actual `/boot` directory.
* `ls $(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/ROOTRAID)/crash` points to the actual `/var/crash` directory.

These symbolic links are important for `kdump` to work. `kdump` will mount the `ROOTRAID` as the root filesystem, and then look for:

* `/boot` to find the kernel image and `System.map` symbols file.
* The crash directory specified in `/etc/sysconfig/kdump` (e.g. `/crash`)

> ***Q/A*** *Why does `kdump` look for the `ROOTRAID`?
>
> `kdump` looks for the `ROOTRAID` because the `/etc/fstab` file denotes that `/` is on `LABEL=ROOTRAID`. `kdump` can look at either `/etc/fstab` or
> `/proc/mounts` to resolve the root. We don't use `/proc/mounts` because `kdump` will resolve the overlayFS as the root filesystem, which is very
> complicated to setup within the `kdump` `initrd`. Instead we tell `kdump` to read `/etc/fstab`, and then provide a mountable filesystem that isn't
> an overlayFS. The `ROOTRAID` is the upper-directory of the overlayFS for the root filesystem, anything written here will appear as if it was written
> to a filesystem mounted at `/`.

### Enabling / disabling

`kdump` is enabled when both the `kdump` package is installed *and* when the `crashkernel` parameter is present on the command line.

## Analyzing a dump

A dump can be inspected using the `crash` command. The analysis requires `kernel-default-debuginfo`
to be installed, the `crash` command can not thoroughly analyze a dump without that package.

1. SSH to the node that has the dump.

1. Install `kernel-default-debug` on the node with the dump.

   > ***NOTE*** The `kernel-default-debug` package for the current kernel (the kernel associated with the dump) must be installed.
   > The steps below load the `dracut-lib.sh` library which sets the `KVER` variable, this contains that value.

    * Install from the embedded repository.

    ```bash
    zypper ar https://packages.local/repository/csm-${CSM_RELEASE}-embedded csm-embedded
    . /srv/cray/scripts/metal/dracut-lib.sh
    zypper --plus-content debug in -y kernel-default-debuginfo=${KVER%-default}
    ```

    * Install from Artifactory if credentials are available.

        ```bash
        read -s ARTIFACTORY_USER
        ````

        ```bash
        read -s ARTIFACTORY_TOKEN
        ```

        ```bash
        zypper ar https://$ARTIFACTORY_USER:$ARTIFACTORY_TOKEN@artifactory.algol60.net/artifactory/sles-mirror/Updates/SLE-Module-Basesystem/15-SP3/x86_64/update_debug/ temp-debug
        ```

        ```bash
        . /srv/cray/scripts/metal/dracut-lib.sh
        zypper --plus-content debug in -y kernel-default-debuginfo=${KVER%-default}
        ```

1. On the node with the dump, go to the crash directory and choose a crash dump to load.

    ```bash
    cd /var/crash
    ls -l
    ```

    For exmaple, if `2022-09-07-14:31` was the crash we wanted to load then we'd change into that directory:

    ```bash
    cd 2022-09-07-14\:31
    ```

1. Run `crash` from within the crash directory.

    > ***NOTE*** This assumes that the crash's kernel and the running kernel are the same,
    > the loaded `dracut-lib.sh` provides the `KVER` variable which has a value equal to
    > that of the currently running kernel.

    ```bash
    . /srv/cray/scripts/metal/dracut-lib.sh
    crash ./vmlinux-${KVER}.gz ./vmcore
    ```

1. Now a crash console will be open, type `?` for help. This console will allow a user to inspect the dump.

## Troubleshooting

This section will assist an administrator or testor in broken dumps.

### `kdump` has hung

During the crash, if `kdump` hangs and never creates a dump after 5 minutes then the node should be reset.

An example of a frozen crash might look like this:

```text
[496626.051460] sysrq: Trigger a crash
[496626.054963] Kernel panic - not syncing: sysrq triggered crash
[496626.060807] CPU: 27 PID: 3860549 Comm: bash Kdump: loaded Tainted: G               X    5.3.18-150300.59.87-default #1 SLE15-SP3
[496626.072448] Hardware name: Intel Corporation S2600WFT/S2600WFT, BIOS SE5C620.86B.02.01.0012.C0001.070720200218 07/07/2020
[496626.083485] Call Trace:
[496626.086033]  dump_stack+0x66/0x8b
[496626.089440]  panic+0xfe/0x2e3
[496626.092499]  ? printk+0x52/0x72
[496626.095730]  sysrq_handle_crash+0x11/0x20
[496626.099828]  __handle_sysrq+0x89/0x140
[496626.103666]  write_sysrq_trigger+0x2b/0x40
[496626.107853]  proc_reg_write+0x39/0x60
[496626.111606]  vfs_write+0xad/0x1b0
[496626.115010]  ksys_write+0xa5/0xe0
[496626.118418]  do_syscall_64+0x5b/0x1e0
[496626.122170]  entry_SYSCALL_64_after_hwframe+0x61/0xc6
[496626.127307] RIP: 0033:0x7f803efe7b13
[496626.130972] Code: 0f 1f 80 00 00 00 00 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 64 8b 04 25 18 00 00 00 85 c0 75 14 b8 01 00 00 00 0f 05 <48> 3d 00 f0 ff ff 77 55 f3 c3 0f 1f 00 41 54 55 49 89 d4 53 48 89
[496626.149805] RSP: 002b:00007ffcbbb86128 EFLAGS: 00000246 ORIG_RAX: 0000000000000001
[496626.157457] RAX: ffffffffffffffda RBX: 0000000000000002 RCX: 00007f803efe7b13
[496626.164674] RDX: 0000000000000002 RSI: 0000564e28f05920 RDI: 0000000000000001
[496626.171894] RBP: 0000564e28f05920 R08: 000000000000000a R09: 0000000000000000
[496626.179111] R10: 00007f803eee8468 R11: 0000000000000246 R12: 00007f803f2cb500
[496626.186329] R13: 0000000000000002 R14: 00007f803f2d0c00 R15: 0000000000000002
[    0.315879] [Firmware Bug]: the BIOS has corrupted hw-PMU resources (MSR 38d is b0)
�[    2.859879] mce: Unable to init MCE device (rc: -5)
Unable to ioctl(KDSETLED) -- are you not on the console? (Inappropriate ioctl for device)
```

1. Reset the targetted node.

    * Set the `ipmi` username.

        ```bash
        read -s USERNAME
        ```

    * Set the `ipmi` password.

        ```bash
        read -s IPMI_PASSWORD
        ```

    * Set the node to target.

        ```bash
        NODE=ncn-w001
        ```

    * Reset the node.

        ```bash
        ipmitool -I lanplus -U $USERNAME -E -H ${NODE}-mgmt power reset 
        ```

### Resetting `kdump`

If `kdump` fails any of the validation tests, it can be easily remedied by purging the bad `initrd` and
restarting the `kdump.service` daemon.

1. Purge all old `kdump` images.

    ```bash
    rm -f /boot/initrd-*-kdump
    ```

1. Restart the `kdump.service` daemon. This will take 10-30 seconds.

    ```bash
    systemctl restart kdump.service
    ```

1. Verify a new `kdump` image exists for the current kernel.

    ```bash
    . /srv/cray/scripts/metal/dracut-lib.sh
    ls -l /boot/initrd-${KVER}-kdump
    ```
