# MLAG

A link aggregation group (LAG) is used for extending the bandwidth from a single link to multiple links and provide
redundancy in case of link failure. Extending the implementation of the LAG to more than a single device provides yet
another level of redundancy that extends from the link level to the node level. This extrapolation of the LAG from
single to multiple switches is referred to as multi-chassis link aggregation (MLAG). MLAG is supported on Ethernet
blades' internal and external ports.

## Configuring L2 MLAG

### Prerequisites

(`switch (config)#`) Enable IP routing:

```console
ip routing
```

(`switch (config)#`) (Recommended) Enable LACP in the switch:

```console
lacp
```

### Enable the MLAG protocol commands

(`switch (config)#`)

```console
protocol mlag
```

### Configuring the IPL

(`switch (config)#`) Create a VLAN for the inter-peer link (IPL) to run on:

```console
vlan 4000
```

(`switch (config)#`) Create a LAG:

```console
interface port-channel 1
```

(`switch (config)#`) Map a physical port to the LAG in active mode (LACP):

```console
interface ethernet 1/1 channel-group 1 mode active
```

(`switch (config interface port-channel 1)#`) Set this LAG as an IPL:

```console
ipl 1
```

(`switch (config)#`) Create a VLAN interface:

```console
interface vlan 4000
```

(`switch (config interface vlan 4000)#`) Configure MTU to 9K:

```console
mtu 9216
```

Set an IP address and netmask for the VLAN interface and configure IP address for the IPL link on both switches:

> NOTE: The IPL IP address should not be part of the management network;
> it could be any IP address and subnet that is not in use in the network. This address is not advertised outside the switch.

(`switch (config interface vlan 4000)#`) On switch 1:

```console
ip address 1.1.1.1 /30
```

(`switch (config interface vlan 4000)#`) On switch 2:

```console
ip address 1.1.1.2 /30
```

The peer with the interface VLAN with the highest IP address is the MLAG master.

In the example above, switch 2 (with IP address `1.1.1.2`) is the master.

The IP addresses of both peers can be seen using the `show mlag` command.

Map the VLAN interface to be used on the IPL and set the peer IP address (the IP address of the IPL port on the second switch) of the IPL peer port.
IPL peer ports must be configured on the same netmask.

(`switch (config interface vlan 4000)#`) On switch 1:

```console
ipl 1 peer-address 1.1.1.2
```

(`switch (config interface vlan 4000)#`) On switch 2:

```console
ipl 1 peer-address 1.1.1.1
```

(Optional) Configure a virtual IP (VIP) address for the MLAG. MLAG VIP is important for retrieving peer information.

NOTE: If the system has a `mgmt0` interface, then the IP address should be within the subnet of the management interface.
Do not use `mgmt1`. The management network is used for `keepalive` messages between the switches.
The MLAG domain must be unique name for each MLAG domain. In the case of having more than one pair of MLAG switches on the same network,
each domain (consisting of two switches) should be configured with different name.

(`switch (config)#`) On switch 1:

```console
mlag-vip my-vip ip 10.234.23.254 /24
```

(`switch (config)#`) On switch 2:

```console
mlag-vip my-vip
```

(`switch (config)#`) (Optional) Configure a virtual system MAC address for the MLAG:

```console
mlag system-mac 00:00:5e:00:01:5d
```

[Back to Index](../README.md)
