# Verify and Update BGP neighbors

This page will detail how to manually configure and verify BGP neighbors on the management switches.

- You will not have BGP peers until ```install.sh``` is ran.  This is where MetalLB is deployed.
- How do I check the status of the BGP neighbors?
- Log into the spine switches and run `show bgp ipv4 unicast summary` for Aruba/HPE switches and `show ip bgp summary` for Mellanox.
- Are my Neighbors stuck in IDLE? running `clear ip bgp all` on the mellanox and `clear bgp *` on the Arubas will restart the BGP process, this process may need to be done when a system is reinstalled.  If only some neighbors are showing `ESTABLISHED` you may need to run the command multiple times for all the BGP peers to come up. 
- The BGP neighbors will be the worker NCN IPs on the NMN (node management network) (VLAN002). If your system is using HPE/Aruba, one of the neighbors will be the other spine switch.
- On the Aruba/HPE switches properly configured BGP will look like the following.

# Generate MetalLB configmap
- Depending on the network architecture of your system you may need to peer with switches other than the spines.  CSI has a BGP peers argument that accepts 'aggregation' as an option, if no option is defined it will default to the spines as being the MetalLB peers. 

CSI cli arguments with ```--bgp-peers aggregation```
```
linux# ~/src/mtl/cray-site-init/bin/csi config init --bootstrap-ncn-bmc-user root --bootstrap-ncn-bmc-pass initial0 --ntp-pool cfntp-4-1.us.cray.com,cfntp-4-2.us.cray.com --can-external-dns 10.103.8.113 --can-gateway 10.103.8.1 --site-ip 172.30.56.2/24 --site-gw 172.30.48.1 --site-dns 172.30.84.40 --site-nic em1 --system-name odin --bgp-peers aggregation
```

# Automated Process
- There is an automated script to update the BGP configuration on both the Mellanox and Aruba switches.  This script is installed into the `$PATH` by the `metal-net-scripts` package
- The scripts are named `mellanox_set_bgp_peers.py` and `aruba_set_bgp_peers.py`
- These scripts pull in data from CSI generated `.yaml` files. The files required are ```CAN.yaml, HMN.yaml, HMNLB.yaml, NMNLB.yaml, NMN.yaml```, these exist in the `networks/` subdirectory of the generated configs.
- In order for these scripts to work the following commands will need to be present on the switches.

Aruba
```
sw-spine-001(config)# https-server rest access-mode read-write
```
Mellanox
```
sw-spine-001 [standalone: master] > enable
sw-spine-001 [standalone: master] # configure terminal
sw-spine-001 [standalone: master] (config) # json-gw enable
```
Script Usage
```
USAGE: - <Spine01/Agg01> <Spine02/Agg02> <Path to CSI generated network files>

       - The IPs used should be Node Management Network IPs (NMN), these IPs will be what's used for the BGP Router-ID.

       - The path must include CAN.yaml', 'HMN.yaml', 'HMNLB.yaml', 'NMNLB.yaml', 'NMN.yaml

Example: ./aruba_set_bgp_peers.py 10.252.0.2 10.252.0.3 /var/www/ephemeral/prep/redbull/networks
```
- After this script is run you will need to verify the configuration and verify the BGP peers are ```ESTABLISHED```

# Manual Process

```
sw-spine-001# show bgp ipv4 unicast summary
VRF : default
BGP Summary
-----------
 Local AS               : 65533        BGP Router Identifier  : 10.252.0.1     
 Peers                  : 4            Log Neighbor Changes   : No             
 Cfg. Hold Time         : 180          Cfg. Keep Alive        : 60             

 Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
 10.252.0.3      65533       31457   31474   00m:02w:04d  Established   Up         
 10.252.2.8      65533       54730   62906   00m:02w:04d  Established   Up         
 10.252.2.9      65533       54732   62927   00m:02w:04d  Established   Up         
 10.252.2.18     65533       54732   62911   00m:02w:04d  Established   Up 
 ```
On the Mellanox switches, first you must run the switch commands listed in the Automated section above. Then the output should look like the following.
 
