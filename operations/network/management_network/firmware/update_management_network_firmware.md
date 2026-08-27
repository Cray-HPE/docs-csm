# Update Management Network Firmware

- [Prerequisites](#prerequisites)
- [Switch firmware](#switch-firmware)
- [Identifying switch models](#identifying-switch-models)
    - [Aruba](#aruba)
    - [Mellanox](#mellanox)
    - [Dell](#dell)
- [Verify current switch firmware levels](#verify-current-switch-firmware-levels)
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
    - Examples in this document will use `/root/firmware/` on `ncn-m001`

Aruba firmware can be found in the HFP package provided with the HPE Cray EX release.
Dell and Mellanox firmware must be downloaded from the manufacturer.

## Switch firmware

| Model                         | software version |
|-------------------------------|-----------------:|
| Aruba 8320 Switch Series      |     `10.13.1040` |
| Aruba 8325 Switch Series      |     `10.13.1040` |
| Aruba 8360 Switch Series      |     `10.13.1040` |
| Aruba 6300 Switch Series      |     `10.13.1040` |
| Mellanox SN2100 Switch Series |       `3.9.3210` |
| Mellanox SN2700 Switch Series |       `3.9.3210` |
| Dell S3048-ON Switch Series   |       `10.5.1.4` |
| Dell S4148T-ON Switch Series  |       `10.5.1.4` |
| Dell S4148F-ON Switch Series  |       `10.5.1.4` |

## Identifying switch models

### Aruba

Run the command `show system` to identify the switch model.

Example output:

```console
Hostname               : sw-spine-001
System Description     : GL.10.13.1080
System Contact         :
System Location        :

Vendor                 : Aruba
Product Name           : JL635A Aruba 8325-48Y8C 48p 25G 8p 100G Swch
Chassis Serial Nbr     : TW06KM003Q
Base MAC Address       : b8d4e7-d33d00
ArubaOS-CX Version     : GL.10.13.1080

Time Zone              : UTC

Up Time                : 2 weeks, 1 day, 20 hours, 3 minutes
CPU Util (%)           : 1
CPU Util (% avg 1 min) : 5
CPU Util (% avg 5 min) : 4
Memory Usage (%)       : 22
```

### Mellanox

Run the `enable` command followed by `show system type` to identify the switch model.

Example output:

```console
MSN2100
```

### Dell

Run the command `show inventory` to identify the switch model.

Example output:

```console
Product               : S3048ON
Description           : S3048-ON 48x1GbE copper, 4x10GbE SFP+ Interface Module
Software version      : 10.5.1.4
Product Base          :
Product Serial Number :
Product Part Number   :

Unit Type                     Part Number  Rev  Piece Part ID             Svc Tag  Exprs Svc Code
-------------------------------------------------------------------------------------------------
* 1  S3048ON                  0J4T5K       A02  CN-0J4T5K-CES00-877-0160  2F700Q2  527 231 556 2
  1  S3048ON-PWR-1-AC-R       00X3X6       A00  TH-00X3X6-17971-86P-0GA3  AEIOU##  226 457 410 55
  1  S3048ON-PWR-2-AC-R       00X3X6       A00  TH-00X3X6-17971-86P-0GEE  AEIOU##  226 457 410 55
  1  S3048ON-FANTRAY-1-R      05JHJD       A00  CN-05JHJD-CES00-86N-0376  AEIOU##  226 457 410 55
  1  S3048ON-FANTRAY-2-R      05JHJD       A00  CN-05JHJD-CES00-86N-0507  AEIOU##  226 457 410 55
  1  S3048ON-FANTRAY-3-R      05JHJD       A00  CN-05JHJD-CES00-86N-0492  AEIOU##  226 457 410 55
```

## Verify current switch firmware levels

The CANU utility can be used to report the current management switch firmware levels. The example output shows that the firmware
is not at the recommended version and needs to be updated.

(`ncn-m#`) Run `canu` to report the firmware level of all switches. The switch admin user password should be supplied when prompted.

```bash
canu report network firmware --csm 1.6 --ips $(awk '/sw-/{ printf "%s%s", sep, $1; sep="," }' /etc/hosts)
```

Example output:

```text
------------------------------------------------------------------
    STATUS  IP              HOSTNAME            FIRMWARE
------------------------------------------------------------------
 ❌ Fail    10.254.0.2      sw-spine-001        LL.10.11.1010       Firmware should be in range ['LL.10.13.1040']
 ❌ Fail    10.254.0.3      sw-spine-002        LL.10.11.1010       Firmware should be in range ['LL.10.13.1040']
 ❌ Fail    10.254.0.4      sw-leaf-bmc-001     FL.10.11.1010       Firmware should be in range ['FL.10.13.1040']

Summary
------------------------------------------------------------------
❌ Fail - 3 switches
LL.10.11.1010 - 2 switches
FL.10.11.1010 - 1 switches
```

## Aruba firmware best practices

Aruba software version number explained:

For example: `10.11.1010`

- 10 = OS
- 13 = Major branch (new features)
- 1040 = CPE release (bug fixes)

It is considered to be a best practice to keep all Aruba CX platform devices running the same software version.

Aruba CX devices have two software image banks, which means switch images can be pre-staged to the device without booting to the
new image.

If upgrading to a new major branch, in Aruba identified by the second integer in the software image number.

When upgrading past a major software release, for example, from 10.9 to 10.11 (and skipping `10.10.xxxx`)
issue the `allow-unsafe-upgrades` command to allow any low level firmware/driver upgrades to complete. If going from the
10.6 branch to 10.7 branch, this step can be skipped as the low level firmware/driver upgrade would be automatically
completed.

```console
config
sw-leaf-001(config)# allow-unsafe-updates 30
```

Example output:

```console
This command will enable non-failsafe updates of programmable devices for
the next 30 minutes.  You will first need to wait for all line and fabric
modules to reach the ready state, and then reboot the switch to begin
applying any needed updates.  Ensure that the switch will not lose power,
be rebooted again, or have any modules removed until all updates have
finished and all line and fabric modules have returned to the ready state.

WARNING: Interrupting these updates may make the product unusable!

Continue (y/n)? y

    Unsafe updates      : allowed (less than 30 minute(s) remaining)
```

VSX software upgrade command can automatically upgrade both of the peers in VSX topology by staging upgrade and
automatically doing traffic shifting between peers to minimize impact to network. The following examples include the
option for standalone and vsx-pair upgrade.

- Aruba 6300 series switches that are deployed as `sw-leaf-bmc` devices should use the [Aruba Firmware Update - Standalone](#aruba-firmware-update---standalone) procedure.
- Aruba 8325, 8320, and 8360 switches that are deployed as `sw-spine`, `sw-leaf`, or `sw-cdu` devices should use the
  [Aruba Firmware Update - VSX Software Upgrade](#aruba-firmware-update---vsx-software-upgrade) procedure.

## Aruba firmware update - Standalone

This procedure applicable to Aruba 6300 series switches that are deployed as `sw-leaf-bmc` devices.

Login into the switch being upgraded.

1. Check images

   ```console
   show images
   ```

   Example output:

   ```console
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : FL.10.13.1040
   Size    : 983 MB
   Date    : 2024-08-01 18:10:26 UTC
   SHA-256 : 62e31372c01a82ba1332bbc2e30dd88d4bbc0a9c85a02c138ae7fd5e49fdb560

   ---------------------------------------------------------------------------
   ArubaOS-CX Secondary Image
   ---------------------------------------------------------------------------
   Version : FL.10.11.1010
   Size    : 1122 MB
   Date    : 2023-03-28 05:07:09 UTC
   SHA-256 : 9629f98029d5e78d76f5cbd0e4722725f8fd84f015794602a78d1bddc16650cb

   Default Image : primary
   Boot Profile Timeout : 5 seconds

   ------------------------------------------------------
   Management Module 1/1 (Active)
   ------------------------------------------------------
   Active Image       : primary
   Service OS Version : FL.01.14.0002
   BIOS Version       : FL.01.0007
   ```

1. Upload the firmware to the desired image.

   The firmware should be uploaded to the image that is not in use. In the previous output the default image is the primary image so
   in this example the firmware is being uploaded to the secondary image.

   CANU 1.8.0 introduced with CSM 1.5.0 moved the CSM networks into their own virtual router (VRF) which necessitates the use of `vrf CSM` with the `copy` command.
   Earlier CSM releases use the `default` VRF for the node and hardware management networks so `vrf CSM` is not necessary for those releases.

   ```console
   copy scp://root@10.252.1.12//root/firmware/ArubaOS-CX_6400-6300_10_13_1080.swi secondary vrf CSM
   ```

   Example output:

   ```console
   The secondary image will be deleted.

   Continue (y/n)? y
   (root@10.252.1.12) Password:
   ArubaOS-CX_6400-6300_10_13_1080.swi                                                                                                                                                                                       100%  941MB  25.7MB/s   00:36

   Verifying and writing system firmware...
   ```

1. Save the switch configuration

   ```console
   write mem
   ```

   Example output:

   ```console
   Copying configuration: [Success]
   ```

1. Once the upload is complete, check the images:

   ```console
   show images
   ```

   Example output:

   ```console
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : FL.10.13.1040
   Size    : 983 MB
   Date    : 2024-08-01 18:10:26 UTC
   SHA-256 : 62e31372c01a82ba1332bbc2e30dd88d4bbc0a9c85a02c138ae7fd5e49fdb560

   ---------------------------------------------------------------------------
   ArubaOS-CX Secondary Image
   ---------------------------------------------------------------------------
   Version : FL.10.13.1080
   Size    : 986 MB
   Date    : 2025-02-12 17:30:57 UTC
   SHA-256 : 738bd148b9f88490a81c5020c8b8ecf6ad2dbb71b67a9d222f50941820873d03

   Default Image : primary
   Boot Profile Timeout : 5 seconds

   ------------------------------------------------------
   Management Module 1/1 (Active)
   ------------------------------------------------------
   Active Image       : primary
   Service OS Version : FL.01.14.0002
   BIOS Version       : FL.01.0007
   ```

1. After the firmware is uploaded, boot the switch into to the new image.

   ```console
   boot system secondary
   ```

   Example output:

   ```console
   Default boot image set to secondary.
   Checking if the configuration needs to be saved...

   Checking for updates needed to programmable devices...
   Done checking for updates.


   This will reboot the entire switch and render it unavailable
   until the process is complete.
   Continue (y/n)? y
   The system is going down for reboot.

   Mar 19 16:25:05 hpe-mgmtmd[3569660]: RebootLibPh1: Reboot reason: Reboot requested by user
   ```

1. Once the reboot is complete, check and make sure the firmware version is correct.

   ```console
   show version
   ```

   Example output:

   ```console
   -----------------------------------------------------------------------------
   ArubaOS-CX
   (c) Copyright 2017-2025 Hewlett Packard Enterprise Development LP
   -----------------------------------------------------------------------------
   Version      : FL.10.13.1080
   Build Date   : 2025-02-12 17:30:57 UTC
   Build ID     : ArubaOS-CX:FL.10.13.1080:b5ead808ab19:202502121708
   Build SHA    : b5ead808ab199c2df94f81df369073b140a9beea
   Hot Patches  :
   Active Image : secondary

   Service OS Version : FL.01.14.0002
   BIOS Version       : FL.01.0007
   ```

## Aruba firmware update - VSX software upgrade

Login to both VSX switches and pre-stage the firmware.

In this example we are pre-staging the firmware to `sw-spine-001` and `sw-spine-002`.

1. Determine VSX role and peer switch.

   Several of the following steps must be run on the VSX primary and secondary switches use the following commands
   to determine the switch role and partner switch.

   1. Determine VSX role.

      ```console
      show vsx status
      ```

      Example output:

      ```console
      VSX Operational State
      ---------------------
      ISL channel             : In-Sync
      ISL mgmt channel        : operational
      Config Sync Status      : In-Sync
      NAE                     : peer_reachable
      HTTPS Server            : peer_reachable

      Attribute           Local               Peer
      ------------        --------            --------
      ISL link            lag256              lag256
      ISL version         2                   2
      System MAC          02:00:00:00:01:00   02:00:00:00:01:00
      Platform            8325                8325
      Software Version    GL.10.13.1080       GL.10.13.1080
      Device Role         primary             secondary
      ```

   1. Determine partner switch.

      ```console
      show system vsx-peer
      ```

      Example output:

      ```console
      Hostname               : sw-spine-002
      System Description     : GL.10.13.1080
      System Contact         :
      System Location        :

      Vendor                 : Aruba
      Product Name           : JL635A Aruba 8325-48Y8C 48p 25G 8p 100G Swch
      Chassis Serial Nbr     : TW05KM0076
      Base MAC Address       : b8d4e7-43fa00
      ArubaOS-CX Version     : GL.10.13.1080

      Time Zone              : UTC

      CPU Util (%)           : 8
      CPU Util (% avg 1 min) : 8
      CPU Util (% avg 5 min) : 6
      Memory Usage (%)       : 22
      ```

      In the above output `sw-spine-002` is the VSX secondary switch.

1. Check images.

   ```console
   show images
   ```

   Example output:

   ```console
   ---------------------------------------------------------------------------
   ArubaOS-CX Primary Image
   ---------------------------------------------------------------------------
   Version : GL.10.13.1040
   Size    : 389 MB
   Date    : 2024-08-01 18:08:32 UTC
   SHA-256 : 89b5bcd560f034ec8d8c811b4e6f229dd2ec575b4d8239a2185380aa42f3da24

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
   Active Image       : primary
   Service OS Version : GL.01.14.0001
   BIOS Version       : GL-01-0013
   ```

1. Upload the firmware to the desired image.

   The firmware should be uploaded to the image that is not in use. In the previous output the default image is the primary image so
   in this example the firmware is being uploaded to the secondary image.

   This step should be performed on both switches in the VSX pair.

   CANU 1.8.0 introduced with CSM 1.5.0 moved the CSM networks into their own virtual router (VRF) which necessitates the use of `vrf CSM` with the `copy` command.
   Earlier CSM releases use the `default` VRF for the node and hardware management networks so `vrf CSM` is not necessary for those releases.

    ```console
   copy sftp://root@10.252.1.12//root/firmware/ArubaOS-CX_8325_10_08_1021.swi secondary vrf CSM
   ```

   Example output:

   ```console
   The secondary image will be deleted.

   Continue (y/n)? y
   (root@10.252.1.12) Password:
   ArubaOS-CX_8325_10_13_1080.swi                                                                                                                                                                                            100%  372MB   7.6MB/s   00:48

   Verifying and writing system firmware...
   ```

1. Verify uploaded image is correct.

   ```console
   show images
   ```

   Example output:

   ```console
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

1. Upgrade firmware.

   After the firmware is uploaded to both VSX switches, the software update should be initiated on the VSX primary.

   The firmware was uploaded to the secondary image, so this is the image that should be used for the upgrade.

    ```console
    vsx update-software boot-bank secondary
    ```

   This will trigger the upgrade process on the VSX pair and it will start the dialogue explaining what will happen
   next, i.e. if any firmware/driver upgrades are needed (i.e. the unit would reboot twice if this was the case)
   and it will show you on the screen the current status of the upgrade process. In VSX upgrade process the secondary
   VSX member will always boot first.

   Example output:

   ```console
   This command will upgrade both VSX primary and secondary systems, using pre-staged
   image, from 'GL.10.13.1040' to 'GL.10.13.1080' installed in secondary bank
   on both devices, then reboot them in sequence. The VSX secondary will reboot first,
   followed by primary.
   Continue (y/n)? y
   Do you want to save the current configuration (y/n)? y
   The running configuration is saved to the startup configuration.

   VSX Primary Software Update Status     : Waiting for VSX secondary to complete reboot
   VSX Secondary Software Update Status   : Control plane shutdown initiated
   VSX ISL Status                         : Up
   Progress [##################........................................................................]
   ```

1. Verify version each switch.

   ```console
   show version
   ```

   Example output:

   ```console
   -----------------------------------------------------------------------------
   ArubaOS-CX
   (c) Copyright 2017-2025 Hewlett Packard Enterprise Development LP
   -----------------------------------------------------------------------------
   Version      : GL.10.13.1080
   Build Date   : 2025-02-12 17:29:23 UTC
   Build ID     : ArubaOS-CX:GL.10.13.1080:b5ead808ab19:202502121708
   Build SHA    : b5ead808ab199c2df94f81df369073b140a9beea
   Hot Patches  :
   Active Image : secondary

   Service OS Version : GL.01.14.0001
   BIOS Version       : GL-01-0013
   ```

1. Verify VSX state.

   ISL channel should be `In-Sync` and `operational` and Config Sync Status should be `In-Sync`.

   ```console
   show vsx status
   ```

   Example output:

   ```console
   VSX Operational State
   ---------------------
   ISL channel             : In-Sync
   ISL mgmt channel        : operational
   Config Sync Status      : In-Sync
   NAE                     : peer_reachable
   HTTPS Server            : peer_reachable

   Attribute           Local               Peer
   ------------        --------            --------
   ISL link            lag256              lag256
   ISL version         2                   2
   System MAC          02:00:00:00:01:00   02:00:00:00:01:00
   Platform            8325                8325
   Software Version    GL.10.13.1080       GL.10.13.1080
   Device Role         primary             secondary
   ```

## Mellanox firmware update

SSH into the switch being upgraded.

1. Fetch the image from `ncn-m001`.

   ```console
   image fetch scp://root@10.252.1.4/root/firmware/onyx-X86_64-3.9.3210.img
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

   ```console
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

SSH into the switch being upgraded.

1. Fetch the image from `ncn-m001`.

   ```console
   image install http://10.252.1.4/root/firmware/OS10_Enterprise_10.5.1.4.stable.tar
   ```

1. Check the image upload status.

   ```console
   show image status
   ```

   Example output:

   ```console
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

   ```console
   Dell EMC Networking OS10 Enterprise
   Copyright (c) 1999-2020 by Dell Inc. All Rights Reserved.
   OS Version: 10.5.1.4
   Build Version: 10.5.1.4.249
   ```
