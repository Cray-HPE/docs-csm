# Management Network Uplink configuration

This page describes how to configure switch to switch connections or uplinks between switches.

# Requirements

- Console access
- Aruba VSX configured on a pair of switches.

# Configuration
The configuration below shows how to configure a Multi-chassis LAG on a pair of VSX switches.
These connections will go to other network switches. 

VSX Pair configuration
Create the multi-chassis LAG on the first switch.
```
sw-24g03(config)# interface lag 100 multi-chassis
sw-24g03(config-lag-if)# no shutdown
sw-24g03(config-lag-if)# no routing
sw-24g03(config-lag-if)# vlan trunk native 1
sw-24g03(config-lag-if)# vlan trunk allowed all
sw-24g03(config-lag-if)# lacp mode active
```
Create the multi-chassis LAG on the second switch.
```
sw-24g04(config)# interface lag 100 multi-chassis
sw-24g04(config-lag-if)# no shutdown
sw-24g04(config-lag-if)# no routing
sw-24g04(config-lag-if)# vlan trunk native 1
sw-24g04(config-lag-if)# vlan trunk allowed all
sw-24g04(config-lag-if)# lacp mode active
```
After creating the multi-chassis LAG we will need to add ports to the LAG.
```
sw-24g03(config)# interface 1/1/48 
sw-24g03(config-if)# no shutdown 
sw-24g03(config-if)# mtu 9198
sw-24g03(config-if)# lag 100
sw-24g03(config-if)#

sw-24g04(config)# interface 1/1/48 
sw-24g04(config-if)# no shutdown 
sw-24g04(config-if)# mtu 9198
sw-24g04(config-if)# lag 100
sw-24g04(config-if)#
```  

This configuration shows the how to setup the LAG on the access switch connecting to the VSX pair. 
```
sw-leaf-001(config)# interface lag 1
sw-leaf-001(config)# no shutdown
sw-leaf-001(config)# no routing
sw-leaf-001(config)# vlan trunk native 1
sw-leaf-001(config)# vlan trunk allowed all
sw-leaf-001(config)# lacp mode active

sw-leaf-001(config)# interface 1/1/48
sw-leaf-001(config-if)# no shutdown 
sw-leaf-001(config-if)# mtu 9198
sw-leaf-001(config-if)# lag 100

sw-leaf-001(config)# interface 1/1/49
sw-leaf-001(config-if)# no shutdown 
sw-leaf-001(config-if)# mtu 9198
sw-leaf-001(config-if)# lag 100
```
