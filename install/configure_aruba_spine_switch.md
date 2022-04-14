# Configure Aruba Spine Switch

This page describes how Aruba spine switches are configured.

Depending on the size of the HPE Cray EX system, the spine switches will serve different purposes. On TDS systems, the NCNs will plug directly into the spine switches. On larger systems with aggregation switches, the spine switches will provide connection between the aggregation switches.

Switch models used:
JL635A Aruba 8325-48Y8C and JL636A Aruba 8325-32C

They run in a high availability pair and use VSX to provide redundancy.

## Prerequisites

- Three connections between the switches, two of these are used for the Inter switch link (ISL), and one used for the keepalive.
- Connectivity to the switch is established.
- The [Configure Aruba Management Network Base](configure_aruba_management_network_base.md) procedure has been run.
- The ISL uses 100GB ports and the keepalive will be a 100GB port on the JL636A and a 25GB port on the JL635A.

The following is an example snippet from a spine switch on the SHCD.

The ISL ports are 31 and 32 on both spine switches.
The keepalive is port 27.

| Source | Source Label Info | Destination Label Info | Destination | Description | Notes
| --- | --- | ---| --- | --- | --- |
| sw-100g01 | x3105u40-j32 | x3105u41-j32 | sw-100g02 | 100g-1m-DAC | |
| sw-100g01 | x3105u40-j31 | x3105u41-j31 | sw-100g02 | 100g-1m-DAC | |
| sw-100g01 | x3105u40-j27 | x3105u41-j27 | sw-100g02 | 100g-1m-DAC | keepalive |

## Configure VSX

1. Create the keepalive VRF on both switches.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
       vrf keepalive
   ```

1. Setup the keepalive link.

   This will require a unique IP address on both switches. The IP address is in its own VRF so this address will not be reachable from anywhere besides the spine pair.

   ```bash
   sw-spine-001(config)#
       int 1/1/27
       no shutdown
       vrf attach keepalive
       description VSX keepalive
       ip address 192.168.255.0/31

   sw-spine-002(config)#
       int 1/1/27
       no shutdown
       vrf attach keepalive
       description VSX keepalive
       ip address 192.168.255.1/31
   ```

1. Create the ISL lag on both switches.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
       interface lag 256
       no shutdown
       description ISL link
       no routing
       vlan trunk native 1 tag
       vlan trunk allowed all
       lacp mode active
   ```

1. Add the ISL ports to the LAG; these are two of the ports connected between the switches.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
       int 1/1/31-1/1/32
       no shutdown
       mtu 9198
       lag 99
   ```

1. Create the VSX instance and setup the keepalive link.

   ```bash
   sw-spine-001(config)#
       no ip icmp redirect
       vsx
       system-mac 02:01:00:00:01:00
       inter-switch-link lag 99
       role primary
       keepalive peer 192.168.255.1 source 192.168.255.0 vrf keepalive
       linkup-delay-timer 600
       vsx-sync vsx-global

   sw-spine-002(config)#
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
   sw-spine-001 # show vsx brief
   ISL State                              : In-Sync
   Device State                           : Sync-Primary
   Keepalive State                        : Keepalive-Established
   Device Role                            : secondary
   Number of Multi-chassis LAG interfaces : 0
   ```


## Configure VLAN

**Cray Site Init (CSI) generates the IP addresses used by the system, below are samples only.**
The VLAN information is located in the network YAML files. The following are examples.

1. View the spine switch VLAN interfaces in NMN, HMN, and CAN networks.

   Example NMN.yaml:

   ```bash
   pit# cat /var/www/ephemeral/prep/${SYSTEM_NAME}/networks/NMN.yaml
   SNIPPET
     - ip_address: 10.252.0.2
       name: sw-spine-001
       comment: x3000c0h12s1
       aliases: []
     - ip_address: 10.252.0.3
       name: sw-spine-002
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
     - ip_address: 10.254.0.2
       name: sw-spine-001
       comment: x3000c0h12s1
       aliases: []
     - ip_address: 10.254.0.3
       name: sw-spine-002
       comment: x3000c0h13s1
       aliases: []
     name: network_hardware
     net-name: HMN
     vlan_id: 4
     comment: ""
     gateway: 10.254.0.1
   ```

   Example CAN.yaml:

   ```bash
   pit# cat /var/www/ephemeral/prep/${SYSTEM_NAME}/networks/CAN.yaml
   SNIPPET
     - ip_address: 10.102.11.2
       name: can-switch-1
       comment: ""
       aliases: []
     - ip_address: 10.102.11.3
       name: can-switch-2
       comment: ""
       aliases: []
     net-name: CAN
     vlan_id: 7
     comment: ""
     gateway: 10.102.11.1
   ```

   The following is an example of spine switch IP addressing based on the network .yaml files from above.

   | VLAN | Spine01 | Spine02 | Purpose |
   | --- | --- | ---| --- |
   | 2 | 10.252.0.2/17| 10.252.0.3/17 | River Node Management |
   | 4 | 10.254.0.2/17| 10.254.0.3/17 | River Hardware Management |
   | 7 | 10.102.11.2/24| 10.102.11.3/24 | Customer Access |

1. Set the NMN VLAN configuration.

   ```bash
   sw-spine-001(config)#
       vlan 2
       interface vlan2
       vsx-sync active-gateways
       ip address 10.252.0.2/17
       active-gateway ip mac 12:01:00:00:01:00
       active-gateway ip 10.252.0.1
       ip mtu 9198
       ip helper-address 10.92.100.222
       exit

   sw-spine-002(config)#
       vlan 2
       interface vlan2
       vsx-sync active-gateways
       ip address 10.252.0.3/17
       active-gateway ip mac 12:01:00:00:01:00
       active-gateway ip 10.252.0.1
       ip mtu 9198
       ip helper-address 10.92.100.222
       exit
   ```

1. Set the HMN VLAN configuration.

   ```
   sw-spine-001(config)#
       vlan 4
       interface vlan4
       vsx-sync active-gateways
       ip address 10.254.0.2/17
       active-gateway ip mac 12:01:00:00:01:00
       active-gateway ip 10.254.0.1
       ip mtu 9198
       ip helper-address 10.94.100.222
       exit

   sw-spine-002(config)#
       vlan 4
       interface vlan4
       vsx-sync active-gateways
       ip address 10.254.0.3/17
       active-gateway ip mac 12:01:00:00:01:00
       active-gateway ip 10.254.0.1
       ip mtu 9198
       ip helper-address 10.94.100.222
       exit
   ```

1. Set the CAN VLAN configuration.

   ```
   sw-spine-001(config)#
       interface vlan 7
       vsx-sync active-gateways
       ip mtu 9198
       ip address 10.102.11.2/24
       active-gateway ip mac 12:01:00:00:01:00
       active-gateway ip 10.102.11.1
       ip helper-address 10.92.100.222

   sw-spine-002(config)#
       interface vlan 7
       vsx-sync active-gateways
       ip mtu 9198
       ip address 10.102.11.3/24
       active-gateway ip mac 12:01:00:00:01:00
       active-gateway ip 10.102.11.1
       ip helper-address 10.92.100.222
   ```

## Configure Uplink

The uplink ports are the ports connecting the spine switches to the downstream switches, these switches can be aggregation, leaf, or spine switches.

1. Create the LAG.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
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
   sw-spine-001 & sw-spine-002 (config)#
   interface 1/1/1 - 1/1/2
       no shutdown
       mtu 9198
       lag 1
       exit
   ```


