# PXE boot Troubleshooting

This page is designed to cover various issues that arise when trying to pxe boot nodes in a Shasta system.

In order for PXE booting to successfully work, the MGMT switches need to be configured correctly.

# Configuration required for PXE booting

To successfully pxe boot nodes, the following is required.

- The IP helper-address must be configured on VLAN 1,2,4,7.  This will be where the layer 3 gateway exists (spine or agg)
- The virtual-IP/VSX/MAGP IP must be configured on VLAN 1,2,4,7.
- There must be a static route pointing to the TFTP server (Aruba Only).
- M001 needs an active gateway on VLAN1 this can be identified from MTL.yaml generated from CSI.
- M001 needs an IP helper-address on VLAN1 pointing to 10.92.100.222. 

snippet of MTL.yaml
```
  name: network_hardware
  net-name: MTL
  vlan_id: 0
  comment: ""
  gateway: 10.1.0.1
```
# Aruba Configuration

Check the configuration for ```interface vlan x```
This configuration will be the same on BOTH Switches (except the ```ip address```).
You'll see that there is an ```active-gateway``` and ```ip helper-address``` configured.
```
sw-spine-002(config)# show run int vlan 1
interface vlan1
    vsx-sync active-gateways
    ip address 10.1.0.3/16
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.1.0.1
    ip mtu 9198
    ip helper-address 10.92.100.222
    exit

sw-spine-002(config)# show run int vlan 2
interface vlan2
    vsx-sync active-gateways
    ip address 10.252.0.3/17
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.252.0.1
    ip mtu 9198
    ip helper-address 10.92.100.222
    exit

sw-spine-002(config)# show run int vlan 4
interface vlan4
    vsx-sync active-gateways
    ip address 10.254.0.3/17
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.254.0.1
    ip mtu 9198
    ip helper-address 10.94.100.222
    exit

sw-spine-002(config)# show run int vlan 7
interface vlan7
    vsx-sync active-gateways
    ip address 10.103.13.3/24
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.103.13.111
    ip mtu 9198
    ip helper-address 10.92.100.222
    exit
```

If any of this configuration is missing, you'll need to update it to BOTH switches.
```
sw-spine-002# conf t
sw-spine-002(config)# int vlan 1
sw-spine-002(config-if-vlan)# ip helper-address 10.92.100.222
sw-spine-002(config-if-vlan)# active-gateway ip mac 12:01:00:00:01:00
sw-spine-002(config-if-vlan)# active-gateway ip 10.1.0.1

sw-spine-002# conf t
sw-spine-002(config)# int vlan 2
sw-spine-002(config-if-vlan)# ip helper-address 10.92.100.222
sw-spine-002(config-if-vlan)# active-gateway ip mac 12:01:00:00:01:00
sw-spine-002(config-if-vlan)# active-gateway ip 10.252.0.1

sw-spine-002# conf t
sw-spine-002(config)# int vlan 4
sw-spine-002(config-if-vlan)# ip helper-address 10.94.100.222
sw-spine-002(config-if-vlan)# active-gateway ip mac 12:01:00:00:01:00

sw-spine-002# conf t
sw-spine-002(config)# int vlan 7
sw-spine-002(config-if-vlan)# ip helper-address 10.92.100.222
sw-spine-002(config-if-vlan)# active-gateway ip mac 12:01:00:00:01:00
sw-spine-002(config-if-vlan)# active-gateway ip xxxxxxx
sw-spine-002(config-if-vlan)# write mem
```

Verify the route to the TFTP server is in place.
This is a static route to get to the TFTP server via a worker node.
You can get the worker node IP from NMN.yaml from CSI generated data.
```
  - ip_address: 10.252.1.9
    name: ncn-w001
    comment: x3000c0s4b0n0
    aliases:
```

```
sw-spine-002(config)# show ip route static

Displaying ipv4 routes selected for forwarding

'[x/y]' denotes [distance/metric]

0.0.0.0/0, vrf default
	via  10.103.15.209,  [1/0],  static
10.92.100.60/32, vrf default
	via  10.252.1.7,  [1/0],  static
```
You can see that the route is ```10.92.100.60/32 via 10.252.1.7``` with ```10.252.1.7``` being the worker node.

If that static route is missing you'll need to add it.
```
sw-spine-001(config)# ip route 10.92.100.60/32 10.252.1.7
```

# Mellanox Configuration

Check the configuration for ```interface vlan 1```
This configuration will be the same on BOTH Switches (except the ```ip address```).
You'll see that there is ```magp``` and ```ip dhcp relay``` configured.

