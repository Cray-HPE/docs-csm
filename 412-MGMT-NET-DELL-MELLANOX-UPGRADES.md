### Management Network Dell And Mellanox Upgrades

The Dell and Mellanox switches have some changes which are needed when moving from Shasta v1.3 to Shasta v1.4.
This page is a guide to walk through the steps of upgrading a network to 1.4.

## 1. Firmware Upgrade
With shasta 1.4 we are using the following firmware, [FIRMWARE](409-MGMT-NET-FIRMWARE-UPDATE.md)


## 2. IP Address and Hostname Changes 
CSI will generate the IPs for the switches on a 1.4 system, they will be located here "/var/www/ephemeral/prep/{system-name}/networks" when ncn-m001 is booted from the LiveCD.

Here is a snippet from NMN.yaml with the IP addresses and hostnames of the switches.  

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

On most 1.3.x systems the IP addresses and hostnames will be as shown below, which will require them to be updated. 

```
spine-01 10.252.0.1
spine-02 10.252.0.3
leaf-01 10.252.0.2
```

To make the hostname and IP address changes for all switches, follow this procedure [Management Network Switch Rename](415-MGMT-NET-SWITCH-RENAME.md)

## 3. Dell Changes to switch from bpdufilter to bpduguard
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


## Mellanox Changes for MAGP

### MAGP
MAGP setup for mellanox spine switches, this should be set for every VLAN interface (1,2,4,7,10)
https://community.mellanox.com/s/article/howto-configure-magp-on-mellanox-switches

```
   protocol magp
   interface vlan 1 magp 1
   interface vlan 2 magp 2
   interface vlan 4 magp 4
   interface vlan 7 magp 7
   interface vlan 10 magp 10
   interface vlan 1 magp 1 ip virtual-router address 10.1.0.1
   interface vlan 2 magp 2 ip virtual-router address 10.252.0.1
   interface vlan 4 magp 4 ip virtual-router address 10.254.0.1
   interface vlan 7 magp 7 ip virtual-router address 10.103.8.20
   interface vlan 10 magp 10 ip virtual-router address 10.11.0.1
   interface vlan 1 magp 1 ip virtual-router mac-address 00:00:5E:00:01:01
   interface vlan 2 magp 2 ip virtual-router mac-address 00:00:5E:00:01:02
   interface vlan 4 magp 4 ip virtual-router mac-address 00:00:5E:00:01:04
   interface vlan 7 magp 7 ip virtual-router mac-address 00:00:5E:00:01:07
   interface vlan 10 magp 10 ip virtual-router mac-address 00:00:5E:00:01:10
```
Output of a working MAGP
```
sw-spine-001 [standalone: master] # show magp

MAGP 1:
  Interface vlan: 1
  Admin state   : Enabled
  State         : Master
  Virtual IP    : 10.1.0.1
  Virtual MAC   : 00:00:5E:00:01:01

MAGP 2:
  Interface vlan: 2
  Admin state   : Enabled
  State         : Master
  Virtual IP    : 10.252.0.1
  Virtual MAC   : 00:00:5E:00:01:02

MAGP 4:
  Interface vlan: 4
  Admin state   : Enabled
  State         : Master
  Virtual IP    : 10.254.0.1
  Virtual MAC   : 00:00:5E:00:01:04

MAGP 7:
  Interface vlan: 7
  Admin state   : Enabled
  State         : Master
  Virtual IP    : 10.103.8.20
  Virtual MAC   : 00:00:5E:00:01:07

MAGP 10:
  Interface vlan: 10
  Admin state   : Enabled
  State         : Master
  Virtual IP    : 10.11.0.1
  Virtual MAC   : 00:00:5E:00:01:10
```

### MLAG
Check if MLAG is setup already.
```
sw-spine-002 [standalone: master] # show mlag
Admin status: Enabled
Operational status: Up
Reload-delay: 30 sec
Keepalive-interval: 1 sec
Upgrade-timeout: 60 min
System-mac: 00:00:5E:00:01:01

MLAG Ports Configuration Summary:
 Configured: 15
 Disabled:   0
 Enabled:    15

MLAG Ports Status Summary:
 Inactive:       0
 Active-partial: 1
 Active-full:    14

MLAG IPLs Summary:
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
ID   Group         Vlan       Operational  Local                                    Peer                                     Up Time              Toggle Counter
     Port-Channel  Interface  State        IP address                               IP address
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
1    Po100         4000       Up           192.168.255.253                          192.168.255.254                          19 days, 18:25:56    1

MLAG Members Summary:
---------------------------------------------------------------------
System-id           State                        Hostname
---------------------------------------------------------------------
50:6B:4B:9C:C6:48   Up                           <sw-spine-002>
98:03:9B:EF:D6:48   Up
```
If output looks like the following, MLAG is already setup.
If MLAG needs to be setup on the system follow these steps.  Most 1.3 systems will have this already configured.
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
sw-spine-001 [rocket-mlag-domain: master] # show mlag-vip
MLAG-VIP:
 MLAG group name: rocket-mlag-domain
 MLAG VIP address: 192.168.255.242/29
 Active nodes: 2
 
----------------------------------------------------------------------------------
Hostname                                 VIP-State            IP Address
----------------------------------------------------------------------------------
sw-spine-001                               master               192.168.255.241
sw-spine-002                               standby              192.168.255.243
```

## Update SNMP configuration

There have been no changes to SNMP in 1.4.
You can verify the settings here.
See [SNMP](407-MGMT-NET-SNMP-CONFIG.md)

## Update CAN configuration

Some systems may have had many switches on the CAN with Shasta v1.3.  In Shasta v1.4, only the spine switches should be on the CAN.  Other switches should remove their IP addresses on vlan7.

See [CAN](408-MGMT-NET-CAN-CONFIG.md)

## Update NTP configuration

Some Shasta v1.3 systems may have set the switch ntp server to be the IP address of ncn-w001.  With the switch rename, the old IP address for ncn-w001 may now be assigned to one of the switches.
The Shasta v1.4 configuration sets the switches to have the first three worker nodes as their ntp servers.

See [NTP](414-MGMT-NET-NTP-CONFIG.md)

## Verify flow-control settings

With Shasta v1.3.2, some changes were made for the flow-control settings which may not be on Shasta v1.3.0 systems.  Verify that these are set correctly for Shasta v1.4.
These changes for flow-control will also disable iSCSI on Dell Switches (Leaf, CDU, and Aggregation).

See [Flow Control](417-MGMT-NET-FLOW-CONTROL.md)
https://connect.us.cray.com/confluence/display/SSI/Management+Network+Changes+for+Shasta+1.3.2

## Update DHCP IP helper configuration

With Shasta v1.3.2, some changes were made for the ip-helper settings which may not be on Shasta v1.3.0 systems.  Verify that these are set correctly for Shasta v1.4.
The IP-helpers are being moved for the switches that are doing the Layer3 Routing.  For most systems this will be moving the helper from the leaf to the spine.
Also the IP-helpers are being added on VLAN1 and VLAN7 to PXE boot NCNs.

See [IP-Helper](418-MGMT-NET-IP-HELPER.md)

https://connect.us.cray.com/confluence/display/SSI/Management+Network+Changes+for+Shasta+1.3.2

# Verify My Dell/Mellanox system is 1.4 compliant.

- Make sure firmware is up to date.
- Change IP addresses of switches accordingly.
- Verify Dell BPDU configuration.
- Verify MLAG is setup.
- Verify MAGP is setup for ALL vlans.
- Verify NTP configuration is updated.
- Verify flow-control settings.
- Verify DHCP IP-Helper settings.

