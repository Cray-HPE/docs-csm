# NCN Boot Workflow

Non-compute nodes boot two ways:
- Network/PXE booting
- Disk Booting

## Topics:

* [Determine the Current Boot Order](#determine-the-current-boot-order)
* [Reasons to Change the Boot Order After CSM Install](#reasons-to-change-the-bootorder)
* [Determine if NCNs Booted via Disk or PXE](#determine-if-ncns-booted-via-disk-or-pxe)
* [Set BMCs to DHCP](#set-bmcs-to-dhcp)
* [Boot Order Overview](#set-boot-order)
* [Setting Order](#setting-order)
* [Trimming Boot Order](#trimming_boot_order)
* [Example Boot Orders](#examples)
* [Reverting Changes](#reverting-changes)
* [Locating USB Device](#locating-usb-device)

<a name="determine-the-current-boot-order"></a>
## Determine the Current Boot Order

Under normal operations, the NCNs use the following boot order:

1. PXE (to ensure the NCN is booting with desired images and configuration)
2. Disk (fallback in the event that PXE services are unavailable)

<a name="reasons-to-change-the-bootorder"></a>
## Reasons to Change the Boot Order After CSM Install

After the CSM install is complete, it is usually not necessary to change the boot order. Having PXE first and disk as a fallback works in the majority of situations.

It may be desirable to change the boot order under these circumstances:

* testing disk-backed booting
* booting from a USB or remote ISO
* testing or deploying other customizations

<a name="determine-if-ncns-booted-via-disk-or-pxe"></a>
## Determine if NCNs Booted via Disk or PXE

There are two different methods for determining whether a management node is booted using disk or
PXE. The method to use will vary depending on the system environment.

1. Check kernel parameters.

    ```bash
    ncn# cat /proc/cmdline
    ```

    If it starts with `kernel`, then the node network booted. If it starts with `BOOT_IMAGE=(`, then it disk booted.

1. Check output from `efibootmgr`.

    ```bash
    ncn# efibootmgr
    ```

    The `BootCurrent` value should be matched to the list beneath to see if it lines up with a networking option or a `cray sd*)` option for disk boots.

    ```bash
    ncn# efibootmgr
    BootCurrent: 0016    <---- BootCurrent
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

<a name="set-bmcs-to-dhcp"></a>
## Set BMCs to DHCP

If you are reinstalling a system, the BMCs for the NCNs may be set to static IP addressing. We check `/var/lib/misc/dnsmasq.leases` for setting up the symlinks for the artifacts each node needs to boot. So if your BMCs are set to static, those artifacts will not get set up correctly. You can set them back to DHCP by using a command such as:

```bash
ncn# export USERNAME=root
ncn# export IPMI_PASSWORD=changeme
ncn# for h in $( grep mgmt /etc/hosts | grep -v m001 | awk -F ',' '{print $2}' )
do
ipmitool -U $USERNAME -I lanplus -H $h -E lan set 1 ipsrc dhcp
done
```

Some BMCs need a cold reset in order to pick up this change fully:

```bash
ncn# export USERNAME=root
ncn# export IPMI_PASSWORD=changeme
ncn# for h in $( grep mgmt /etc/hosts | grep -v m001 | awk -F ',' '{print $2}' )
do
ipmitool -U $USERNAME -I lanplus -H $h -E mc reset cold
done
```

<a name="set-boot-order"></a>
## Boot Order Overview

- `ipmitool` can set and edit boot order; it works better for some vendors based on their BMC implementation
- `efibootmgr` speaks directly to the node's UEFI; it can only be ignored by new BIOS activity

> **`NOTE`** Cloud-init will set boot order when it runs, but this does not always work with certain hardware vendors. An administrator can invoke the cloud-init script at `/srv/cray/scripts/metal/set-efi-bbs.sh` on any NCN. Find the script [here, on GitHub](https://github.com/Cray-HPE/node-image-build/blob/lts/csm-1.0/boxes/ncn-common/files/scripts/metal/set-efi-bbs.sh).

<a name="setting-order"></a>
## Setting Order

This section gives the procedure for setting the boot order on NCNs and the PIT node.

Setting the boot order with efibootmgr will ensure that the desired network interfaces and disks are in the proper order for booting.

The commands are the same for all hardware vendors, except where noted.

1. Create a list of the desired IPv4 boot devices.

    Follow the section corresponding to the hardware manufacturer of the system:

    * Gigabyte Technology

        ```bash
        ncn/pit# efibootmgr | grep -iP '(pxe ipv?4.*adapter)' | tee /tmp/bbs1
        ```
        
    * Hewlett-Packard Enterprise

        ```bash
        ncn/pit# efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
        ```

    * Intel Corporation

        ```bash
        ncn/pit# efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
        ```

1. Create a list of the cray disk boot devices.

    ```bash
    ncn/pit# efibootmgr | grep -i cray | tee /tmp/bbs2
    ```
    
1. Set the boot order to first PXE boot, with disk boot as the fallback options.

    ```bash
    ncn/pit# efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
    ```

1. Set all of the desired boot options to be active.

    ```bash
    ncn/pit# cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
    ```

After following the steps above on a given NCN, that NCN will now use the desired Shasta boot order.

This is the end of the Setting Boot Order procedure.

<a name="trimming_boot_order"></a>
## Trimming Boot Order

This section gives the procedure for removing unwanted entries from the boot order on NCNs and the PIT node.

This section will only advise on removing other PXE entries. There are too many
vendor-specific entries beyond disks and NICs to cover in this section (e.g. BIOS entries, iLO entries, etc.).

In this case, the instructions are the same regardless of node type (management, storage, or worker):

1. Make lists of the unwanted boot entries.

    * Gigabyte Technology

        ```bash
        ncn/pit# efibootmgr | grep -ivP '(pxe ipv?4.*)' | grep -iP '(adapter|connection|nvme|sata)' | tee /tmp/rbbs1
        ncn/pit# efibootmgr | grep -iP '(pxe ipv?4.*)' | grep -i connection | tee /tmp/rbbs2
        ```

    * Hewlett-Packard Enterprise
        > **`NOTE`** This does not trim HSN Mellanox cards; these should disable their OpROMs using [the high speed network snippet(s)](../install/switch_pxe_boot_from_onboard_nic_to_pcie.md#high-speed-network).

        ```bash
        ncn/pit# efibootmgr | grep -vi 'pxe ipv4' | grep -i adapter |tee /tmp/rbbs1
        ncn/pit# efibootmgr | grep -iP '(sata|nvme)' | tee /tmp/rbbs2
        ```

    * Intel Corporation

        ```bash
        ncn/pit# efibootmgr | grep -vi 'ipv4' | grep -iP '(sata|nvme|uefi)' | tee /tmp/rbbs1
        ncn/pit# efibootmgr | grep -i baseboard | tee /tmp/rbbs2
        ```

1. Remove them.

    ```bash
    ncn/pit# cat /tmp/rbbs* | awk '!x[$0]++' | sed 's/^Boot//g' | awk '{print $1}' | tr -d '*' | xargs -r -t -i efibootmgr -b {} -B
    ```

Your boot menu should be trimmed down to contain only relevant entries.

This is the end of the Trimming Boot Order procedure.

<a name="examples"></a>
## Example Boot Orders

* Master node (with onboard NICs enabled)

    ```bash
    ncn-m# efibootmgr
    BootCurrent: 0009
    Timeout: 2 seconds
    BootOrder: 0004,0000,0007,0009,000B,000D,0012,0013,0002,0003,0001
    Boot0000* cray (sda1)
    Boot0001* UEFI: Built-in EFI Shell
    Boot0002* UEFI OS
    Boot0003* UEFI OS
    Boot0004* cray (sdb1)
    Boot0007* UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection
    Boot0009* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:34:89:62
    Boot000B* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:34:89:63
    Boot000D* UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection
    Boot0012* UEFI: PNY USB 3.1 FD PMAP
    Boot0013* UEFI: PNY USB 3.1 FD PMAP, Partition 2
    ```

* Storage node (with onboard NICs enabled)

    ```bash
    ncn-s# efibootmgr
    BootNext: 0005
    BootCurrent: 0006
    Timeout: 2 seconds
    BootOrder: 0007,0009,0000,0002
    Boot0000* cray (sda1)
    Boot0001* UEFI: Built-in EFI Shell
    Boot0002* cray (sdb1)
    Boot0005* UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection
    Boot0007* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:34:88:76
    Boot0009* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:34:88:77
    Boot000B* UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection
    ```

* Worker node (with onboard NICs enabled)

    ```bash
    ncn-w# efibootmgr
    BootNext: 0005
    BootCurrent: 0008
    Timeout: 2 seconds
    BootOrder: 0007,0009,000B,0000,0002
    Boot0000* cray (sda1)
    Boot0001* UEFI: Built-in EFI Shell
    Boot0002* cray (sdb1)
    Boot0005* UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection
    Boot0007* UEFI: PXE IP4 Mellanox Network Adapter - 98:03:9B:AA:88:30
    Boot0009* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:34:89:2A
    Boot000B* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:34:89:2B
    Boot000D* UEFI: PXE IP4 Intel(R) I350 Gigabit Network Connection
    ```

<a name="reverting-changes"></a>
## Reverting Changes

**This procedure is only needed if you wish to revert boot order changes.**

Reset the BIOS. Refer to vendor documentation for resetting the BIOS or attempt to reset the BIOS with `ipmitool`

> **`NOTE`** When using `ipmitool` against a machine remotely, it requires more arguments:
> ```bash
> linux# USERNAME=root
> linux# IPMI_PASSWORD=CHANGEME
> linux# ipmitool -I lanplus -U $USERNAME -E -H <bmc-hostname>
> ```

1. Reset BIOS with `ipmitool`

    ```bash
    ncn/pit# ipmitool chassis bootdev none options=clear-cmos
    ```

1. Set next boot with `ipmitool`

    ```bash
    ncn/pit# ipmitool chassis bootdev pxe options=efiboot,persistent
    ```

1. Boot to BIOS for checkout of boot devices

    ```bash
    ncn/pit# ipmitool chassis bootdev bios options=efiboot
    ```

This is the end of the Reverting Changes procedure.

<a name="locating-usb-device"></a>
## Locating USB Device

This procedure explains how to identify USB devices on NCNs.

Some nodes very obviously display which device is the USB, other nodes (such as Gigabyte) do not.

Parsing the output of `efibootmgr` can be helpful in determining which device is your USB device. One can and should use tools such as `lsblk`, `blkid`, or kernel (`/proc`) as well if one knows how. As an example, one can sometimes match up `ls -l /dev/disk/by-partuuid` with `efibootmgr -v`.

1. Display the current UEFI boot selections.

    ```bash
    ncn/pit# efibootmgr
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

 1. Set next boot entry.

    In the example above, our device is `0014` or `0015`. We will guess it is the first one, and can correct this on-the-fly in POST.
    Notice the lack of "Boot" in the ID number given, we want `Boot0014` so we pass `0014` to `efibootmgr`:

    ```bash
    ncn/pit# efibootmgr -n 0014
    ```

1. Verify the `BootNext` device is what you selected:

    ```bash
    ncn/pit# efibootmgr | grep -i bootnext
    BootNext: 0014
    ```

1. Now the UEFI Samsung Flash Drive will boot next.

    > **`Note`** There are duplicates in the list. During boot, the EFI boot manager will select the first one. If you find that the first one is false, false entries can be deleted with `efibootmgr -b 0014 -d`.

This is the end of the Locating USB Device procedure.
