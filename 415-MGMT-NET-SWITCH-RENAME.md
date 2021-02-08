# Management Network Switch Rename

Any system moving from Shasta v1.3 to Shasta v1.4 software needs to adjust the hostnames and IP addresses for all switches to match the new standard.  There is now a virtual IP ending in .1 which is used by spine switches.  In Shasta v1.3, the first spine switch used the .1 address.  In Shasta v1.4, the ordering of the switches has changed with spine switches being grouped first.  The hostname for switches has changed from two digits to a dash and then 3 digits.

From v1.3, this example system had these IP addresses and hostnames on the HMN network. Similar names and IP address numbers for the NMN and CAN networks as well.

```
10.1.0.1        sw-spine01
10.1.0.2        sw-leaf01
10.1.0.3        sw-spine02
10.1.0.4        sw-leaf02
10.1.0.5        sw-cdu01
10.1.0.6        sw-cdu02
```

The desired settings for the HMN network would be more like these.

```
10.1.0.2        sw-spine-001
10.1.0.3        sw-spine-002
10.1.0.4        sw-leaf-001
10.1.0.5        sw-leaf-002
10.1.0.6        sw-cdu-001
10.1.0.7        sw-cdu-002
```

This system needs to do the renames in this order: do CDUs (6 to 7, 5 to 6) and then leafs (4 to 5, but also 2 to 4), then spines (3 to 3, and 1 to 2). These have IP address changes and name changes since we now have 3 digits instead of 2 for the switch hostname.  So even though sw-spine02 has the same IP address, it has the new name sw-spine-002.

1. Check switch IP addresses, names, and component names in /var/www/ephemeral/prep/${SYSTEM_NAME}/networks when booted from the LiveCD on ncn-m001.

   ```
   pit# export SYSTEM_NAME=eniac
   pit# cd /var/www/ephemeral/prep/${SYSTEM_NAME}/networks
   pit# vi NMN.yaml
   ```

   Excerpt from NMN.yaml

   ```
     ip_reservations:
     - ip_address: 10.252.0.2
       name: sw-spine-001
       comment: x3000c0h33s1
       aliases: []
     - ip_address: 10.252.0.3
       name: sw-spine-002
       comment: x3000c0h34s1
       aliases: []
     - ip_address: 10.252.0.4
       name: sw-leaf-001
       comment: x3000c0w38
       aliases: []
     - ip_address: 10.252.0.5
       name: sw-leaf-002
       comment: x3000c0w36
       aliases: []
     - ip_address: 10.252.0.6
       name: sw-cdu-001
       comment: d0w1
       aliases: []
     - ip_address: 10.252.0.7
       name: sw-cdu-002
       comment: d0w2
       aliases: []
   ```

   ```
   pit# vi HMN.yaml
   ```

   Excerpt from HMN.yaml

   ```
     ip_reservations:
     - ip_address: 10.254.0.2
       name: sw-spine-001
       comment: x3000c0h33s1
       aliases: []
     - ip_address: 10.254.0.3
       name: sw-spine-002
       comment: x3000c0h34s1
       aliases: []
     - ip_address: 10.254.0.4
       name: sw-leaf-001
       comment: x3000c0w38
       aliases: []
     - ip_address: 10.254.0.5
       name: sw-leaf-002
       comment: x3000c0w36
       aliases: []
     - ip_address: 10.254.0.6
       name: sw-cdu-001
       comment: d0w1
       aliases: []
     - ip_address: 10.254.0.7
       name: sw-cdu-002
       comment: d0w2
       aliases: []
   ```

   ```
   pit# vi CAN.yaml
   ```

   Excerpt from CAN.yaml showing the two spine switches. Most v1.3 systems would have had these as ending in .1 and in .3.

   ```
     ip_reservations:
     - ip_address: 10.103.8.2
       name: can-switch-1
       comment: ""
       aliases: []
     - ip_address: 10.103.8.3
       name: can-switch-2
       comment: ""
       aliases: []
   ```

2. Save the running-config from all swiches before you start.

   Note: Mellanox switches require the "enable" command before doing "show running-config"

   pit# ssh admin@10.1.0.1
   switch# show running-config
   switch# exit

   Save this information in a text file for later evaluation and comparison after all changes have been made.
   pit# vi before.sw-spine01.txt

   Repeat this for all of the switches.  The example system has switches up to 10.1.0.6.

