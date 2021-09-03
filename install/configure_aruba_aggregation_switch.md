# Configure Aruba Aggregation Switch

This page describes how Aruba aggregation switches are configured.

Management nodes and Application nodes will be plugged into aggregation switches.

Switch Models used:
JL635A Aruba 8325-48Y8C

They run in a high availability pair and use VSX to provide redundancy.

Requirements:
   - Three connections between the switches, two of these are used for the ISL (Inter switch link) and one used for the keepalive.
   - The ISL uses 100GB ports and the keepalive will be a 25 GB port.

Here is an example snippet from a aggregation switch on the 25G_10G tab of the SHCD spreadsheet.

| Source | Source Label Info | Destination Label Info | Destination | Description | Notes
| --- | --- | ---| --- | --- | --- |
| sw-25g01 | x3105u38-j49 | x3105u39-j49 | sw-25g02 | 100g-1m-DAC | |
| sw-25g01 | x3105u38-j50 | x3105u39-j50 | sw-25g02 | 100g-1m-DAC | |
| sw-25g01 | x3105u38-j53 | x3105u39-j53 | sw-25g02 | 100g-1m-DAC | keepalive |

It is assumed that you have connectivity to the switch and have done the [Configure Aruba Management Network Base](configure_aruba_management_network_base.md) procedure.

## Configure VSX

1. Create the keepalive VRF on both switches.
   ```
   sw-agg-001 & sw-agg-002 (config)#
       vrf keepalive
   ```

1. Set up the keepalive link.
   This will require a unique IP address on both switches. The IP address is in its own VRF so this address will not be reachable from anywhere besides the aggregation pair.

   ```
   sw-agg-001(config)#
       int 1/1/48
       no shutdown
       vrf attach keepalive
       description VSX keepalive
       ip address 192.168.255.0/31

   sw-agg-002(config)#
       int 1/1/48
       no shutdown
       vrf attach keepalive
       description VSX keepalive
       ip address 192.168.255.1/31
   ```

1. Create the ISL lag on both switches.

   ```
   sw-agg-001 & sw-agg-002 (config)#
       interface lag 99
       no shutdown
       description ISL link
       no routing
       vlan trunk native 1 tag
       vlan trunk allowed all
       lacp mode active
   ```

1. Add the ISL ports to the LAG, these are two of the ports connected between the switches.

   ```
   sw-agg-001 & sw-agg-002 (config)#
       int 1/1/31-1/1/32
       no shutdown
       mtu 9198
       lag 99
   ```

1. Create the VSX instance and setup the keepalive link.

   ```
   sw-agg-001(config)#
       no ip icmp redirect
       vsx
       system-mac 02:01:00:00:01:00
       inter-switch-link lag 99
       role primary
       keepalive peer 192.168.255.1 source 192.168.255.0 vrf keepalive
       linkup-delay-timer 600
       vsx-sync vsx-global

   sw-agg-002(config)#
       no ip icmp redirect
       vsx
       system-mac 02:01:00:00:01:00
       inter-switch-link lag 99
       role secondary
       keepalive peer 192.168.255.0 source 192.168.255.1 vrf keepalive
       linkup-delay-timer 600
       vsx-sync vsx-global

   ```
1. At this point you should have an `Established` VSX session
   ```
   sw-agg-001 # show vsx brief
   ISL State                              : In-Sync
   Device State                           : Sync-Primary
   Keepalive State                        : Keepalive-Established
   Device Role                            : secondary
   Number of Multi-chassis LAG interfaces : 0
   ```

## Configure VLAN

**Cray Site Init (CSI) generates the IP addresses used by the system, below are samples only.**
The VLAN information is located in the network YAML files. Below are examples.

1. The aggregation switches will have VLAN interfaces in NMN, HMN networks
   ```
   pit# cat /var/www/ephemeral/prep/${SYSTEM_NAME}/networks/NMN.yaml
   SNIPPET
     - ip_address: 10.252.0.4
       name: sw-agg-001
       comment: x3000c0h12s1
       aliases: []
     - ip_address: 10.252.0.5
       name: sw-agg-002
       comment: x3000c0h13s1
       aliases: []
     name: network_hardware
     net-name: NMN
     vlan_id: 2
     comment: ""
     gateway: 10.252.0.1
   ```
   ```
   pit# cat /var/www/ephemeral/prep/${SYSTEM_NAME}/networks/HMN.yaml
   SNIPPET
     - ip_address: 10.254.0.4
       name: sw-agg-001
       comment: x3000c0h12s1
       aliases: []
     - ip_address: 10.254.0.5
       name: sw-agg-002
       comment: x3000c0h13s1
       aliases: []
     name: network_hardware
     net-name: HMN
     vlan_id: 4
     comment: ""
     gateway: 10.254.0.1
   ```

