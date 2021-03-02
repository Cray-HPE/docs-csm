# EFI Boot MGR

### Locating a USB Stick

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
