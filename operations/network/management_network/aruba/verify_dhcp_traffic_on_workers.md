# Verify the DHCP Traffic on the Worker Nodes

The source address of the DHCP reply/offer **MUST** be the address of the VLAN interface on the worker node.
If the source IP address of the DHCP reply/offer is the MetalLB IP address of KEA (`10.92.100.222`),
then the DHCP packet will never make it out of the NCN.

## Check DHCP traffic on worker

(`ncn-w#`) Look at DHCP traffic on a worker:

```bash
tcpdump -envli bond0 port 67 or 68
```

Look for the source IP address of the DHCP reply/offer. The following is
example output of a working offer:

```text
10.252.1.9.67 > 255.255.255.255.68: BOOTP/DHCP, Reply, length 309, hops 1, xid 0x98b0982e, Flags [Broadcast]
      Administratorsr-IP 10.252.1.17
      Server-IP 10.92.100.60
      Gateway-IP 10.252.0.1
      Client-Ethernet-Address 14:02:ec:d9:79:88
      file "ipxe.efi"[|bootp]
```

If the source IP address of the DHCP reply/offer is the MetalLB IP address of KEA (`10.92.100.222`),
then the DHCP packet will never make it out of the NCN.
The following example output shows this issue:

```text
10.92.100.222.116 > 255.255.255.255.68: BOOTP/DHCP, Reply, length 309, hops 1, xid 0x260ea655, Flags [Broadcast]
  Administratorsr-IP 10.252.1.14
  Server-IP 10.92.100.60
  Gateway-IP 10.252.0.4
  Client-Ethernet-Address 14:02:ec:d9:79:88
  file "ipxe.efi"[|bootp]
```

## Resolution

If this issue occurs, then the only solution is to restart KEA and making sure that it gets moved to a different worker node.

[Back to Index](../README.md)