3. Start moves with the highest numbered switch. In this case, that is sw-cdu02.

   Move sw-cdu02 to sw-cdu-002 and increase IP addresses by 1. It is a Dell switch.

   Note: You can change many addresses in a single session, but not the one you used to connect. This first connection will skip vlan 1 and change all of the other vlans (vlan 2 and vlan 4 on a CDU switch.)

   ```
   pit# ssh admin@10.1.0.6
   sw-cdu02# configure terminal
   sw-cdu02(config)# hostname sw-cdu-002
   sw-cdu-002(config)# interface vlan2
   sw-cdu-002(conf-if-vl-2)# ip address 10.252.0.7/17
   sw-cdu-002(conf-if-vl-2)# interface vlan4
   sw-cdu-002(conf-if-vl-4)# ip address 10.254.0.7/17
   sw-cdu-002(conf-if-vl-4)# router ospf 1
   sw-cdu-002(config-router-ospf-1)# router-id 10.252.0.7
   sw-cdu-002(config-router-ospf-1)# exit
   sw-cdu-002(config)# exit
   sw-cdu-002# write memory
   ```

Logout of the switch and return using the new IP address for vlan 2 so that vlan 1 can be corrected.

   ```
   sw-cdu-002# exit
   pit# ssh admin@10.252.0.7
   sw-cdu-002# configure terminal
   sw-cdu-002(config)# interface vlan1
   sw-cdu-002(conf-if-vl-1)# ip address 10.1.0.7/16
   sw-cdu-002(conf-if-vl-1)# exit
   sw-cdu-002(config)# exit
   sw-cdu-002# write memory
   sw-cdu-002# exit
   pit#
   ```

4. Move sw-cdu01 to sw-cdu-001 and increase IP addresses by 1. It is a Dell switch.

   Note: You can change many addresses in a single session, but not the one you used to connect. This first connection will skip vlan 1 and change all of the other vlans (vlan 2 and vlan 4 on a CDU switch.)

   ```
   pit# ssh admin@10.1.0.5
   sw-cdu01# configure terminal
   sw-cdu01(config)# hostname sw-cdu-001
   sw-cdu-001(config)# interface vlan2
   sw-cdu-001(conf-if-vl-2)# ip address 10.252.0.6/17
   sw-cdu-001(conf-if-vl-2)# interface vlan4
   sw-cdu-001(conf-if-vl-4)# ip address 10.254.0.6/17
   sw-cdu-001(conf-if-vl-4)# router ospf 1
   sw-cdu-001(config-router-ospf-1)# router-id 10.252.0.6
   sw-cdu-001(config-router-ospf-1)# exit
   sw-cdu-001(config)# exit
   sw-cdu-001# write memory
   ```

   Logout of the switch and return using the new IP address for vlan 2 so that vlan 1 can be corrected.

   ```
   sw-cdu-001# exit
   pit# ssh admin@10.252.0.6
   sw-cdu-001# configure terminal
   sw-cdu-001(config)# interface vlan1
   sw-cdu-001(conf-if-vl-1)# ip address 10.1.0.6/16
   sw-cdu-001(conf-if-vl-1)# exit
   sw-cdu-001(config)# exit
   sw-cdu-001# write memory
   sw-cdu-001# exit
   pit#
   ```

5. Move sw-leaf02 to sw-leaf-002 and increase IP addresses by 1. It is a Dell switch.

   Note: You can change many addresses in a single session, but not the one you used to connect. This first connection will skip vlan 1 and change all of the other vlans (vlan 2, vlan 4, vlan 7, vlan 10) on a leaf switch.

   ```
   pit# ssh admin@10.1.0.4
   sw-leaf02# configure terminal
   sw-leaf02(config)# hostname sw-leaf-002
   sw-leaf-002(config)# interface vlan2
   sw-leaf-002(conf-if-vl-2)# ip address 10.252.0.5/17
   sw-leaf-002(conf-if-vl-2)# interface vlan4
   sw-leaf-002(conf-if-vl-4)# ip address 10.254.0.5/17
   sw-leaf-002(conf-if-vl-4)# interface vlan7
   sw-leaf-002(conf-if-vl-7)# ip address 10.103.8.5/24
   sw-leaf-002(conf-if-vl-7)# interface vlan10
   sw-leaf-002(conf-if-vl-10)# ip address 10.11.0.5/16
   sw-leaf-002(conf-if-vl-10)# router ospf 1
   sw-leaf-002(config-router-ospf-1)# router-id 10.252.0.5
   sw-leaf-002(config-router-ospf-1)# exit
   sw-leaf-002(config)# exit
   sw-leaf-002# write memory
   ```

   Logout of the switch and return using the new IP address for vlan 2 so that vlan 1 can be corrected.

   ```
   sw-leaf-002# exit
   pit# ssh admin@10.252.0.5
   sw-leaf-002# configure terminal
   sw-leaf-002(config)# interface vlan1
   sw-leaf-002(conf-if-vl-1)# ip address 10.1.0.5/16
   sw-leaf-002(conf-if-vl-1)# exit
   sw-leaf-002(config)# exit
   sw-leaf-002# write memory
   sw-leaf-002# exit
   pit#
   ```

