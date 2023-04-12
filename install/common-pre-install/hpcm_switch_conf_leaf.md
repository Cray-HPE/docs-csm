# Configuration of Leaf Switch 001

Copy the following text for `sw-leaf-bmc-001` configuration:

> __Note:__ The username and password must be updated accordingly.

```text
! Version 10.5.1.4
! Last configuration change at Mar  06 12:09:16 2023
!
ip vrf default
!
hostname sw-leaf-bmc-001
iscsi enable
iscsi target port 860
iscsi target port 3260
system-user [LINUXADMIN] password [PASSWORD]
username [ADMIN] password [PASSWORD]
aaa authentication login default local
aaa authentication login console local
!
class-map type application class-iscsi
!
policy-map type application policy-iscsi
!
interface vlan1
 no shutdown
 ip address 10.1.0.4/16
!
interface port-channel51
 no shutdown
 switchport access vlan 1
!
interface mgmt1/1/1
 no shutdown
 ip address dhcp
 ipv6 address autoconfig
!
interface ethernet1/1/1
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/2
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/3
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/4
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/5
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/6
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/7
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/8
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/9
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/10
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/11
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/12
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/13
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/14
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/15
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/16
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/17
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/18
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/19
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/20
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/21
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/22
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/23
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/24
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/25
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/26
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/27
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/28
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/29
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/30
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/31
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/32
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/33
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/34
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/35
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/36
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/37
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/38
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/39
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/40
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/41
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/42
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/43
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/44
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/45
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/46
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/47
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/48
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/49
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/50
 no shutdown
 switchport access vlan 1
 flowcontrol receive on
!
interface ethernet1/1/51
 no shutdown
 channel-group 51
 no switchport
 flowcontrol receive on
!
interface ethernet1/1/52
 no shutdown
 channel-group 51
 no switchport
 flowcontrol receive on
!
snmp-server contact "Contact Support"
!
telemetry
ntp server 10.1.0.5
```
