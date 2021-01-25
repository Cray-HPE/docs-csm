# Management Network VLAN Configuration

# Requirements

- Access to all of the switches
- SHCD available

# Configuration

At this point we should have access to the switches.
We will start by adding all the VLANS required by the Shasta system.
**Cray Site Init (CSI) generates the IPs used by the system, below are samples only.**

| VLAN | Switch1 IP | Switch2 IP	| Active Gateway | Purpose |
| --- | --- | ---| --- | --- | --- | --- |
| 2 | 10.252.0.2/17| 10.252.0.3/17 | 10.252.0.1 | Node Management
| 4 | 10.254.0.2/17| 10.254.0.3/17 | 10.254.0.1 | Hardware Management
| 7 | TBD| TBD | TBD | Customer Access Network
| 10 | 10.11.0.2/17| 10.11.0.3/17 | 10.11.0.1 | Storage (future)

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

Add the networks to the switches that the BMCs are connected to.

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

