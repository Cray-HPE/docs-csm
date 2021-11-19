
## Compute Node Boot Issue Symptom: Duplicate Address Warnings and Declined DHCP Offers in Logs

If the DHCP and node logs show duplicate address warnings and indicate declined DHCP offers, it may be because another component owns the IP address that DHCP is trying to assign to a node. If this happens, the node will not accept the IP address and will repeatedly submit a DHCP discover request. As a result, the node and DHCP become entangled in a loop of requesting and rejecting. This often happens when DHCP is statically assigning IP addresses to nodes, but the assigned IP address for a node has already been assigned to another component.

### Symptoms

This scenario results in node logs similar to the following:

**Node log**:

```bash
[   97.946332] dracut Warning: Duplicate address detected for 10.100.160.195 while doing dhcp. retrying
[   97.789015] dracut-initqueue[604]: dracut Warning: Duplicate address detected for 10.100.160.195 while doing dhcp. \
retrying
[  108.007243] dracut Warning: Duplicate address detected for 10.100.160.195 while doing dhcp. retrying
[  107.873650] dracut-initqueue[604]: dracut Warning: Duplicate address detected for 10.100.160.195 while doing dhcp. \
retrying
[  110.082877] dracut Warning: Duplicate address detected for 10.100.160.195 while doing dhcp. retrying
```

**DHCP log**:

```bash
Abandoning IP address 10.100.160.195: declined.
DHCPDECLINE of 10.100.160.195 from a4:bf:01:2e:81:4c (undefined) via eth0: abandoned
DHCPOFFER on 10.100.160.195 to "" (undefined) via eth0
DHCPREQUEST for 10.100.160.195 (10.100.160.2) from a4:bf:01:29:92:be via eth0: unknown lease 10.100.160.195.
DHCPREQUEST for 10.100.160.195 (10.100.160.2) from a4:bf:01:29:92:eb via eth0: unknown lease 10.100.160.195.
DHCPOFFER on 10.100.160.195 to a4:bf:01:2e:81:4c via eth0
DHCPREQUEST for 10.100.160.195 (10.100.160.2) from a4:bf:01:2e:81:4c via eth0
DHCPACK on 10.100.160.195 to a4:bf:01:2e:81:4c via eth0
Abandoning IP address 10.100.160.195: declined.
```

Notice that two different components \(identifiable by the two different MAC addresses `a4:bf:01:29:92:eb` and `a4:bf:01:2e:81:4c`\) have made DHCP requests for the IP address `10.100.160.195`.

`a4:bf:01:29:92:eb` is the component that owns the IP address `10.100.160.195`, while `a4:bf:01:2e:81:4c` has been statically assigned the IP address `10.100.160.195` in the DHCP configuration file. As such, DHCP keeps trying to assign it that address, but after being offered the address, `a4:bf:01:2e:81:4c` declines it because it realizes that `a4:bf:01:29:92:eb` already owns it.

### Problem Detection

There are multiple ways to check if this problem exists:

