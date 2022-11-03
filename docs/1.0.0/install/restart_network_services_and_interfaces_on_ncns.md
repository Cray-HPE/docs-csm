# Restart Network Services and Interfaces on NCNs

Interfaces within the network stack can be reloaded or reset to fix wedged interfaces.
The NCNs have network device names set during first boot. The names vary based on the
available hardware. For more information, see [NCN Networking](../background/ncn_networking.md).
Any process covered on this page will be covered by the installer.

The use cases for resetting services:

* Interfaces not showing up
* IP Addresses not applying
* Member/children interfaces not being included

## Topics

* [Restart Network Services and Interfaces](#restart_network_services_and_interfaces))))
* [Command Reference](#command_reference)
  * Check interface status (up/down/broken)
  * Show routing and status for all devices
  * Print real devices (ignore no-device)
  * Show the currently enabled network service (Wicked or Network Manager)

<a name="restart_network_services_and_interfaces"></a>

## Restart Network Services

There are a few daemons that make up the SUSE network stack. The following are
sorted by safest to touch relative to keeping an SSH connection up.

1. `wickedd.service`: The daemons handling each interface. Resetting this clears stale configuration.
    This command restarts the `wickedd` service without reconfiguring the network interfaces.

    ```bash
    ncn# systemctl restart wickedd
    ```

2. `wicked.service`: The overarching service for spawning daemons and manipulating interface configuration.
    Resetting this reloads daemons and configuration.
    This command restarts the `wicked` service which will respawns daemons and reconfigure the network.

    ```bash
    ncn# systemctl restart wicked
    ```

3. `network.service`: Responsible for network configuration per interface; This does not reload `wicked`.
    This command restarts the network interface configuration, but leaves wicked daemons alone.

    > **NOTE:** Commonly the problem exists within `wicked`. This is a last resort in the event the
    configuration is so bad `wicked` cannot handle it.

    ```bash
    # Restart the network interface configuration, but leaves wicked daemons alone.
    ncn# systemctl restart network
    ```

<a name="command_reference"></a>

## Command Reference

* Check interface status (up/down/broken)

   ```bash
   ncn# wicked ifstatus
   ```

* Show routing and status for all devices

   ```bash
   ncn# wicked ifstatus --verbose all
   lo              up
         link:     #1, state up
         type:     loopback
         control:  persistent
         config:   compat:suse:/etc/sysconfig/network/ifcfg-lo,
                   uuid: 6ad37e59-72d7-5988-9675-93b8df96d9f6
         leases:   ipv4 static granted
         leases:   ipv6 static granted
         addr:     ipv4 127.0.0.1/8 scope host label lo [static]
         addr:     ipv6 ::1/128 scope host [static]
         route:    ipv6 ::1/128 type unicast table main scope universe protocol kernel priority 256

   em1             device-unconfigured
         link:     #2, state down, mtu 1500
         type:     ethernet, hwaddr a4:bf:01:48:1f:dc
         config:   none

   em2             device-unconfigured
         link:     #3, state down, mtu 1500
         type:     ethernet, hwaddr a4:bf:01:48:1f:dd
         config:   none

   mgmt0           enslaved
         link:     #4, state up, mtu 9000, master bond0
         type:     ethernet, hwaddr b8:59:9f:f9:1c:8e
         control:  none
         config:   compat:suse:/etc/sysconfig/network/ifcfg-mgmt0,
                   uuid: 7175c041-ee2b-5ce2-a4d7-67fa6cb94a17

   mgmt1           device-unconfigured
         link:     #5, state up, mtu 9000, master bond0
         type:     ethernet, hwaddr b8:59:9f:f9:1c:8e
         config:   none

   bond0           device-unconfigured
         link:     #6, state up, mtu 9000
         type:     bond, mode ieee802-3ad, hwaddr b8:59:9f:f9:1c:8e
         config:   none
         addr:     ipv6 fe80::ba59:9fff:fef9:1c8e/64 scope link
         route:    ipv6 fe80::/64 type unicast table main scope universe protocol kernel priority 256

   vlan002         device-unconfigured
         link:     #7, state up, mtu 9000
         type:     vlan bond0[2], hwaddr b8:59:9f:f9:1c:8e
         config:   none
         addr:     ipv4 10.252.2.2/17 brd 10.252.2.2 scope universe label vlan002
         addr:     ipv6 fe80::ba59:9fff:fef9:1c8e/64 scope link
         route:    ipv4 0.0.0.0/0 via 10.252.1.1 dev vlan002 type unicast table main scope universe protocol boot
         route:    ipv4 10.252.0.0/17 type unicast table main scope link protocol kernel pref-src 10.252.2.2
         route:    ipv6 fe80::/64 type unicast table main scope universe protocol kernel priority 256

   vlan004         device-unconfigured
         link:     #8, state up, mtu 9000
         type:     vlan bond0[4], hwaddr b8:59:9f:f9:1c:8e
         config:   none
         addr:     ipv4 10.254.2.2/17 brd 10.254.2.2 scope universe label vlan004
         addr:     ipv6 fe80::ba59:9fff:fef9:1c8e/64 scope link
         route:    ipv4 10.254.0.0/17 type unicast table main scope link protocol kernel pref-src 10.254.2.2
         route:    ipv6 fe80::/64 type unicast table main scope universe protocol kernel priority 256

   vlan007         device-unconfigured
         link:     #9, state up, mtu 9000
         type:     vlan bond0[7], hwaddr b8:59:9f:f9:1c:8e
         config:   none
         addr:     ipv4 10.102.9.12/24 brd 10.102.9.12 scope universe label vlan007
         addr:     ipv6 fe80::ba59:9fff:fef9:1c8e/64 scope link
         route:    ipv4 10.102.9.0/24 type unicast table main scope link protocol kernel pref-src 10.102.9.12
         route:    ipv6 fe80::/64 type unicast table main scope universe protocol kernel priority 256

   eth0            no-device
   ```

* Print real devices (ignore no-device)

   ```bash
   ncn# wicked show --verbose all
   ```

* Show the currently enabled network service (Wicked or Network Manager)

   ```bash
   ncn# systemctl show -p Id network.service
   Id=wicked.service
   ```
