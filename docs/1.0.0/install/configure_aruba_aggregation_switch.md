# Configure Aruba Aggregation Switch

This page describes how Aruba aggregation switches are configured.

Management nodes and Application nodes will be plugged into aggregation switches.

Switch models used: JL635A Aruba 8325-48Y8C

They run in a high availability pair and use VSX to provide redundancy.

## Prerequisites

- Three connections between the switches, two of these are used for the Inter switch link (ISL), and one used for the keepalive.
- The ISL uses 100GB ports and the keepalive will be a 25 GB port.

  Here is an example snippet from an aggregation switch on the 25G_10G tab of the SHCD spreadsheet.

  | Source | Source Label Info | Destination Label Info | Destination | Description | Notes
  | --- | --- | ---| --- | --- | --- |
  | sw-25g01 | x3105u38-j49 | x3105u39-j49 | sw-25g02 | 100g-1m-DAC | |
  | sw-25g01 | x3105u38-j50 | x3105u39-j50 | sw-25g02 | 100g-1m-DAC | |
  | sw-25g01 | x3105u38-j53 | x3105u39-j53 | sw-25g02 | 100g-1m-DAC | keepalive |

- Connectivity to the switch is established.
- The [Configure Aruba Management Network Base](configure_aruba_management_network_base.md) procedure has been run.

## Configure VSX

1. Create the keepalive VRF on both switches.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       vrf keepalive
   ```

1. Set up the keepalive link.

   This will require a unique IP address on both switches. The IP address is in its own VRF so this address will not be reachable from anywhere besides the aggregation pair.

   ```bash
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

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       interface lag 99
       no shutdown
       description ISL link
       no routing
       vlan trunk native 1 tag
       vlan trunk allowed all
       lacp mode active
   ```

1. Add the ISL ports to the LAG.

   These are two of the ports connected between the switches.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       int 1/1/31-1/1/32
       no shutdown
       mtu 9198
       lag 99
   ```

1. Create the VSX instance and setup the keepalive link.

   ```bash
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

1. Verify there is an `Established` VSX session.

   ```bash
   sw-agg-001 # show vsx brief
   ISL State                              : In-Sync
   Device State                           : Sync-Primary
   Keepalive State                        : Keepalive-Established
   Device Role                            : secondary
   Number of Multi-chassis LAG interfaces : 0
   ```

## Configure VLAN

**Cray Site Init (CSI) generates the IP addresses used by the system, below are samples only.**
The VLAN information is located in the network YAML files. The following are examples.

1. Check that the aggregation switches have VLAN interfaces in the Node Management Network (NMN) and Hardware Management Network (HMN).

   Example NMN.yaml:

   ```bash
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

   Example HMN.yaml:

   ```bash
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

   The following is an example of aggregation switch IP addressing based on the network .yaml files above:

   | VLAN | Agg01 | Agg02	| Purpose |
   | --- | --- | ---| --- |
   | 2 | 10.252.0.4/17| 10.252.0.5/17 | River Node Management
   | 4 | 10.254.0.4/17| 10.254.0.5/17 | River Hardware Management

1. Configure the NMN VLAN.

   ```bash
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

1. Configure the HMN VLAN.

   ```bash
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

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
   interface lag 1 multi-chassis
       no shutdown
       no routing
       vlan trunk native 1
       vlan trunk allowed all
       lacp mode active
       exit
   ```

1. Add ports to the LAG.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
   interface 1/1/1 - 1/1/2
       no shutdown
       mtu 9198
       lag 1
       exit
   ```

## Configure ACL

These ACLs are designed to block traffic from the NMN to and from the HMN.

One port is shutdown.

1. Create the access list.

   **NOTE:** The following are examples only. The IP addresses below need to match what was generated by CSI.

   ```bash
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

   ```bash
   sw-cdu-001 & sw-cdu-002 (config)#
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

## Configure Spanning-Tree

The following configuration is applied to Aruba aggregation switches:

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       spanning-tree mode rpvst
       spanning-tree
       spanning-tree priority 7
       spanning-tree vlan 1,2,4,7
   ```

## Configure OSPF

OSPF is a dynamic routing protocol used to exchange routes.
It provides reachability from the MTN networks to NMN/Kubernetes networks.
The router-id used here is the NMN IP address. (VLAN 2 IP)

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       router ospf 1
       router-id 10.252.0.x
       interface vlan2
       ip ospf 1 area 0.0.0.2
       interface vlan4
       ip ospf 1 area 0.0.0.4
   ```

## Configure NTP

The IP addresses used are be the first three worker nodes on the NMN network. These can be found in NMN.yaml.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       ntp server 10.252.1.7
       ntp server 10.252.1.8
       ntp server 10.252.1.9
       ntp enable
   ```

## Configure DNS

The following will point to the unbound DNS server.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       ip dns server-address 10.92.100.225
   ```

## Configure Edge Port

These are ports that are connected to management nodes.

1. Set the worker node and master node configuration.

   Refer to [Cable Management Network Servers](cable_management_network_servers.md) for cabling specs.

   ```bash
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

1. Set the Aruba Storage port configuration (future use).

   These will be configured, but the ports will be shut down until needed.
   These are OCP and PCIe port 2 on storage nodes.

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       interface 1/1/7
       shutdown
       mtu 9198
       lag 4
       exit
   ```

1. Set the Aruba LAG configuration.

   ```bash
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

## Configure User Access/Login/Application Node Port

- One connection will go to an NMN (VLAN2) access port, which is where the UAN will PXE boot and communicate with internal nodes (see SHCD for UAN cabling).
- One Bond (two connections) will be going to the MLAG/VSX pair of switches. This will be a trunk port for the CAN connection.

1. Set the Aruba UAN NMN configuration.

   One port is shutdown.

   ```bash
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

1. Set the Aruba UAN CAN configuration.

   Port Configuration is the same on both switches.

   ```bash
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

   ```bash
   sw-agg-001 & sw-agg-002 (config)#
       interface 1/1/17
       no shutdown
       mtu 9198
       lag 17
   ```

## Save Configuration

To save a configuration:

   ```bash
   sw-agg-001(config)# exit
   sw-agg-001# write memory
   ```


## Show Running Configuration

To show the currently running configuration:

   ```bash
   sw-agg-001# show running-config
   ```
