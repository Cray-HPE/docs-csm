# Performing upgrade on Mellanox switches

Supported Software Upgrades

Target Version |Verified Versions from Which to Upgrade|
| ----- | -----: |
3.9.3xxx| 3.9.2xxx, 3.9.1xxx
3.9.2xxx| 3.9.1xxx, 3.9.0xxx
3.9.1xxx| 3.9.0xxx, 3.8.2xxx
3.9.0xxx| 3.8.2xxx, 3.8.1xxx

Note: the following steps should be repeated for each “upgrade hop”

 

Upgrading the Switch via CLI

The Switch OS software packages include the switch firmware and the CPU software for the specific switch board CPU (x86).

Installing the CPU software also automatically installs the embedded firmware. Similarly, once the OS is upgraded, the firmware is upgraded as well.

The switch's OS image and its documentation collateral (release notes, user manual) can be found in MyMellanox

 

1. Run the following commands in order to upgrade (e.g. upgrading to version 3.9.0606 )
```
switch (config)#image delete XXX // --> delete old images one at a time, if exist
switch (config)#image fetch scp://root:password@server/path-to-image/image-X86_64-3.9.0606.img
switch (config)#image install image-X86_64-3.9.0606.img
switch (config)#image boot next
switch (config)#configuration write
switch (config)#reload
```
 

2. Wait a few minutes to allow the OS's upgrade process to complete and then reconnect to the system.

3. To verify the installation was completed successfully, run:
```
# show version

Product name:      MLNX-OS

Product release:   3.9.0606

Build ID:          #1-dev

Build date:        2020-05-01 08:20:15

Target arch:       x86_64

Target hw:         x86_64

Built by:          sw-r2d2-bot@b13770d14a06

Version summary:   X86_64 3.9.0606 2020-05-01 08:20:15 x86_64

 

Product model:     x86

Host ID:           7CFE900BC470

System UUID:       03000200-0400-0500-0006-000700080009

 

Uptime:            16m 54.930s

CPU load averages: 0.02 / 0.08 / 0.11

Number of CPUs:    2

System memory:     485 MB used / 3278 MB free / 3763 MB total

Swap:              0 MB used / 0 MB free / 0 MB total

l-csi-7800-0537 [standalone: master] (config) # 

6. To verify the system's firmware version:

# show asic-version

l-csi-7800-0537 [standalone: master] (config) # show asic-version

---------------------------------------------------

Module             Device              Version

---------------------------------------------------

MGMT               SIB2                15.2007.0900
```
[Back to Index](../index.md)

