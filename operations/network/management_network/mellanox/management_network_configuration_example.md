# Management Network Configuration Example

Create the CAN VRF.

(`switch#`) Aruba

```console
vrf CAN
```

Move interfaces into CAN VRF.

* Existing CAN interface configurations will be deleted once the interface is moved into the new VRF; the deleted configurations must be re-applied.
* NOTE: These are example configurations only; most implementations of Bi-CAN will be different.

(`switch#`) Aruba primary configuration

```console
interface vlan 7
    vsx-sync active-gateways
    vrf attach CAN
    description CAN
    ip mtu 9198
    ip address 128.55.176.2/23
    active-gateway ip mac 12:00:00:00:6b:00
    active-gateway ip 128.55.176.1
    ip ospf 2 area 0.0.0.210
```

(`switch#`) Aruba secondary configuration

```console
interface vlan 7
    vsx-sync active-gateways
    vrf attach CAN
    description CAN
    ip mtu 9198
    ip address 128.55.176.3/23
    active-gateway ip mac 12:00:00:00:6b:00
    active-gateway ip 128.55.176.1
    ip ospf 2 area 0.0.0.210
```

Create BGP process in CAN VRF.

* A new BGP process will need to be running in the CAN VRF; this will peer with the CAN IP addresses on the NCN workers.
* These are example configurations only; the neighbors below are the IP addresses of the CAN interface on the workers.

(`switch#`) Aruba configuration

```console
router bgp 65533
vrf CAN
    maximum-paths 8
        neighbor 128.55.176.3 remote-as 65533
        neighbor 128.55.176.25 remote-as 65534
        neighbor 128.55.176.25 passive
        neighbor 128.55.176.26 remote-as 65534
        neighbor 128.55.176.26 passive
        neighbor 128.55.176.27 remote-as 65534
        neighbor 128.55.176.27 passive
```

Setup customer edge router

* The customer edge router has to be certified by the Slingshot team.
* The configuration for this is going to be unique for most customers.
* Below is an example configuration of a single Arista switch with a static LAG to a single Slingshot switch.

(`switch#`) Arista LAG configuration

```console
interface Ethernet24/1
   mtu 9214
   flowcontrol send on
   flowcontrol receive on
   speed forced 100gfull
   error-correction encoding reed-solomon
   channel-group 1 mode on

interface Ethernet25/1
   mtu 9214
   flowcontrol send on
   flowcontrol receive on
   speed forced 100gfull
   error-correction encoding reed-solomon
   channel-group 1 mode on

interface Port-Channel1
   mtu 9214
   switchport access vlan 2
   switchport trunk native vlan 2
   switchport mode trunk
```

* VLAN 2 is being used for the HSN network.

(`switch#`) VLAN 2 configuration

```console
interface Vlan2
   ip address 10.101.10.1/24
```

* The following is the Arista BGP configuration for peering over the HSN.
    * The BGP neighbor IP addresses used are HSN IP addresses of worker nodes.

(`ncn-w#`) Example HSN IP configuration

```bash
ip a show hsn0
```

Example output:

```text
8: hsn0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq state UP group default qlen 1000
    link/ether 02:00:00:00:00:0d brd ff:ff:ff:ff:ff:ff
    inet 10.101.10.10/24 scope global hsn0
       valid_lft forever preferred_lft forever
    inet6 fe80::ff:fe00:d/64 scope link
       valid_lft forever preferred_lft forever
```

* Create a prefix list and `route-map` to only accept routes from the HSN network.

(`switch#`) Arista BGP configuration

```console
ip prefix-list HSN seq 10 permit 10.101.10.0/24 ge 24

route-map HSN permit 5
   match ip address prefix-list HSN

 router bgp 65534
   maximum-paths 32
   neighbor 10.101.10.10 remote-as 65533
   neighbor 10.101.10.10 transport connection-mode passive
   neighbor 10.101.10.10 route-map HSN in
   neighbor 10.101.10.11 remote-as 65533
   neighbor 10.101.10.11 transport connection-mode passive
   neighbor 10.101.10.11 route-map HSN in
   neighbor 10.101.10.12 remote-as 65533
   neighbor 10.101.10.12 transport connection-mode passive
   neighbor 10.101.10.12 route-map HSN in
```

