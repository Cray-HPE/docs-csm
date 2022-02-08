# Verify the DHCP traffic on the workers

Example issue: Source address of the DHCP Offer is the MetalLB address of KEA "10.92.100.222".  

The source address of the DHCP Reply/Offer NEEDS to be the address of the vlan interface on the Worker.

Here's how to look at DHCP traffic on the workers:

```
ncn-w001:~ # tcpdump -envli bond0 port 67 or 68
```

You are looking for the source IP address of the DHCP Reply/Offer, this is an example of working offer:

```
10.252.1.9.67 > 255.255.255.255.68: BOOTP/DHCP, Reply, length 309, hops 1, xid 0x98b0982e, Flags [Broadcast]
      Your-IP 10.252.1.17
      Server-IP 10.92.100.60
      Gateway-IP 10.252.0.1
      Client-Ethernet-Address 14:02:ec:d9:79:88
      file "ipxe.efi"[|bootp]
If the Source IP address of the DHCP Reply/Offer is the MetalLB IP address, the DHCP packet will never make it out of the NCN. An example of this is below.
10.92.100.222.116 > 255.255.255.255.68: BOOTP/DHCP, Reply, length 309, hops 1, xid 0x260ea655, Flags [Broadcast]
  Your-IP 10.252.1.14
  Server-IP 10.92.100.60
  Gateway-IP 10.252.0.4
  Client-Ethernet-Address 14:02:ec:d9:79:88
  file "ipxe.efi"[|bootp]
```
 
If you run into this, the only solution that we have found so far is restarting KEA and making sure that it gets moved to a different worker.  

[Back to Index](../index.md)
