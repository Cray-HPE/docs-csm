# Management Network VLAN Configuration

# Requirements

- Access to all of the switches
- SHCD available

# Aruba Configuration

At this point we should have access to the switches.
We will start by adding all the VLANS required by the Shasta system.
**Cray Site Init (CSI) generates the IPs used by the system, below are samples only.**
Some switches will NOT need the CAN(VLAN7), most of the time this IP is only located on the Spine for external connectivity.

The River Cabinets will need the following VLANs

| VLAN | Switch1 IP | Switch2 IP	| Active Gateway | Purpose |
| --- | --- | ---| --- | --- | --- | --- |
| 2 | 10.252.0.2/17| 10.252.0.3/17 | 10.252.0.1 | River Node Management
| 4 | 10.254.0.2/17| 10.254.0.3/17 | 10.254.0.1 | River Hardware Management
| 7 | TBD| TBD | TBD | Customer Access Network
| 10 | 10.11.0.2/17| 10.11.0.3/17 | 10.11.0.1 | Storage (future)

The Mountain Cabinets will need the following VLANs, these are typically the CDU switches.
The 2xxx and 3xxx VLANs are per cabinet, so with each additional cabinet you will increment the VLAN by 1 and add a new /22 subnet.

| VLAN | Switch1 IP | Switch2 IP	| Purpose |
| --- | --- | ---| --- | --- | --- | --- |
| 2 | 10.252.0.x/17| 10.252.0.x/17 | River Node Management
| 4 | 10.254.0.x/17| 10.254.0.x/17 | River Hardware Management
| 2000 | 10.100.0.2/22| 10.100.0.3/22 | Mountain Node Management
| 3000 | 10.104.0.2/22| 10.104.0.3/22 | Mountain Hardware Management


Add the networks to each of the VSX pairs.
```
sw-24g03(config)# vlan 2
sw-24g03(config-vlan-2)# name NMN
sw-24g03(config-vlan-2)# vlan 4
sw-24g03(config-vlan-4)# name HMN
sw-24g03(config-vlan-4)# vlan 7 
sw-24g03(config-vlan-7)# name CAN
sw-24g03(config-vlan-7)# vlan 10
sw-24g03(config-vlan-10)# name SUN

sw-24g04(config)# vlan 2
sw-24g04(config-vlan-2)# name NMN
sw-24g04(config-vlan-2)# vlan 4
sw-24g04(config-vlan-4)# name HMN
sw-24g04(config-vlan-4)# vlan 7 
sw-24g04(config-vlan-7)# name CAN
sw-24g04(config-vlan-7)# vlan 10
sw-24g04(config-vlan-10)# name SUN
```

Add the networks to the leaf switches or the switches that the BMCs are connected to.

```
sw-smn01(config)# vlan 2
sw-smn01(config-vlan-2)# name NMN
sw-smn01(config-vlan-2)# vlan 4
sw-smn01(config-vlan-4)# name HMN
sw-smn01(config-vlan-4)# vlan 7 
sw-smn01(config-vlan-7)# name CAN
sw-smn01(config-vlan-7)# vlan 10
sw-smn01(config-vlan-10)# name SUN
```

Add VLAN interfaces to the VLANs just created.
Specific Addresses are provide CSI.

```
sw-smn01(config)# int vlan 1
sw-smn01(config-if-vlan)# ip address 10.1.0.4/16
sw-smn01(config-if-vlan)# int vlan 2
sw-smn01(config-if-vlan)# ip address 10.252.0.4/17
sw-smn01(config-if-vlan)# int vlan 4
sw-smn01(config-if-vlan)# ip address 10.254.0.4/17
```


