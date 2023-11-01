# Update Management Network Firmware

This page describes how to update firmware on the management network switches. More details and other options to upgrade
firmware can be found in the switch [External User Guides](../external_user_guides.md).

## Prerequisites

- Access to the switches.
- Firmware in a location that the switches can reach.

All firmware can be found in the HFP package provided with the Shasta release.

## Switch Firmware

| Model                         | software version |
|-------------------------------|-----------------:|
| Aruba 8320 Switch Series      |     `10.11.1010` |
| Aruba 8325 Switch Series      |     `10.11.1010` |
| Aruba 8360 Switch Series      |     `10.11.1010` |
| Aruba 6300 Switch Series      |     `10.11.1010` |
| Mellanox SN2100 Switch Series |       `3.9.3210` |
| Mellanox SN2700 Switch Series |       `3.9.3210` |
| Dell S3048-ON Switch Series   |       `10.5.1.4` |
| Dell S4148T-ON Switch Series  |       `10.5.1.4` |
| Dell S4148F-ON Switch Series  |       `10.5.1.4` |

## Aruba Firmware Best Practices

Aruba software version number explained:

For example: `10.11.1010`

- 10 = OS

- 11 = Major branch (new features)

- 1010 = CPE release (bug fixes)

It is considered to be a best practice to keep all Aruba CX platform devices running the same software version.

Aruba CX devices two software image banks, which means switch images can be pre-staged to the device without booting to the
new image.

If upgrading to a new major branch, in Aruba identified by the second integer in the software image number.

When upgrading past a major software release, for example, from 10.9 to 10.11 (and skipping `10.10.xxxx`)
issue the `allow-unsafe-upgrades` command to allow any low level firmware/driver upgrades to complete. If going from the
10.6 branch to 10.7 branch, this step can be skipped as the low level firmware/driver upgrade would be automatically
completed.

```bash
config
sw-leaf-001(config)# allow-unsafe-updates 30
```

This command will enable non-failsafe updates of programmable devices for the next 30 minutes. First, wait for all line
and fabric modules to reach the ready state, and then reboot the switch to begin applying any needed updates. Ensure
that the switch will not lose power, be rebooted again, or have any modules removed until all updates have finished and
all line and fabric modules have returned to the ready state.

**WARNING:** Interrupting these updates may make the product unusable!

```bash
Continue (y/n)? y
Unsafe updates      : allowed (less than 30 minute(s) remaining)
```

VSX software upgrade command can automatically upgrade both of the peers in VSX topology by staging upgrade and
automatically doing traffic shifting between peers to minimize impact to network. The following examples include the
option for standalone and vsx-pair upgrade.

## Aruba Firmware Update - Standalone

Console into the switch being upgraded.

1. Check images

   ```bash
   show images                        
   ```

   Potential output:

   ```text
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : GL.10.09.0010
   Size    : 480 MB
   Date    : 2022-02-01 01:04:17 UTC
   SHA-256 : 52b2a6d2c5c039ed8eb0dbd6a3313ea93d268dd91688d2e3b295e03f946eb177

   ---------------------------------------------------------------------------
   ArubaOS-CX Secondary Image
   ---------------------------------------------------------------------------
   Version : GL.10.11.1010
   Size    : 501 MB
   Date    : 2023-03-28 04:53:23 UTC
   SHA-256 : 7c3594162675c5d95d06e4a465546e6fac8b60b8fce9a82ab82d303f8defd2cd

   Default Image : primary
   Boot Profile Timeout : 5 seconds

   ------------------------------------------------------
   Management Module 1/1 (Active)
   ------------------------------------------------------
   Active Image       : secondary
   Service OS Version : GL.01.08.0003
   BIOS Version       : GL-01-0013
   ```

1. Upload the firmware to the desired image.

   In this example we are uploading it to the secondary.

   ```bash
   copy sftp://root@10.252.1.12//root/ArubaOS-CX_6400-6300_10_08_1021.swi secondary

   write mem
   ```

   Expected output:

   ```text
   Copying configuration: [Success]
   ```

1. Once the upload is complete, check the images:

   ```bash
   show image
   ```

   Potential output:

   ```text
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : GL.10.09.0010
   Size    : 480 MB
   Date    : 2022-02-01 01:04:17 UTC
   SHA-256 : 52b2a6d2c5c039ed8eb0dbd6a3313ea93d268dd91688d2e3b295e03f946eb177

   ---------------------------------------------------------------------------
   ArubaOS-CX Secondary Image
   ---------------------------------------------------------------------------
   Version : GL.10.11.1010
   Size    : 501 MB
   Date    : 2023-03-28 04:53:23 UTC
   SHA-256 : 7c3594162675c5d95d06e4a465546e6fac8b60b8fce9a82ab82d303f8defd2cd

   Default Image : primary
   Boot Profile Timeout : 5 seconds

   ------------------------------------------------------
   Management Module 1/1 (Active)
   ------------------------------------------------------
   Active Image       : secondary
   Service OS Version : GL.01.08.0003
   BIOS Version       : GL-01-0013
   ```

1. After the firmware is uploaded, boot the switch to the correct image.

   ```bash
   boot system secondary
   ```

1. Once the reboot is complete, check and make sure the firmware version is correct.

   ```bash
   show version
   ```

   Potential output:

   ```text
   -----------------------------------------------------------------------------
   ArubaOS-CX
   (c) Copyright 2017-2020 Hewlett Packard Enterprise Development LP
   -----------------------------------------------------------------------------
   Version      : GL.10.11.1010
   Build Date   : 2023-03-28 04:53:23 UTC
   Build ID     : ArubaOS-CX:GL.10.11.1010:966f173e8e4e:202303280333
   Build SHA    : 966f173e8e4e519b5296fa51297754f663ef2ad8
   Hot Patches  : 
   Active Image : secondary

   Service OS Version : GL.01.08.0003
   BIOS Version       : GL-01-0013
   ```

