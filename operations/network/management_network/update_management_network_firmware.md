# Update Management Network Firmware

This page describes how to update firmware on the management network switches.

## Requirements

Access to the switches from the LiveCD/ncn-m001.

## Configuration

All firmware can be found in the HFP package provided with the Shasta release.

## Switch Firmware

| Vendor | Model | Version |
| --- | --- | --- |
| Aruba | 6300 | ArubaOS-CX_6400-6300_10.06.0010 |
| Aruba | 8320 | ArubaOS-CX_8320_10.06.0010 or ArubaOS-CX_8320_10.06.0110 |
| Aruba | 8325 | ArubaOS-CX_8325_10.06.0010 |
| Aruba | 8360 | ArubaOS-CX_8360_10.06.0010 or ArubaOS-CX_8360_10.06.0110 |
| Dell | S3048-ON | 10.5.1.4 |
| Dell | S4148F-ON | 10.5.1.4 |
| Dell | S4148T-ON | 10.5.1.4 |
| Mellanox | MSN2100 | 3.9.1014 |
| Mellanox | MSN2700 | 3.9.1014 |

## Aruba Firmware Best Practices

Aruba software version number explained:

For example: 10.06.0120

- 10		= OS

- 06		= Major branch (new features)

- 0120	= CPE release (bug fixes)


It is considered to be a best practice to keep all Aruba CX platform devices running the same software version.

Aruba CX devices two software image banks, which means sw images can be pre-staged to the device without booting to the new image.

If upgrading to a new major branch, in Aruba identified by the second integer in the software image number.

When upgrading past a major software release, for example, from 10.6 to 10.8 (and skipping 10.7), issue the `allow-unsafe-upgrades` command to allow any low level firmware/driver upgrades to complete. If going from the 10.6 branch to 10.7 branch, this step can be skipped as the low level firmware/driver upgrade would be automatically completed.

```
sw-leaf-001# config
sw-leaf-001(config)# allow-unsafe-updates 30
```

This command will enable non-failsafe updates of programmable devices for
the next 30 minutes. First, wait for all line and fabric
modules to reach the ready state, and then reboot the switch to begin
applying any needed updates. Ensure that the switch will not lose power,
be rebooted again, or have any modules removed until all updates have
finished and all line and fabric modules have returned to the ready state.

**WARNING:** Interrupting these updates may make the product unusable!

```
Continue (y/n)? y
Unsafe updates      : allowed (less than 30 minute(s) remaining)
```

VSX software upgrade command can automatically upgrade both of the peers in VSX topology by staging upgrade and automatically doing traffic shifting between peers to minimize impact to network. The following examples include the option for standalone and vsx-pair upgrade.

## Aruba Firmware Update - Standalone

SSH into the switch being upgraded.

Example: the IP address `10.252.1.12` used is the liveCD.
```
sw-leaf-001# copy sftp://root@10.252.1.12//var/www/ephemeral/data/network_images/ArubaOS-CX_6400-6300_10_06_0010.stable.swi primary

sw-leaf-001# write mem
Copying configuration: [Success]
```
Once the upload is complete, check the images:

```
sw-leaf-001# show image
---------------------------------------------------------------------------
ArubaOS-CX Primary Image
---------------------------------------------------------------------------
Version : FL.10.06.0010
Size    : 643 MB
Date    : 2020-12-14 10:06:34 PST
SHA-256 : 78dc27c5e521e92560a182ca44dc04b60d222b9609129c93c1e329940e1e11f9
```
After the firmware is uploaded, boot the switch to the correct image.

```
sw-leaf-001# boot system primary
```

Once the reboot is complete, check and make sure the firmware version is correct.

```
sw-leaf-001# show version
```

Example output:

```
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
## Aruba Firmware Update - VSX Software Upgrade

1. SSH into the Primary VSX member of the VSX-pair to upgrade.

     Example: the IP `10.252.1.12` used is the LiveCD.

2. Upload the firmware.

   ```
   sw-leaf-001# copy sftp://root@10.252.1.12//var/www/ephemeral/data/network_images/ArubaOS-CX_6400-6300_10_06_0120.stable.swi primary

   sw-leaf-001# write mem
   Copying configuration: [Success]
   ```

3. Once the upload is complete, check the images.

   ```
   sw-leaf-001# show image
   ```

   Example output:

   ```
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : FL.10.06.0120
   Size    : 643 MB
   Date    : 2021-03-14 10:06:34 PST
   SHA-256 : 78dc27c5e521e92560a182ca44dc04b60d222b9609129c93c1e329940e1e11f9
   ```

4. After the firmware is uploaded, boot the switch to the correct image.

   Example: the IP address `10.252.1.12` used is the liveCD.

   ```
   sw-leaf-001# copy sftp://root@10.252.1.12//var/www/ephemeral/data/network_images/ArubaOS-CX_6400-6300_10_06_0120.stable.swi primary

   sw-leaf-001# write mem
   Copying configuration: [Success]
   ```
   Once the upload is complete, check the images:

   ```
   sw-leaf-001# show image
   ```

   Example output:

   ```
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : FL.10.06.0120
   Size    : 643 MB
   Date    : 2021-03-14 10:06:34 PST
   SHA-256 : 78dc27c5e521e92560a182ca44dc04b60d222b9609129c93c1e329940e1e11f9
   ```
   
   After the firmware is uploaded, boot the switch to the correct image. When upgrading a VSX pair, use the VSX upgrade command to automatically upgrade both pairs.
   
   ```
   sw-leaf-001# vsx update-software boot-bank primary
   ```
   
   This will trigger the upgrade process on the VSX pair and it will start the dialogue explaining what will happen next, i.e. if any firmware/driver upgrades are needed (i.e. the unit would reboot twice if this was the case) and it will show you on the screen the current status of the upgrade process. in VSX upgrade process the secondary VSX member will always boot first.

## Mellanox Firmware Update

1. SSH into the switch being upgraded.

1. Fetch the image from ncn-m001.

   ```
   sw-spine-001 [standalone: master] # image fetch http://10.252.1.4/fw/network/onyx-X86_64-3.9.1014.stable.img
   ```

3. Install the image.

   ```
   sw-spine-001 [standalone: master] # image install onyx-X86_64-3.9.1014.stable.img
   ```

4. Select the image to boot next.

   ```
   sw-spine-001 [standalone: master] # image boot next
   ```

5. Write memory and reload.

   ```
   sw-spine-001 [standalone: master] # write memory
   sw-spine-001 [standalone: master] # reload
   ```

6. Once the switch is available, verify the image is installed.

   ```
   sw-spine-001 [standalone: master] # show images
   ```

   Example output:

   ```
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

1. SSH into the switch being upgraded.

1. Fetch the image from ncn-m001.

   ```
   sw-leaf-001# image install http://10.252.1.4/fw/network/OS10_Enterprise_10.5.1.4.stable.tar
   ```

3. Check the image upload status.

   ```
   sw-leaf-001# show image status
   ```

   Example output:

   ```
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

4. Reboot after the image is uploaded.

   ```
   sw-leaf-001# write memory
   sw-leaf-001# reload
   ```

5. Once the switch is available, verify the image is installed.

   ```
   sw-leaf-001# show version
   ```

   Example output:

   ```
   Dell EMC Networking OS10 Enterprise
   Copyright (c) 1999-2020 by Dell Inc. All Rights Reserved.
   OS Version: 10.5.1.4
   Build Version: 10.5.1.4.249
   ```
