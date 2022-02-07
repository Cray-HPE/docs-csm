# MLAG

A link aggregation group (LAG) is used for extending the bandwidth from a single link to multiple links and provide redundancy in case of link failure. Extending the implementation of the LAG to more than a single device provides yet another level of redundancy that extends from the link level to the node level. This extrapolation of the LAG from single to multiple switches is referred to as multi-chassis link aggregation (MLAG). MLAG is supported on Ethernet blades' internal and external ports.

Configuring L2 MLAG  

### Prerequisites:

Enable IP routing: 

```
switch (config)# ip routing
```

(Recommended) Enable LACP in the switch:

```
switch (config)# lacp
```

### Enable the MLAG protocol commands:

```
switch (config)# protocol mlag
```

Configuring the IPL:

Create a VLAN for the inter-peer link (IPL) to run on: 

```
switch (config)# vlan 4000
switch (config vlan 4000)#
```

Create a LAG:

```
switch (config)# interface port-channel 1
switch (config interface port-channel 1)#
```

Map a physical port to the LAG in active mode (LACP):

```
switch (config)# interface ethernet 1/1 channel-group 1 mode active
```

Set this LAG as an IPL:

```
switch (config interface port-channel 1)# ipl 1
```

Create a VLAN interface:

```
switch (config)# interface vlan 4000
switch (config interface vlan 4000)#
```

Configure MTU to 9K: 

```
switch (config interface vlan 4000)# mtu 9216
```

Set an IP address and netmask for the VLAN interface and configure IP address for the IPL link on both switches:

NOTE: The IPL IP address should not be part of the management network, it could be any IP address and subnet that is not in use in the network. This address is not advertised outside the switch.

On Switch 1:

```
switch (config interface vlan 4000)# ip address 1.1.1.1 /30
```

On Switch 2:

```
switch (config interface vlan 4000)# ip address 1.1.1.2 /30
```

The peer with the interface VLAN with the highest IP address is the MLAG master. 

In the example, above, Switch 2 (with IP address 1.1.1.2) is the master. 

The IP addresses of both peers can be seen in via "show mlag" command.

Map the VLAN interface to be used on the IPL and set the peer IP address (the IP address of the IPL port on the second switch) of the IPL peer port. IPL peer ports must be configured on the same netmask.

On Switch 1:

```
switch (config interface vlan 4000)# ipl 1 peer-address 1.1.1.2
```

On Switch 2:

```
switch (config interface vlan 4000)# ipl 1 peer-address 1.1.1.1
```

(Optional) Configure a virtual IP (VIP) address for the MLAG. MLAG VIP is important for retrieving peer information. 

NOTE: If you have a mgmt0 interface, the IP address should be within the subnet of the management interface. Do not use mgmt1. The management network is used for keepalive messages between the switches. The MLAG domain must be unique name for each MLAG domain. In case you have more than one pair of MLAG switches on the same network, each domain (consist of two switches) should be configured with different name.

On Switch 1: 

```
switch (config)# mlag-vip my-vip ip 10.234.23.254 /24
```

On Switch 2: 

```
switch (config)# mlag-vip my-vip
```

(Optional) Configure a virtual system MAC for the MLAG: 

```
switch (config)# mlag system-mac 00:00:5e:00:01:5d
```

[Back to Index](./index.md)
