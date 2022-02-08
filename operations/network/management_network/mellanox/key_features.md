# Key features used in the management network configuration

This section is to list and define the key features used in the management network configuration. 

Feature list:

| Feature      | Notes | Description     |
| :---        |    :----:   |          :--- |
|MLAG	| | Layer 2 Redundancy, Allows the NCNs to be bonded so if one link fails they can continue to operate. |
|MLAG	| | Layer 3 Redundancy, Allows one Spine switch/default gateway to fail and continue to work |
|Vlan	| | Segregates layer 2 broadcast domains, need to separate NMN/HMN/compute traffic. |
|MSTP	| | Layer 2 loop prevention mechanism at edge |
|IP routing	| | IP routing / static routes |
|OSPF	| | Routing protocol used to peer from Leaf switches to Spines |
|BGP	| | Routing protocol used to peer with MetalLB |
|Prefix-Lists	| | Lists to match components of an IP route |
|Route-Maps	| | Defines which route are redistributed |
|NTP	| | Network Time Protocol |
|ACLs	| | Access Control Lists |
|Max MTU - 9198	| | Max Transmission Unit/Maximum Frame size |
|SNMP	| | Allows for device polling from the NCNs to map out interfaces |
|VRF	| | Virtual routing and forwarding, used to segregate traffic between networks |


[Back to Index](../index.md)