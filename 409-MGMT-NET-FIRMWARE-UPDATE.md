# Management Network Firmware Update

This page describes how to update firmware on the Management network switches.

# Requirements

Access to the switches from the liveCD/M001

# Configuration

- All firmware will be located at ```/var/www/network/firmware``` on the LiveCD
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
| Aruba | 6300 | ArubaOS-CX_6400-6300_10.05.0040 |
| Aruba | 8320 | ArubaOS-CX_8320_10.05.0040 |
| Aruba | 8325 | ArubaOS-CX_8325_10.05.0040 |
| Dell | S3048-ON | 10.5.1.4P1 |
| Dell | S4148F-ON | 10.5.1.4P1 |
| Dell | S4148T-ON | 10.5.1.4P1 |
| Mellanox | MSN2100 | 3.9.1014 |
| Mellanox | MSN2700 | 3.9.1014 |

# Aruba Firmware Update

We will be leveraging the Aruba API to update firmware

