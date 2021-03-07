# UEFI :: `efibootmgr` Reference Guide

This page will assist an administrator in using the `efibootmgr` tool.

  * [Boot Order](064-EFIBOOTMGR.md#boot-order)
    * [Setting Order](064-EFIBOOTMGR.md#setting-order)
    * [Triming](064-EFIBOOTMGR.md#trimming)
        * [Examples](064-EFIBOOTMGR.md#examples)
    * [Reverting Changes](064-EFIBOOTMGR.md#reverting-changes)
  * [Locating a USB Stick](064-EFIBOOTMGR.md#locating-a-usb-stick)


<a name="boot-order"></a>
### Boot Order

- `ipmitool` can set and edit boot order; works better on some vendors based on their BMC implementation
- `efibootmgr` speaks directly to systems UEFI; can only be ignored by new BIOS activity

> **`NOTE`** Cloud-init will set bootorder on boot, but this is bugged (CASMINST-1686) with certain vendors.

<a name="setting-order"></a>
#### Setting Order

1. Create our boot-bios-selector file(s) based on the manufacturer:

> ##### Gigabyte Technology
>
>
> ###### Masters
> 
> ```bash
> ncn-m002:~ # efibootmgr | grep -iP '(pxe ipv?4.*adapter)' | tee /tmp/bbs1
> Boot0007* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:BE:8F:2E
> Boot0009* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:BE:8F:2F                
> ncn-m002:~ # efibootmgr | grep cray | tee /tmp/bbs2
> Boot0000* cray (sda1)
> Boot0002* cray (sdb1)
> ```
>
> ###### Storage
> 
> ```bash
> ncn-s001:~ # efibootmgr | grep -iP '(pxe ipv?4.*adapter)' | tee /tmp/bbs1
> Boot0007* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:C7:11:FA
> Boot0009* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:C7:11:FB
> ncn-s001:~ # efibootmgr | grep cray | tee /tmp/bbs2
> Boot0000* cray (sda1)
> Boot0002* cray (sdb1)
> ```
> 
> ###### Workers
> 
> > **`NOTE`** If more than 3 interfaces appear in `/tmp/bbs1` the administrator may want to consider
> > disabling PXE on their HSN cards. On the other hand, the rogue boot entry can be removed with a hand crafted `efibootmgr -b <num> -B` command.
> 
> ```bash
> ncn-w001:~ # efibootmgr | grep -iP '(pxe ipv?4.*adapter)' | tee /tmp/bbs1
> Boot0007* UEFI: PXE IP4 Mellanox Network Adapter - 98:03:9B:AA:88:30
> Boot0009* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:34:89:2A
> Boot000B* UEFI: PXE IP4 Mellanox Network Adapter - B8:59:9F:34:89:2B
> ncn-w001:~ # efibootmgr | grep cray | tee /tmp/bbs2
> Boot0000* cray (sda1)
> Boot0002* cray (sdb1)
> ```
> 
> ##### Hewlett-Packard Enterprise
>
>
> ###### Masters
>
> ```bash
> ncn-m002:~ # efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
> Boot0014* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
> Boot0018* Slot 1 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - PXE (PXE IPv4)
> ncn-m002:~ # efibootmgr | grep cray | tee /tmp/bbs2
> Boot0021* cray (sdb1)
> Boot0022* cray (sdc1)
> ```
>
> ###### Storage
>
> ```bash
> ncn-s002:~ # efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
> Boot001C* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
> Boot001D* Slot 1 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HLCU-HC MD2 Adapter - PXE (PXE IPv4)
> ncn-s002:~ # efibootmgr | grep cray | tee /tmp/bbs2
> Boot0002* cray (sdg1)
> Boot0020* cray (sdh1)
> ```
> 
> ###### Workers
>
> ```bash
> ncn-w001:~ # efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
> Boot0012* OCP Slot 10 Port 1 : Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - NIC - Marvell FastLinQ 41000 Series - 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter - PXE (PXE IPv4)
> ncn-w001:~ #
> ncn-w001:~ # efibootmgr | grep cray | tee /tmp/bbs2\
> ncn-w001:~ # efibootmgr | grep cray | tee /tmp/bbs2
> Boot0017* cray (sdb1)
> Boot0018* cray (sdc1)
> ```
> ##### Intel Corporation
> 
>
> ###### Masters
> ```bash
> ncn-m002:~ # efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
> Boot000E* UEFI IPv4: Network 00 at Riser 02 Slot 01
> Boot0014* UEFI IPv4: Network 01 at Riser 02 Slot 01
> ncn-m002:~ # efibootmgr | grep -i 'cray' | tee /tmp/bbs2
> Boot0011* cray (sda1)
> Boot0012* cray (sdb1)
>```
> 
> ###### Storage
> ```bash
> ncn-s001:~ # efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
> Boot000E* UEFI IPv4: Network 00 at Riser 02 Slot 01
> Boot0012* UEFI IPv4: Network 01 at Riser 02 Slot 01
> ncn-s001:~ # efibootmgr | grep -i 'cray' | tee /tmp/bbs2
> Boot0014* cray (sda1)
> Boot0015* cray (sdb1)
> ```
>
> ###### Workers
> 
> ```bash
> ncn-w001:~ # efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
> Boot0008* UEFI IPv4: Network 00 at Riser 02 Slot 01
> Boot000C* UEFI IPv4: Network 01 at Riser 02 Slot 01
> ncn-w001:~ # efibootmgr | grep -i 'cray' | tee /tmp/bbs2
> Boot0010* cray (sda1)
> Boot0011* cray (sdb1)
> ```


2. Set Order (works universally; every vendor, every Shasta ncn-type):
> ```bash
> ncn-m002:~ # efibootmgr -o $(cat /tmp/bbs* | sed 's/^Boot//g' | awk '{print $1}' | tr -t '*' ',' | tr -d '\n' | sed 's/,$//') | grep -i bootorder
> BootOrder: 000E,0014,0011,0012
> ```

After following the twp-steps on a given NCN, that NCN will now use the desired Shasta boot order.

<a name="trimming"></a>
### Trimming
   
As for removing entries, this section will only advise on removing other PXE entries. There are too many vendor-specific entries beyond
disks and NICs to cover in this section (e.g. BIOS entries, iLO entries, etc.).

Simply run the reverse-pattern of the PXE commands from the [fixing boot order](#fixing-boot-order) section:

1. Find the other PXE entries:
   - Gigabyte Technology:
     > **`NOTE`** This will not remove onboard PXE IPv4 options. 
     ```bash
     ncn# efibootmgr | grep -ivP '(pxe ipv?4.*)' | grep -iP '(adapter|connection)' | tee /tmp/rbbs1
     ```
   - Hewlett-Packard Enterprise
     ```bash
     ncn#  efibootmgr | grep -i 'port 1' | grep -vi 'pxe ipv4' | tee /tmp/rbbs1
     ```
   - Intel Corporation
     ```bash
     ncn#  efibootmgr | grep -vi 'ipv4' | grep -i 'baseboard' | tee /tmp/rbbs1
     ```
2. Remove them:
    ```bash
   ncn# cat /tmp/rbbs* | sed 's/^Boot//g' | awk '{print $1}' | tr -d '*' | xargs -t -i efibootmgr -b {} -B
    ```

Your boot menu should be trimmed down to only contain relevant entries.


<a name="examples"></a>
###### Examples

Master node (with onboards enabled):

```bash
ncn-m001:~ # efibootmgr
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

Storage node (with onboards enabled):

```bash
ncn-s001:~ # efibootmgr
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

Worker node  (with onboards enabled):

```bash
ncn-w001:~ # efibootmgr
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
### Reverting Changes


Reset the BIOS.

Refer to vendor documentation for resetting the BIOS.

Optionally attempt to with `ipmitool`:

```bash
# reset
ipmitool chassis bootdev none options=clear-cmos

# set boot order
ipmitool chassis bootdev pxe options=efiboot,persistent

# boot to bios for checkout
ipmitool chassis bootdev bios options=efiboot
```
> **`NOTE`** `ipmitool` works against a machine remotely over TCP/IP, it requires more arugments:
> ```bash
> username=root
> IPMI_PASSWORD=
> ipmitool -I lanplus -U $username -E -H <bmc-hostname>
> ```

<a name="locating-a-usb-stick"></a>
## Locating a USB Stick

Some systems very obviously print out which device is the USB, other systems (like Gigabyte based) do not.

Parsing the output of `efibootmgr` can be helpful in determining which device is your USB stick. One can and should use tools such as `lsblk`, `blkid`, or kernel (`/proc`) as well if one knows how. As an example, one can sometimes match up `ls -l /dev/disk/by-partuuid` with `efibootmgr -v`.


```bash
# Print off the UEFI's boot selections:
ncn-m001# efibootmgr
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

In the example above, our device is 0014 or 0015. We'll guess its the first one, and can correct this on-the-fly in POST
Notice the lack of "Boot" in the ID number given, we want Boot0014 so we pass '0014' to efibootmgr:

```bash
ncn-m001# efibootmgr -n 0014

# Verify the BootNext device is what you selected:
ncn-m001# efibootmgr | grep -i bootnext
BootNext: 0014
```

Now the UEFI Samsung Flash Drive will boot next.

> **`Note`** there are duplicates in the list. During boot, the boot-manager will select the first one. If you find that the first one is false, false entries can be deleted with `efibootmgr -b 0014 -d`.
