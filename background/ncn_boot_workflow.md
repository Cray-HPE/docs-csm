# NCN Boot Workflow

Non-compute nodes boot two ways:
- Network/PXE booting
- Disk Booting

### Topics:

* [Determine if NCNs booted via disk or PXE](#determine-if-ncns-booted-via-disk-or-pxe)
* [Set BMCs to DHCP](#set-bmcs-to-dhcp)
* [Set Boot Order](#set-boot-order)
   * [Setting Order](#setting-order)
   * [Trimming Boot Order](#trimming_boot_order)
   * [Examples](#examples)
   * [Reverting Changes](#reverting-changes)
   * [Locating USB Device](#locating-usb-device)

## Details

<a name="determine-if-ncns-booted-via-disk-or-pxe"></a>
### Determine if NCNs booted via disk or PXE

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

   The `BootCurrent` value should be matched to the list beneath it to see if it lines up with a networking option or a `cray sd*)` option for disk boots.

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
### Set BMCs to DHCP

If you are reinstalling a system, the BMCs for the NCNs may be set to static. We check `/var/lib/misc/dnsmasq.leases` for setting up the symlinks for the artifacts each node needs to boot. So if your BMCs are set to static, those artifacts will not get setup correctly. You can set them back to DHCP by using a command such as:

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
### Set Boot Order

- `ipmitool` can set and edit boot order; works better for some vendors based on their BMC implementation
- `efibootmgr` speaks directly to the node's UEFI; can only be ignored by new BIOS activity

> **`NOTE`** Cloud-init will set bootorder on boot, but this is bugged (CASMINST-1686) with certain vendors.

<a name="setting-order"></a>
#### Setting Order

Setting the boot order with efibootmgr will ensure that the desired network interfaces and disks are in the proper order for booting. The commands and output vary by the vendor and the function of the node.

> **`NOTE`** The four digit hex numbers shown in the examples below may be different, even between nodes of the same function and vendor. The first two efibootmgr commands will display the correct hex numbers for the third efibootmgr command to use in setting the proper boot order.

Follow the section corresponding to the hardware manufacturer of the system:

   > <a name="gigabyte-technology"></a>
   > #### Gigabyte Technology
   >
   > ##### Masters
   >
   > ```bash
   > ncn-m# efibootmgr | grep -iP '(pxe ipv?4.*adapter)' | tee /tmp/bbs1
   > Boot0007* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:BE:8F:2E
   > Boot0009* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:BE:8F:2F
   > ncn-m# efibootmgr | grep cray | tee /tmp/bbs2
   > Boot0000* cray (sda1)
   > Boot0002* cray (sdb1)
   > ncn-m# efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
   > BootOrder: 0007,0009,0000,0002
   > ncn-m# cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
   > ```
   >
   > ##### Storage
   >
   > ```bash
   > ncn-s# efibootmgr | grep -iP '(pxe ipv?4.*adapter)' | tee /tmp/bbs1
   > Boot0007* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:C7:11:FA
   > Boot0009* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:C7:11:FB
   > ncn-s# efibootmgr | grep cray | tee /tmp/bbs2
   > Boot0000* cray (sda1)
   > Boot0002* cray (sdb1)
   > ncn-s# efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
   > BootOrder: 0007,0009,0000,0002
   > ncn-s# cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
   > ```
   >
   > ##### Workers
   >
   > > **`NOTE`** If more than 3 interfaces appear in `/tmp/bbs1` the administrator may want to consider
   > > disabling PXE on their HSN cards. On the other hand, the rogue boot entry can be removed with a hand crafted `efibootmgr -b <num> -B` command.
   >
   > ```bash
   > ncn-w# efibootmgr | grep -iP '(pxe ipv?4.*adapter)' | tee /tmp/bbs1
   > Boot0007* UEFI: PXE IP4 Mellanox Network Adapter - 98:03:9B:AA:88:30
   > Boot0009* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:34:89:2A
   > Boot000B* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:34:89:2B
   > ncn-w# efibootmgr | grep cray | tee /tmp/bbs2
   > Boot0000* cray (sda1)
   > Boot0002* cray (sdb1)
   > ncn-w# efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
   > BootOrder: 0009,0007,000B,0000,0002
   > ncn-w# cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
   > ```
   >
   > <a name="hewlett-packard-enterprise"></a>
   > #### Hewlett-Packard Enterprise
   >
   >
   > ##### Masters
   >
   > ```bash
   > ncn-m# efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
   > Boot0014* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
   > Boot0018* Slot 1 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - PXE (PXE IPv4)
   > ncn-m# efibootmgr | grep cray | tee /tmp/bbs2
   > Boot0021* cray (sdb1)
   > Boot0022* cray (sdc1)
   > ncn-m# efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
   > BootOrder: 0014,0018,0021,0022
   > ncn-m# cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
   > ```
   >
   > ##### Storage
   >
   > ```bash
   > ncn-s# efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
   > Boot001C* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
   > Boot001D* Slot 1 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - PXE (PXE IPv4)
   > ncn-s# efibootmgr | grep cray | tee /tmp/bbs2
   > Boot0002* cray (sdg1)
   > Boot0020* cray (sdh1)
   > ncn-s# efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
   > BootOrder: 001C,001D,0002,0020
   > ncn-s# cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
   > ```
   >
   > ##### Workers
   >
   > ```bash
   > ncn-w# efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
   > Boot0012* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
   > ncn-w#
   > ncn-w# efibootmgr | grep cray | tee /tmp/bbs2
   > Boot0017* cray (sdb1)
   > Boot0018* cray (sdc1)
   > ncn-w# efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
   > BootOrder: 0012,0017,0018
   > ncn-w# cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
   > ```
   >
   > <a name="intel-corporation"></a>
   > #### Intel Corporation
   >
   > ##### Masters
   > ```bash
   > ncn-m# efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
   > Boot000E* UEFI IPv4: Network 00 at Riser 02 Slot 01
   > Boot0014* UEFI IPv4: Network 01 at Riser 02 Slot 01
   > ncn-m# efibootmgr | grep -i 'cray' | tee /tmp/bbs2
   > Boot0011* cray (sda1)
   > Boot0012* cray (sdb1)
   > ncn-m# efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
   > BootOrder: 000E,0014,0011,0012
   > ncn-m# cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
   >```
   > ##### Storage
   > ```bash
   > ncn-s# efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
   > Boot000E* UEFI IPv4: Network 00 at Riser 02 Slot 01
   > Boot0012* UEFI IPv4: Network 01 at Riser 02 Slot 01
   > ncn-s# efibootmgr | grep -i 'cray' | tee /tmp/bbs2
   > Boot0014* cray (sda1)
   > Boot0015* cray (sdb1)
   > ncn-s# efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
   > BootOrder: 000E,0012,0014,0015
   > ncn-s# cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
   > ```
   > ##### Workers
   >
   > ```bash
   > ncn-w# efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
   > Boot0008* UEFI IPv4: Network 00 at Riser 02 Slot 01
   > Boot000C* UEFI IPv4: Network 01 at Riser 02 Slot 01
   > ncn-w# efibootmgr | grep -i 'cray' | tee /tmp/bbs2
   > Boot0010* cray (sda1)
   > Boot0011* cray (sdb1)
   > ncn-w# efibootmgr -o $(cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | tr -t '\n' ',' | sed 's/,$//') | grep -i bootorder
   > BootOrder: 0008,000C,0010,0011
   > ncn-w# cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -t -i efibootmgr -b {} -a
   > ```

After following the steps above on a given NCN, that NCN will now use the desired Shasta boot order.

<a name="trimming_boot_order"></a>
#### Trimming Boot Order

As for removing entries, this section will only advise on removing other PXE entries. There are too many
vendor-specific entries beyond disks and NICs to cover in this section (e.g. BIOS entries, iLO entries, etc.).

Simply run the reverse-pattern of the PXE commands from the [setting boot order](#setting-order) section:

1. Find the other PXE entries:
   - Gigabyte Technology:

      ```bash
      ncn# efibootmgr | grep -ivP '(pxe ipv?4.*)' | grep -iP '(adapter|connection|nvme|sata)' | tee /tmp/rbbs1
      ncn# efibootmgr | grep -iP '(pxe ipv?4.*)' | grep -i connection | tee /tmp/rbbs2
      ```
   - Hewlett-Packard Enterprise
      > **`NOTE`** This does not trim HSN Mellanox cards; these should disable their OpROMs using [the high speed network snippet(s)](../install/switch_pxe_boot_from_onboard_nic_to_pcie.md#high-speed-network).

      ```bash
      ncn# efibootmgr | grep -vi 'pxe ipv4' | grep -i adapter |tee /tmp/rbbs1
      ncn# efibootmgr | grep -iP '(sata|nvme)' | tee /tmp/rbbs2
      ```
   - Intel Corporation

      ```bash
      ncn# efibootmgr | grep -vi 'ipv4' | grep -iP '(sata|nvme|uefi)' | tee /tmp/rbbs1
      ncn# efibootmgr | grep -i baseboard | tee /tmp/rbbs2
       ```

2. Remove them:

   ```bash
   ncn# cat /tmp/rbbs* | awk '!x[$0]++' | sed 's/^Boot//g' | awk '{print $1}' | tr -d '*' | xargs -r -t -i efibootmgr -b {} -B
   ```

Your boot menu should be trimmed down to contain only relevant entries.

<a name="examples"></a>
###### Examples

Master node (with onboard NICs enabled):

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

Storage node (with onboard NICs enabled):

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

Worker node (with onboard NICs enabled):

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
#### Reverting Changes

Reset the BIOS. Refer to vendor documentation for resetting the BIOS or attempt to reset the BIOS with `ipmitool`

> **`NOTE`** When using `ipmitool` against a machine remotely, it requires more arguments:
> ```bash
> linux# USERNAME=root
> linux# IPMI_PASSWORD=CHANGEME
> linux# ipmitool -I lanplus -U $USERNAME -E -H <bmc-hostname>
> ```

1. Reset BIOS with ipmitool

   ```bash
   ncn# ipmitool chassis bootdev none options=clear-cmos
   ```

1. Set next boot with ipmitool

   ```bash
   ncn# ipmitool chassis bootdev pxe options=efiboot,persistent
   ```

1. Boot to BIOS for checkout of boot devices

   ```bash
   ncn# ipmitool chassis bootdev bios options=efiboot
   ```

<a name="locating-usb-device"></a>
#### Locating USB Device

Some nodes very obviously display which device is the USB, other nodes (such as Gigabyte) do not.

Parsing the output of `efibootmgr` can be helpful in determining which device is your USB device. One can and should use tools such as `lsblk`, `blkid`, or kernel (`/proc`) as well if one knows how. As an example, one can sometimes match up `ls -l /dev/disk/by-partuuid` with `efibootmgr -v`.

   1. Display the current UEFI boot selections.

      ```bash
      ncn-m# efibootmgr
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

      In the example above, our device is 0014 or 0015. We will guess it is the first one, and can correct this on-the-fly in POST.
      Notice the lack of "Boot" in the ID number given, we want Boot0014 so we pass '0014' to efibootmgr:

      ```bash
      ncn-m# efibootmgr -n 0014
      ```
   1. Verify the BootNext device is what you selected:

      ```bash
      ncn-m# efibootmgr | grep -i bootnext
      BootNext: 0014
      ```
   1. Now the UEFI Samsung Flash Drive will boot next.

      > **`Note`** there are duplicates in the list. During boot, the EFI boot manager will select the first one. If you find that the first one is false, false entries can be deleted with `efibootmgr -b 0014 -d`.
