# Management Network Firmware Update

This page describes how to update firmware on the Management network switches.

# Requirements

Access to the switches from the liveCD/M001

# Configuration

- All firmware will be located at ```/var/www/fw/network``` on the LiveCD
- It should contain the following files.
```
ncn-m001-pit:/var/www/network/firmware # ls -lh
total 2.7G
-rw-r--r-- 1 root root 614M Jan 15 18:57 ArubaOS-CX_6400-6300_10_05_0040.stable.swi
-rw-r--r-- 1 root root 368M Jan 15 19:09 ArubaOS-CX_8320_10_05_0040.stable.swi
-rw-r--r-- 1 root root 406M Jan 15 18:59 ArubaOS-CX_8325_10_05_0040.stable.swi
-rw-r--r-- 1 root root 729M Aug 26 17:11 onyx-X86_64-3.9.1014.stable.img
-rw-r--r-- 1 root root 577M Oct 28 11:45 OS10_Enterprise_10.5.1.4.stable.tar
```

1.4 Switch firmware.

| Vendor | Model | Version |
| --- | --- | ---|
| Aruba | 6300 | ArubaOS-CX_6400-6300_10.06.0010 |
| Aruba | 8320 | ArubaOS-CX_8320_10.06.0010 |
| Aruba | 8320 used as CDU | ArubaOS-CX_8320_10.06.0110 |
| Aruba | 8325 | ArubaOS-CX_8325_10.06.0010 |
| Aruba | 8360 | ArubaOS-CX_8360.06.0110 |
| Dell | S3048-ON | 10.5.1.4 |
| Dell | S4148F-ON | 10.5.1.4 |
| Dell | S4148T-ON | 10.5.1.4 |
| Mellanox | MSN2100 | 3.9.1014 |
| Mellanox | MSN2700 | 3.9.1014 |

# Aruba Firmware Update - when used as a MLAG pair using VSX
The following procedure is recommended by Aruba for switch pairs using VSX to provide minimal outages during the upgrade.

NOTE: For the following example the switch pair will be composed of sw-cdu-001 and sw-cdu-002 with the second switch in the pair being sw-cdu-002.
NOTE: In the example: ```10.252.1.12``` used is the liveCD firmware location.

SSH into the second switch of the pair:
```
ssh admin@sw-cdu-002

sw-cdu-002# copy sftp://root@10.252.1.12//var/www/ephemeral/data/network_images/ArubaOS-CX_8360.06.0110.stable.swi primary

sw-cdu-002# write mem
Copying configuration: [Success]
```
Once the upload is complete you can check the images
Check Firmware Version and VSX status (you should see both Local and Peer).
```
sw-cdu-002# show vsx status
VSX Operational State
---------------------
  ISL channel             : In-Sync
  ISL mgmt channel        : operational
  Config Sync Status      : In-Sync
  NAE                     : peer_reachable
  HTTPS Server            : peer_reachable

Attribute           Local               Peer
------------        --------            --------
ISL link            lag99               lag99
ISL version         2                   2
System MAC          02:01:00:00:01:00   02:01:00:00:01:00
Platform            8325                8325
Software Version    GL.10.06.0010       GL.10.06.0010
Device Role         primary             secondary
```
After the firmware is uploaded you will need to boot the switch to the correct image.

```
sw-cdu-002# boot system primary
```

Once the reboot is complete check and make sure the firmware version is correct.  You should also see that the VSX Peer is empty of information.  This will resolve after the other switch is updated. For now the current switch (sw-cdu-002) is the master and will be accepting all traffic.

```
sw-cdu-002# show vsx status
VSX Operational State
---------------------
  ISL channel             : In-Sync
  ISL mgmt channel        : operational
  Config Sync Status      : 
  NAE                     : peer_reachable
  HTTPS Server            : peer_reachable

Attribute           Local               Peer
------------        --------            --------
ISL link            lag99               
ISL version         2                   
System MAC          02:01:00:00:01:00   
Platform            8360                
Software Version    GL.10.06.0110       
Device Role         primary             
```
Repeat the process just performed on the second switch in the pair on the first switch in the pair. For this example the first switch is sw-cdu-001.
1. ssh to sw-cdu-001
2. upload the new firmware to primary.
3. validate vsx status
4. reboot the switch to the new firmware.
6. validate vsx status: both Local and Peer VSX columns should be populated and have the correct, updated firmware versions running.

# Aruba Firmware Update - standalone

SSH into the switch you want to upgrade.

Example: the IP ```10.252.1.12``` used is the liveCD 
```
sw-leaf-001# copy sftp://root@10.252.1.12//var/www/ephemeral/data/network_images/ArubaOS-CX_6400-6300_10_06_0010.stable.swi primary

sw-leaf-001# write mem
Copying configuration: [Success]
```
Once the upload is complete you can check the images

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
After the firmware is uploaded you will need to boot the switch to the correct image.

```
sw-leaf-001# boot system primary
```

Once the reboot is complete check and make sure the firmware version is correct.

```
sw-leaf-001# show version
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

# Mellanox Firmware Update

SSH into the switch you want to upgrade

Fetch the image from ncn-m001.
```
sw-spine-001 [standalone: master] # image fetch http://10.252.1.4/fw/network/onyx-X86_64-3.9.1014.stable.img
```

Install the image.
```
sw-spine-001 [standalone: master] # image install onyx-X86_64-3.9.1014.stable.img 
```

Select the image to boot next.
```
sw-spine-001 [standalone: master] # image boot next
```

Write memory and reload.
```
sw-spine-001 [standalone: master] # write memory 
sw-spine-001 [standalone: master] # reload
```

Once the switch is available, verify the image is installed.
```
sw-spine-001 [standalone: master] # show images 

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

# Dell Firmware Update

SSH into the switch you want to upgrade

Fetch the image from ncn-m001.
```
sw-leaf-001# image install http://10.252.1.4/fw/network/OS10_Enterprise_10.5.1.4.stable.tar
```

Check the image upload status.

```
sw-leaf-001# show image status
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

Once the image is uploaded all that's left is a reboot.
```
sw-leaf-001# write memory 
sw-leaf-001# reload
```

Once the switch is available, verify the image is installed.
```
sw-leaf-001# show version 
Dell EMC Networking OS10 Enterprise
Copyright (c) 1999-2020 by Dell Inc. All Rights Reserved.
OS Version: 10.5.1.4
Build Version: 10.5.1.4.249
```
