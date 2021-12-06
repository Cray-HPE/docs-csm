# Virtual switching extension (VSX) 

Aruba’s Virtual Switching Extension (VSX) is a solution that integrates two independent ArubaOS-CX switches into an active/active virtualized high availability (HA) solution. The two switch peers utilize a connected link for control and data. This solution allows the switches to present as one virtualized switch in critical areas. Configuration synchronization is one aspect of this VSX solution where the primary switch configuration is synced to the secondary switch. This allows for pseudo-single pane of glass configuration and helps keep key configuration pieces in sync as operational changes are made. Since the solution is primarily for HA, it is expected that the vast majority of configuration policy is the same across both peers. 

Relevant Configuration 

Enable VSX 

```
switch(config)# vsx
```

Give the device a role of primary or secondary 

```
switch(config-vsx)# role <primary|secondary>
```

Configure the VSX keepalive between the two VSX peer switches 

```
switch(config-vsx)# keepalive peer PEER-IP source SRC-IP
```

Select a physical or LAG interface to become the inter-switch-link 

```
switch(config-vsx)# inter-switch-link IFACE
```

Create Multi-Chassis LAG interfaces 

```
switch(config)# interface lag LAG multi-chassis
```

Associate the physical interfaces with the LAG 
```
switch(config-if)# lag LAG
```

Synchronize global configurations 

```
switch(config-vsx)# vsx-sync [aaa] [sflow] [snmp] [static-routes] [time] [copp-policy] [dns]
[mclag-interfaces] [qos-global] [ssh]
Synchronize interface memberships 
switch(config-if)# vsx-sync [access-lists] [policies] [qos] [vlans] [rate-limits]
Synchronize VLAN interface memberships 
switch(config-if-vlan)# vsx-sync [active-gateways] [policies]
Synchronize feature configurations 
switch(config-vlan)# vsx-sync
switch(config-acl-ip)# vsx-sync
switch(config-class-ip)# vsx-sync
switch(config-policy)# vsx-sync
switch(config-pbr-action-list)# vsx-sync
switch(config-schedule)# vsx-sync
switch(config-queue)# vsx-sync
switch(config-portgroup)# vsx-sync
switch(config-addrgroup)# vsx-sync
```

Show commands to validate functionality:  

```
switch# show vsx <brief|configuration|status> [config-sync]
```

Example Output 

```
switch(config)# int 1/1/49
switch(config-if)# description VSX KEEPALIVE LINK
switch(config-if)# no shut
switch(config-if)# ip address 1.1.1.1/30
switch(config-if)# ex
switch(config)# conf
switch(config)# int lag 128
switch(config-lag-if)# description VSX INTER-SWITCH-LINK
switch(config-lag-if)# lacp mode active
switch(config-lag-if)# no shut
switch(config-lag-if)# no routing
switch(config-lag-if)# vlan trunk allowed all
switch(config-lag-if)# exit
switch(config)# int 1/1/50
switch(config-if)# no shut
switch(config-if)# lag 128
switch(config-if)# ex
switch(config)# vsx
switch(config-vsx)# role primary
switch(config-vsx)# keepalive peer 1.1.1.2 source 1.1.1.1
switch(config-vsx)# inter-switch-link lag 128
switch(config-vsx)# exit

switch(config)# show run int 1/1/49

interface 1/1/49
   no shutdown
   ip address 1.1.1.1/30
   exit

switch(config)# show run int lag128

interface lag 128
   description VSX INTER-SWITCH-LINK
   no shutdown
   no routing
   vlan trunk native 1 tag
   vlan trunk allowed all
   lacp mode active
   exit

switch(config)# show vsx status

VSX Operational State
---------------------
Platform
Software Version
Device Role
X86-64              X86-64
Virtual.10.01.0001G Virtual.10.01.0001G
primary             secondary
switch(config-if)# int lag 1 multi-chassis
switch(config-lag-if)# no routing
switch(config-lag-if)# vlan trunk allowed all
switch(config-lag-if)# no shut
switch(config-lag-if)# exit
switch(config)# int 1/1/11
switch(config-if)# no shut
switch(config-if)# lag 1
switch(config-if)# exit
switch(config)# show lacp interfaces
State abbreviations :
A - Active        P - Passive      F - Aggregable I - Individual
S - Short-timeout L - Long-timeout N - InSync     O - OutofSync
C - Collecting    D - Distributing
X - State m/c expired              E - Default neighbor state
Actor details of all interfaces:
------------------------------------------------------------------------------
Intf    Aggr       Port  Port  State   System-id         System Aggr Forwarding
        Name       Id    Pri                             Pri    Key  State
------------------------------------------------------------------------------
1/1/11  lag1(mc)   11    1     ALFNCD  98:f2:b3:68:a2:7e 65534  1    up
1/1/50  lag128     51    1     ALFNCD  98:f2:b3:68:a2:7e 65534  128  up
Partner details of all interfaces:
------------------------------------------------------------------------------
Intf    Aggr       Port  Port  State   System-id         System Aggr
        Name       Id    Pri                             Pri    Key
------------------------------------------------------------------------------
1/1/11  lag1(mc)   56    0     ALFNCD  50:65:f3:12:6d:00 27904  986
1/1/50  lag128     51    1     ALFNCD  98:f2:b3:68:c4:9a 65534  128

switch(config)# vlan 10
switch(config-vlan-10)# vsx-sync
switch(config)# access-list ip secure_mcast_sources
switch(config-acl-ip)# vsx-sync
switch(config-acl-ip)# 10 permit igmp any any
switch(config-acl-ip)# 15 comment block downstream from sourcing mcast
switch(config-acl-ip)# 20 deny any any 224.0.0.0/4
switch(config-acl-ip)# 30 permit any any
switch(config-acl-ip)# int 1/1/1
switch(config-if)# no shutdown
switch(config-if)# no routing
switch(config-if)# vlan access 10
switch(config-if)# apply access-list ip secure_mcast_sources
switch(config-if)# vsx-sync
switch(config-if)# end

switch# show run vsx-sync
Current vsx-sync configuration:
vlan 10
    vsx-sync
vlan 20
    vsx-sync
vlan 30
    vsx-sync
access-list ip secure_mcast_sources
    vsx-sync
    !
    10 comment allow igmp traffic from downstream
    10 permit igmp any any
    15 comment block downstream from sourcing mcast
    20 deny any any 224.0.0.0/240.0.0.0
    30 permit any any any
```

Expected Results 

* Step 1: You can configure vsx
* Step 2: You can create a multi-chassis interface
* Step 3: You can add ports to the multi-chassis interface
* Step 4: You can configure the VLANs and ACLs for synchronization
* Step 5: Everything is synchronized from the primary to the secondary  

	
[Back to Index](./index.md)