```
sw-spine-001 [standalone: master] # show run int vlan 1
interface vlan 1
interface vlan 1 ip address 10.1.0.2/16 primary
interface vlan 1 ip dhcp relay instance 2 downstream
interface vlan 1 magp 1
interface vlan 1 magp 1 ip virtual-router address 10.1.0.1
interface vlan 1 magp 1 ip virtual-router mac-address 00:00:5E:00:01:01
```
If this configuration is missing, you'll need to add it to BOTH switches.
```
sw-spine-001 [standalone: master] # conf t
sw-spine-001 [standalone: master] (config) # interface vlan 1 magp 1
sw-spine-001 [standalone: master] (config interface vlan 1 magp 1) # ip virtual-router address 10.1.0.1
sw-spine-001 [standalone: master] (config interface vlan 1 magp 1) # ip virtual-router mac-address 00:00:5E:00:01:01
sw-spine-001 [standalone: master] # conf t
sw-spine-001 [standalone: master] (config) # ip dhcp relay instance 2 vrf default
sw-spine-001 [standalone: master] (config) # ip dhcp relay instance 2 address 10.92.100.222
sw-spine-001 [standalone: master] (config) # interface vlan 2 ip dhcp relay instance 2 downstream
```
You can then verify the VLAN 1 MAGP configuration.
```
sw-spine-001 [standalone: master] # show magp 1

MAGP 1:
  Interface vlan: 1
  Admin state   : Enabled
  State         : Master
  Virtual IP    : 10.1.0.1
  Virtual MAC   : 00:00:5E:00:01:01
```
Verify the DHCP relay configuration

```
sw-spine-001 [standalone: master] (config) # show ip dhcp relay instance 2

VRF Name: default

DHCP Servers:
  10.92.100.222

DHCP relay agent options:
  always-on         : Disabled
  Information Option: Disabled
  UDP port          : 67
  Auto-helper       : Disabled

-------------------------------------------
Interface   Label             Mode
-------------------------------------------
vlan1       N/A               downstream
vlan2       N/A               downstream
vlan7       N/A               downstream
```

Verify that the route to the TFTP server and the route for the ingress gateway are available.

```
sw-spine-001 [standalone: master] # show ip route 10.92.100.60

Flags:
  F: Failed to install in H/W
  B: BFD protected (static route)
  i: BFD session initializing (static route)
  x: protecting BFD session failed (static route)
  c: consistent hashing
  p: partial programming in H/W

VRF Name default:
  ------------------------------------------------------------------------------------------------------
  Destination       Mask              Flag     Gateway           Interface        Source     AD/M
  ------------------------------------------------------------------------------------------------------
  default           0.0.0.0           c        10.101.15.161     eth1/12          static     1/1
  10.92.100.60      255.255.255.255   c        10.252.0.5        vlan2            bgp        200/0
                                      c        10.252.0.6        vlan2            bgp        200/0
                                      c        10.252.0.7        vlan2            bgp        200/0
```
```
sw-spine-001 [standalone: master] # show ip route 10.92.100.71

Flags:
  F: Failed to install in H/W
  B: BFD protected (static route)
  i: BFD session initializing (static route)
  x: protecting BFD session failed (static route)
  c: consistent hashing
  p: partial programming in H/W

VRF Name default:
  ------------------------------------------------------------------------------------------------------
  Destination       Mask              Flag     Gateway           Interface        Source     AD/M
  ------------------------------------------------------------------------------------------------------
  default           0.0.0.0           c        10.101.15.161     eth1/12          static     1/1
  10.92.100.71      255.255.255.255   c        10.252.0.5        vlan2            bgp        200/0
                                      c        10.252.0.6        vlan2            bgp        200/0
                                      c        10.252.0.7        vlan2            bgp        200/0
```
If these routes are missing please see the [BGP](400-SWITCH-BGP-NEIGHBORS.md) page.

# Next steps

If your configuration looks good, and you are still not able to pxe boot there are some other things to try.

### Restart BSS
If while watching an NCN boot attempt you see the following output on the console during PXE 
(specifically the 404 error at the bottom):

```text
https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript...X509 chain 0x6d35c548 added X509 0x6d360d68 "eniac.dev.cray.com"
X509 chain 0x6d35c548 added X509 0x6d3d62e0 "Platform CA - L1 (a0b073c8-5c9c-4f89-b8a2-a44adce3cbdf)"
X509 chain 0x6d35c548 added X509 0x6d3d6420 "Platform CA (a0b073c8-5c9c-4f89-b8a2-a44adce3cbdf)"
EFITIME is 2021-02-26 21:55:04
HTTP 0x6d35da88 status 404 Not Found
```

Rollout a restart of the BSS deployment from any other NCN (likely ncn-m002 if you're executing the ncn-m001 reboot):
```bash
ncn-m002# kubectl -n services rollout restart deployment cray-bss
deployment.apps/cray-bss restarted
```
Then wait for this command to return (it will block showing status as the pods are refreshed):
```bash
ncn-m002# # kubectl -n services rollout status deployment cray-bss
Waiting for deployment "cray-bss" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "cray-bss" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "cray-bss" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "cray-bss" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "cray-bss" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "cray-bss" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "cray-bss" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "cray-bss" rollout to finish: 1 old replicas are pending termination...
deployment "cray-bss" successfully rolled out
```

Then reboot the NCN one more time.

### Restart KEA
In some cases rebooting the KEA pod has resolved pxe issues.

Get KEA pod
```
ncn-m002# kubectl get pods -n services | grep kea
cray-dhcp-kea-6bd8cfc9c5-m6bgw                                 3/3     Running     0          20h
```
Delete Pod
```
ncn-m002# kubectl delete pods -n services cray-dhcp-kea-6bd8cfc9c5-m6bgw
```


