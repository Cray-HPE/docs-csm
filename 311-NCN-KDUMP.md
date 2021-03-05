# NCN kdump

## Status

The `kdump` service is running on the NCNs, but in most cases, you won't be able to complete a kdump due to the node running out of memory (OOM) during the process.

There are several reasons why this is happening, but this document explains how to workaround this OOM problem.  

## The workaround

This workaround is tedious, and will require some close attention, and a test crash of an actual node to verify functionality.  It also needs to be applied to each NCN.

## High-level overview

1. Modify the kernel parameters
2. Restart the kdump service
3. Expand the auto-generated kdump initrd
4. Modify the save_dump.sh script
5. Rebuild the initrd with the modified contents
6. Restart the kdump service again
7. Test crash the node

### Modify the kernel parameters

The node will run out of memory very quickly without these additional parameters.

Edit `/etc/sysconfig/kdump` and set `KDUMP_COMMANDLINE_APPEND` to read:

```
KDUMP_COMMANDLINE_APPEND="irqpoll nr_cpus=1 selinux=0 reset_devices cgroup_disable=memory mce=off numa=off udev.children-max=2 acpi_no_memhotplug rd.neednet=1 rd.shell panic=10 nohpet nokaslr metal.debug=0 transparent_hugepage=never rd.driver.blacklist=mlx5_core,mlx5_ib"
```

### Restart the kdump service

After making that change, restart the `kdump` service to apply it.

```bash
systemctl restart kdump
```

### Expand the auto-generated kdump initrd

Since the auto-generated kdump initrd runs out of memory (even with the changes made to `/etc/sysconfig/kdump`), you need to expand it so you can modify it's contents.

```bash
mkdir ktmp && cd ktmp
/usr/lib/dracut/skipcpio /boot/initrd-5.3.18-24.46-default-kdump | xzcat | cpio -id
```

### Modify the save_dump.sh script

```bash
vim ./lib/kdump/save_dump.sh
```

Make the following change, setting `MYROOT` to a local disk (not the overlay), such as `/var/lib/kubelet/crash`.

```
...
...
MYROOTDIR=/var/lib/kubelet/crash
echo "-----> MYROOTDIR=$MYROOTDIR KDUMPTOOL_OPTIONS=$KDUMPTOOL_OPTIONS"
read hostname < /etc/hostname.kdump
HOME=$MYROOTDIR TMPDIR=$MYROOTDIR/tmp kdumptool save_dump --root=$MYROOTDIR \
...
...
```

Make that directory so it can be mounted there.

```bash
mkdir /var/lib/kubelet/crash
```

### Rebuild the initrd with the modified contents

```bash
# backup original initrd
mv /boot/initrd-5.3.18-24.46-default-kdump /boot/initrd-5.3.18-24.46-default-kdump.orig
# create modified one
find . | cpio -oac | xz -C crc32 -z -c > /boot/initrd-5.3.18-24.46-default-kdump
```

### Restart the kdump service

After making that change, restart the `kdump` service to apply it.

```bash
systemctl restart kdump
```

### Test crash the node

Open a SOL connection to the node and login.  Then run this command to crash the node.

```
echo c >/proc/sysrq-trigger
```

After a few minutes, it will crash, make a dump file, and reboot.

This process should be repeated for each NCN needing a semi-working kdump.
