# NCN `tcpdump`

- [Running a packet capture](#running-a-packet-capture)
- [View traffic captured to a file](#view-traffic-captured-to-a-file)
- [Filter packet capture output](#filter-packet-capture-output)

## Running a packet capture

(`ncn-mw#`) If a host is not getting an IP address, then run a packet capture to see if DHCP traffic is being transmitted.

> This example will look for DHCP traffic on interface `bond0.nmn0`. It will collect all DHCP
> traffic on ports 67 and 68, and write the output to a file named `dhcp.pcap` in the current directory.

```bash
tcpdump -w dhcp.pcap -envli bond0.nmn0 port 67 or port 68
```

## View traffic captured to a file

(`ncn-mw#`) To view previously captured traffic from a generated file:

> This example uses the file generated from the [Running a packet capture](#running-a-packet-capture) example.

```bash
tcpdump -r dhcp.pcap -v -n
```

## Filter packet capture output

Use filters to sort the output if it is very long.

(`ncn-mw#`) To do a `tcpdump` for a specific MAC address:

> This example uses the MAC address of `b4:2e:99:3b:70:30`, and shows the output on the terminal rather than saving it to a file.

```bash
tcpdump -i eth0 -vvv -s 1500 '((port 67 or port 68) and (udp[38:4] = 0x993b7030))'
```

[Back to index](README.md).
