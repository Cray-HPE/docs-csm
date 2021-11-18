# Rebooting NCN and PXE fails

Common Error messages.

```
2021-04-19 23:27:09   PXE-E18: Server response timeout.
2021-02-02 17:06:13   PXE-E99: Unexpected network error.
```

Verify the ip helper-address on VLAN 1 on the switches.  

This is the same configuration as above "Aruba Configuration".

Verify DHCP packets can be forwarded from the workers to the MTL network (VLAN1)

* If the Worker nodes can't reach the metal network DHCP will fail.
* ALL WORKERS need to be able to reach the MTL network!
* This can normally be achieved by having a default route 

Simple connectivity tests below:

```
ncn-w001:~ # ping 10.1.0.1
PING 10.1.0.1 (10.1.0.1) 56(84) bytes of data.
64 bytes from 10.1.0.1: icmp_seq=1 ttl=64 time=0.361 ms
64 bytes from 10.1.0.1: icmp_seq=2 ttl=64 time=0.145 ms
```

If this fails you may have a misconfigured CAN or need to add a route to the MTL network.

```
ncn-w001:~ # ip route add 10.1.0.0/16 via 10.252.0.1 dev bond0.nmn0
```

[Back to Index](./index.md)