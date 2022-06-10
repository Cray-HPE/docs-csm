# Native VLAN

Untagged ingress packets are destined to the native VLAN. An interface can be configured in one of two native modes - Native-Untagged or Native-Tagged. A native-untagged port accepts any untagged or tagged (with native VLAN ID) traffic on ingress. Packets that egress on a native-untagged port in the native VLAN will not have an 802.1Q header. A native-tagged port accepts only tagged traffic (with native VLAN ID) on ingress. Any untagged packet ingress on a native-tagged port is always dropped. Packets that egress on a native-tagged port in the native VLAN will always have an 802.1Q header.

## Configuration Commands

Configure a VLAN as native:

```text
switch(config-if)# vlan trunk native VLAN
```

Show commands to validate functionality:

```text
show vlan [VLAN]
```

## Example Output

```text
switch(config)# vlan 100
switch(config-vlan-100)# no shutdown
switch(config-vlan-100)# end
switch(config)# interface 1/1/1
switch(config-if)# no shutdown
switch(config-if)# no routing
switch(config-if)# vlan trunk native 100
switch(config-if)# exit
show vlan
--------------------------------------------------------------------------------------
VLAN  Name                              Status  Reason          Type      Interfaces
--------------------------------------------------------------------------------------
1     DEFAULT_VLAN_1                    down    no_member_port  default
100   VLAN100                           up      ok              static    1/1/1
```

## Expected Results

1. Administrators can create a VLAN
2. Administrators can assign a native VLAN to the physical interface
3. Administrators can configure an IP address on the VLAN interface
4. Administrators can successfully ping the other switch's VLAN interface

[Back to Index](../README.md)