6. Move sw-leaf01 to sw-leaf-001 and increase IP addresses by 1. It is a Dell switch.

   Note: You can change many addresses in a single session, but not the one you used to connect. This first connection will skip vlan 1 and change all of the other vlans (vlan 2, vlan 4, vlan 7, vlan 10) on a leaf switch.

   ```
   pit# ssh admin@10.1.0.2
   sw-leaf01# configure terminal
   sw-leaf01(config)# hostname sw-leaf-001
   sw-leaf-001(config)# interface vlan2
   sw-leaf-001(conf-if-vl-2)# ip address 10.252.0.4/17
   sw-leaf-001(conf-if-vl-2)# interface vlan4
   sw-leaf-001(conf-if-vl-4)# ip address 10.254.0.4/17
   sw-leaf-001(conf-if-vl-4)# interface vlan7
   sw-leaf-001(conf-if-vl-7)# ip address 10.103.8.4/24
   sw-leaf-001(conf-if-vl-7)# interface vlan10
   sw-leaf-001(conf-if-vl-10)# ip address 10.11.0.4/16
   sw-leaf-001(conf-if-vl-10)# router ospf 1
   sw-leaf-001(config-router-ospf-1)# router-id 10.252.0.4
   sw-leaf-001(config-router-ospf-1)# exit
   sw-leaf-001(config)# exit
   sw-leaf-001# write memory
   ```

   Logout of the switch and return using the new IP address for vlan 2 so that vlan 1 can be corrected.

   ```
   sw-leaf-001# exit
   pit# ssh admin@10.252.0.4
   sw-leaf-001# configure terminal
   sw-leaf-001(config)# interface vlan1
   sw-leaf-001(conf-if-vl-1)# ip address 10.1.0.4/16
   sw-leaf-001(conf-if-vl-1)# exit
   sw-leaf-001(config)# exit
   sw-leaf-001# write memory
   sw-leaf-001# exit
   pit#
   ```

