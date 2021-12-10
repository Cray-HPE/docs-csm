# Static Routing 

“Static routing is manually performed by the network administrator. The administrator is responsible for discovering and propagating routes through the network. These definitions are manually programmed in every routing device in the envi- ronment. After a device has been configured, it simply forwards packets out the predetermined ports. There is no com- munication between routers regarding the current topology of the network.” –IBM Redbook, TCP/IP Tutorial and Technical Overview 

## Configuration Commands

```bash
switch(config)# <ip|ipv6> route IP-ADDR/<SUBNET|PREFIX> IP-ADDR
```

Show commands to validate functionality:  

```bash
switch# show <ip|ipv6> route [static]
```

## Example Output 

```bash
switch# show ip route
Displaying ipv4 routes selected for forwarding
'[x/y]' denotes [distance/metric]30.0.0.0/30,  1 (null) next-hops
        via  1/1/3,  [0/0],  connected, vrf vrf_default
40.0.0.0/24,  1 (null) next-hops
        via  30.0.0.2,  [1/0],  static, vrf vrf_default

switch# show ip route static
Displaying ipv4 routes selected for forwarding
'[x/y]' denotes [distance/metric]
40.0.0.0/24,  1 (null) next-hops
        via  30.0.0.2,  [1/0],  static, vrf vrf_default

switch# show ipv6 route
Displaying ipv6 routes selected for forwarding
'[x/y]' denotes [distance/metric]
2001:10::/64,  1 (null) next-hops
        via  1/1/1,  [0/0],  connected, vrf default
2001:30::/64,  1 (null) next-hops
        via  2001:10::2,  [1/0],  static, vrf default

switch# show ipv6 route static
Displaying ipv6 routes selected for forwarding
'[x/y]' denotes [distance/metric]
2001:30::/64,  1 (null) next-hops
        via  2001:10::2,  [1/0],  static, vrf default
```

## Expected Results 

1. You can configure a static route on the DUT
2. You can validate using the `show` command(s)
3. You can ping the connected device

[Back to Index](../index_aruba.md)
