### Management Network Dell And Mellanox Upgrades

## IP Changes
- CSI will generate the IPs for the switches on a 1.4 system, they will be located here "/var/www/ephemeral/prep/root/{system-name}/networks"on the liveCD/m001.
- here's a snipet of NMN.yaml

```
ip_reservations:
 - ip_address: 10.252.0.2
   name: sw-spine-001
   comment: x3000c0h41s1
   aliases: []
 - ip_address: 10.252.0.3
   name: sw-spine-002
   comment: x3000c0h41s2
   aliases: []
 - ip_address: 10.252.0.4
   name: sw-leaf-001
   comment: x3000c0w40
   aliases: []
```
- Next step is to validate whether the switches match the NMN.yaml, HMN.yaml, and CAN.yaml files, If the IPs do not match you will have to change the IP for the appropriate network. 
- On most 1.3.x systems the IP addresses will be as shown below, which will require them to be updated. 

```
spine-01 10.252.0.1
spine-02 10.252.0.3
leaf-01 10.252.0.2
```
- To verify that these are correct you can SSH into the device and check the hostname or check the switch config repo.  Here's an example of rockets switch repo https://stash.us.cray.com/projects/SSI/repos/network-switch-cfg/browse/Rocket/RiverSpine/Mellanox_SN2100_v3.9/sw-spine01.conf

Changing Mellanox IP

```
sw-spine01 [rocket-mlag-domain: standby] > ena
sw-spine01 [rocket-mlag-domain: standby] # conf t
sw-spine01 [rocket-mlag-domain: standby] (config) # no protocol magp
sw-spine01 [rocket-mlag-domain: standby] (config interface vlan 2) # no ip address 10.252.0.1/17
sw-spine01 [rocket-mlag-domain: standby] (config interface vlan 2) # ip address 10.252.0.2/17
```
 - If MAGP is enabled it will need to be disabled before deleting the current IP.  This needs to be turned back on and configured in the MAGP section.

 Changing Dell IP

 ```
sw-leaf01# configure terminal
sw-leaf01(config)# interface vlan 2
sw-leaf01(conf-if-vl-2)# ip address 10.252.0.4/17
 ```
 - When changing these IPs make sure you are not changing the IP that you are currently SSHed to.
 - Make sure the IP change is done for all VLANs. (1, 2, 4, 7, 10)
 - make sure to write memory to save changes. 

- Mellanox Write memory
 ```
sw-spine01 [rocket-mlag-domain: standby] (config) # write memory
 ```
- Dell Write memory
```
sw-leaf01# write memory
```

## Dell Changes
* Remove spanning-tree bpdufilter
* Add spanning-tree bpduguard

Shasta v1.3 (old) config
```
!v1.3 config
interface ethernet1/1/3
 no shutdown
 switchport mode trunk
 switchport access vlan 1
 switchport trunk allowed vlan 2,4,7,10
 mtu 9216
 flowcontrol receive on
 flowcontrol transmit off
 spanning-tree bpdufilter enable
 spanning-tree port type edge
```

Shasta v1.4 (new) config
```
!v1.4 config
interface ethernet1/1/2
 no shutdown
 switchport mode trunk
 switchport access vlan 1
 switchport trunk allowed vlan 2,4,7,10
 mtu 9216
 flowcontrol receive on
 flowcontrol transmit off
 spanning-tree bpduguard enable
 spanning-tree port type edge
```

Shasta v1.3 to v1.4 Delta
```
!v1.3 to v1.4 changes
configure terminal
interface ethernet 1/1/x
no spanning-tree bpdufilter 
spanning-tree bpduguard enable
exit
write memory
```

Dell CDU changes
Add BPDUgudard to ports going to CMMs

```
interface port-channel1
 description CMM_CAB_1000
 no shutdown
 switchport mode trunk
 switchport access vlan 2000
 switchport trunk allowed vlan 3000,4091
 mtu 9216
 vlt-port-channel 1
 spanning-tree bpduguard enable
```


