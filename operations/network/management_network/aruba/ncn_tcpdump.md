# TCPDUMP

If your host is not getting an IP address you can run a packet capture to see if DHCP traffic is being transmitted.

On ncn-w001 or a worker/manager with kubectl, run:

```
tcpdump -w dhcp.pcap -envli bond0.nmn0 port 67 or port 68
```

This will make a .pcap file named dhcp in your current directory. It will collect all DHCP traffic on the port you specify, in this example we are looking for DHCP traffic on interface bond0.nmn0 (10.252.0.0/17)

To view the DHCP traffic, run:

```
tcpdump -r dhcp.pcap -v -n
```

The output may be very long so you might have to use filters.

If you want to do a tcpdump for a certain MAC address you can run:

```
tcpdump -i eth0 -vvv -s 1500 '((port 67 or port 68) and (udp[38:4] = 0x993b7030))'
```

Note: This example is using the MAC of b4:2e:99:3b:70:30 and will show the output on your terminal and not save to a file. 

<<<<<<< HEAD
[Back to Index](./index.md)
=======
[Back to Index](../index.md)
>>>>>>> release/1.2