```
sw-spine-001 [standalone: master] # show ip bgp summary 

VRF name                  : default
BGP router identifier     : 10.252.0.1
local AS number           : 65533
BGP table version         : 308
Main routing table version: 308
IPV4 Prefixes             : 261
IPV6 Prefixes             : 0
L2VPN EVPN Prefixes       : 0

------------------------------------------------------------------------------------------------------------------
Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd        
------------------------------------------------------------------------------------------------------------------
10.252.0.7        4    65533        37421     42948     308       0      0      12:23:16:07   ESTABLISHED/53
10.252.0.8        4    65533        37421     42920     308       0      0      12:23:16:07   ESTABLISHED/51
10.252.0.9        4    65533        37420     42962     308       0      0      12:23:16:07   ESTABLISHED/51
```
- If the BGP neighbors are not in the `ESTABLISHED` state make sure the IPs are correct for the route-map and BGP configuration.
- If IPs are incorrect you will have to update the configuration to match the IPs, the configuration below will need to be edited.
- You can get the NCN IPs from the CSI generated files (NMN.yaml, CAN.yaml, HMN.yaml), these IPs are also located in /etc/dnsmasq.d/statics.conf on the LiveCD/ncn-m001.

```
pit# grep w00 /etc/dnsmasq.d/statics.conf | grep nmn
host-record=ncn-w003,ncn-w003.nmn,10.252.1.13
host-record=ncn-w002,ncn-w002.nmn,10.252.1.14
host-record=ncn-w001,ncn-w001.nmn,10.252.1.15
```
- The route-map configuration will require you to get the HMN, and CAN IPs as well. Note the `Bond0 Mac0/Mac1` entry is for the NMN.
```
pit# grep ncn-w /etc/dnsmasq.d/statics.conf | egrep "Bond0|HMN|CAN" | grep -v mgmt
dhcp-host=50:6b:4b:08:d0:4a,10.252.1.13,ncn-w003,20m # Bond0 Mac0/Mac1
dhcp-host=50:6b:4b:08:d0:4a,10.254.1.20,ncn-w003,20m # HMN
dhcp-host=50:6b:4b:08:d0:4a,10.102.4.12,ncn-w003,20m # CAN
dhcp-host=98:03:9b:0f:39:4a,10.252.1.14,ncn-w002,20m # Bond0 Mac0/Mac1
dhcp-host=98:03:9b:0f:39:4a,10.254.1.22,ncn-w002,20m # HMN
dhcp-host=98:03:9b:0f:39:4a,10.102.4.13,ncn-w002,20m # CAN
dhcp-host=98:03:9b:bb:a9:94,10.252.1.15,ncn-w001,20m # Bond0 Mac0/Mac1
dhcp-host=98:03:9b:bb:a9:94,10.254.1.24,ncn-w001,20m # HMN
dhcp-host=98:03:9b:bb:a9:94,10.102.4.14,ncn-w001,20m # CAN
```
- The Aruba configuration will require you to set the other peering switch as a BGP neighbor, the mellanox configuration does not require this. 
- You will need to delete the previous route-map, and BGP configuration on both switches.
Aruba delete commands.
```
sw-spine-001# configure terminal

sw-spine-001(config)# no router  bgp 65533                          
This will delete all BGP configurations on this device.
Continue (y/n)? y

sw-spine-001(config)# no route-map ncn-w003
sw-spine-001(config)# no route-map ncn-w002
sw-spine-001(config)# no route-map ncn-w001
```
Aruba configuration example.
```
route-map rm-ncn-w001 permit seq 10
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.2.8
route-map rm-ncn-w001 permit seq 20
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.2.27
route-map rm-ncn-w001 permit seq 30
     match ip address prefix-list pl-can
     set ip next-hop 10.103.10.10
route-map rm-ncn-w002 permit seq 10
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.2.9
route-map rm-ncn-w002 permit seq 20
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.2.25
route-map rm-ncn-w002 permit seq 30
     match ip address prefix-list pl-can
     set ip next-hop 10.103.10.9
route-map rm-ncn-w003 permit seq 10
     match ip address prefix-list pl-nmn
     set ip next-hop 10.252.2.18
route-map rm-ncn-w003 permit seq 20
     match ip address prefix-list pl-hmn
     set ip next-hop 10.254.2.26
route-map rm-ncn-w003 permit seq 30
     match ip address prefix-list pl-can
     set ip next-hop 10.103.10.11
!                                                              
router bgp 65533
    bgp router-id 10.252.0.1
    maximum-paths 8
    neighbor 10.252.0.3 remote-as 65533
    neighbor 10.252.2.8 remote-as 65533
    neighbor 10.252.2.9 remote-as 65533
    neighbor 10.252.2.18 remote-as 65533
    address-family ipv4 unicast
        neighbor 10.252.0.3 activate
        neighbor 10.252.2.8 activate
        neighbor 10.252.2.8 route-map ncn-w001 in
        neighbor 10.252.2.9 activate
        neighbor 10.252.2.9 route-map ncn-w002 in
        neighbor 10.252.2.18 activate
        neighbor 10.252.2.18 route-map ncn-w003 in
    exit-address-family
```
Mellanox delete commands.
```
sw-spine-001 [standalone: master] # 
sw-spine-001 [standalone: master] # conf t
sw-spine-001 [standalone: master] (config) # no router bgp 65533
sw-spine-001 [standalone: master] (config) # no route-map ncn-w001
sw-spine-001 [standalone: master] (config) # no route-map ncn-w002
sw-spine-001 [standalone: master] (config) # no route-map ncn-w003
```
Mellanox configuration example.
```
## Route-maps configuration
##
   route-map rm-ncn-w001 permit 10 match ip address pl-nmn
   route-map rm-ncn-w001 permit 10 set ip next-hop 10.252.0.7
   route-map rm-ncn-w001 permit 20 match ip address pl-hmn
   route-map rm-ncn-w001 permit 20 set ip next-hop 10.254.0.7
   route-map rm-ncn-w001 permit 30 match ip address pl-can
   route-map rm-ncn-w001 permit 30 set ip next-hop 10.103.8.7
   route-map rm-ncn-w002 permit 10 match ip address pl-nmn
   route-map rm-ncn-w002 permit 10 set ip next-hop 10.252.0.8
   route-map rm-ncn-w002 permit 20 match ip address pl-hmn
   route-map rm-ncn-w002 permit 20 set ip next-hop 10.254.0.8
   route-map rm-ncn-w002 permit 30 match ip address pl-can
   route-map rm-ncn-w002 permit 30 set ip next-hop 10.103.8.8
   route-map rm-ncn-w003 permit 10 match ip address pl-nmn
   route-map rm-ncn-w003 permit 10 set ip next-hop 10.252.0.9
   route-map rm-ncn-w003 permit 20 match ip address pl-hmn
   route-map rm-ncn-w003 permit 20 set ip next-hop 10.254.0.9
   route-map rm-ncn-w003 permit 30 match ip address pl-can
   route-map rm-ncn-w003 permit 30 set ip next-hop 10.103.8.9
   
##
## BGP configuration
##
   protocol bgp
   router bgp 65533 vrf default
   router bgp 65533 vrf default router-id 10.252.0.1 force
   router bgp 65533 vrf default maximum-paths ibgp 32
   router bgp 65533 vrf default neighbor 10.252.0.7 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.0.7 route-map ncn-w001
   router bgp 65533 vrf default neighbor 10.252.0.8 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.0.8 route-map ncn-w002
   router bgp 65533 vrf default neighbor 10.252.0.9 remote-as 65533
   router bgp 65533 vrf default neighbor 10.252.0.9 route-map ncn-w003
   router bgp 65533 vrf default neighbor 10.252.0.10 remote-as 65533
```

- Once the IPs are updated for the route-maps and BGP neighbors you may need to restart the BGP process on the switches, you do this by running `clear ip bgp all` on the mellanox and `clear bgp *` on the Arubas. (This may need to be done multiple times for all the peers to come up)
- When worker nodes are reinstalled, the BGP process will need to be restarted. 
- If the BGP peers are still not coming up you should check the metallb.yaml config file for errors.  The MetalLB config file should point to the NMN IPs of the switches configured.

metallb.yaml configuration example.
- The peer-address should be the IP of the switch that you are doing BGP peering with.  
```
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    peers:
    - peer-address: 10.252.0.2
      peer-asn: 65533
      my-asn: 65533
    - peer-address: 10.252.0.3
      peer-asn: 65533
      my-asn: 65533
    address-pools:
    - name: customer-access
      protocol: bgp
      addresses:
      - 10.102.9.112/28
    - name: customer-access-dynamic
      protocol: bgp
      addresses:
      - 10.102.9.128/25
    - name: hardware-management
      protocol: bgp
      addresses:
      - 10.94.100.0/24
    - name: node-management
      protocol: bgp
      addresses:
      - 10.92.100.0/24
```

