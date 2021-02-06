# Management Network Firmware Update

This page describes how to update firmware on the Management network switches.

# Requirements

Access to the switches from the liveCD/M001

# Configuration

- All firmware will be located at ```/var/www/fw/network``` on the LiveCD
- It should contain the following files.
```
surtur-ncn-m001-pit:/var/www/network/firmware # ls -lh
total 2.7G
-rw-r--r-- 1 root root 614M Jan 15 18:57 ArubaOS-CX_6400-6300_10_05_0040.stable.swi
-rw-r--r-- 1 root root 368M Jan 15 19:09 ArubaOS-CX_8320_10_05_0040.stable.swi
-rw-r--r-- 1 root root 406M Jan 15 18:59 ArubaOS-CX_8325_10_05_0040.stable.swi
-rw-r--r-- 1 root root 729M Aug 26 17:11 onyx-X86_64-3.9.1014.stable.img
-rw-r--r-- 1 root root 577M Oct 28 11:45 OS10_Enterprise_10.5.1.4.stable.tar
```

1.4 Switch firmware.

| Vendor | Model | Version	|
| --- | --- | ---| --- | --- | --- | --- |
| Aruba | 6300 | ArubaOS-CX_6400-6300_10.06.0010 |
| Aruba | 8320 | ArubaOS-CX_8320_10.06.0010 |
| Aruba | 8325 | ArubaOS-CX_8325_10.06.0010 |
| Dell | S3048-ON | 10.5.1.4 |
| Dell | S4148F-ON | 10.5.1.4 |
| Dell | S4148T-ON | 10.5.1.4 |
| Mellanox | MSN2100 | 3.9.1014 |
| Mellanox | MSN2700 | 3.9.1014 |

# Aruba Firmware Update

SSH into the switch you want to upgrade.

Example: the IP ```10.252.1.12``` used is the liveCD 
```
sw-leaf01# copy sftp://root@10.252.1.12//var/www/ephemeral/data/network_images/ArubaOS-CX_6400-6300_10_06_0010.stable.swi primary

sw-leaf01# write mem
Copying configuration: [Success]
```
Once the upload is complete you can check the images

```
sw-leaf01# show image
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
sw-leaf01# boot system primary
```

Once the reboot is complete check and make sure the firmware version is correct.

```
sw-leaf01# show version
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







