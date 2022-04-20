<a name="initrd-not-found"></a>
### `initrd.img.xz` Not Found

This is a problem that is fixed in CSM 1.0+, but if your system was upgraded from CSM 0.9 you may run into this. Below is the full error seen when attempting to boot:

```
Loading Linux  ...
Loading initial ramdisk ...
error: file `/boot/grub2/../initrd.img.xz' not found.
Press any key to continue...
[    2.528752] Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
[    2.537264] CPU: 0 PID: 1 Comm: swapper/0 Not tainted 5.3.18-24.64-default #1 SLE15-SP2
[    2.545499] Hardware name: Cray Inc. R272-Z30-00/MZ32-AR0-00, BIOS C27 05/12/2021
[    2.553196] Call Trace:
[    2.555716]  dump_stack+0x66/0x8b
[    2.559127]  panic+0xfe/0x2d7
[    2.562184]  mount_block_root+0x27d/0x2e1
[    2.566306]  ? set_debug_rodata+0x11/0x11
[    2.570431]  prepare_namespace+0x130/0x166
[    2.574645]  kernel_init_freeable+0x23f/0x26b
[    2.579125]  ? rest_init+0xb0/0xb0
[    2.582623]  kernel_init+0xa/0x110
[    2.586127]  ret_from_fork+0x22/0x40
[    2.590747] Kernel Offset: 0x0 from 0xffffffff81000000 (relocation range: 0xffffffff80000000-0xffffffffbfffffff)
[    2.690969] ---[ end Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0) ]---
```

#### Fix

Follow these steps on any NCN to fix the issue:

   1. Install the Shasta 1.4 (a.k.a. CSM 0.9) `csm-install-workarounds` RPM. See the CSM 0.9 documentation for details on how to do this.

   1. Run the `CASMINST-2689.sh` script from the `CASMINST-2689` workaround at the `livecd-post-reboot` breakpoint:

      ```bash
      ncn# /opt/cray/csm/workarounds/livecd-post-reboot/CASMINST-2689/CASMINST-2689.sh
      ```

   1. Run these commands:

      ```bash
      ncn# for i in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ' '); do
               scp -r /opt/cray/csm/workarounds/livecd-post-reboot/CASMINST-2689 $i:/opt/cray/csm/workarounds/livecd-post-reboot/
            done
      ncn# pdsh -b -S -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') '/opt/cray/csm/workarounds/livecd-post-reboot/CASMINST-2689/CASMINST-2689.sh'
      ```

   1. Remove the Shasta 1.4 install workaround RPM from the NCN.

      ```bash
      ncn# rpm -e csm-install-workarounds
      ```

#### Validate

Running the script again will produce this output:

```
Examining /metal/boot/boot/kernel...kernel is OK.
Examining /metal/boot/boot/initrd.img.xz...initrd.img.xz is OK.
Examining /metal/boot/boot/kernel...kernel is OK.
Examining /metal/boot/boot/initrd.img.xz...initrd.img.xz is OK.
Examining /metal/boot/boot/kernel...kernel is OK.
Examining /metal/boot/boot/initrd.img.xz...initrd.img.xz is OK.
Examining /metal/boot/boot/kernel...kernel is OK.
Examining /metal/boot/boot/initrd.img.xz...initrd.img.xz is OK.
Examining /metal/boot/boot/kernel...kernel is OK.
Examining /metal/boot/boot/initrd.img.xz...initrd.img.xz is OK.
Examining /metal/boot/boot/kernel...kernel is OK.
Examining /metal/boot/boot/initrd.img.xz...initrd.img.xz is OK.
Examining /metal/boot/boot/kernel...kernel is OK.
Examining /metal/boot/boot/initrd.img.xz...initrd.img.xz is OK.
Examining /metal/boot/boot/kernel...kernel is OK.
Examining /metal/boot/boot/initrd.img.xz...initrd.img.xz is OK.
```

<a name="power-capping"></a>