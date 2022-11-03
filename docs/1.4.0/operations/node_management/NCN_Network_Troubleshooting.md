# NCN Network Troubleshooting

Interfaces within the network stack can be reloaded or reset to fix wedged interfaces.
The NCNs have network device names set during first boot. The names vary based on the
available hardware. For more information, see [NCN Networking](../../background/ncn_networking.md).
Any process covered on this page will be covered by the installer.

The use cases for resetting services:

* Interfaces not showing up
* IP Addresses not applying
* Member/children interfaces not being included

## Topics

* [Restart Network Services and Interfaces](#restart-network-services-and-interfaces)
* [Command Reference](#command-reference)
  * Check interface status (up/down/broken)
  * Show routing and status for all devices
  * Print real devices ( ignore no-device )
  * Show the currently enabled network service (Wicked or Network Manager)

## Restart Network Services and Interfaces

There are a few daemons that make up the SUSE network stack. The following are
sorted by safest to touch relative to keeping an SSH connection up.

1. `wickedd.service`: The daemons handling each interface. Resetting this clears stale configuration.
    This command restarts the `wickedd` service without reconfiguring the network interfaces.

    ```bash
    systemctl restart wickedd
    ```

2. `wicked.service`: The overarching service for spawning daemons and manipulating interface configuration.
    Resetting this reloads daemons and configuration.
    This command restarts the `wicked` service which will respawns daemons and reconfigure the network.

    ```bash
    systemctl restart wicked
    ```

3. `network.service`: Responsible for network configuration per interface; This does not reload `wicked`.
    This command restarts the network interface configuration, but leaves wicked daemons alone.

    > **`NOTE`** Commonly the problem exists within `wicked`. This is a last resort in the event the
    configuration is so bad `wicked` cannot handle it.

    ```bash
    # Restart the network interface configuration, but leaves wicked daemons alone.
    systemctl restart network
    ```

## Command Reference

* (`ncn#` or `pit#`) Check interface status (up/down/broken):

   ```bash
   wicked ifstatus
   ```

* (`ncn#` or `pit#`) Show routing and status for all devices:

   ```bash
   wicked ifstatus --verbose all
   ```

   This will output similar information to the below example:

   ```text
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

   bond0.nmn0      device-unconfigured
         link:     #7, state up, mtu 9000
         type:     vlan bond0[2], hwaddr b8:59:9f:f9:1c:8e
         config:   none
         addr:     ipv4 10.252.2.2/17 brd 10.252.2.2 scope universe label bond0.nmn0
         addr:     ipv6 fe80::ba59:9fff:fef9:1c8e/64 scope link
         route:    ipv4 0.0.0.0/0 via 10.252.1.1 dev bond0.nmn0 type unicast table main scope universe protocol boot
         route:    ipv4 10.252.0.0/17 type unicast table main scope link protocol kernel pref-src 10.252.2.2
         route:    ipv6 fe80::/64 type unicast table main scope universe protocol kernel priority 256

   bond0.hmn0      device-unconfigured
         link:     #8, state up, mtu 9000
         type:     vlan bond0[4], hwaddr b8:59:9f:f9:1c:8e
         config:   none
         addr:     ipv4 10.254.2.2/17 brd 10.254.2.2 scope universe label bond0.hmn0
         addr:     ipv6 fe80::ba59:9fff:fef9:1c8e/64 scope link
         route:    ipv4 10.254.0.0/17 type unicast table main scope link protocol kernel pref-src 10.254.2.2
         route:    ipv6 fe80::/64 type unicast table main scope universe protocol kernel priority 256

   bond0.can0      device-unconfigured
         link:     #9, state up, mtu 9000
         type:     vlan bond0[7], hwaddr b8:59:9f:f9:1c:8e
         config:   none
         addr:     ipv4 10.102.9.12/24 brd 10.102.9.12 scope universe label bond0.can0
         addr:     ipv6 fe80::ba59:9fff:fef9:1c8e/64 scope link
         route:    ipv4 10.102.9.0/24 type unicast table main scope link protocol kernel pref-src 10.102.9.12
         route:    ipv6 fe80::/64 type unicast table main scope universe protocol kernel priority 256

   ```

* (`ncn#` or `pit#`) Print real devices (ignore no-device):

    ```bash
    wicked show --verbose all
    ```

* (`ncn#` or `pit#`) Show the currently enabled network service (Wicked or Network Manager):

    ```bash
    systemctl show -p Id network.service
    ```

    This will output the current network service:

    ```text
    Id=wicked.service
    ```