## Mellanox Changes
### MAGP
MAGP setup for mellanox spine switches, this should be set for every VLAN interface. 
https://community.mellanox.com/s/article/howto-configure-magp-on-mellanox-switches
#### Spine01
```
(config) # protocol mlag
(config) # interface port-channel 100
(config) # interface ethernet 1/14 channel-group 100 mode active
(config) # interface ethernet 1/13 channel-group 100 mode active
(config) # interface ethernet 1/13 dcb priority-flow-control mode on force
(config) # interface ethernet 1/14 dcb priority-flow-control mode on force
(config) # vlan 4000
(config) # interface vlan 4000
(config) # interface port-channel 100 ipl 1
(config) # interface port-channel 100 dcb priority-flow-control mode on force
(config interface vlan 4000) # ip address 192.168.255.254 255.255.255.252
(config interface vlan 4000) # ipl 1 peer-address 192.168.255.253
(config) # mlag system-mac 00:00:5E:00:01:5D
(config) # no mlag shutdown
```
#### Spine02
```
(config) # protocol mlag
(config) # interface port-channel 100
(config) # interface ethernet 1/14 channel-group 100 mode active
(config) # interface ethernet 1/13 channel-group 100 mode active
(config) # interface ethernet 1/13 dcb priority-flow-control mode on force
(config) # interface ethernet 1/14 dcb priority-flow-control mode on force
(config) # vlan 4000
(config) # interface vlan 4000
(config) # interface port-channel 100 ipl 1
(config) # interface port-channel 100 dcb priority-flow-control mode on force
(config interface vlan 4000) # ip address 192.168.255.253 255.255.255.252
(config interface vlan 4000) # ipl 1 peer-address 192.168.255.254
(config) # mlag system-mac 00:00:5E:00:01:5D
(config) # no mlag shutdown
```

Adding MLAG ports (these ports go to NCNs)
#### Spine01
```
(config) # int mlag-port-channel 1
(config interface mlag-port-channel 1) # mtu 9216 force
(config interface mlag-port-channel 1) # switchport mode hybrid
(config interface mlag-port-channel 1) # no shutdown
(config interface mlag-port-channel 1) # lacp-individual enable force
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 2
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 4
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 7
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 10
```

#### Spine02
NOTE: 'lacp fallback' is only on one of the Spines.
We are only applying it to Spine01 here.
```
(config) # int mlag-port-channel 1
(config interface mlag-port-channel 1) # mtu 9216 force
(config interface mlag-port-channel 1) # switchport mode hybrid
(config interface mlag-port-channel 1) # no shutdown
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 2
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 4
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 7
(config interface mlag-port-channel 1) # switchport hybrid allowed-vlan add 10
```

Once you create the MLAG you need to add ports to it.

```
(config) # interface ethernet 1/1
(config interface ethernet 1/1) # mlag-channel-group 1 mode active
(config interface ethernet 1/1) # interface ethernet 1/1 speed 40G force
(config interface ethernet 1/1) # interface ethernet 1/1 mtu 9216 force
```

Configuration with Recommended MLAG-VIP cable.
- This is recommended by Mellanox but not required.
- It's purpose is to prevent "split brain" which is where both spines think they are the active gateway.
- It requires a RJ45 cable between the mgmt0 ports on both switches.
- https://community.mellanox.com/s/article/how-to-configure-mlag-on-mellanox-switches#jive_content_id_MLAG_VIP

#### Spine01
```
no interface mgmt0 dhcp
   interface mgmt0 ip address 192.168.255.241 /29
no mlag shutdown
   mlag system-mac 00:00:5E:00:01:5D
mlag-vip rocket-mlag-domain ip 192.168.255.242 /29 force
   ```

#### Spine02
```
no interface mgmt0 dhcp
   interface mgmt0 ip address 192.168.255.243 /29
no mlag shutdown
   mlag system-mac 00:00:5E:00:01:5D	
mlag-vip rocket-mlag-domain ip 192.168.255.242 /29 force
```

Verifying mlag-vip
```
sw-spine01 [rocket-mlag-domain: master] # show mlag-vip
MLAG-VIP:
 MLAG group name: rocket-mlag-domain
 MLAG VIP address: 192.168.255.242/29
 Active nodes: 2
 
----------------------------------------------------------------------------------
Hostname                                 VIP-State            IP Address
----------------------------------------------------------------------------------
sw-spine01                               master               192.168.255.241
sw-spine02                               standby              192.168.255.243
```