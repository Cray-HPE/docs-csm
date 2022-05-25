# Compute Node Boot Issue Symptom: Duplicate Address Warnings and Declined DHCP Offers in Logs

If the DHCP and node logs show duplicate address warnings and indicate declined DHCP offers, it may be because another component owns the IP address that DHCP is trying to assign to a node. If this happens, the node will not accept the IP address and will repeatedly submit a DHCP discover request. As a result, the node and DHCP become entangled in a loop of requesting and rejecting. This often happens when DHCP is statically assigning IP addresses to nodes, but the assigned IP address for a node has already been assigned to another component.

### Symptoms

This scenario results in node logs similar to the following:

**Node log:**

```bash
[   97.946332] dracut Warning: Duplicate address detected for 10.100.160.195 while doing dhcp. retrying
[   97.789015] dracut-initqueue[604]: dracut Warning: Duplicate address detected for 10.100.160.195 while doing dhcp. \
retrying
[  108.007243] dracut Warning: Duplicate address detected for 10.100.160.195 while doing dhcp. retrying
[  107.873650] dracut-initqueue[604]: dracut Warning: Duplicate address detected for 10.100.160.195 while doing dhcp. \
retrying
[  110.082877] dracut Warning: Duplicate address detected for 10.100.160.195 while doing dhcp. retrying
```

**DHCP log:**

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
-   Check the Address Resolution Protocol \(ARP\) cache using the `arp` command. Because it is a cache, it is possible that IP addresses can age out of the cache, so the IP address may not be present. If the address that is failing to be assigned is in the ARP cache, and it is assigned to a node with a different MAC address, then that is confirmation that this problem has occurred.

    ```bash
    ncn-m001# arp
    ```

    Example output:

    ```
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

    [...]
    ```


### Resolution

Force the component that has been assigned an incorrect IP address to request another one. This may involve powering that component down and then back up.