1. Below is an example of aggregation switch IP addressing based on the network .yaml files from above.

   | VLAN | Agg01 | Agg02	| Purpose |
   | --- | --- | ---| --- |
   | 2 | 10.252.0.4/17| 10.252.0.5/17 | River Node Management
   | 4 | 10.254.0.4/17| 10.254.0.5/17 | River Hardware Management

1. NMN VLAN config
   ```
   sw-agg-001(config)#
       vlan 2
       interface vlan2
       vsx-sync active-gateways
       ip address 10.252.0.2/17
       ip mtu 9198
       exit

   sw-agg-002(config)#
       vlan 2
       interface vlan2
       ip address 10.252.0.4/17
       ip mtu 9198
       exit
   ```
1. HMN VLAN config
   ```
   sw-agg-001(config)#
       vlan 4
       interface vlan4
       vsx-sync active-gateways
       ip address 10.254.0.4/17
       ip mtu 9198
       exit

   sw-agg-002(config)#
       vlan 4
       interface vlan4
       vsx-sync active-gateways
       ip address 10.254.0.5/17
       ip mtu 9198
       exit
   ```

## Configure Uplink
The uplink ports are the ports connecting the aggregation switches to the spine switches.
1. Create the LAG.

   ```
   sw-agg-001 & sw-agg-002 (config)#
   interface lag 1 multi-chassis
       no shutdown
       no routing
       vlan trunk native 1
       vlan trunk allowed all
       lacp mode active
       exit
   ```

1. Add ports to the LAG
   ```
   sw-agg-001 & sw-agg-002 (config)#
   interface 1/1/1 - 1/1/2
       no shutdown
       mtu 9198
       lag 1
       exit
   ```

## Configure ACL

These ACLs are designed to block traffic from the node management network to and from the hardware management network and restrict management access to the hardware management network.

1. The first step is to create the access list, once it is created we have to apply it to a VLAN.

   NOTE: these are examples only, the IP addresses below need to match what was generated by CSI.
   ```
   sw-agg-001 & sw-agg-002 (config)#
       access-list ip nmn-hmn
       10 deny any 10.252.0.0/255.255.128.0 10.254.0.0/255.255.128.0
       20 deny any 10.252.0.0/255.255.128.0 10.104.0.0/255.252.0.0
       30 deny any 10.254.0.0/255.255.128.0 10.252.0.0/255.255.128.0
       40 deny any 10.254.0.0/255.255.128.0 10.100.0.0/255.252.0.0
       50 deny any 10.100.0.0/255.252.0.0 10.254.0.0/255.255.128.0
       60 deny any 10.100.0.0/255.252.0.0 10.104.0.0/255.252.0.0
       70 deny any 10.104.0.0/255.252.0.0 10.252.0.0/255.255.128.0
       80 deny any 10.104.0.0/255.252.0.0 10.100.0.0/255.252.0.0
       90 permit any any any
   ```

1. Apply ACL to VLANs.
   ```
   sw-agg-001 & sw-agg-002 (config)#
       vlan 2
       apply access-list ip nmn-hmn in
       apply access-list ip nmn-hmn out
       vlan 4
       apply access-list ip nmn-hmn in
       apply access-list ip nmn-hmn out
       vlan 2000
       apply access-list ip nmn-hmn in
       apply access-list ip nmn-hmn out
       vlan 3000
       apply access-list ip nmn-hmn in
       apply access-list ip nmn-hmn out
   ```

Control plane ACL
- This restricts management traffic to the HMN.

