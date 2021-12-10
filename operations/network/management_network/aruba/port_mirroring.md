
# Port Mirroring 

Port mirroring, also known as Switched Port Analyzer (SPAN), enables traffic on one or more switch interfaces to be replicated on another interface for purposes such as monitoring. 

## Configuration Commands

Create and enable a mirror session: 

```bash
switch(config)# mirror session <1-4> switch(config-mirror)# enable
```

Configure a source interface:

```bash
switch(config-mirror)# source interface IFACE <both|tx|rx>
```

Configure an interface as the mirror destination:

```bash
switch(config-mirror)# destination interface IFACE 
```

Configure a tunnel as the mirror destination (ERSPAN): 

```bash
switch(config-mirror)# destination tunnel IP-ADDR source IP-ADDR [id VALUE> [vrf VRF]
```

Configure CPU as the mirror destination:

```bash 
switch(config-mirror)# destination cpu
```

Generate and copy the internal packet capture: 

```bash
switch# diagnostics
switch# diag utilities tshark [file]
switch# copy tshark-pcap REMOTE-URL vrf VRF
```

Show commands to validate functionality:  

```bash
switch# show mirror <1-4>
```
 
> **NOTES:**
> * You can set the Switch CPU as the destination for mirrored traffic. Keep in mind that all the traffic from an  interface will be sent to the CPU and could create high CPU utilization. 
> * We advise against using this method on taking captures in live network as the amount of traffic could negatively hit the CPU, so in those cases recommendation would be to use external capture station.

To do a port capture directly on device: 

```
8325(config)# mirror session 1
8325(config-mirror-1)# destination cpu
8325(config-mirror-1)# source interface 1/1/1
  both  A source of transmit & receive traffic
  rx    A source of receive-only traffic
  tx    A source of transmit-only traffic
8325(config-mirror-1)# source interface 1/1/1 both
8325(config-mirror-1)# enable
```

To start TCPDUMP from shell:

```
8325# start-shell
8325:~$ sudo su
8325:/home/admin# ip netns
VRF_1
wireless_mgmt
ntb (id: 0)
mirror_ns
nonet
swns
8325:/home/admin# ip netns exec mirror_ns bash
8325:/home/admin# ifconfig
MirrorRxNetLink encap:Ethernet  HWaddr 02:10:18:96:FD:EE
          UP BROADCAST RUNNING MULTICAST  MTU:9326  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0  TX bytes:0
 
lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Bcast:0.0.0.0  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0  TX bytes:0
8325:/home/admin# tcpdump -i MirrorRxNet -xx
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on MirrorRxNet, link-type EN10MB (Ethernet), capture size 262144 bytes
^C
0 packets captured
0 packets received by filter
0 packets dropped by kernel
```
 
> **NOTE:** host/dst arguments to the `tcpdump` command can help to restrict the filter to only capture packets you need.


## Expected Results 

1. You can configure port mirroring
2. The output of the `show` commands is correct
3. You can see the traffic for the source interface on the sniffer 


[Back to Index](../index.md)