## Aruba Firmware Update - VSX Software Upgrade

Console into both VSX switches and pre-stage the firmware.

In this example we are pre-staging the firmware to `sw-spine-001` and `sw-spine-002`

1. Check images first.

   ```bash
   show images
   ```

   Potential output:

   ```text
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : GL.10.09.0010
   Size    : 480 MB
   Date    : 2022-02-01 01:04:17 UTC
   SHA-256 : 52b2a6d2c5c039ed8eb0dbd6a3313ea93d268dd91688d2e3b295e03f946eb177

   ---------------------------------------------------------------------------
   ArubaOS-CX Secondary Image
   ---------------------------------------------------------------------------
   Version : GL.10.11.1010
   Size    : 501 MB
   Date    : 2023-03-28 04:53:23 UTC
   SHA-256 : 7c3594162675c5d95d06e4a465546e6fac8b60b8fce9a82ab82d303f8defd2cd

   Default Image : primary
   Boot Profile Timeout : 5 seconds

   ------------------------------------------------------
   Management Module 1/1 (Active)
   ------------------------------------------------------
   Active Image       : secondary
   Service OS Version : GL.01.08.0003
   BIOS Version       : GL-01-0013
   ```

1. Upload the firmware to the desired image.

   In this example we are uploading it to the secondary.

    ```bash
   copy sftp://root@10.252.1.12//var/www/ephemeral/data/network_images/ArubaOS-CX_8325_10_08_1021.swi secondary

   write mem
   ```

   Expected output:

   ```text
   Copying configuration: [Success]
   ```

1. Once the upload is complete, check the images and make sure the version is correct.

   ```bash
   show image
   ```

   Potential output:

   ```text
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : GL.10.09.0010
   Size    : 480 MB
   Date    : 2022-02-01 01:04:17 UTC
   SHA-256 : 52b2a6d2c5c039ed8eb0dbd6a3313ea93d268dd91688d2e3b295e03f946eb177

   ---------------------------------------------------------------------------
   ArubaOS-CX Secondary Image
   ---------------------------------------------------------------------------
   Version : GL.10.11.1010
   Size    : 501 MB
   Date    : 2023-03-28 04:53:23 UTC
   SHA-256 : 7c3594162675c5d95d06e4a465546e6fac8b60b8fce9a82ab82d303f8defd2cd

   Default Image : primary
   Boot Profile Timeout : 5 seconds

   ------------------------------------------------------
   Management Module 1/1 (Active)
   ------------------------------------------------------
   Active Image       : secondary
   Service OS Version : GL.01.08.0003
   BIOS Version       : GL-01-0013
   ```

1. After the firmware is uploaded to both VSX switches, you will need to start the software update from the VSX primary
   member.

   Since we uploaded to the secondary image, we choose that one to boot to.

    ```bash
    vsx update-software boot-bank secondary
    ```

   This will trigger the upgrade process on the VSX pair and it will start the dialogue explaining what will happen
   next, i.e. if any firmware/driver upgrades are needed (i.e. the unit would reboot twice if this was the case)
   and it will show you on the screen the current status of the upgrade process. In VSX upgrade process the secondary
   VSX member will always boot first.

   Once software update is complete verify the image version on both switches.

   ```bash
   show version
   ```

   Potential output:

   ```text
   -----------------------------------------------------------------------------
   ArubaOS-CX
   (c) Copyright 2017-2020 Hewlett Packard Enterprise Development LP
   -----------------------------------------------------------------------------
   Version      : GL.10.11.1010
   Build Date   : 2023-03-28 04:53:23 UTC
   Build ID     : ArubaOS-CX:GL.10.11.1010:966f173e8e4e:202303280333
   Build SHA    : 966f173e8e4e519b5296fa51297754f663ef2ad8
   Hot Patches  : 
   Active Image : secondary

   Service OS Version : GL.01.08.0003
   BIOS Version       : GL-01-0013
   ```

## Mellanox Firmware Update

SSH into the switch being upgraded.

1. Fetch the image from `ncn-m001`.

   ```bash
   image fetch scp://root@10.252.1.4/root/onyx-X86_64-3.9.3210.img
   ```

2. Install the image.

   ```bash
   image install onyx-X86_64-3.9.3210.img
   ```

3. Select the image to boot next.

   ```bash
   image boot next
   ```

4. Write memory and reload.

   ```bash
   write memory
   reload
   ```

5. Once the switch is available, verify the image is installed.

   ```bash
   show images
   ```

   Expected output:

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

## Dell Firmware Update

SSH into the switch being upgraded.

1. Fetch the image from `ncn-m001`.

   ```bash
   image install http://10.252.1.4/fw/network/OS10_Enterprise_10.5.1.4.stable.tar
   ```

2. Check the image upload status.

   ```bash
   show image status
   ```

   Potential output:

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

3. Reboot after the image is uploaded.

   ```bash
   write memory
   reload
   ```

4. Once the switch is available, verify the image is installed.

   ```bash
   show version
   ```

   Potential output:

   ```text
   Dell EMC Networking OS10 Enterprise
   Copyright (c) 1999-2020 by Dell Inc. All Rights Reserved.
   OS Version: 10.5.1.4
   Build Version: 10.5.1.4.249
   ```