```
   sw-agg-001 & sw-agg-002 (config)#
    access-list ip mgmt
    05 comment ALLOW SSH, HTTPS, AND SNMP ON HMN SUBNET
    10 permit tcp 10.254.0.0/17 any eq 22
    20 permit tcp 10.254.0.0/17 any eq 443
    30 permit udp 10.254.0.0/17 any eq 161
    40 permit udp 10.254.0.0/17 any eq 162
    45 comment ALLOW SNMP FROM HMN METALLB SUBNET
    50 permit udp 10.94.100.0/24 any eq 161
    60 permit udp 10.94.100.0/24 any eq 162
    65 comment BLOCK SSH, HTTPS, AND SNMP FROM EVERYWHERE ELSE
    70 deny tcp any any eq 22
    80 deny tcp any any eq 443
    90 deny udp any any eq 161
    100 deny udp any any eq 162
    105 comment ALLOW ANYTHING ELSE
    110 permit any any any
    apply access-list ip mgmt control-plane vrf default
```

## Configure Spanning-tree

1. The following config is applied to Aruba aggregation switches.

   ```
   sw-agg-001 & sw-agg-002 (config)#
       spanning-tree mode rpvst
       spanning-tree
       spanning-tree priority 7
       spanning-tree vlan 1,2,4,7
   ```

## Configure OSPF

1. OSPF is a dynamic routing protocol used to exchange routes.
   It provides reachability from the MTN networks to NMN/Kubernetes networks.
   The router-id used here is the NMN IP address. (VLAN 2 IP)

   ```
   sw-agg-001 & sw-agg-002 (config)#
       router ospf 1
       router-id 10.252.0.x
       interface vlan2
       ip ospf 1 area 0.0.0.2
       interface vlan4
       ip ospf 1 area 0.0.0.4
   ```

## Configure NTP

1. The IP addresses used here will be the first three worker nodes on the NMN network. These can be found in NMN.yaml.

   ```
   sw-agg-001 & sw-agg-002 (config)#
       ntp server 10.252.1.7
       ntp server 10.252.1.8
       ntp server 10.252.1.9
       ntp enable
   ```

## Configure DNS

1. This will point to the unbound DNS server.

   ```
   sw-agg-001 & sw-agg-002 (config)#
       ip dns server-address 10.92.100.225
   ```

## Configure Edge Port

These are ports that are connected to management nodes.

1. Worker node and master node configuration
   Refer to [Cable Management Network Servers](cable_management_network_servers.md) for cabling specs.

   ```
   sw-agg-001 & sw-agg-002 (config)#
       interface lag 4 multi-chassis
       no shutdown
       description w001
       no routing
       vlan trunk native 1
       vlan trunk allowed 1-2,4,7
       lacp mode active
       lacp fallback
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit

   sw-agg-001 & sw-agg-002 (config)#
       interface 1/1/7
       no shutdown
       mtu 9198
       lag 4
       exit
   ```

1. Aruba Storage port configuration (future use)
   These will be configured, but the ports will be shut down until needed.
   These are OCP and PCIe port 2 on storage nodes.

   ```
   sw-agg-001 & sw-agg-002 (config)#
       interface 1/1/7
       shutdown
       mtu 9198
       lag 4
       exit
   ```
1. Aruba LAG Configuration
   ```
   sw-agg-001 & sw-agg-002 (config)#
       interface lag 4 multi-chassis
       shutdown
       no routing
       vlan access 10
       lacp mode active
       lacp fallback
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit
   ```

## Configure User Access/Login/Application node port
- One connection will go to a NMN (VLAN2) access port, this is where the UAN will PXE boot and communicate with internal nodes. (see SHCD for UAN cabling).
- One Bond (two connections) will be going to the MLAG/VSX pair of switches. This will be a trunk port for the CAN connection.

1. Aruba UAN NMN Configuration
   One port is shutdown.

   ```
   sw-agg-001 (config)#
       interface 1/1/16
       no shutdown
       mtu 9198
       no routing
       vlan access 2
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit

   sw-agg-002 (config)#
       interface 1/1/16
       shutdown
       mtu 9198
       no routing
       vlan access 2
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit
   ```

1. Aruba UAN CAN Configuration

   Port Configuration is the same on both switches.

   ```
   sw-agg-001 (config)#
       interface 1/1/16
       no shutdown
       mtu 9198
       no routing
       vlan access 2
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit

   sw-agg-002 (config)#
       interface 1/1/16
       shutdown
       mtu 9198
       no routing
       vlan access 2
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit
   ```

   ```
   sw-agg-001 & sw-agg-002 (config)#
       interface 1/1/17
       no shutdown
       mtu 9198
       lag 17
   ```

## Save configuration

   ```
   sw-agg-001(config)# exit
   sw-agg-001# write memory
   ```


## Show Running Configuration

   ```
   sw-agg-001# show running-config
   ```
