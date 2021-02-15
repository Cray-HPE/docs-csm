# IP-Helper configuration

This page will describe how to setup IP-Helpers on Aruba, Dell, and Mellanox switches.

If you are migrating from a 1.3.2 system, the IP-helpers are being moved to the switches that are doing the Layer3 Routing.  For most systems this will be moving the helper from the leaf to the spine.

IP-Helpers will reside on VLANs 1,2,4,7,2xxx, and 3xxx.

# Aruba Configuration

On both switches participating in VSX we will need to add configuration to the VLAN interfaces.
The IP-Helper is used to forward DCHP traffic from one network to a specified IP address.

```
sw-24g03(config)# int vlan 1
sw-24g03(config-if-vlan)# ip helper-address 10.92.100.222
sw-24g03(config-if-vlan)# int vlan 2
sw-24g03(config-if-vlan)# ip helper-address 10.92.100.222
sw-24g03(config-if-vlan)# int vlan 4
sw-24g03(config-if-vlan)# ip helper-address 10.94.100.222
sw-24g03(config-if-vlan)# int vlan 7
sw-24g03(config-if-vlan)# ip helper-address 10.92.100.222

sw-24g04(config)# int vlan 1
sw-24g04(config-if-vlan)# ip helper-address 10.92.100.222
sw-24g04(config-if-vlan)# int vlan 2
sw-24g04(config-if-vlan)# ip helper-address 10.92.100.222
sw-24g04(config-if-vlan)# int vlan 4
sw-24g04(config-if-vlan)# ip helper-address 10.94.100.222
sw-24g04(config-if-vlan)# int vlan 7
sw-24g04(config-if-vlan)# ip helper-address 10.92.100.222
```
For CDU switches the IP helpers will look like the following.
Any 2xxx VLANs will have ```10.92.100.222``` as the ip helper-address and any 3xxx VLANs will have ```10.94.100.222``` as the ip helper-address
```
interface vlan 2000
    ip helper-address 10.92.100.222
interface vlan 3000
    ip helper-address 10.94.100.222
```

# Dell Configuration
In shasta 1.3.2 the IP-helpers for the NMN(VLAN2), and HMN(VLAN4) resided on the leafs, these are moving to the spines.

Remove IP-Helper configuration from the leafs.
```
sw-leaf-001(config)# interface vlan 2
sw-leaf-001(conf-if-vl-2)# no ip helper-address 10.92.100.222
sw-leaf-001(config)# interface vlan 4
sw-leaf-001(conf-if-vl-4)# no ip helper-address 10.94.100.222
```

On CDU switches the IP-Helpers need to be set accordingly.  This is the same setting as 1.3.
For 2xxx VLANS the config should look like the following.
```
sw-cdu-001# show running-configuration interface vlan 2000
!
interface vlan2000
 mode L3
 description CAB_1000_MTN_NMN
 no shutdown
 ip address 10.100.0.2/22
 ip access-group nmn-hmn in
 ip access-group nmn-hmn out
 ip ospf 1 area 0.0.0.2
 ip ospf passive
 ip helper-address 10.92.100.222
```

For 3xxx VLANS the config should look like the following.
```
sw-cdu-001# show running-configuration interface vlan 3000
!
interface vlan3000
 mode L3
 description CAB_1000_MTN_HMN
 no shutdown
 ip address 10.104.0.2/22
 ip access-group nmn-hmn in
 ip access-group nmn-hmn out
 ip ospf 1 area 0.0.0.4
 ip ospf passive
 ip helper-address 10.94.100.222
```

# Mellanox Configuration

Configuration for Mellanox switch.
Notice there is a helper for vlan 1,2,4, and 7. 
```
## DHCP relay configuration
##
   ip dhcp relay instance 2 vrf default
   ip dhcp relay instance 4 vrf default
   ip dhcp relay instance 2 address 10.92.100.222
   ip dhcp relay instance 4 address 10.94.100.222
   interface vlan 1 ip dhcp relay instance 2 downstream
   interface vlan 2 ip dhcp relay instance 2 downstream
   interface vlan 4 ip dhcp relay instance 4 downstream
   interface vlan 7 ip dhcp relay instance 2 downstream
```

Verify the configuration.

```
sw-spine-002 [standalone: master] # show ip dhcp relay

Instance ID 2:
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

Instance ID 4:
  VRF Name: default

  DHCP Servers:
    10.94.100.222

  DHCP relay agent options:
    always-on         : Disabled
    Information Option: Disabled
    UDP port          : 67
    Auto-helper       : Disabled

  -------------------------------------------
  Interface   Label             Mode
  -------------------------------------------
  vlan4       N/A               downstream
```
