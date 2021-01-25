# LiveCD USB Booting

You will need to parse the output of `efibootmgr` to determine which device is your USB stick. You can and should use tools such as `lsblk`, `blkid`, or kernel-fu if `efibootmgr` is insufficient. As an example, you can sometimes match up `ls -l /dev/disk/by-partuuid` with `efibootmgr -v`.  Some systems very obviously print out which device is the USB, other systems (like Gigabyte based) do not.

```bash
# Print off the UEFI's boot selections:
ncn-m001:~ # efibootmgr
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




# In the example above, our device is 0014 or 0015. We'll guess its the first one, and can correct this on-the-fly in POST
# Notice the lack of "Boot" in the ID number given, we want Boot0014 so we pass '0014' to efibootmgr:
ncn-m001:~ # efibootmgr -n 0014

# Verify the BootNext device is what you selected:
ncn-m001:~ # efibootmgr | grep -i bootnext
BootNext: 0014
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

Once the system boots, you will need to create a **new** password for the root account.  

**The initial password is empty for the root user.**

After you hit return, it will prompt you to change the password.  
We are setting the root password on 1.4 system to `!nitial0` to be consistent.

```
macbook:~$ ipmitool -I lanplus -U $user -P $password -H ${system}-mgmt sol activate
[SOL Session operational.  Use ~? for help]

pit login: root
Password:           <-------just press Enter here for a blank password
You are required to change your password immediately (administrator enforced)
Changing password for root.
Current password:   <------- press Enter here, again, for a blank password
New password:       <------- type new password
Retype new password:<------- retype new password
Welcome to the CRAY Prenstall Toolkit (LiveOS)

Offline CSM documentation can be found at /usr/share/doc/metal (version: rpm -q docs-csm-install)
```

(for information on _recovery_, see [LiveCD Troubleshooting](020-LIVECD-TROUBLESHOOTING.md)

After logging in, have your network information handy so you can populate it in the next steps.
- IP and netmask for your external connection(s).
- The CAN IP/CIDR (ex: `10.102.4.110/24`)


Once booted, your system will come up with all the interfaces configured:

```
[  OK  ] Started Permit User Sessions.
[  OK  ] Started Serial Getty on ttyS0.
[  OK  ] Started DNS caching server..
[  OK  ] Reached target Host and Network Name Lookups.
         Starting NTP client/server...
[  OK  ] Started NTP client/server.
[  OK  ] Reached target System Time Synchronized.
[  OK  ] Started Daily rotation of log files.
[  OK  ] Started Discard unused blocks once a week.
[  OK  ] Reached target Timers.
         Starting The Apache Webserver...
[  OK  ] Started OpenSSH Daemon.
[  OK  ] Started The Apache Webserver.
[  OK  ] Started Getty on tty1.
[  OK  ] Reached target Login Prompts.
[  OK  ] Reached target Multi-User System.
         Starting Update UTMP about System Runlevel Changes...
         Starting Tell blogd to Quit...
[  OK  ] Started Update UTMP about System Runlevel Changes.
[  OK  ] Started Tell blogd to Quit.

pit login: root
Password:
You are required to change your password immediately (administrator enforced)
Changing password for root.
Current password:
New password:
Retype new password:
Welcome to the CRAY Prenstall Toolkit (LiveOS)

Offline CSM documentation can be found at /usr/share/doc/metal (version: rpm -q docs-csm-install)
pit:~ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: em1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq master lan0 state UP group default qlen 1000
    link/ether b4:2e:99:3a:26:08 brd ff:ff:ff:ff:ff:ff
3: em2: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether b4:2e:99:3a:26:09 brd ff:ff:ff:ff:ff:ff
4: p1p1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master bond0 state UP group default qlen 1000
    link/ether b8:59:9f:c7:12:f2 brd ff:ff:ff:ff:ff:ff
5: p1p2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master bond0 state UP group default qlen 1000
    link/ether b8:59:9f:c7:12:f2 brd ff:ff:ff:ff:ff:ff
6: lan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether b4:2e:99:3a:26:08 brd ff:ff:ff:ff:ff:ff
    inet 172.30.52.183/20 brd 172.30.63.255 scope global lan0
       valid_lft forever preferred_lft forever
    inet6 fe80::b62e:99ff:fe3a:2608/64 scope link
       valid_lft forever preferred_lft forever
7: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether b8:59:9f:c7:12:f2 brd ff:ff:ff:ff:ff:ff
    inet 10.1.1.2/16 brd 10.1.255.255 scope global bond0
       valid_lft forever preferred_lft forever
    inet6 fe80::ba59:9fff:fec7:12f2/64 scope link
       valid_lft forever preferred_lft forever
8: vlan004@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether b8:59:9f:c7:12:f2 brd ff:ff:ff:ff:ff:ff
    inet 10.254.1.8/16 brd 10.254.255.255 scope global vlan004
       valid_lft forever preferred_lft forever
    inet6 fe80::ba59:9fff:fec7:12f2/64 scope link
       valid_lft forever preferred_lft forever
9: vlan007@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether b8:59:9f:c7:12:f2 brd ff:ff:ff:ff:ff:ff
    inet 10.102.3.6/26 brd 10.102.3.63 scope global vlan007
       valid_lft forever preferred_lft forever
    inet6 fe80::ba59:9fff:fec7:12f2/64 scope link
       valid_lft forever preferred_lft forever
10: vlan002@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether b8:59:9f:c7:12:f2 brd ff:ff:ff:ff:ff:ff
    inet 10.252.1.7/16 brd 10.252.255.255 scope global vlan002
       valid_lft forever preferred_lft forever
    inet6 fe80::ba59:9fff:fec7:12f2/64 scope link
       valid_lft forever preferred_lft forever
pit:~ #
```

Then you can move onto these next three pages:
1. Configure the [Management Network Switches](401-MANAGEMENT-NETWORK-INSTALL.md)
1. Setting up NCN communication[LiveCD Setup](004-LIVECD-SETUP.md)
1. [Booting NCNs](005-NCN-BOOTS.md)