7. Move sw-spine02 to sw-spine-002. It already has the .3 IP address so does not need to change. It is a Mellanox switch.

   Note: You can change many addresses in a single session, but not the one you used to connect. This first connection will skip vlan 1 and change all of the other vlans (vlan 2, vlan 4, vlan 7, vlan 10) on a leaf switch.

   ```
   pit# ssh admin@10.1.0.3
   sw-spine02> enable
   sw-spine02# configure terminal
   sw-spine02(config)# hostname sw-spine-002
   sw-spine02(config)# no protocol magp
   sw-spine-002(config)# interface vlan 1 ip address 10.1.0.3/16 primary
   sw-spine-002(config)# interface vlan 2 ip address 10.252.0.3/17 primary
   sw-spine-002(config)# interface vlan 4 ip address 10.254.0.3/17 primary
   sw-spine-002(config)# interface vlan 7 ip address 10.103.8.3/24 primary
   sw-spine-002(config)# interface vlan 10 ip address 10.11.0.3/16 primary
   sw-spine-002(config)# router bgp 65533 vrf default router-id 10.252.0.3 force
   sw-spine-002(config)# router ospf 1 vrf default router-id 10.252.0.1
   sw-spine-002(config)# exit
   sw-spine-002# write memory
   ```

   Logout of the switch and return using the new IP address for vlan 2 so that vlan 1 can be corrected.

   ```
   sw-spine-002# exit
   pit# ssh admin@10.252.0.3
   sw-spine-002 [standalone: master] > enable
   sw-spine-002 [standalone: master] # configure terminal
   sw-spine-002 [standalone: master] (config) # no protocol magp
   sw-spine-002 [standalone: master] (config) # interface vlan 1
   sw-spine-002 [standalone: master] (config interface vlan 1) # no ip address
   sw-spine-002 [standalone: master] (config interface vlan 1) # ip address 10.1.0.3/16 primary
   sw-spine-002 [standalone: master] (config interface vlan 1) # exit
   sw-spine-002 [standalone: master] (config) # protocol magp
   sw-spine-002 [standalone: master] (config) #    interface vlan 2 magp 2
   sw-spine-002 [standalone: master] (config interface vlan 2 magp 2) # ip virtual-router address 10.252.0.1
   sw-spine-002 [standalone: master] (config interface vlan 2 magp 2) # ip virtual-router mac-address 00:00:5E:00:01:02
   sw-spine-002 [standalone: master] (config interface vlan 2 magp 2) # exit
   sw-spine-002 [standalone: master] (config) #    interface vlan 4 magp 4
   sw-spine-002 [standalone: master] (config interface vlan 4 magp 4) # ip virtual-router address 10.254.0.1
   sw-spine-002 [standalone: master] (config interface vlan 4 magp 4) # ip virtual-router mac-address 00:00:5E:00:01:04
   sw-spine-002 [standalone: master] (config interface vlan 4 magp 4) # exit
   sw-spine-002 [standalone: master] (config) #    interface vlan 7 magp 7
   sw-spine-002 [standalone: master] (config interface vlan 7 magp 7) # ip virtual-router address 10.103.8.20
   sw-spine-002 [standalone: master] (config interface vlan 7 magp 7) # ip virtual-router mac-address 00:00:5E:00:01:07
   sw-spine-002 [standalone: master] (config interface vlan 7 magp 7) # exit
   sw-spine-002 [standalone: master] (config) #    interface vlan 10 magp 10
   sw-spine-002 [standalone: master] (config interface vlan 10 magp 10) # ip virtual-router address 10.11.0.1
   sw-spine-002 [standalone: master] (config interface vlan 10 magp 10) # ip virtual-router mac-address 00:00:5E:00:01:10
   sw-spine-002 [standalone: master] (config interface vlan 10 magp 10) # exit
   sw-spine-002 [standalone: master] (config) # exit
   sw-spine-002 [standalone: master] # write memory
   sw-spine-002 [standalone: master] # exit
   pit#
   ```

