# Configuration of NCN Bonding

Non-compute nodes \(NCNs\) have network interface controllers \(NICs\) connected to the management network that are configured in a redundant manner via Link Aggregation Control Protocol \(LACP\) link aggregation. The link aggregation configuration can be modified by editing and applying various configuration files either through Ansible or the interfaces directly.

The bond configuration exists across three files on an NCN. These files may vary depending on the NCN in use:

-   **`ifcfg-bond0`**

    Physical configuration and member interfaces.

-   **`ifroute-bond0`**

    Routing, which is critical for NCN PXE to work.

-   **`ifrule-bond0`**

    Routing table selecting, which is critical for NCN PXE to work.


The following is an example of `ifcfg-bond0`:

```bash
ncn-w001# cat /etc/sysconfig/network/ifcfg-bond0
BONDING_MASTER='yes'
BONDING_MODULE_OPTS='mode=802.3ad miimon=100 lacp_rate=fast xmit_hash_policy=layer2+3'
BONDING_SLAVE0='p1p1'
BONDING_SLAVE1='p1p2'
MTU='9238'
STARTMODE='auto'
BOOTPROTO='static'
PREFIXLEN='16'
IPADDR='10.1.1.1/16'
ZONE='Do not assign ZONE'
```

The bond is configured with modules that can be changed at the network administrators discretion and coordination.

It may be useful to only adjust the XMIT value to `layer2`; the current setting is chosen as a default to match existing settings for compute nodes from the previous release. This can be weighed out if problems arise across the NCNs over the bond and dual-spine or Multi-Chassis Link Aggregation \(MLAG\).

### Wicked NetworkManager

Wicked is the SUSE NetworkManager and Daemon wrapper for handling interfaces' processes and applying their configuration. See the [SUSE Wicked](https://documentation.suse.com/external-tree/en-us/sles/12-SP4/networking_with_wicked_in_suse_linux_enterprise_12_guide.pdf) external documentation for more information.

For administrators familiar with the more common Linux distribution, Ubuntu, it has an analogue to Wicked called NetPlan. The benefit is that it removes tedious, low-level configurations. However, Wicked and NetPlan each have their own web of configuration. The examples below are useful ways Wicked can be used to debug and triage interfaces.

To view a system wide interface network configuration:

```bash
ncn-w001# wicked ifstatus all
```

Use the following command to view information about a specific interface. In this example, vlan007 is used.

```bash
ncn-w001# wicked ifstatus --verbose vlan007
vlan007         up
      link:     #4603, state up, mtu 1500
      type:     vlan bond0[7], hwaddr b8:59:9f:c7:11:12
      control:  none
      config:   compat:suse:/etc/sysconfig/network/ifcfg-vlan007,
                uuid: 5cce4d33-8d99-50a2-b6c0-b4b3d101c557
      leases:   ipv4 static granted
      addr:     ipv6 fe80::ba59:9fff:fec7:1112/64 scope link
      addr:     ipv4 10.102.3.4/24 brd 10.102.3.4 scope universe label vlan007 [static]
      route:    ipv4 0.0.0.0/0 via 10.102.3.20 dev vlan007 type unicast table 3 scope universe protocol boot
      route:    ipv4 10.102.3.0/24 type unicast table main scope link protocol kernel pref-src 10.102.3.4
      route:    ipv6 fe80::/64 type unicast table main scope universe protocol kernel priority 256
```

To view information about the bond:

```bash
ncn-w001# wicked ifstatus bond0
bond0           device-not-running
      link:     #9, state up, mtu 9238
      type:     bond, mode ieee802-3ad, hwaddr b8:59:9f:4a:f6:30
      config:   compat:suse:/etc/sysconfig/network/ifcfg-bond0
      leases:   ipv4 static failed
```

