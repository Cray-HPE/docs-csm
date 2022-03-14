
# Verify the DHCP Traffic on the Worker Nodes

This section is an example issue of where the source address of the DHCP Offer is the Metallb address of KEA "10.92.100.222".  

The source address of the DHCP Reply/Offer **MUST** be the address of the VLAN interface on the worker node.

Use the following command to look at DHCP traffic on the workers:

```bash
ncn-w001# tcpdump -envli bond0 port 67 or 68
```

Look for the source IP of the DHCP Reply/Offer. The following is an example of working offer:

```
10.252.1.9.67 > 255.255.255.255.68: BOOTP/DHCP, Reply, length 309, hops 1, xid 0x98b0982e, Flags [Broadcast]
      Administratorsr-IP 10.252.1.17
      Server-IP 10.92.100.60
      Gateway-IP 10.252.0.1
      Client-Ethernet-Address 14:02:ec:d9:79:88
      file "ipxe.efi"[|bootp]
If the Source IP of the DHCP Reply/Offer is the MetalLB IP, the DHCP packet will never make it out of the NCN  An example of this is below.
10.92.100.222.116 > 255.255.255.255.68: BOOTP/DHCP, Reply, length 309, hops 1, xid 0x260ea655, Flags [Broadcast]
  Administratorsr-IP 10.252.1.14
  Server-IP 10.92.100.60
  Gateway-IP 10.252.0.4
  Client-Ethernet-Address 14:02:ec:d9:79:88
  file "ipxe.efi"[|bootp]
```

## Resolution

If this issue occurs, the only solution is to restart KEA and making sure that it gets moved to a different worker node.  

[Back to Index](../index.md)
