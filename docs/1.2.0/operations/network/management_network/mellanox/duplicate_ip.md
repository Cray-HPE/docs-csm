# You are getting an IP address, but not the correct one. Duplicate IP address check

A sign of a duplicate IP address is seeing a DECLINE message from the client to the server.

```
10.40.0.0.337 > 10.42.0.58.67: BOOTP/DHCP, Request from b4:2e:99:be:1a:d3, length 301, hops 1, xid 0x9d1210d, Flags [none]
     Gateway-IP 10.252.0.2
     Client-Ethernet-Address b4:2e:99:be:1a:d3
     Vendor-rfc1048 Extensions
       Magic Cookie 0x63825363
       DHCP-Message Option 53, length 1: Decline
       Client-ID Option 61, length 19: hardware-type 255, 99:be:1a:d3:00:01:00:01:26:c8:55:c3:b4:2e:99:be:1a:d3
       Server-ID Option 54, length 4: 10.42.0.58
       Requested-IP Option 50, length 4: 10.252.0.26
       Agent-Information Option 82, length 22:
         Circuit-ID SubOption 1, length 20: vlan2-ethernet1/1/12
```

To test for Duplicate IP addresses you can ping the suspected address while you turn off the node, if you continue to get responses, then you have a duplicate IP.

[Back to Index](../index.md)