8. Move sw-spine01 to sw-spine-001 and increase IP addresses by 1. It is a Mellanox switch.

   Note: You can change many addresses in a single session, but not the one you used to connect. This first connection will skip vlan 1 and change all of the other vlans (vlan 2, vlan 4, vlan 7, vlan 10) on a leaf switch.

   ```
   pit# ssh admin@10.1.0.1
   sw-spine01> enable
   sw-spine01# configure terminal
   sw-spine01(config)# hostname sw-spine-001
   sw-spine-001(config)# no protocol magp
   sw-spine-001(config)# interface vlan 2
   sw-spine-001 [standalone: master] (config interface vlan 2) # no ip address
   sw-spine-001 [standalone: master] (config interface vlan 2) # ip address 10.252.0.2/17 primary
   sw-spine-001 [standalone: master] (config interface vlan 2) # exit
   sw-spine-001 [standalone: master] (config) # interface vlan 4
   sw-spine-001 [standalone: master] (config interface vlan 4) # no ip address
   sw-spine-001 [standalone: master] (config interface vlan 4) # 
   sw-spine-001 [standalone: master] (config interface vlan 4) # ip address 10.254.0.2/17 primary
   sw-spine-001 [standalone: master] (config interface vlan 4) # 
   sw-spine-001 [standalone: master] (config interface vlan 4) # exit
   sw-spine-001 [standalone: master] (config) # interface vlan 7 
   sw-spine-001 [standalone: master] (config interface vlan 7) # 
   sw-spine-001 [standalone: master] (config interface vlan 7) # no ip address
   sw-spine-001 [standalone: master] (config interface vlan 7) # 
   sw-spine-001 [standalone: master] (config interface vlan 7) # ip address 10.103.8.2/24 primary
   sw-spine-001 [standalone: master] (config interface vlan 7) # 
   sw-spine-001 [standalone: master] (config interface vlan 7) # exit
   sw-spine-001 [standalone: master] (config) # interface vlan 10
   sw-spine-001 [standalone: master] (config interface vlan 10) # 
   sw-spine-001 [standalone: master] (config interface vlan 10) # no ip address
   sw-spine-001 [standalone: master] (config interface vlan 10) # 
   sw-spine-001 [standalone: master] (config interface vlan 10) #  ip address 10.11.0.2/16 primary
   sw-spine-001 [standalone: master] (config interface vlan 10) # 
   sw-spine-001 [standalone: master] (config interface vlan 10) # exit
   sw-spine-001 [standalone: master] (config) # router bgp 65533 vrf default router-id 10.252.0.2 force
   sw-spine-001 [standalone: master] (config) # router ospf 1 vrf default router-id 10.252.0.2
   sw-spine-001 [standalone: master] (config) # exit
   sw-spine-001 [standalone: master] # write memory
   ```

   Logout of the switch and return using the new IP address for vlan 2 so that vlan 1 can be corrected.

   ```
   sw-spine-001# exit
   pit# ssh admin@10.252.0.2
   sw-spine-001 [standalone: master] > enable
   sw-spine-001 [standalone: master] # configure terminal
   sw-spine-001 [standalone: master] (config) # no protocol magp
   sw-spine-001 [standalone: master] (config) # interface vlan 1
   sw-spine-001 [standalone: master] (config interface vlan 1) # no ip address
   sw-spine-001 [standalone: master] (config interface vlan 1) # ip address 10.1.0.2/16 primary
   sw-spine-001 [standalone: master] (config interface vlan 1) # exit
   sw-spine-001 [standalone: master] (config) # protocol magp
   sw-spine-001 [standalone: master] (config) #    interface vlan 2 magp 2
   sw-spine-001 [standalone: master] (config interface vlan 2 magp 2) # ip virtual-router address 10.252.0.1
   sw-spine-001 [standalone: master] (config interface vlan 2 magp 2) # ip virtual-router mac-address 00:00:5E:00:01:02
   sw-spine-001 [standalone: master] (config interface vlan 2 magp 2) # exit
   sw-spine-001 [standalone: master] (config) #    interface vlan 4 magp 4
   sw-spine-001 [standalone: master] (config interface vlan 4 magp 4) # ip virtual-router address 10.254.0.1
   sw-spine-001 [standalone: master] (config interface vlan 4 magp 4) # ip virtual-router mac-address 00:00:5E:00:01:04
   sw-spine-001 [standalone: master] (config interface vlan 4 magp 4) # exit
   sw-spine-001 [standalone: master] (config) #    interface vlan 7 magp 7
   sw-spine-001 [standalone: master] (config interface vlan 7 magp 7) # ip virtual-router address 10.103.8.20
   sw-spine-001 [standalone: master] (config interface vlan 7 magp 7) # ip virtual-router mac-address 00:00:5E:00:01:07
   sw-spine-001 [standalone: master] (config interface vlan 7 magp 7) # exit
   sw-spine-001 [standalone: master] (config) #    interface vlan 10 magp 10
   sw-spine-001 [standalone: master] (config interface vlan 10 magp 10) # ip virtual-router address 10.11.0.1
   sw-spine-001 [standalone: master] (config interface vlan 10 magp 10) # ip virtual-router mac-address 00:00:5E:00:01:10
   sw-spine-001 [standalone: master] (config interface vlan 10 magp 10) # exit
   sw-spine-001 [standalone: master] (config) # exit
   sw-spine-001 [standalone: master] # write memory
   sw-spine-001 [standalone: master] # exit
   pit#
   ```

9. Save the running-config from all swiches after completion

   Note: Mellanox switches require the "enable" command before doing "show running-config"

   ```
   pit# ssh admin@10.1.0.2
   switch# show running-config
   switch# exit
   ```
   
   Save this information in a text file for comparison with the running-config saved before all changes were made.
   `pit# vi after.sw-spine01.txt`

   Repeat this for all of the switches.  The example system has switches up to 10.1.0.7.

There are other changes needed, as described in [Dell and Mellanox Changes for Shasta v1.3 to v1.4 Upgrades](412-MGMT-NET-DELL-MELLANOX-UPGRADES.md)

