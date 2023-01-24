# Boot LiveCD USB

These steps provide a bootable USB capable of installing this CSM release.

## Topics

1. [Create the Bootable Media](#create-the-bootable-media)
1. [Boot the LiveCD](#boot-the-livecd)

## Create the Bootable Media

Cray Site Init will create the bootable LiveCD. Before creating the media, identify
which device will be used for it.

1. (`external`) Set up the initial typescript.

   ```bash
   SCRIPT_FILE="$(pwd)/csm-install-usb.$(date +%Y-%m-%d).txt"
   script -af "${SCRIPT_FILE}"
   export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
   export OUT_DIR=$(pwd)/csm-temp
   ```

1. (`external#`) Identify the USB device.

   > **`NOTE`** This example shows the USB device is `/dev/sdd` on the host.

   ```bash
   lsscsi
   ```

   Expected output looks similar to the following:

   ```text
   [6:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sda
   [7:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sdb
   [8:0:0:0]    disk    ATA      SAMSUNG MZ7LH480 404Q  /dev/sdc
   [14:0:0:0]   disk    SanDisk  Extreme SSD      1012  /dev/sdd
   [14:0:0:1]   enclosu SanDisk  SES Device       1012  -
   ```

   In the above example, internal disks are the `ATA` devices and USB drives are the final two devices.

   Set a variable with the USB device and for the `CSM_PATH`:

   ```bash
   USB=/dev/sd<disk_letter>
   ```

1. Format the USB device.

    - Use the CSI application to do this:

        ```bash
        csi pit format "${USB}" "${OUT_DIR}/"pre-install-toolkit-*.iso 50000
        ```

    - If CSI is unavailable, then fetch and use the `write-livecd.sh` script:

        > **`NOTE`** This assumes the `write-livecd.sh` script was extracted from the tarball's
        > `cray-site-init` RPM. If that was skipped in
        > [the USB section of Boot the LiveCD](../pre-installation.md#12-boot-the-livecd), the script
        > is also available on GitHub:
        >
        >    ```curl
        >    curl -f -o "${OUT_DIR}/write-livecd.sh" https://raw.githubusercontent.com/Cray-HPE/cray-site-init/main/scripts/write-livecd.sh && chmod +x "${OUT_DIR}/write-livecd.sh"
        >    ```
        >
        > Alternatively if the RPM is available but the LiveCD is being created on a non-RPM based distro,
        > then the script can be extracted from the RPM file:
        >
        >    ```bash
        >    bsdtar xvf cray-site-init-*.rpm --include *write-livecd.sh -C "./${OUT_DIR}"
        >    mv -v "${OUT_DIR}/usr/local/bin/write-livecd.sh" ./
        >    rmdir -pv "${OUT_DIR}/usr/local/bin/"
        >    ```
        >

        ```bash
        write-livecd.sh "${USB}" "${OUT_DIR}/"pre-install-toolkit-*.iso 50000
        ```

## Boot the LiveCD

Some systems will boot the USB device automatically if no other OS exists (bare-metal). Otherwise the
administrator may need to use the BIOS Boot Selection menu to choose the USB device.

If an administrator has the node booted with an operating system which will next be rebooting into the LiveCD,
then use `efibootmgr` to set the boot order to be the USB device. See the
[set boot order](../../background/ncn_boot_workflow.md#setting-boot-order) page for more information about how to set the
boot order to have the USB device first.

> **`NOTE`** UEFI booting must be enabled in order for the system to find the USB device's EFI bootloader.

1. (`external#`) Confirm that the IPMI credentials work for the BMC by checking the power status.

   Set the `BMC` variable to the hostname or IP address of the BMC of the PIT node.

   > `read -s` is used in order to prevent the credentials from being displayed on the screen or recorded in the shell history.

   ```bash
   USERNAME=root
   BMC=eniac-ncn-m001-mgmt
   read -r -s -p "${BMC} ${USERNAME} password: " IPMI_PASSWORD
   export IPMI_PASSWORD
   ipmitool -I lanplus -U "${USERNAME}" -E -H "${BMC}" chassis power status
   ```

1. (`external#`) Power the NCN on and connect to the IPMI console.

   > **`NOTE`** The boot device can be set via IPMI; the example below uses the `floppy` option. At a glance this seems incorrect,
   > however it selects the primary removable media. This step instructs the user to power off the node to ensure
   > the BIOS has the best chance at finding the USB via a cold boot.
   >
   > ```bash
   > ipmitool chassis bootdev
   > ```
   >
   > ```text
   >    Received a response with unexpected ID 0 vs. 1
   >    bootdev <device> [clear-cmos=yes|no]
   >    bootdev <device> [options=help,...]
   >    none  : Do not change boot device order
   >    pxe   : Force PXE boot
   >    disk  : Force boot from default Hard-drive
   >    safe  : Force boot from default Hard-drive, request Safe Mode
   >    diag  : Force boot from Diagnostic Partition
   >    cdrom : Force boot from CD/DVD
   >    bios  : Force boot into BIOS Setup
   >    floppy: Force boot from Floppy/primary removable media
   > ```

   ```bash
   ipmitool -I lanplus -U "${username}" -E -H "${BMC}" chassis bootdev floppy options=efiboot
   ipmitool -I lanplus -U "${username}" -E -H "${BMC}" chassis power off
   ```

1. Insert the USB stick into a USB3 port (USB2 is compatible, USB3 offers the best performance).

1. (`external#`) Power the server on.

   ```bash
   ipmitool -I lanplus -U "${username}" -E -H "${BMC}" chassis power on
   ipmitool -I lanplus -U "${username}" -E -H "${BMC}" sol activate
   ```

1. Do not exit the typescript. After completing this procedure, proceed to [First log in](../pre-installation.md#13-first-log-in).
