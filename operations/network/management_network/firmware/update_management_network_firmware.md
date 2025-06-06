# Update Management Network Firmware

- [Prerequisites](#prerequisites)
- [Switch firmware](#switch-firmware)
- [Aruba firmware best practices](#aruba-firmware-best-practices)
- [Aruba firmware update - Standalone](#aruba-firmware-update---standalone)
- [Aruba firmware update - VSX software upgrade](#aruba-firmware-update---vsx-software-upgrade)
- [Mellanox firmware update](#mellanox-firmware-update)
- [Dell firmware update](#dell-firmware-update)

This page describes how to update firmware on the management network switches. More details and other options to upgrade
firmware can be found in the switch user guides, available from the specific switch manufacturer.

## Prerequisites

- Access to the switches.
- Firmware in a location that the switches can reach.

Aruba firmware can be found in the HFP package provided with the HPE Cray EX release.
Dell and Mellanox firmware must be downloaded from the manufacturer.

## Switch firmware

| Model                         | software version |
|-------------------------------|-----------------:|
| Aruba 8320 Switch Series      |     `10.09.0010` |
| Aruba 8325 Switch Series      |     `10.09.0010` |
| Aruba 8360 Switch Series      |     `10.09.0010` |
| Aruba 6300 Switch Series      |     `10.09.0010` |
| Mellanox SN2100 Switch Series |       `3.9.3210` |
| Mellanox SN2700 Switch Series |       `3.9.3210` |
| Dell S3048-ON Switch Series   |       `10.5.1.4` |
| Dell S4148T-ON Switch Series  |       `10.5.1.4` |
| Dell S4148F-ON Switch Series  |       `10.5.1.4` |

## Aruba firmware best practices

Aruba software version number explained:

For example: `10.06.0120`

- `10` is the OS
- `06` is the major branch (new features)
- `0120` is the CPE release (bug fixes)

It is considered to be a best practice to keep all Aruba CX platform devices running the same software version.

Aruba CX devices have two software image banks, which means software images can be pre-staged to the device without booting to the new image.

(`sw#`) When upgrading past a major software release (for example, from `10.6` to `10.8`, skipping `10.7`), then issue the `allow-unsafe-upgrades` command to allow any low level firmware/driver upgrades to complete.
If going from the `10.6` branch to the `10.7` branch, this step can be skipped because the low level firmware/driver upgrade would be automatically completed.

```console
config
allow-unsafe-updates 30
```

This command will enable non-failsafe updates of programmable devices for
the next 30 minutes. Wait for all line and fabric
modules to reach the ready state, and then reboot the switch to begin
applying any needed updates. Ensure that the switch will not lose power,
be rebooted again, or have any modules removed until all updates have
finished and all line and fabric modules have returned to the ready state.

**WARNING:** Interrupting these updates may make the product unusable!

VSX software upgrade command can automatically upgrade both of the peers in VSX topology by staging upgrade and automatically doing traffic shifting between peers to minimize impact to network.
The following examples include the option for standalone and vsx-pair upgrade.

## Aruba firmware update - Standalone

Console into the switch being upgraded.

1. Check images

   ```console
   show images
   ```

   Example output:

   ```text
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : FL.10.06.0010
   Size    : 658 MB
   Date    : 2020-12-14 11:49:52 PST
   SHA-256 : 9e03da5697ef40d261b4a2920a19197ab64ea338533578ce576e5ca1a6849285

   ---------------------------------------------------------------------------
   ArubaOS-CX Secondary Image
   ---------------------------------------------------------------------------
   Version : FL.10.04.0010
   Size    : 722 MB
   Date    : 2019-12-03 10:41:01 PST
   SHA-256 : 2f00ca2d86338701225aadf4b9aa9b076e929b2b4620239b44122f300ff29e2d

   Default Image : primary
   Boot Profile Timeout : 5 seconds

   ------------------------------------------------------
   Management Module 1/1 (Active)
   ------------------------------------------------------
   Active Image       : primary
   Service OS Version : FL.01.07.0002
   BIOS Version       : FL.01.0002
   ```

1. Upload the firmware to the desired image.
In this example we are uploading it to the secondary.

   ```console
   copy sftp://root@10.252.1.12//root/ArubaOS-CX_6400-6300_10_08_1021.swi secondary
   write mem
   ```

   Example output:

   ```text
   Copying configuration: [Success]
   ```

1. Once the upload is complete, check the images:

   ```console
   show image
   ```

   Example output:

   ```text
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : FL.10.06.0010
   Size    : 658 MB
   Date    : 2020-12-14 11:49:52 PST
   SHA-256 : 9e03da5697ef40d261b4a2920a19197ab64ea338533578ce576e5ca1a6849285

   ---------------------------------------------------------------------------
   ArubaOS-CX Secondary Image
   ---------------------------------------------------------------------------
   Version : FL.10.08.1021
   Size    : 812 MB
   Date    : 2021-11-08 02:09:58 UTC
   SHA-256 : 3e7f5e22843b49438d2eab19f0e6df8ebccef053e38d6cd65110cfeb37d707fc

   Default Image : primary
   Boot Profile Timeout : 5 seconds

   ------------------------------------------------------
   Management Module 1/1 (Active)
   ------------------------------------------------------
   Active Image       : primary
   Service OS Version : FL.01.07.0002
   BIOS Version       : FL.01.0002
   ```

1. After the firmware is uploaded, boot the switch to the correct image.

   ```console
   boot system secondary
   ```

1. Once the reboot is complete, check and make sure the firmware version is correct.

   ```console
   show version
   ```

   Example output:

   ```text
   -----------------------------------------------------------------------------
   ArubaOS-CX
   (c) Copyright 2017-2020 Hewlett Packard Enterprise Development LP
   -----------------------------------------------------------------------------
   Version      : FL.10.06.0010
   Build Date   : 2020-09-29 07:44:16 PDT
   Build ID     : ArubaOS-CX:FL.10.06.0010:3cbfcce60961:202009291304
   Build SHA    : 3cbfcce609617b0cf84a6b941a2b36c43dfeb2cb
   Active Image : primary

   Service OS Version : FL.01.07.0002
   BIOS Version       : FL.01.0002
   ```

## Aruba firmware update - VSX software upgrade

1. Console into both VSX switches and pre-stage the firmware.
In this example we are pre-staging the firmware to `sw-spine-001` and `sw-spine-002`

1. Check images first.

   ```console
   show images
   ```

   Example output:

   ```text
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : GL.10.06.0010
   Size    : 444 MB
   Date    : 2020-12-14 11:55:16 PST
   SHA-256 : 4157d15a5cad6efce4d0e8b35f75b4d6212de5af0c5c9bf3ad8f74853df67733

   ---------------------------------------------------------------------------
   ArubaOS-CX Secondary Image
   ---------------------------------------------------------------------------
   Version : GL.10.02.0020
   Size    : 360 MB
   Date    : 2019-03-12 09:26:31 PDT
   SHA-256 : da629a197e6acbdd805bc7cb85f1decff772ce25223ea20f7c55d426df03fcbe

   Default Image : primary
   Boot Profile Timeout : 5 seconds

   ------------------------------------------------------
   Management Module 1/1 (Active)
   ------------------------------------------------------
   Active Image       : primary
   Service OS Version : GL.01.08.0002
   BIOS Version       : GL-01-0013
   ```

1. Upload the firmware to the desired image.
In this example we are uploading it to the secondary.

   ```console
   copy sftp://root@10.252.1.12//var/www/ephemeral/data/network_images/ArubaOS-CX_8325_10_08_1021.swi secondary
   write mem
   ```

   Example output:

   ```text
   Copying configuration: [Success]
   ```

1. Once the upload is complete, check the images and make sure the version is correct.

   ```console
   show image
   ```

   Example output:

   ```text
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : GL.10.06.0010
   Size    : 444 MB
   Date    : 2020-12-14 11:55:16 PST
   SHA-256 : 4157d15a5cad6efce4d0e8b35f75b4d6212de5af0c5c9bf3ad8f74853df67733

   ---------------------------------------------------------------------------
   ArubaOS-CX Secondary Image
   ---------------------------------------------------------------------------
   Version : GL.10.08.1021
   Size    : 473 MB
   Date    : 2021-11-08 01:48:56 UTC
   SHA-256 : c16dc680333eaf72188061209e56cd24854cb291e6babe2333110ff6029e8227

   Default Image : primary
   Boot Profile Timeout : 5 seconds

   ------------------------------------------------------
   Management Module 1/1 (Active)
   ------------------------------------------------------
   Active Image       : primary
   Service OS Version : GL.01.08.0002
   BIOS Version       : GL-01-0013
   ```

1. After the firmware is uploaded to both VSX switches, you will need to start the software update from the VSX primary member.

   Since we uploaded to the secondary image, we choose that one to boot to.

   ```console
   vsx update-software boot-bank secondary
   ```

   This will trigger the upgrade process on the VSX pair and it will start the dialogue explaining what will happen next, i.e. if any firmware/driver upgrades are needed
   and it will show on the screen the current status of the upgrade process. In the VSX upgrade process, the secondary VSX member will always boot first.

1. Once software update is complete verify the image version on both switches.

   ```console
   show version
   ```

   Example output:

   ```text
   -----------------------------------------------------------------------------
   ArubaOS-CX
   (c) Copyright 2017-2021 Hewlett Packard Enterprise Development LP
   -----------------------------------------------------------------------------
   Version      : GL.10.08.1021
   Build Date   : 2021-11-08 01:48:56 UTC
   Build ID     : ArubaOS-CX:GL.10.08.1021:befed610d5e5:202111080115
   Build SHA    : befed610d5e59c29e3cfb6e163fa45af615a2bd3
   Active Image : secondary

   Service OS Version : GL.01.08.0002
   BIOS Version       : GL-01-0013
   ```

## Mellanox firmware update

1. SSH into the switch being upgraded.

1. Fetch the image from `ncn-m001`.

   ```console
   image fetch scp://root@10.252.1.4/root/onyx-X86_64-3.9.3210.img
   ```

1. Install the image.

   ```console
   image install onyx-X86_64-3.9.3210.img
   ```

1. Select the image to boot next.

   ```console
   image boot next
   ```

1. Write memory and reload.

   ```console
   write memory
   reload
   ```

1. Once the switch is available, verify the image is installed.

   ```console
   show images
   ```

   Example output:

   ```text
   Installed images:
   Partition 1:
     version: X86_64 3.9.0300 2020-02-26 19:25:24 x86_64

   Partition 2:
     version: X86_64 3.9.1014 2020-08-05 18:06:58 x86_64

   Last boot partition: 2
   Next boot partition: 1

   Images available to be installed:
   1:
     Image  : onyx-X86_64-3.9.1014.stable.img
     Version: X86_64 3.9.1014 2020-08-05 18:06:58 x86_64
   ```

## Dell firmware update

1. SSH into the switch being upgraded.

1. Fetch the image from `ncn-m001`.

   ```console
   image install http://10.252.1.4/fw/network/OS10_Enterprise_10.5.1.4.stable.tar
   ```

1. Check the image upload status.

   ```console
   show image status
   ```

   Example output:

   ```text
   Image Upgrade State:     download
   ==================================================
   File Transfer State:     download
   --------------------------------------------------
     State Detail:          In progress
     Task Start:            2021-02-08T21:24:14Z
     Task End:              0000-00-00T00:00:00Z
     Transfer Progress:     7 %
     Transfer Bytes:        40949640 bytes
     File Size:             604119040 bytes
     Transfer Rate:         869 kbps
   ```

1. Reboot after the image is uploaded.

   ```console
   write memory
   reload
   ```

1. Once the switch is available, verify the image is installed.

   ```console
   show version
   ```

   Example output:

   ```text
   Dell EMC Networking OS10 Enterprise
   Copyright (c) 1999-2020 by Dell Inc. All Rights Reserved.
   OS Version: 10.5.1.4
   Build Version: 10.5.1.4.249
   ```
