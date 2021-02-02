# Booting Directly From A Virtual ISO

With BMCs like ILO or Gigabyte it is possible to boot directly to an ISO rather than requiring a local USB stick.

After booting you can then setup Pre-Install Toolkit configs directly on the OS rather than requiring a USB with a PITDATA pre-populated with configs.

## Requirements:

1. Access to a pre-built PIT ISO. Either web hosted, such as on artifactory (for ILO BMCs) or a local ISO (for Gigabyte BMCs)
2. Access to stash/bitbucket
3. All other requirements in [LiveCD Creation](002-LIVECD-CREATION.md) and [LiveCD Setup](004-LIVECD-SETUP.md) for creating and populating configs

## Booting

> **`NOTE`** It may appear that the boot is stalled at a line of `EXT4-fs (loop1): mounted ...` or `Starting dracut pre-mount hook...`. This is the step when it actually begins downloading the ISO's squashfs root filesystem and can take a few minutes

### ILO

ILO BNCs allow for booting directly from an HTTP accessible ISO location. This can be done either from the web interface or a helper script

**Web Interface**

Access your BMC's web interface and navigate to the `Remote Console & Media` page and then the `Virtual Media` tab.

Here you can insert the Virtual Media URL, select Boot on Next Reset, and click Insert Media

![ILO BMC Mount](./img/bmc-virtual-media-ilo.png)

Next go ahead and reboot by select reset in the top right menu control option

![ILO BMC Reboot](./img/bmc-reboot-ilo.png)

Finally you can open up the virtual terminal by choosing the `HTML5 Console` option when clicking the terminal image in the bottom left corner.

**Helper Script**

There is also a helper script located at `../cray-pre-install-toolkit/scripts/boot-to-iso-ilo.sh`.

This will prompt for the BMC password, connect to the BMC over ssh, mount the ISO, reboot the machine, and drop you in an ipmitool terminal

```bash
../cray-pre-install-toolkit/scripts/boot-to-iso-ilo.sh <ISO URL> <BNC Hostname or IP>
```

### Gigabyte

**Web Interface**

Access your BMC's web interface and navigate to `Settings -> Media Redirection Settings -> General Settings`.

Enable `Remote Media Support` and `Mount CD/DVD` and then fill in the server IP or DNS name and the path to server.

![Gigabyte BMC Settings](./img/bmc-virtual-media-settings-gigabyte.png)

> **`NOTE`** The gigabyte url appears to not allow certain characters and has a limit on path length. So you may need to move or rename the ISO to a location with a smaller file name.

Next head to `Image Redirection -> Remote Images` and click on the `Start` button to start the Virtual ISO mount.

![Gigabyte BMC Start](./img/bmc-virtual-media-start-gigabyte.png)

Finally, reboot the server and select the `Virtual CDROM` option from the manual boot options.

![Gigabyte BMC Boot](./img/bmc-virtual-media-boot-gigabyte.png)




## Configuring

At this point you're booted into a bare PIT OS and can begin configuring it.

> **`NOTE`** The root OS `/` directory is writeable, but with an in-memory overlay on top of the ISO. This means that restarting the machine will result in all changes being lost. So be sure to follow the `Backing up the Overlay COW FS` section after you finish configuring or making changes.
>
>Likewise, if you are here after previously backing up the overlay directory you can follow the section `Restoring from an Overlay COW FS Backup` section and not have to reconfigure this OS

1. Set the initial password to `!nitial0` following the [LiveCD USB Boot](020-LIVECD-USB-BOOT.md) section
2. Follow the `Gather / Create Seed Files` section of [LiveCD Creation](002-LIVECD-CREATION.md)
3. Change directory to `cd /var/www/ephemeral/prep` and follow the section `Configuration Payload` of [LiveCD Creation](002-LIVECD-CREATION.md)
4. Follow the applicable sections of [LiveCD Setup](002-LIVECD-SETUP.md)

### Next: Deploy the NCNs

Now you can now pass GO, collect $200, and begin the [NCN Boots](005-NCN-BOOTS.md) page...

## Backing up the Overlay COW FS

You can backup the writeable overlay uperdir so that your changes are not lost after a reboot or when updating your ISO.

This requires that you have a location that you can SSH at tarball to as a backup.

```bash
tar czf /run/overlay.tar.gz -C /run/overlayfs/rw .
scp /run/overlay.tar.gz <somelocation>
```
> **`NOTE`** If you want to reduce the size of the backup you can also delete any squashfs files first or exclude them in the tar command `--exclude='*.squashfs'`. You will then need to re-populate those after you restore your backup


## Restoring from an Overlay COW FS Backup

Restore a backed up tarball from the previous command with

```bash
 scp <somelocation> /run/overlay.tar.gz
tar xf /run/overlay.tar.gz -C /run/overlayfs/rw
mount -o remount /
```

If you excluded the `squashfs` files from the backup you will also want to repopulate them following the configuration section.

## Troubleshooting

### Boots to USB instead of Virtual ISO
If after booting to the Virtual ISO it may appear you are actually booted to the USB. This is because the Dracut and LiveCD functionality will look for a `cow` labeled partition and use that for the rootfs overlay.

So you may have actually booted from the Virtual ISO but the USB partition was still picked up automatically.

A quick fix for this, other than wiping the USB, is to just relabel the partition with `e2label /dev/sdd3 cow-original`. You can then verify labels with `lsblk -o name,mountpoint,fstype,label,size`.

If you still run into problems it may be because the USB has a label of `CRAYLIVE` which can conflict with the boot order during early initrd startup.  Unfortunately the only fix for this is to fully wipe the USB disk to remove the label `wipefs -af /dev/sdd`
### Corrupt File System
On hela after time we saw some errors about a corrupt file system.
Some examples are

```bash
hela-ncn-m001-pit:~ # podman ls
bash: /usr/bin/podman: Input/output error
```

```bash
[60240.126063] SQUASHFS error: xz decompression failed, data probably corrupt
[60240.134712] SQUASHFS error: squashfs_read_data failed to read block 0x3a6e2272
[60240.143588] blk_update_request: I/O error, dev loop1, sector 4756320 op 0x0:(READ) flags 0x0 phys_seg 1 prio class 0
[60240.156283] SQUASHFS error: xz decompression failed, data probably corrupt
[60240.164840] SQUASHFS error: squashfs_read_data failed to read block 0x3a6e2272
[60240.173476] blk_update_request: I/O error, dev loop1, sector 4756320 op 0x0:(READ) flags 0x0 phys_seg 1 prio class 0
-bash: /usr/bin/md5sum: Input/output error
```

We haven't been able to determine what caused this or if there is a fix. We believe it may have been caused by the BMC unmounting or disconnecting the virtual iso, or the artifactory hosted ISO may have changed while it was still mounted.

### Gigabyte Drops to Recovery Shell
During testing of booting to gigabyte you may notice that it drops you into a recovery shell.

It appears this happens when the dracut module begins downloading the large squashfs image from the Virtual ISO url. When this happens you may see errors like this in the kernel logs:

```bash
Jan 30 00:32:03 localhost kernel: blk_update_request: I/O error, dev sr0, sector 1019912 op 0x0:(READ) flags 0x0 phys_seg 2 prio class 0
Jan 30 00:32:03 localhost kernel: Buffer I/O error on dev sr0, logical block 254978, async page read
Jan 30 00:32:03 localhost kernel: Buffer I/O error on dev sr0, logical block 254979, async page read
```

Currently there is not a work around or fix for this and may be caused by the BMC itself, the web server hosting the ISO, network issues, or dracut download command itself.
