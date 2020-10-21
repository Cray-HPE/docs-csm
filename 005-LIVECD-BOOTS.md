# Booting Into Your LiveCD

You will need to parse the output of `efibootmgr` to determine which device is your USB stick. You can and should use tools such as `lsblk`, `blkid`, or kernel-fu if `efibootmgr` is insufficient. As an example, you can sometimes match up `ls -l /dev/disk/by-partuuid` with `efibootmgr -v`.  Some systems very obviously print out which device is the USB, other systems (like Gigabyte based) do not.

```bash
# Print off the UEFI's boot selections:
ncn-m001:~ # efibootmgr

# Select Boot0002 as the next device (notice the lack of "Boot" in the ID number.
ncn-m001:~ # efibootmgr -n 0002

# Verify the BootNext device is what you selected:
ncn-m001:~ # efibootmgr | grep -i bootnext
BootNext
```

Alternatively, if you cannot find the USB stick in `efibootmgr` you can use ipmitool to set the node to boot into the bios and you can select the USB device from there.

```bash
mypc:~ > ipmitool -I lanplus -U $user -P $password -H ${system}-mgmt chassis bootdev bios 
```

```bash
# Boot up, setup the liveCD (nics/dnsmasq/ipxe)
ncn-m001:~ # reboot                                                       
# Use the Serial-over-LAN to control the system and boot into the USB drive                 
mypc:~ > system=loki-ncn-m001
mypc:~ > ipmitool -I lanplus -U $user -P $password -H ${system}-mgmt sol activate
# Or use the iKVM: https://${system}-mgmt/
```


If you observe the entire boot, you will see an integrity check occur before Linux starts. This can be skipped by hitting OK when it appears. It is very quick.


Once the system boots, you will need to create a **new** password for the root account.  The initial password is empty for the root user.  After you hit return, it will prompt you to change the password.  
We are setting the root password on 1.4 system to `!nitial0` to be consistent.

(for information on _recovery_, see [010-LIVECD-RECOVERY.md](010-LIVECD-RECOVERY.md).

After logging in, have your network information handy so you can populate it in the next steps.  This is the information in qnd-1.4.sh
- IP and netmask for your external connection(s).
- IP and netmask for your bis nodes (MTL, NMN, & HMN IPs)
- Ranges for DHCP (MTL, NMN, CAN, & HMN)
- The CAN IP/CIDR (ex: `can_cidr=10.102.4.110/24`)

Then you can move onto these next two pages:
1. Setting up communication...[006-LIVECD-SETUP.md](006-LIVECD-SETUP.md)
2. Booting NCNs [007-LIVECD-NCN-BOOTS.md](007-LIVECD-NCN-BOOTS.md)