## Configure ACL

These ACLs are designed to block traffic from the node management network to and from the hardware management network.

1. Create the access list.

   **NOTE:** these are examples only, the IP addresses below need to match what was generated by CSI.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
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
   sw-spine-001 & sw-spine-002 (config)#
       vlan 2
       name RVR_NMN
       apply access-list ip nmn-hmn in
       apply access-list ip nmn-hmn out
       vlan 4
       name RVR_HMN
       apply access-list ip nmn-hmn in
       apply access-list ip nmn-hmn out
   ```


## Configure Spanning-Tree

1. Apply the following configuration to Aruba spine switches.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
       spanning-tree mode rpvst
       spanning-tree
       spanning-tree priority 7
       spanning-tree vlan 1,2,4,7
   ```

## Configure OSPF

OSPF is a dynamic routing protocol used to exchange routes.
It provides reachability from the MTN networks to NMN/Kubernetes networks.
The router-id used here is the NMN IP address. (VLAN 2 IP)

1. Configure OSPF.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
       router ospf 1
       router-id 10.252.0.x
       interface vlan2
       ip ospf 1 area 0.0.0.2
       interface vlan4
       ip ospf 1 area 0.0.0.4
       redistribute bgp
   ```

## Configure NTP

1. Configure NTP.

   The IP addresses used are the first three worker nodes on the NMN. These can be found in NMN.yaml.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
       ntp server 10.252.1.7
       ntp server 10.252.1.8
       ntp server 10.252.1.9
       ntp enable
   ```


## Configure DNS

1. Configure DNS.

   This will point to the unbound DNS server.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
       ip dns server-address 10.92.100.225
   ```


## Configure Edge Port

Edge ports are connected to non-compute nodes (NCNs).

1. Set the worker and master node configuration.

   Refer to [Cable Management Network Servers](cable_management_network_servers.md) for cabling specs.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
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

   sw-spine-001 & sw-spine-002 (config)#
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
   sw-spine-001 & sw-spine-002 (config)#
       interface 1/1/7
       shutdown
       mtu 9198
       lag 4
       exit
   ```

1. Set the Aruba LAG configuration.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
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

- One connection will go to an NMN (VLAN2) access port; this is where the UAN will PXE boot and communicate with internal systems (see SHCD for UAN cabling).
- ONE OF THESE PORTS IS SHUTDOWN.
- One Bond (two connections) will be going to the MLAG/VSX pair of switches. This will be a TRUNK port for the CAN connection.

1. Set the Aruba UAN NMN configuration.

   One port is shutdown.

   ```bash
   sw-spine-001 (config)#
       interface 1/1/16
       no shutdown
       mtu 9198
       no routing
       vlan access 2
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit

   sw-spine-002 (config)#
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

   Port configuration is the same on both switches.

   ```bash
   sw-spine-001 & sw-spine-002 (config)#
       interface lag 17 multi-chassis
       no shutdown
       no routing
       vlan trunk native 1
       vlan trunk allowed 7
       lacp mode active
       lacp fallback
       spanning-tree bpdu-guard
       spanning-tree port-type admin-edge
       exit

   sw-spine-001 & sw-spine-002 (config)#
       interface 1/1/17
       no shutdown
       mtu 9198
       lag 17
   ```

## Save Configuration

To save the configuration:

   ```bash
   sw-spine-001(config)# exit
   sw-spine-001# write memory
   ```


## Show Running Configuration

To display the running configuration:

   ```
   sw-spine-001# show running-config
   ```

