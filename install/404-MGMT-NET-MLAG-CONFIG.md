# Management Network MLAG Configuration

This page describes how to setup a bonded configuration from the Non-Compute nodes (NCN) to the management network.

# Requirements

- Console Access to the switches participating in MLAG configuration.
- Two switches running the same firmware version.
- Three cables connected between the switches, two for the Inter Switch Link (ISL) and one for the Keepalive.

# Aruba Configuration

Create the keepalive vrf on both switches.
The following configuration will need to be done on both switches participating in VSX/MLAG, if there is a unique configuration 
it will be called out.

```
sw-24g04(config)# vrf keepalive
```

Create the ISL lag on both switches.

```
sw-24g04(config)# interface lag 99
sw-24g04(config-lag-if)# no shutdown 
sw-24g04(config-lag-if)# description ISL link
sw-24g04(config-lag-if)# no routing
sw-24g04(config-lag-if)# vlan trunk native 1 tag
sw-24g04(config-lag-if)# vlan trunk allowed all
sw-24g04(config-lag-if)# lacp mode active
```

Setup the keepalive link.
This will require a unique IP on both switches.

```
sw-24g04(config)# int 1/1/3
sw-24g04(config-if)# no shutdown 
sw-24g04(config-if)# mtu 9198
sw-24g04(config-if)# vrf attach keepalive   
sw-24g04(config-if)# description keepalive
sw-24g04(config-if)# ip address 192.168.255.0/31

sw-24g03(config)# int 1/1/3
sw-24g03(config-if)# no shutdown
sw-24g03(config-if)# mtu 9198
sw-24g03(config-if)# vrf attach keepalive
sw-24g03(config-if)# description keepalive
sw-24g03(config-if)# ip address 192.168.255.1/31
```

Add the ISL ports to the LAG, these are two of the ports connected between the switches.

```
sw-24g04(config)# int 1/1/1-1/1/2
sw-24g04(config-if-<1/1/1-1/1/2>)# no shutdown
sw-24g04(config-if-<1/1/1-1/1/2>)# mtu 9198
sw-24g04(config-if-<1/1/1-1/1/2>)# lag 99
```

Create the VSX instance and setup the keepalive link.

```
sw-24g03(config)# vsx
sw-24g03(config-vsx)# system-mac 02:01:00:00:01:00
sw-24g03(config-vsx)# inter-switch-link lag 99
sw-24g03(config-vsx)# role primary
sw-24g03(config-vsx)# keepalive peer 192.168.255.0 source 192.168.255.1 vrf keepalive
sw-24g03(config-vsx)# linkup-delay-timer 600
sw-24g03(config-vsx)# vsx-sync vsx-global

sw-24g04(config)# vsx
sw-24g04(config-vsx)# system-mac 02:01:00:00:01:00
sw-24g04(config-vsx)# inter-switch-link lag 99
sw-24g04(config-vsx)# role secondary
sw-24g04(config-vsx)# keepalive peer 192.168.255.1 source 192.168.255.0 vrf keepalive
sw-24g04(config-vsx)# linkup-delay-timer 600
sw-24g04(config-vsx)# vsx-sync vsx-global

```
At this point you should have an Established VSX session
```
sw-24g04(config-if-vlan)# show vsx brief 
ISL State                              : In-Sync
Device State                           : Sync-Primary
Keepalive State                        : Keepalive-Established
Device Role                            : secondary
Number of Multi-chassis LAG interfaces : 0
```

Create and setup high availability VLAN interfaces
This should be done for all VLANS
VLANs in the 2xxx and 3xxx range will be for CDU switches only
**Cray Site Init (CSI) generates the IPs used by the system, below are samples only.**

| VLAN | Switch1 IP | Switch2 IP	| Active Gateway |
| --- | --- | ---| --- | --- | --- | --- |
| 2 | 10.252.0.2/17| 10.252.0.3/17 | 10.252.0.1 |
| 4 | 10.254.0.2/17| 10.254.0.3/17 | 10.254.0.1 |
| 7 | TBD| TBD | TBD |
| 10 | 10.11.0.2/17| 10.11.0.3/17 | 10.11.0.1 |
| 2000 | 10.100.0.2/22| 10.100.0.3/22 | 10.100.0.1/22 | 
| 3000 | 10.104.0.2/22| 10.104.0.3/22 | 10.104.0.1/22 | 

```
sw-24g04(config)# vlan 2
sw-24g04(config-vlan-2)# interface vlan 2
sw-24g04(config-if-vlan)# vsx-sync active-gateways 
sw-24g04(config-if-vlan)# ip mtu 9198
sw-24g04(config-if-vlan)# ip address 10.252.0.3/17
sw-24g04(config-if-vlan)# active-gateway ip mac 12:01:00:00:01:00
sw-24g04(config-if-vlan)# active-gateway ip 10.252.0.1

sw-24g03(config)# vlan 2
sw-24g03(config-vlan-2)# interface vlan 2
sw-24g03(config-if-vlan)# vsx-sync active-gateways 
sw-24g03(config-if-vlan)# ip mtu 9198
sw-24g03(config-if-vlan)# ip address 10.252.0.2/17
sw-24g03(config-if-vlan)# active-gateway ip mac 12:01:00:00:01:00
sw-24g03(config-if-vlan)# active-gateway ip 10.252.0.1
```

Configure bonds on ports connecting to the NCNs, this information can be found on the SHCD.
```
sw-24g04(config)# interface lag 1 multi-chassis
sw-24g04(config-lag-if)#  no shutdown
sw-24g04(config-lag-if)#  no routing
sw-24g04(config-lag-if)#  vlan trunk native 1
sw-24g04(config-lag-if)#  vlan trunk allowed 1-2,4,7,10
sw-24g04(config-lag-if)#  lacp mode active
sw-24g04(config-lag-if)#  lacp fallback

sw-24g04(config)# interface 1/1/1
sw-24g04(config)# no shutdown
sw-24g04(config)# mtu 9198
sw-24g04(config)# lag 1
```