Configure MetalLB

MetalLB must be configured to peer with the new CAN VRF interfaces and the new HSN interface on the customer edge router.

```yaml
apiVersion: v1
data:
  config: |
    peers:
    - peer-address: 10.252.0.2
      peer-asn: 65533
      my-asn: 65533
    - peer-address: 10.252.0.3
      peer-asn: 65533
      my-asn: 65533
    - peer-address: 10.101.8.2
      peer-asn: 65533
      my-asn: 65536
    - peer-address: 10.101.8.3
      peer-asn: 65533
      my-asn: 65536
    - peer-address: 10.101.10.1
      peer-asn: 65534
      my-asn: 65533
    address-pools:
    - name: customer-access
      protocol: bgp
      addresses:
      - 10.101.8.128/25
    - name: customer-access-static
      protocol: bgp
      addresses:
      - 10.101.8.112/28
    - name: customer-high-speed
      protocol: bgp
      addresses:
      - 10.101.10.128/25
    - name: customer-high-speed-static
      protocol: bgp
      addresses:
      - 10.101.10.112/28
    - name: hardware-management
      protocol: bgp
      addresses:
      - 10.94.100.0/24
    - name: node-management
      protocol: bgp
      addresses:
      - 10.92.100.0/24
```

Verify BGP and routes

* Once MetalLB is configured, the BGP peers on the customer edge router and the CAN VRF should be established.

(`sw-edge01(config-router-bgp)#`) Arista edge router

```console
show ip bgp summary
```

Example output:

```text
BGP summary information for VRF default
Router identifier 192.168.50.50, local AS number 65534
Neighbor Status Codes: m - Under maintenance
  Neighbor         V  AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State  PfxRcd PfxAcc
  10.101.10.10     4  65533             23        12    0    0 00:03:49 Estab  14     14
  10.101.10.11     4  65533             25        11    0    0 00:03:49 Estab  16     16
  10.101.10.12     4  65533             23        11    0    0 00:03:49 Estab  14     14
```

* The Arista routing table should now include the external IP addresses exposed by MetalLB.
* The on site network team is responsible for distributing these routes to the rest of their network.

(`sw-edge01(config)#`)

```console
show ip route
```

Example output:

```text
B E    10.101.8.113/32 [200/0] via 10.101.10.10, Vlan2
                                via 10.101.10.11, Vlan2
                                via 10.101.10.12, Vlan2
 B E    10.101.8.128/32 [200/0] via 10.101.10.10, Vlan2
                                via 10.101.10.11, Vlan2
                                via 10.101.10.12, Vlan2
 B E    10.101.8.129/32 [200/0] via 10.101.10.10, Vlan2
                                via 10.101.10.11, Vlan2
                                via 10.101.10.12, Vlan2
 B E    10.101.8.130/32 [200/0] via 10.101.10.10, Vlan2
                                via 10.101.10.11, Vlan2
                                via 10.101.10.12, Vlan2
 O      10.101.8.0/24 [110/20] via 192.168.75.3, Ethernet1/1
                               via 192.168.75.1, Ethernet2/1
```

(`sw-spine-001 [standalone: master] #`) Example of how BGP routes would look like in the switch located in the High-speed network.

```console
show ip bgp vrf CAN summary
```

Example output:

```text
VRF name                  : CAN
BGP router identifier     : 192.168.75.1
local AS number           : 65533
BGP table version         : 665
Main routing table version: 665
IPV4 Prefixes             : 44
IPV6 Prefixes             : 0
L2VPN EVPN Prefixes       : 0

------------------------------------------------------------------------------------------------------------------
Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
------------------------------------------------------------------------------------------------------------------
10.101.8.8        4    65536        24725     27717     665       0      0      0:11:52:43    ESTABLISHED/14
10.101.8.9        4    65536        24836     27692     665       0      0      0:08:44:20    ESTABLISHED/16
10.101.8.10       4    65536        24704     27741     665       0      0      0:08:44:18    ESTABLISHED/14
```

