# CSM Troubleshooting Information

This document provides troubleshooting information for services and functionality provided by CSM.

### Topics
 * [Known Issues](#known-issues)
    * [Hardware Discovery](#known-issues-hardware-discovery)
    * [initrd.img.xz not found](#initrd-not-found)

<a name="known-issues"></a>

### Known Issues
Listing of known issues and procedures to workaround them in this CSM release.

<a name="known-issues-hardware-discovery"></a>

#### Hardware Discovery
Known issues related to hardware discovery in a system.
 * [Air cooled hardware is not getting properly discovered with Aruba leaf switches](known_issues/discovery_aruba_snmp_issue.md)
 * [HMS Discovery job not creating RedfishEndpoints in Hardware State Manager](known_issues/discovery_job_not_creating_redfish_endpoints.md)

<a name="initrd-not-found"></a>
#### ``error: file  `/boot/grub2/../initrd.img.xz' not found.Press any key to continue...``

This is a problem that is fixed in CSM 1.0+, but if your system was upgraded from CSM 0.9.x you may run into this.  Below is the full error seen when attempting to boot:

```
Loading Linux  ...
Loading initial ramdisk ...
error: file `/boot/grub2/../initrd.img.xz' not found.Press any key to continue...
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

##### Fix

Run these commands to fix the issue:

```bash
git clone -b release/0.9 ssh://git@stash.us.cray.com:7999/csm/csm-install-workarounds.git
csm-install-workarounds/workarounds/livecd-post-reboot/CASMINST-1612/CASMINST-1612.sh
```

###### Validate

You can validate the fix worked by running this:

```bash
pdsh -b -S -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') '
if ! mkdir -p /tmp/mount.$$ ; then
echo "mkdir failed"
exit 1
elif ! mount -L BOOTRAID /tmp/mount.$$/ ; then
echo "mount failed"
exit 1
fi
RC=1
INITRD=$(grep initrdefi /tmp/mount.$$/boot/grub2/grub.cfg | awk -F/ "{ print \$NF }")
if [ -z "$INITRD" ]; then
echo "No initrd found in grub.cfg"
elif [ ! -f /tmp/mount.$$/boot/$INITRD ]; then
echo "Expected initrd not found: boot/$INITRD"
else
echo ok
RC=0
fi
umount /tmp/mount.$$
exit $RC' && echo "All checks passed" || echo "At least one check did not pass"
```
