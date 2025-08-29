# NCN Boot Workflow

This document provides information on non-compute node (NCN) boot devices and boot ordering.

* [Boot sources](#boot-sources)
* [Determine the current boot order](#determine-the-current-boot-order)
* [Reasons to change the boot order after CSM install](#reasons-to-change-the-boot-order-after-csm-install)
* [Determine if NCNs booted via disk or PXE](#determine-if-ncns-booted-via-disk-or-pxe)
* [Set BMCs to DHCP](#set-bmcs-to-dhcp)
* [Boot order overview](#boot-order-overview)
* [Setting boot order](#setting-boot-order)
* [Trimming boot order](#trimming-boot-order)
* [Example boot orders](#example-boot-orders)
* [Reverting changes](#reverting-changes)
* [Locating USB device](#locating-usb-device)

## Boot sources

Non-compute nodes (NCNs) can boot from two sources:

* Network/PXE
* Disk

## Determine the current boot order

Under normal operations, the NCNs use the following boot order:

1. PXE (to ensure that the NCN is booting with desired images and configuration)
1. Disk (fallback in the event that PXE services are unavailable)

## Reasons to change the boot order after CSM install

After the CSM install is complete, it is usually not necessary to change the boot order. Having PXE first and disk as a fallback works in the majority of situations.

It may be desirable to change the boot order under these circumstances:

* Testing disk-backed booting
* Booting from a USB or remote ISO
* Testing or deploying other customizations

## Determine if NCNs booted via disk or PXE

There are two different methods for determining whether a management node is booted using disk or
PXE. The method to use will vary depending on the system environment.

1. (`ncn#` or `pit#`) Check kernel parameters.

    ```bash
    cat /proc/cmdline
    ```

    If it starts with `kernel`, then the node network booted. If it starts with `BOOT_IMAGE=(`, then it disk booted.

1. (`ncn#` or `pit#`) Check output from `efibootmgr`.

    ```bash
    efibootmgr
    ```

    The `BootCurrent` value should be matched to the list beneath to see if it lines up with a networking option or a `cray sd*)` option for disk boots.

    ```bash
    efibootmgr
    ```

    Example output:

    ```text
    BootCurrent: 0016
    Timeout: 2 seconds
    BootOrder: 0000,0011,0013,0014,0015,0016,0017,0005,0007,0018,0019,001A,001B,001C,001D,001E,001F,0020,0021,0012
    Boot0000* cray (sda1)
    Boot0001* UEFI: Built-in EFI Shell
    Boot0005* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:1D:D8:4E
    Boot0007* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:1D:D8:4F
    Boot0010* UEFI: AMI Virtual CDROM0 1.00
    Boot0011* cray (sdb1)
    Boot0012* UEFI: Built-in EFI Shell
    Boot0013* UEFI OS
    Boot0014* UEFI OS
    Boot0015* UEFI: AMI Virtual CDROM0 1.00
    Boot0016* UEFI: SanDisk     <--- Matches here
    Boot0017* UEFI: SanDisk, Partition 2
    Boot0018* UEFI: HTTP IP4 Intel(R) I350 Gigabit Network Connection
    Boot0019* UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection
    Boot001A* UEFI: HTTP IP4 Mellanox Network Adapter - B8:59:9F:1D:D8:4E
    Boot001B* UEFI: HTTP IP4 Mellanox Network Adapter - B8:59:9F:1D:D8:4F
    Boot001C* UEFI: HTTP IP4 Intel(R) I350 Gigabit Network Connection
    Boot001D* UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection
    Boot001E* UEFI: PXE IP6 Intel(R) I350 Gigabit Network Connection
    Boot001F* UEFI: PXE IP6 Intel(R) I350 Gigabit Network Connection
    Boot0020* UEFI: PXE IP6 Mellanox Network Adapter - B8:59:9F:1D:D8:4E
    Boot0021* UEFI: PXE IP6 Mellanox Network Adapter - B8:59:9F:1D:D8:4F
    ```

## Set BMCs to DHCP

When reinstalling a system, the BMCs for the NCNs may be set to static IP addressing. The `/var/lib/misc/dnsmasq.leases` file is checked when setting up the symlinks for the
artifacts each node needs to boot. So if the BMCs are set to static, those artifacts will not get set up correctly. Set the BMCs back to DHCP by using a command such as:

> `read -s` is used to prevent the password from being written to the screen or the shell history.

```bash
USERNAME=root
read -r -s -p "NCN BMC ${USERNAME} password: " IPMI_PASSWORD
export IPMI_PASSWORD
for h in $( grep mgmt /etc/hosts | grep -v m001 | awk -F ',' '{print $2}' ); do
    ipmitool -U "${USERNAME}" -I lanplus -H "${h}" -E lan set 1 ipsrc dhcp
done
```

Some BMCs need a cold reset in order to pick up this change fully:

```bash
for h in $( grep mgmt /etc/hosts | grep -v m001 | awk -F ',' '{print $2}' ); do
      ipmitool -U "${USERNAME}" -I lanplus -H "${h}" -E mc reset cold
done
```

## Boot order overview

* `ipmitool` can set and edit boot order; it works better for some vendors based on their BMC implementation
* `efibootmgr` speaks directly to the node's UEFI; it can only be ignored by new BIOS activity

> **NOTE:** `cloud-init` will set boot order and trim boot devices during its `runcmd` module, but this does not always work with certain hardware vendors. An administrator may invoke the `cloud-init` script on
> any NCN or PIT by loading `/srv/cray/scripts/metal/metal-lib.sh` (this should be loaded in a sub-shell as the library has a `set -e` flag.)

## Setting boot order

This section gives the procedure for setting the boot order on NCNs and the PIT node.

Setting the boot order with `efibootmgr` will ensure that the desired network interfaces and disks are in the proper order for booting.

The commands are the same for all hardware vendors, except where noted.

1. (`ncn#` or `pit#`) Create a list of the desired IPv4 boot devices.

    Follow the section corresponding to the hardware manufacturer of the system:

    * Gigabyte Technology

        ```bash
        efibootmgr | grep -iP '(pxe ipv?4.*adapter)' | tee /tmp/bbs1
        ```

    * Hewlett-Packard Enterprise

        ```bash
        efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
        ```

    * Intel Corporation

        ```bash
        efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
        ```

1. (`ncn#` or `pit#`) Create a list of the Cray disk boot devices.

    ```bash
    efibootmgr | grep -i cray | tee /tmp/bbs2
    ```

1. (`ncn#` or `pit#`) Set the boot order to first PXE boot, with disk boot as the fallback option.

    ```bash
    efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
    ```

1. (`ncn#` or `pit#`) Set all of the desired boot options to be active.

    ```bash
    cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
    ```

1. (`ncn#` or `pit#`) Set next boot entry.

    ```bash
    efibootmgr -n <desired_next_boot_device>
    ```

After following the steps above on a given NCN, that NCN will use the desired Shasta boot order.

This is the end of the `Setting boot order` procedure.

## Trimming boot order

This procedure prunes the list of boot devices, optimizing the boot order to align with CSM's requirements.

(`ncn#` or `pit#`) Load the metal tools library and invoke the boot trim function.

```bash
TEMP=$(mktemp -d)
efibootmgr > "${TEMP}/original.log"
(
. /srv/cray/scripts/metal/metal-lib.sh
setup_uefi_bootorder >"${TEMP}/run.log"
)
```

> ***NOTE*** The above snippet is `pdsh` friendly for bulk trims.

The `${TEMP}/run.log` file will show the output from each `efibootmgr` call to trim the boot order.

The boot order has been trimmed.

## Example boot orders

Each section shows example output of the `efibootmgr` command.

* Master node (with onboard NICs enabled)

    ```text
    BootCurrent: 0002
    Timeout: 0 seconds
    BootOrder: 0000,0013,001A,0002,000F,0012,0014,0015
    Boot0000* System Utilities
    Boot0001  Non bootable Hotkey
    Boot0002* CRAY UEFI OS 0
    Boot0003  Intelligent Provisioning
    Boot0004  Embedded UEFI Shell
    Boot0005  Embedded iPXE
    Boot0006  Diagnose Error
    Boot0007  Boot Menu
    Boot0008  Network Boot
    Boot0009  View Integrated Management Log
    Boot000A  View GUI mode Integrated Management Log
    Boot000B  View BIOS Event Log
    Boot000C  HTTP Boot
    Boot000D  PXE Boot
    Boot000E  Embedded Diagnostics
    Boot000F* CRAY UEFI OS 1
    Boot0010* Generic USB Boot
    Boot0012  SATA Drive  Box 1 Bay 1 : VK000480GWTHA
    Boot0013* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
    Boot0014  SATA Drive  Box 1 Bay 2 : VK000480GWTHA
    Boot0015  SATA Drive  Box 1 Bay 3 : VK000480GWTHA
    Boot0016* Rear USB 1 : PNY USB 3.1 FD
    Boot001A* Slot 1 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - PXE (PXE IPv4)
    ```

* Storage node (with onboard NICs enabled)

    ```text
    BootCurrent: 0014
    Timeout: 0 seconds
    BootOrder: 0000,0014,0015,0016,0010,0011,0012
    Boot0000* System Utilities
    Boot0001  Non bootable Hotkey
    Boot0002  Intelligent Provisioning
    Boot0003  Embedded UEFI Shell
    Boot0004  Embedded iPXE
    Boot0005  Diagnose Error
    Boot0006  Boot Menu
    Boot0007  Network Boot
    Boot0008  View Integrated Management Log
    Boot0009  View GUI mode Integrated Management Log
    Boot000A  View BIOS Event Log
    Boot000B  HTTP Boot
    Boot000C  PXE Boot
    Boot000D  Embedded Diagnostics
    Boot000E* Generic USB Boot
    Boot000F* OCP Slot 10 Port 2 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
    Boot0010  SATA Drive  Box 1 Bay 1 : VK000480GWTHA
    Boot0011  SATA Drive  Box 1 Bay 2 : VK000480GWTHA
    Boot0012  SATA Drive  Box 1 Bay 3 : VK001920GWTHC
    Boot0013  Temporary Legacy Boot Option
    Boot0014* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
    Boot0015* CRAY UEFI OS 0
    Boot0016* CRAY UEFI OS 1
    ```

* Worker node (with onboard NICs enabled)

    ```text
    BootCurrent: 0019
    Timeout: 20 seconds
    BootOrder: 0000,0019,001E,001C,001D,0010,0011,0012,0013,0014,0015,0016,0017,0018,001A
    Boot0000* System Utilities
    Boot0001  Non bootable Hotkey
    Boot0002  Intelligent Provisioning
    Boot0003  Embedded UEFI Shell
    Boot0004  Embedded iPXE
    Boot0005  Diagnose Error
    Boot0006  Boot Menu
    Boot0007  Network Boot
    Boot0008  View Integrated Management Log
    Boot0009  View GUI mode Integrated Management Log
    Boot000A  View BIOS Event Log
    Boot000B  HTTP Boot
    Boot000C  PXE Boot
    Boot000D  Embedded Diagnostics
    Boot000E* Generic USB Boot
    Boot000F  Temporary Legacy Boot Option
    Boot0010  SATA Drive  Box 4 Bay 2 : VK001920GWTTC
    Boot0011  SATA Drive  Box 4 Bay 1 : VK001920GWTTC
    Boot0012  SATA Drive  Box 1 Bay 5 : VK001920GWTTC
    Boot0013  SATA Drive  Box 1 Bay 6 : VK001920GWTTC
    Boot0014  SATA Drive  Box 1 Bay 7 : VK001920GWTTC
    Boot0015  SATA Drive  Box 1 Bay 8 : VK001920GWTTC
    Boot0016  SATA Drive  Box 1 Bay 1 : VK000480GWTHA
    Boot0017  SATA Drive  Box 1 Bay 2 : VK000480GWTHA
    Boot0018  SATA Drive  Box 1 Bay 3 : VK001920GWTTC
    Boot0019* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
    Boot001A  SATA Drive  Box 1 Bay 4 : VK001920GWTTC
    Boot001B* Generic USB Boot
    Boot001C* CRAY UEFI OS 0
    Boot001D* CRAY UEFI OS 1
    Boot001E* Slot 1 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - PXE (PXE IPv4)
    ```

## Reverting changes

**This procedure is only needed if wishing to revert boot order changes.**

Reset the BIOS. Refer to vendor documentation for resetting the BIOS or attempt to reset the BIOS with `ipmitool`

> **NOTE:** When using `ipmitool` against a machine remotely, it requires more arguments:
>
> `read -s` is used to prevent the password from being written to the screen or the shell history.
>
> ```bash
> USERNAME=root
> read -r -s -p "NCN BMC ${USERNAME} password: " IPMI_PASSWORD
> export IPMI_PASSWORD
> ipmitool -I lanplus -U "${USERNAME}" -E -H <bmc-hostname>
> ```

1. (`ncn#` or `pit#`) Reset BIOS with `ipmitool`.

    ```bash
    ipmitool chassis bootdev none options=clear-cmos
    ```

1. (`ncn#` or `pit#`) Set next boot with `ipmitool`.

    ```bash
    ipmitool chassis bootdev pxe options=persistent
    ipmitool chassis bootdev pxe options=efiboot
    ```

1. (`ncn#` or `pit#`) Boot to BIOS for checkout of boot devices.

    ```bash
    ipmitool chassis bootdev bios options=efiboot
    ```

This is the end of the `Reverting changes` procedure.

## Locating USB device

This procedure explains how to identify USB devices on NCNs.

Some nodes very obviously display which device is the USB, whereas other nodes (such as Gigabyte) do not.

Parsing the output of `efibootmgr` can be helpful in determining which device is a USB device. Tools such as `lsblk`, `blkid`, or kernel (`/proc`) may
also be of use. As an example, one can sometimes match up `ls -l /dev/disk/by-partuuid` with `efibootmgr -v`.

1. (`ncn#` or `pit#`) Display the current UEFI boot selections.

    ```bash
    efibootmgr
    ```

    Example output:

    ```text
    BootCurrent: 0015
    Timeout: 1 seconds
    BootOrder: 000E,000D,0011,0012,0007,0005,0006,0008,0009,0000,0001,0002,000A,000B,000C,0003,0004,000F,0010,0013,0014
    Boot0000* Enter Setup
    Boot0001  Boot Device List
    Boot0002  Network Boot
    Boot0003* Launch EFI Shell
    Boot0004* UEFI HTTPv6: Network 00 at Riser 02 Slot 01
    Boot0005* UEFI HTTPv6: Intel Network 00 at Baseboard
    Boot0006* UEFI HTTPv4: Intel Network 00 at Baseboard
    Boot0007* UEFI IPv4: Intel Network 00 at Baseboard
    Boot0008* UEFI IPv6: Intel Network 00 at Baseboard
    Boot0009* UEFI HTTPv6: Intel Network 01 at Baseboard
    Boot000A* UEFI HTTPv4: Intel Network 01 at Baseboard
    Boot000B* UEFI IPv4: Intel Network 01 at Baseboard
    Boot000C* UEFI IPv6: Intel Network 01 at Baseboard
    Boot000D* UEFI HTTPv4: Network 00 at Riser 02 Slot 01
    Boot000E* UEFI IPv4: Network 00 at Riser 02 Slot 01
    Boot000F* UEFI IPv6: Network 00 at Riser 02 Slot 01
    Boot0010* UEFI HTTPv6: Network 01 at Riser 02 Slot 01
    Boot0011* UEFI HTTPv4: Network 01 at Riser 02 Slot 01
    Boot0012* UEFI IPv4: Network 01 at Riser 02 Slot 01
    Boot0013* UEFI IPv6: Network 01 at Riser 02 Slot 01
    Boot0014* UEFI Samsung Flash Drive 1100
    Boot0015* UEFI Samsung Flash Drive 1100
    Boot0018* UEFI SAMSUNG MZ7LH480HAHQ-00005 S45PNA0M838871
    Boot1001* Enter Setup
    ```

1. (`ncn#` or `pit#`) Set next boot entry.

    In the example above, the device is `0014` or `0015`. An option is to guess it is the first one, and can correct this on-the-fly in POST.
    Notice the lack of `Boot` in the ID number given; If wanting to choose `Boot0014` in the output above, pass `0014` to `efibootmgr`:

    ```bash
    efibootmgr -n 0014
    ```

1. (`ncn#` or `pit#`) Verify that the `BootNext` device is what was selected.

    ```bash
    efibootmgr | grep -i bootnext
    ```

    Example output:

    ```text
    BootNext: 0014
    ```

1. Now the UEFI Samsung Flash Drive will boot next.

    > **NOTE:** There are duplicates in the list. During boot, the EFI boot manager will select the first one. If the first one is false, then it can be deleted with
    > `efibootmgr -b 0014 -d`.

This is the end of the `Locating USB device` procedure.

[background/ncn_boot_workflow.md](#determine-the-current-boot-order)

[background/ncn_boot_workflow.md](#setting-boot-order)

[background/ncn_boot_workflow.md](#trimming-boot-order)
