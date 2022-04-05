# NCN TCPDUMP

If a host is not getting an IP address, run a packet capture to see if DHCP traffic is being transmitted.

On `ncn-w001` or a worker/manager with `kubectl`, run the following:

```text
ncn# tcpdump -w dhcp.pcap -envli bond0.nmn0 port 67 or port 68
```

This will make a .pcap file named dhcp in the current directory. It will collect all DHCP traffic on the specified port. In this example, we are looking for DHCP traffic on interface bond0.nmn0 (10.252.0.0/17).

To view the DHCP traffic:

```text
ncn# tcpdump -r dhcp.pcap -v -n
```

Use filters to sort the output if it is very long.

To do a `tcpdump` for a specific MAC address:

```text
ncn# tcpdump -i eth0 -vvv -s 1500 '((port 67 or port 68) and (udp[38:4] = 0x993b7030))'
```

**NOTE:** This example is using the MAC of b4:2e:99:3b:70:30 and will show the output on the terminal and will not save to a file.

[Back to Index](./index.md)
