# PXE Booting Runbook

PXE booting is a key component of a working Shasta system. There are a lot of different components involved, which increases the complexity.
This guide runs through the most common issues and shows what is needed in order to have a successful PXE boot.

1. [NCNs on install](#ncns-on-install)<br>
2. [`ncn-m001` on reboot or NCN boot](#ncn-m001-on-reboot)<br>
    2.1. [Verify DHCP packets can be forwarded from the workers to the MTL network (VLAN1)](#Verify-DHCP-packets)<br>
    2.2. [Verify BGP](#verify-bgp)<br>
    2.3. [Verify route to TFTP](#verify-route-to-tftp)<br>
    2.4. [Test TFTP traffic (Aruba Only)](#test-tftp-traffic)<br>
    2.5. [Check DHCP lease is getting allocated](#check-dhcp-lease)<br>
    2.6. [Verify the DHCP traffic on the Workers](#verify-the-dhcp-traffic)<br>
    2.7. [Verify the switches are forwarding DHCP traffic.](#verify-the-switches)<br>
3. [Computes/UANs/Application Nodes](#computes-uans-applications-nodes)<br>

<a name="ncns-on-install"></a>

## 1. NCNs on install


* Verify the DNSMASQ configuration file matches what is configured on the switches.
    * Here is a DNSMASQ configuration file for the Metal network (VLAN1). As you can see, the router IP address is `10.1.0.1`. This has to match what the IP address is on the switches doing the routing for the MTL network. This is most commonly on the spines. This configuration is commonly missed on the CSI input file.

>MTL dnsmasq file

```text
# MTL:
server=/mtl/
address=/mtl/
domain=mtl,10.1.1.0,10.1.1.233,local
dhcp-option=interface:bond0,option:domain-search,mtl
interface=bond
interface-name=pit.mtl,bond
# This needs to point to the LiveCD IP address for provisioning in bare-metal environments.
dhcp-option=interface:bond0,option:dns-server,10.1.1.
dhcp-option=interface:bond0,option:ntp-server,10.1.1.
# This must point at the router for the network; the L3/IP address for the VLAN.
dhcp-option=interface:bond0,option:router,10.1.0.
dhcp-range=interface:bond0,10.1.1.33,10.1.1.233,10m
```

* Here is an example of what the spine switch configuration should be.



>Mellanox Configuration

```
sw-spine-001 [standalone: master] # show run int vlan 1
interface vlan 1
interface vlan 1 ip address 10.1.0.2/16 primary
interface vlan 1 ip dhcp relay instance 2 downstream
interface vlan 1 magp 1
interface vlan 1 magp 1 ip virtual-router address 10.1.0.
interface vlan 1 magp 1 ip virtual-router mac-address
00:00:5E:00:01:
```
```
sw-spine-002 [standalone: master] # show run int vlan 1
interface vlan 1
interface vlan 1 ip address 10.1.0.3/16 primary
interface vlan 1 ip dhcp relay instance 2 downstream
interface vlan 1 magp 1
interface vlan 1 magp 1 ip virtual-router address 10.1.0.
interface vlan 1 magp 1 ip virtual-router mac-address
00:00:5E:00:01:
```

>Aruba Configuration

```
sw-spine-001# show run int vlan 1
interface vlan
vsx-sync active-gateways
ip address 10.1.0.2/
active-gateway ip mac 12:01:00:00:01:
active-gateway ip 10.1.0.
ip mtu 9198
ip bootp-gateway 10.1.0.
ip helper-address 10.92.100.
exit
```

```
sw-spine-002# show run int vlan 1
interface vlan
vsx-sync active-gateways
ip address 10.1.0.3/
active-gateway ip mac 12:01:00:00:01:
active-gateway ip 10.1.0.
ip mtu 9198
ip helper-address 10.92.100.
exit
```
* You should be able to ping the MTL router from `ncn-m001`.

<a name="ncn-m001-on-reboot"></a>

## 2. `ncn-m001` on reboot or NCN boot


* Common Error messages.

    * `2021-04-19 23:27:09 PXE-E18: Server response timeout.`
    * `2021-02-02 17:06:13 PXE-E99: Unexpected network error.`

* Verify the ip helper-address on VLAN 1 on the switches. This is the same configuration as above ^ "Mellanox Config" and "Aruba Config"

<a name="Verify-DHCP-packets"></a>
## 2.1. Verify DHCP packets can be forwarded from the workers to the MTL network (VLAN1)


* If the Worker nodes cannot reach the metal network DHCP will fail.
* ALL WORKERS need to be able to reach the MTL network!
* This can normally be achieved by having a default route
* TEST

```bash
ncn-w# ping 10.1.0.
PING 10.1.0.1 (10.1.0.1) 56(84) bytes of data.
64 bytes from 10.1.0.1: icmp_seq=1 ttl=64 time=0.361 ms
64 bytes from 10.1.0.1: icmp_seq=2 ttl=64 time=0.145 ms
```

* If this fails you may have a misconfigured CAN or need to add a route to the MTL network.

```bash
ncn-w# ip route add 10.1.0.0/16 via 10.252.0.1 dev vlan
```

<a name="verify-bgp"></a>
## 2.2. Verify BGP


* Verify the BGP neighbors are in the established state on BOTH the switches.

>Aruba BGP

```
sw-spine-002# show bgp ipv4 u s
VRF : default
BGP Summary
-----------
 Local AS               : 65533        BGP Router Identifier  : 10.252.0.3
 Peers                  : 4            Log Neighbor Changes   : No
 Cfg. Hold Time         : 180          Cfg. Keep Alive        : 60
 Confederation Id       : 0

 Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
 10.252.0.2      65533       45052   45044   02m:02w:02d  Established   Up
 10.252.1.7      65533       78389   90090   02m:02w:02d  Established   Up
 10.252.1.8      65533       78384   90059   02m:02w:02d  Established   Up
 10.252.1.9      65533       78389   90108   02m:02w:02d  Established   Up

```

>Mellanox BGP

```
sw-spine-001 [standalone: master] # show ip bgp summary

VRF name                  : default
BGP router identifier     : 10.252.0.2
local AS number           : 65533
BGP table version         : 39
Main routing table version: 39
IPV4 Prefixes             : 18
IPV6 Prefixes             : 0
L2VPN EVPN Prefixes       : 0

------------------------------------------------------------------------------------------------------------------
Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
------------------------------------------------------------------------------------------------------------------
10.252.1.7        4    65533        18018     20690     39        0      0      6:05:54:02    ESTABLISHED/6
10.252.1.8        4    65533        18014     20694     39        0      0      6:05:54:03    ESTABLISHED/6
10.252.1.9        4    65533        18010     20671     39        0      0      6:05:52:03    ESTABLISHED/6
```

<a name="verify-route-to-tftp"></a>

## 2.3. Verify route to TFTP

* On BOTH Aruba switches we need a single route to the TFTP server 10.92.100.60. This is needed because there are issues with Aruba
ECMP hashing and TFTP traffic.

```
sw-spine-002# show ip route 10.92.100.60

Displaying ipv4 routes selected for forwarding

'[x/y]' denotes [distance/metric]

10.92.100.60/32, vrf default, tag 0
    via  10.252.1.9,  [70/0],  bgp
```

* This route can be a static route or a BGP route that is pinned to a single worker. (1.4.2 patch introduces the BGP pinned route)
* Verify that you can ping the next hop of this route.
* For the example above we would ping 10.252.1.9. If this is not reachable this is your problem.

<a name="test-tftp-traffic"></a>
## 2.4. Test TFTP traffic (Aruba Only)


* You can test the TFTP traffic by trying to download the ipxe.efi binary.
* Log into the leaf switch and try to download the iPXE binary.
* This requires that the leaf switch can talk to the TFTP server "10.92.100.60"

```
sw-leaf-001# start-shell
sw-leaf-001:~$ sudo su
sw-leaf-001:/home/admin# tftp 10.92.100.
tftp> get ipxe.efi
Received 1007200 bytes in 2.2 seconds
tftp> get ipxe.efi
Received 1007200 bytes in 2.2 seconds
tftp> get ipxe.efi
Received 1007200 bytes in 2.2 seconds
```

* You can see here that the ipxe.efi binary is downloaded three times in a row. When we have seen issues with ECMP hashing this
would fail intermittently.

<a name="check-dhcp-lease"></a>
## 2.5. Check DHCP lease is getting allocated

* Check the KEA logs and verify that the lease is getting allocated.
```bash
ncn# kubectl logs -n services pod/$(kubectl get -n services pods |
         grep kea | head -n1 | cut -f 1 -d ' ') -c cray-dhcp-kea
```

```
2021-04-21 00:13:05.416 INFO  [kea-dhcp4.leases/24.139710796402304] DHCP4_LEASE_ALLOC [hwtype=1 02:23:28:01:30:10], cid=[00:78:39:30:30:30:63:31:73:30:62:31], tid=0x21f2433a: lease 10.104.0.23 has been allocated for 300 seconds
```

* Here we can see that KEA is allocating a lease to `10.104.0.23`.
* The lease MUST say `DHCP4_LEASE_ALLOC`. If it says `DHCP4_LEASE_ADVERT`, there is likely a problem. Restarting KEA will fix this issue most of the time.

```
2021-06-21 16:44:31.124 INFO  [kea-dhcp4.leases/18.139837089017472] DHCP4_LEASE_ADVERT [hwtype=1 14:02:ec:d9:79:88], cid=[no info], tid=0xe87fad10: lease 10.252.1.16 will be advertised
```

<a name="verify-the-dhcp-traffic"></a>
## 2.6. Verify the DHCP traffic on the Workers


* We have ran into issues on HPE servers and Aruba switches where the source address of the DHCP Offer is the Metallb address
of KEA `10.92.100.222`. The source address of the DHCP Reply/Offer **needs** to be the address of the VLAN interface on the
Worker.
* Here is how to look at DHCP traffic on the workers.

```bash
ncn-w# tcpdump -envli bond0 port 67 or 68
```

* You are looking for the source IP address of the DHCP Reply/Offer.

```
10.252.1.9.67 > 255.255.255.255.68: BOOTP/DHCP, Reply, length 309, hops 1, xid 0x98b0982e, Flags [Broadcast]
      Your-IP 10.252.1.17
      Server-IP 10.92.100.60
      Gateway-IP 10.252.0.1
      Client-Ethernet-Address 14:02:ec:d9:79:88
      file "ipxe.efi"[|bootp]
```

* If the Source IP address of the DHCP Reply/Offer is the MetalLB IP address, the DHCP packet will never make it out of the NCN. An example of
this is below.

```
10.92.100.222.116 > 255.255.255.255.68: BOOTP/DHCP, Reply, length 309, hops 1, xid 0x260ea655, Flags [Broadcast]
  Your-IP 10.252.1.14
  Server-IP 10.92.100.60
  Gateway-IP 10.252.0.4
  Client-Ethernet-Address 14:02:ec:d9:79:88
  file "ipxe.efi"[|bootp]
```

* If you run into this, the only solution that we have found so far is restarting KEA and making sure that it gets moved to a different
worker. We believe this has something to do with conntrack.

<a name="verify-the-switches"></a>
## 2.7. Verify the switches are forwarding DHCP traffic.

* If you still cannot PXE boot, the IP-Helper may be breaking on the switch.
* On Aruba, Dell, and Mellanox switches we have seen the IP-Helpers get stuck and stop forwarding DHCP traffic to the client.
    * The solutions vary from vendor to vendor.
    * On an Aruba or Mellanox switch, delete the entire VLAN configuration and re-apply it, in order for the DHCP traffic to come back.
    * On a Dell switch, do a reboot in order to restore DHCP traffic.
* The underlying cause of IP-Helper breaking is not yet known.

<a name="computes-uans-applications-nodes"></a>
## 3. Compute Nodes/UANs/Application Nodes

* The following are required for compute node PXE booting.
    * [Verify BGP](#ncns-on-install)<br>
    * [Verify route to TFTP](#verify-route-to-tftp)
    * [Test TFTP traffic](#test-tftp-traffic)
    * [Check DHCP lease is getting allocated](#check-dhcp-lease)
    * [Verify the DHCP traffic on the Workers](#verify-the-dhcp-traffic)
    * [Verify the switches are forwarding DHCP traffic](#verify-the-switches)
* Verify the IP-Helpers on the VLAN the computes nodes are booting over. This is typically VLAN 2 or VLAN 2xxx (MTN Computes)
* If the compute nodes make it past PXE and go into the PXE shell you can verify DNS and connectivity.

```
iPXE> dhcp
Configuring (net0 98:03:9b:a8:60:88).................. No configuration methods succeeded (http://ipxe.org/040ee186)
Configuring (net1 b4:2e:99:be:1a:37)...... ok

iPXE> show dns
net1.dhcp/dns:ipv4 = 10.92.100.225

iPXE> nslookup address api-gw-service-nmn.local
iPXE> echo ${address}
10.92.100.71
```