-   Ping the IP address and see if another component responds. Log into the component and determine its IP address. If it is the same as the IP address that DHCP is attempting to assign, then this issue does exist.
-   Check the Address Resolution Protocol \(ARP\) cache using the arp command. Because it is a cache, it is possible that IP addresses can age out of the cache, so the IP address may not be present. If the address that is failing to be assigned is in the ARP cache, and it is assigned to a node with a different MAC address, then that is confirmation that this problem has occurred.

    ```bash
    ncn-m001# arp
    Address                  HWtype  HWaddress           Flags Mask            Iface
    ncn-w002.local           ether   98:03:9b:b4:f1:fe   C                     bond0.nmn0
    10.46.11.201             ether   ca:d3:dc:33:29:e7   C                     weave
    10.46.12.7               ether   7e:7e:7f:f0:0d:2d   C                     weave
    10.46.11.197             ether   62:4c:91:91:ec:9f   C                     weave
    10.46.11.193             ether   52:dd:02:01:34:ab   C                     weave
    10.32.0.5                ether   ba:ff:65:af:a7:4e   C                     weave
    10.46.11.191             ether   be:36:79:07:84:08   C                     weave
    10.45.1.121              ether   fe:93:50:63:9a:fd   C                     weave
    10.46.11.187             ether   e6:2e:8c:ed:f8:78   C                     weave
    10.46.11.250             ether   c6:73:6d:c4:b9:77   C                     weave
    10.48.15.0               ether   da:c2:40:ed:f4:ec   CM                    flannel.2
    10.46.11.183             ether   a2:f2:0d:34:cc:8b   C                     weave
    10.46.11.246             ether   7e:42:c4:0f:59:97   C                     weave
    nid000003-nmn.local      ether   a4:bf:01:3e:f9:cd   C                     bond0.nmn0
    10.46.11.242             ether   4e:06:ef:eb:5c:ba   C                     weave
    10.46.11.234             ether   f2:76:9d:1a:68:00   C                     weave
    sw-spine01-nmn.local     ether   b8:59:9f:68:97:48   C                     bond0.nmn0
    10.46.11.230             ether   6a:a3:65:5c:37:ba   C                     weave
    10.46.12.28              ether   06:0e:54:02:a7:c4   C                     weave
    10.46.11.226             ether   5a:5b:55:77:97:b7   C                     weave
    10.46.12.24              ether   ba:4c:84:e3:53:2b   C                     weave
    10.38.1.89               ether   5a:c7:15:17:78:dc   C                     weave
    10.46.11.222             ether   52:61:38:42:7c:00   C                     weave
    10.46.11.218             ether   66:81:68:6e:2e:38   C                     weave
    10.46.11.214             ether   ea:91:c2:b7:de:a2   C                     weave
    10.46.12.12              ether   5a:dd:d2:8b:20:66   C                     weave
    ncn-m002.local           ether   b8:59:9f:1d:da:26   C                     bond0.nmn0
    10.46.11.210             ether   2e:9f:17:a6:d7:d4   C                     weave
    10.48.52.0               ether   e2:9e:26:a4:d3:ba   CM                    flannel.2
    ncn-s003.local           ether   98:03:9b:bb:a9:48   C                     bond0.nmn0
    10.38.1.73               ether   46:67:08:21:f1:fc   C                     weave
    10.46.11.206             ether   36:b9:47:ad:69:8d   C                     weave
    ncn-s002.local           ether   b8:59:9f:34:88:ca   C                     bond0.nmn0
    10.46.12.0               ether   36:cb:f8:3c:b4:05   C                     weave
    10.46.11.194             ether   e2:7d:57:7e:9c:9e   C                     weave
    10.32.0.6                ether   46:e2:fe:29:1d:02   C                     weave
    10.46.11.188             ether   aa:3c:5a:60:45:af   C                     weave
    10.46.11.255             ether   3a:e6:e4:91:7a:ec   C                     weave
    10.48.16.0               ether   1a:fa:2e:8f:80:5c   CM                    flannel.2
    10.46.11.247             ether   c2:af:c4:53:ba:ff   C                     weave
    nid000002-nmn.local      ether   a4:bf:01:3e:ef:d7   C                     bond0.nmn0
    10.46.11.243             ether   de:5c:cc:47:db:55   C                     weave
    10.46.11.235             ether   c6:bb:07:55:8a:4d   C                     weave
    10.46.11.231             ether   6a:73:3c:fe:3f:95   C                     weave
    10.46.12.29              ether   a6:d6:6f:71:d1:50   C                     weave
    10.46.11.227             ether   b6:fe:d9:9d:41:0c   C                     weave
    10.46.12.21              ether   42:cd:2c:a3:d2:97   C                     weave
    10.46.11.219             ether   8a:47:b1:71:05:f9   C                     weave
    10.46.11.215             ether   ce:b1:cb:48:c7:e3   C                     weave
    10.46.12.13              ether   e2:34:38:f3:ce:3f   C                     weave
    ncn-m001.local           ether   b8:59:9f:1d:d8:4a   C                     bond0.nmn0
    10.46.11.211             ether   7e:ad:22:04:9b:32   C                     weave
    10.46.11.203             ether   16:23:a2:96:d4:d2   C                     weave
    10.46.12.1               ether   8e:51:2a:b6:f1:cc   C                     weave
    10.46.11.199             ether   e6:f4:ee:92:b8:a8   C                     weave
    10.46.11.195             ether   ce:0e:d2:e8:d5:fa   C                     weave
    10.46.11.189             ether   92:ad:7c:93:ec:d8   C                     weave
    10.46.11.252             ether   a2:92:18:0f:54:a8   C                     weave
    10.48.57.0               ether   4a:ac:84:c4:76:b1   CM                    flannel.2
    10.46.11.248             ether   ea:ff:53:cd:27:36   C                     weave
    10.46.11.240             ether   6a:33:63:3a:50:0a   C                     weave
    cfgw-48-vrrp.us.cray.com  ether   00:00:5e:00:01:30   C                     em1
    10.252.120.2             ether   b8:59:9f:1d:da:26   C                     bond0.nmn0
    sw-leaf-001-can.local      ether   3c:2c:30:5e:6d:b5   C                     bond0.cmn0
    nid000001-nmn.local      ether   a4:bf:01:3e:e0:93   C                     bond0.nmn0
    10.46.11.232             ether   3a:69:e4:d9:7f:1f   C                     weave
    10.45.1.166              ether   9a:86:9c:c0:53:c5   C                     weave
    10.46.11.224             ether   d6:ec:f3:eb:6a:cb   C                     weave
    10.46.12.30              ether   a2:e1:8e:f5:65:64   C                     weave
    10.46.11.220             ether   1e:37:ab:42:15:24   C                     weave
    10.46.11.212             ether   16:82:52:f6:ca:de   C                     weave
    sw-leaf-001-hmn.local      ether   3c:2c:30:5e:6d:b5   C                     bond0.hmn0
    sw-leaf-001-mtl.local      ether   3c:2c:30:5e:6d:b5   C                     p1p1
    10.46.11.208             ether   0e:cf:3d:df:ea:21   C                     weave
    10.46.12.14              ether   92:73:ff:8d:8a:07   C                     weave
    10.46.12.10              ether   32:19:b3:75:3c:f7   C                     weave
    ncn-w003.local           ether   98:03:9b:bb:a8:8c   C                     bond0.nmn0
    10.46.11.200             ether   1a:c3:46:0f:a0:b9   C                     weave
    10.48.3.0                ether   16:78:89:dd:ae:7c   CM                    flannel.2
    10.46.12.6               ether   c6:3d:da:ef:d8:a5   C                     weave
    ncn-s001.local           ether   b8:59:9f:1d:d9:1e   C                     bond0.nmn0
    10.46.11.196             ether   96:88:fc:f4:15:ac   C                     weave
    10.46.12.2               ether   d2:ac:dd:44:2c:0a   C                     weave
    10.46.11.192             ether   e6:aa:51:79:ee:83   C                     weave
    10.46.11.253             ether   a6:dc:f1:57:24:84   C                     weave
    10.46.11.190             ether   62:a8:e0:3c:13:be   C                     weave
    10.46.11.249             ether   fa:37:7f:0a:ed:73   C                     weave
    10.46.11.186             ether   aa:d9:05:39:cd:77   C                     weave
    10.46.11.241             ether   36:a7:00:8a:8a:9e   C                     weave
    nid000004-nmn.local      ether   a4:bf:01:3e:ca:61   C                     bond0.nmn0
    172.17.0.2               ether   02:42:ac:11:00:02   C                     docker0
    10.46.11.233             ether   3a:5f:0f:9f:ce:e1   C                     weave
    10.46.12.35              ether   9e:6d:fa:63:5e:2c   C                     weave
    10.45.1.100              ether   32:65:00:82:9b:90   C                     weave
    10.46.12.31              ether   ee:bd:3e:ee:ab:80   C                     weave
    169.254.255.254          ether   74:83:ef:2a:e7:83   C                     hsn0
    10.46.12.27              ether   1a:42:25:07:ee:0d   C                     weave
    10.46.11.213             ether   06:b8:de:1d:b2:99   C                     weave
    10.46.12.19              ether   82:61:83:18:fc:b7   C                     weave
    sw-spine-001-hmn.local     ether   b8:59:9f:68:97:48   C                     bond0.hmn0
    10.46.12.15              ether   ce:92:74:c6:4b:b3   C                     weave
    ncn-m003.local           ether   b8:59:9f:1d:d9:f2   C                     bond0.nmn0
    10.46.11.205             ether   16:e7:2e:6d:a3:e2   C                     weave
    10.46.12.11              ether   22:33:f7:4f:be:80   C                     weave
    ```


### Resolution

Force the component that has been assigned an incorrect IP address to request another one. This may involve powering that component down and then back up.

