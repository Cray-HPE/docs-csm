# Management Network Layer3 Configuration

This page describes how to configure layer 3 routing for Hill and MTN cabinets.

MTN cabinets have their own "CDU" Switches.

Hill cabinets are connected the leaf switches.

# Requirements

- Access to all of the switches
- SHCD available

# Aruba Configuration

At this point you should be able to ping the CDU switches on their VLAN 2 and VLAN 4 interfaces.
We will need to setup routing so the compute nodes can communicate with k8s.

Spine/Agg switch configuration
- First step is to start the OSPF process, give the switch a router-id. This is typically the NMN IP.
- We will need to redistribute BGP into OSPF, this will allow devices to communicate with K8s
```
router ospf 1
    router-id 10.252.0.3
    redistribute bgp
    area 0.0.0.2
    area 0.0.0.4
```
The OSPF peering will happen over VLAN 2 and VLAN 4.
```
interface vlan 2
    ip ospf 1 area 0.0.0.2
interface vlan 4
    ip ospf 1 area 0.0.0.4
```

The BGP config will need to be changed on these switches to avoid routing loops.
```
router bgp 65533
    distance bgp 85 70
```

CDU/Leaf switch Layer3 configuration
```
router ospf 1
    router-id 10.252.0.6
    area 0.0.0.2
    area 0.0.0.4
interface vlan 2
    ip ospf 1 area 0.0.0.2
interface vlan 4
    ip ospf 1 area 0.0.0.4
interface vlan 2000
    ip ospf 1 area 0.0.0.2
    ip ospf passive
interface vlan 3000
    ip ospf 1 area 0.0.0.4
    ip ospf passive
```

Once this is complete you should be able to see OSPF neighbors on the CDU/Leaf switches.

```
sw-cdu-002# show ip ospf neighbors 
OSPF Process ID 1 VRF default
==============================

Total Number of Neighbors: 6

Neighbor ID      Priority  State             Nbr Address       Interface
-------------------------------------------------------------------------
10.252.0.2       1         FULL/DROther      10.252.0.2         vlan2          

10.252.0.3       1         FULL/DROther      10.252.0.3         vlan2          

10.252.0.5       1         FULL/BDR          10.252.0.5         vlan2          

10.252.0.2       1         FULL/DROther      10.254.0.2         vlan4          

10.252.0.3       1         FULL/DROther      10.254.0.3         vlan4          

10.252.0.5       1         FULL/BDR          10.254.0.5         vlan4 
```

# Aruba Static route
This route is needed for consistent PXE booting on Aruba switches.
The second IP ```10.252.1.10``` will be a worker node.  Here we are using worker 1. 
```
ip route 10.92.100.60/32 10.252.1.10
ip route 10.94.100.60/32 10.252.1.10
```