Configure default routes on workers.

(`ncn-w#`) The default route will need to change on the workers so they send their traffic out of the HSN interface.

```bash
ip route replace default via 10.101.10.1 dev hsn0
```

(`ncn-w#`) In order to make it persistent, create an `ifcfg` file for `hsn0` and remove the old `vlan7` default route.

```bash
mv /etc/sysconfig/network/ifroute-bond0.cmn0 /etc/sysconfig/network/ifroute-bond0.cmn0.old
echo "default 10.101.10.1 - -" > /etc/sysconfig/network/ifroute-hsn0
```

(`ncn-w#`) Verify the routing table.

```bash
ip route
```

Example output:

```text
default via 10.101.10.1 dev hsn0
```

(`ncn-w#`) Verify external connectivity.

```bash
ping 8.8.8.8 -c 1
```

Example output:

```text
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=110 time=13.6 ms
```

There should now be external connectivity from outside the Shasta system to the external services offered by MetalLB over the HSN.

(`ncn-mw#`) Verify this is going over the HSN by a `traceroute`.

```bash
traceroute 10.101.8.113
```

Example output:

```text
traceroute to 10.101.8.113 (10.101.8.113), 64 hops max, 52 byte packets
 1  172.30.252.234 (172.30.252.234)  37.652 ms  37.930 ms  36.574 ms
 2  10.103.255.228 (10.103.255.228)  37.684 ms  37.180 ms  36.765 ms
 3  10.103.255.249 (10.103.255.249)  36.531 ms  38.350 ms  39.593 ms
 4  172.30.254.219 (172.30.254.219)  38.543 ms  38.699 ms  40.811 ms
 5  172.30.254.212 (172.30.254.212)  37.931 ms  37.347 ms  40.404 ms
 6  172.30.254.243 (172.30.254.243)  47.029 ms  39.014 ms  38.292 ms
 7  172.30.254.134 (172.30.254.134)  42.197 ms  37.267 ms  38.522 ms
 8  172.30.254.130 (172.30.254.130)  39.562 ms  38.094 ms  39.500 ms
 9  10.101.15.254 (10.101.15.254)  37.616 ms  37.741 ms  37.529 ms
10  10.101.15.178 (10.101.15.178)  39.465 ms  37.052 ms  36.734 ms
11  10.101.8.113 (10.101.8.113)  39.937 ms  38.565 ms  36.524 ms
```

(`ncn-mw#`) Administrators can also listen on all the HSN interfaces for `ping`/`traceroute` while pinging the external facing
IP address (`10.101.8.113` in this example).

```bash
nodes=$(kubectl get nodes| awk '{print $1}' | grep  ncn-w | awk -vORS=, '{print $1}'); pdsh -w ${nodes} "tcpdump -envli hsn0 icmp"
```

Example output:

```text
ncn-w002: tcpdump: listening on hsn0, link-type EN10MB (Ethernet), capture size 262144 bytes
ncn-w003: tcpdump: listening on hsn0, link-type EN10MB (Ethernet), capture size 262144 bytes
ncn-w001: tcpdump: listening on hsn0, link-type EN10MB (Ethernet), capture size 262144 bytes
ncn-w003: 04:59:35.826691 98:5d:82:71:ba:2d > 02:00:00:00:00:1e, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 54, id 951, offset 0, flags [none], proto ICMP (1), length 84)
ncn-w003:     172.25.64.129 > 10.101.8.113: ICMP echo request, id 37368, seq 0, length 64
ncn-w003: 04:59:36.825591 98:5d:82:71:ba:2d > 02:00:00:00:00:1e, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 54, id 33996, offset 0, flags [none], proto ICMP (1), length 84)
```

[Back to Index](../README.md)
