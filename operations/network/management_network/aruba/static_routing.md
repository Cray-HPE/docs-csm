# Static Routing

"Static routing is manually performed by the network administrator.
The administrator is responsible for discovering and propagating routes through the network.
These definitions are manually programmed in every routing device in the environment.
After a device has been configured, it simply forwards packets out the predetermined ports.
There is no communication between routers regarding the current topology of the network." – IBM Redbook, TCP/IP Tutorial and Technical Overview

## Configuration commands

(`switch(config)#`)

```console
<ip|ipv6> route IP-ADDR/<SUBNET|PREFIX> IP-ADDR
```

## Show commands to validate functionality

(`switch(config)#`)

```console
show <ip|ipv6> route [static]
```

(`switch(config)#`)

```console
show ip route
```

Example output:

```text
Displaying ipv4 routes selected for forwarding
'[x/y]' denotes [distance/metric]30.0.0.0/30,  1 (null) next-hops
        via  1/1/3,  [0/0],  connected, vrf vrf_default
40.0.0.0/24,  1 (null) next-hops
        via  30.0.0.2,  [1/0],  static, vrf vrf_default
```

(`switch(config)#`)

```console
show ip route static
```

Example output:

```text
Displaying ipv4 routes selected for forwarding
'[x/y]' denotes [distance/metric]
40.0.0.0/24,  1 (null) next-hops
        via  30.0.0.2,  [1/0],  static, vrf vrf_default
```

(`switch(config)#`)

```console
show ipv6 route
```

Example output:

```text
Displaying ipv6 routes selected for forwarding
'[x/y]' denotes [distance/metric]
2001:10::/64,  1 (null) next-hops
        via  1/1/1,  [0/0],  connected, vrf default
2001:30::/64,  1 (null) next-hops
        via  2001:10::2,  [1/0],  static, vrf default
```

(`switch(config)#`)

```console
show ipv6 route static
```

Example output:

```text
Displaying ipv6 routes selected for forwarding
'[x/y]' denotes [distance/metric]
2001:30::/64,  1 (null) next-hops
        via  2001:10::2,  [1/0],  static, vrf default
```

## Expected results

* Administrators can configure a static route on the DUT.
* Administrators can validate using the `show` commands.
* Administrators can ping the connected device.

[Back to Index](../README.md)
