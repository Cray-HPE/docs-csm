# Static Routing

"Static routing is manually performed by the network administrator. The administrator is responsible for discovering and propagating routes through the network. These definitions are manually programmed in every routing device in the environment. After a device has been configured, it simply forwards packets out the predetermined ports. There is no communication between routers regarding the current topology of the network." –IBM Redbook, TCP/IP Tutorial and Technical Overview

## Configuration Commands

```text
switch(config)# <ip|ipv6> route IP-ADDR/<SUBNET|PREFIX> IP-ADDR
```

Show commands to validate functionality:

```text
show <ip|ipv6> route [static]
```

## Example Output

```text
show ip route
Displaying ipv4 routes selected for forwarding
'[x/y]' denotes [distance/metric]30.0.0.0/30,  1 (null) next-hops
        via  1/1/3,  [0/0],  connected, vrf vrf_default
40.0.0.0/24,  1 (null) next-hops
        via  30.0.0.2,  [1/0],  static, vrf vrf_default

show ip route static
Displaying ipv4 routes selected for forwarding
'[x/y]' denotes [distance/metric]
40.0.0.0/24,  1 (null) next-hops
        via  30.0.0.2,  [1/0],  static, vrf vrf_default

show ipv6 route
Displaying ipv6 routes selected for forwarding
'[x/y]' denotes [distance/metric]
2001:10::/64,  1 (null) next-hops
        via  1/1/1,  [0/0],  connected, vrf default
2001:30::/64,  1 (null) next-hops
        via  2001:10::2,  [1/0],  static, vrf default

show ipv6 route static
Displaying ipv6 routes selected for forwarding
'[x/y]' denotes [distance/metric]
2001:30::/64,  1 (null) next-hops
        via  2001:10::2,  [1/0],  static, vrf default
```

## Expected Results

1. Administrators can configure a static route on the DUT
2. Administrators can validate using the `show` command(s)
3. Administrators can ping the connected device

[Back to Index](../README.md)
