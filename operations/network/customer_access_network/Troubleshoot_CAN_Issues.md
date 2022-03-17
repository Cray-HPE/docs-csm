## Troubleshoot CAN Issues

Various connection points to check when using the CAN and how to fix any issues that arise.

The most frequent issue with the Customer Access Network \(CAN\) is trouble accessing IP addresses outside of the HPE Cray EX system from a node or pod inside the system.

The best way to resolve this issue is to try to ping an outside IP address from one of the NCNs other than `ncn-m001`, which has a direct connection that it can use instead of the Customer Access Network \(CAN\). The following are some things to check to make sure CAN is configured correctly:

### Does the NCN have an IP Address Configured on the vlan007 Interface?

Check the status of the vlan007 interface. Make sure it has an address specified.

```screen
ncn-w002# ip addr show vlan007
534: vlan007@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 98:03:9b:b4:27:62 brd ff:ff:ff:ff:ff:ff
    inet 10.102.5.5/26 brd 10.101.8.255 scope global vlan007
       valid_lft forever preferred_lft forever
    inet6 fe80::9a03:9bff:feb4:2762/64 scope link
       valid_lft forever preferred_lft forever
```

If there is not an address specified, make sure the `can-` values have been defined in `csi config init` input.

### Does the NCN have a Default Gateway Configured?

Check the default route on an NCN other than `ncn-m001`. There should be a default route with a gateway matching the can-gateway value.

```screen
ncn-w002# ip route | grep default
default via 10.102.5.27 dev vlan007
```

If there is not an address specified, make sure the `can-` values have been defined in `csi config init` input.

### Can the Node Reach the Default CAN Gateway?

Check that the node can ping the default gateway shown in the default route.

```screen
ncn-w002# ping 10.102.5.27
PING 10.102.5.27 (10.102.5.27) 56(84) bytes of data.
64 bytes from 10.102.5.27: icmp_seq=1 ttl=64 time=0.148 ms
64 bytes from 10.102.5.27: icmp_seq=2 ttl=64 time=0.107 ms
64 bytes from 10.102.5.27: icmp_seq=3 ttl=64 time=0.133 ms
64 bytes from 10.102.5.27: icmp_seq=4 ttl=64 time=0.122 ms
^C
--- 10.102.5.27 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3053ms
rtt min/avg/max/mdev = 0.107/0.127/0.148/0.018 ms
```

If the default gateway cannot be accessed, check the spine switch configuration.

### Can the Spines Reach Outside of the System?

Check that each of the spines can ping an IP address outside of the HPE Cray EX system. This must be an IP address that is reachable from the network to which the CAN is connected. If there is only one spine being used on the system, only `spine-001` needs to be checked.

```screen
sw-spine-001 [standalone: master] # ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=112 time=12.6 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=112 time=12.5 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=112 time=22.4 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=112 time=12.5 ms
^C
--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 12.501/15.022/22.440/4.285 ms
```

If the outside IP address cannot be reached, check the spine switch configuration and the connection to the customer network.

### Can the Spines Reach the NCN?

Check that each of the spines can ping one or more of the NCNs at its vlan007 IP address. If there is only one spine being used on the system, only `spine-001` needs to be checked.

```screen
sw-spine-001 [standalone: master] # ping 10.102.5.5
PING 10.102.5.5 (10.102.5.5) 56(84) bytes of data.
64 bytes from 10.102.5.5: icmp_seq=1 ttl=64 time=0.140 ms
64 bytes from 10.102.5.5: icmp_seq=2 ttl=64 time=0.134 ms
64 bytes from 10.102.5.5: icmp_seq=3 ttl=64 time=0.126 ms
64 bytes from 10.102.5.5: icmp_seq=4 ttl=64 time=0.178 ms
^C
--- 10.102.5.5 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3058ms
rtt min/avg/max/mdev = 0.126/0.144/0.178/0.023 ms
```

If the NCN cannot be reached, check the spine switch configuration.

### Can a Device Outside the System Reach the CAN Gateway?

Check that a device outside the HPE Cray EX system that is expected to have access to nodes and services on the CAN can ping the CAN gateway.

```screen
$ ping 10.102.5.27
PING 10.102.5.27 (10.102.5.27): 56 data bytes
64 bytes from 10.102.5.27: icmp_seq=0 ttl=58 time=54.724 ms
64 bytes from 10.102.5.27: icmp_seq=1 ttl=58 time=65.902 ms
64 bytes from 10.102.5.27: icmp_seq=2 ttl=58 time=51.960 ms
64 bytes from 10.102.5.27: icmp_seq=3 ttl=58 time=55.032 ms
64 bytes from 10.102.5.27: icmp_seq=4 ttl=58 time=57.606 ms
^C
--- 10.102.5.27 ping statistics ---
5 packets transmitted, 5 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 51.960/57.045/65.902/4.776 ms
```

If the CAN gateway cannot be reached from outside, check the spine switch configuration and the connection to the customer network.



