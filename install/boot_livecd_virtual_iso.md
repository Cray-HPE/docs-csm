# Boot LiveCD Virtual ISO

This page will walk-through booting the LiveCD `.iso` file directly onto a BMC.

### Topics:

* [Requirements](#requirements)
* [BMCs' Virtual Mounts](#bmcs-virtual-mounts)
  * [HPE iLO BMCs](#hpe-ilo-bmcs)
  * [Gigabyte BMCs](#gigabyte-bmcs)
* [Configuring](#configuring)
   * [Backing up the Overlay COW FS](#backing-up-the-overlay-cow-fs)
   * [Restoring from an Overlay COW FS Backup](#restoring-from-an-overlay-cow-fs-backup)

## Details

<a name="requirements"></a>
### Requirements

A Cray Pre-Install Toolkit ISO is required for this process. This ISO can be obtained from:

- The Cray Pre-Install Toolkit ISO included in a CSM release tar file. It will have a filename similar to
  `cray-pre-install-toolkit-sle15sp2.x86_64-1.4.10-20210514183447-gc054094.iso`

<a name="bmcs-virtual-mounts"></a>
### BMCs' Virtual Mounts

Most BMCs offer a **Web Interface** for controlling the node and for providing access to its BIOS and firmware.

Refer to the following pages based on your node vendor for help mounting an ISO image:

* [HPE iLO BMCs](#hpe-ilo-bmcs)
* [Gigabyte](#gigabyte-bmcs)

<a name="hpe-ilo-bmcs"></a>
#### HPE iLO BMCs

HPE iLO BMCs allow for booting directly from an HTTP-accessible ISO location.

> Enter the `Virtual Media URL`, select `Boot on Next Reset`, and click `Insert Media`.

![Screen Shot of iLO BMC Virtual Media Mount](../img/bmc-virtual-media-ilo.png)

> Next reboot by selecting `Reset` in the top right power menu.

![Screen Shot of iLO BMC Reboot](../img/bmc-reboot-ilo.png)

> Open the virtual terminal by choosing the `HTML5 Console` option when clicking the terminal image in the bottom left corner.

> **`NOTE`** It may appear that the boot is stalled at a line of `EXT4-fs (loop1): mounted ...` or `Starting dracut pre-mount hook...`. This is the step when it actually begins downloading the ISO's squashfs root file system and can take a few minutes

<a name="gigabyte-bmcs"></a>
#### Gigabyte BMCs

Gigabyte BMCs allow for booting over HTTP.

**Note:** Because of problems in the Gigabyte firmware, do not try to boot over NFS or CIFS.

Go to the BMC settings and setup the remote ISO for your protocol and node.

![Screen Shot of Gigabyte BMC Virtual Media Settings](../img/bmc-virtual-media-gigabyte-settings.png)

**Web Interface**

Access your BMC's web interface and navigate to `Settings` -> `Media Redirection Settings` -> `General Settings`.

Enable `Remote Media Support` and `Mount CD/DVD` and then fill in the server IP address or DNS name and the path to the server.

![Screen Shot of Gigabyte BMC General Settings](../img/bmc-virtual-media-settings-gigabyte.png)

> **`NOTE`** The Gigabyte URL appears to not allow certain characters and has a limit on path length. You may need to move or rename the ISO to a location with a smaller file name.

Next navigate to `Image Redirection` -> `Remote Images` and click on the `Start` button to start the Virtual ISO mount.

![Screen Shot of Gigabyte BMC Start](../img/bmc-virtual-media-start-gigabyte.png)

Finally, reboot the node and select the `Virtual CDROM` option from the manual boot options.

![Screen Shot of Gigabyte BMC Boot](../img/bmc-virtual-media-boot-gigabyte.png)

<a name="configuring"></a>
### Configuring

* [Configuring](#configuring)
   * [Backing up the Overlay COW FS](#backing-up-the-overlay-cow-fs)
   * [Restoring from an Overlay COW FS Backup](#restoring-from-an-overlay-cow-fs-backup)

The ISO boots with no password, requiring one be set on first login.
Continue the bootstrap process by setting the root password
following the procedure [First Login](bootstrap_livecd_remote_iso.md#first-login).

> **`NOTE`** The root OS `/` directory is writable without persistence. This means that restarting the machine will result in all changes being lost. Before restarting, consider following [Backing up the Overlay COW FS](#backing-up-the-overlay-cow-fs) and the accompanying [Restoring from an Overlay COW FS Backup](#restoring-from-an-overlay-cow-fs-backup) section.

<a name="backing-up-the-overlay-cow-fs"></a>
#### Backing up the Overlay COW FS

You can backup the writable overlay upper-dir so that your changes are not lost after a reboot or when updating your ISO.

This requires that you have a location to which you can `scp` a tar file as a backup.

```bash
tar czf /run/overlay.tar.gz -C /run/overlayfs/rw .
scp /run/overlay.tar.gz <somelocation>
```
> **`NOTE`** If you want to reduce the size of the backup you can also delete any squashfs files first, or exclude them in the tar command using `--exclude='*.squashfs'`. You will then need to re-populate those after you restore your backup

<a name="restoring-from-an-overlay-cow-fs-backup"></a>
#### Restoring from an Overlay COW FS Backup

Restore a backed up tar file from the previous command with

```bash
scp <somelocation> /run/overlay.tar.gz
tar xf /run/overlay.tar.gz -C /run/overlayfs/rw
mount -o remount /
```

If you excluded the `squashfs` files from the backup, you will also need to repopulate them following the configuration section.
