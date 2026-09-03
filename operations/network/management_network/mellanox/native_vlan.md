# Native VLAN

Untagged ingress packets are destined to the native VLAN. An interface can be configured
in one of two native modes - native untagged or native tagged.

A native untagged port accepts any untagged or tagged (with native VLAN ID) traffic on ingress.
Packets that egress on a native untagged port in the native VLAN will not have an `802.1Q` header.

A native tagged port accepts only tagged traffic (with native VLAN ID) on ingress.
Any untagged packet ingress on a native tagged port is always dropped.
Packets that egress on a native tagged port in the native VLAN will always have an `802.1Q` header.

## Configuration commands

(`switch#`) Configure a VLAN as native.

```console
enable
configure terminal
vlan 3
exit
interface ethernet 1/1
switchport mode hybrid
switchport access vlan 3
```

## Show commands to validate functionality

(`switch#`)

```console
show interface switchport
```

## Expected results

* Administrators can create a VLAN.
* Administrators can assign a native VLAN to the physical interface.
* Administrators can configure an IP address on the VLAN interface.
* Administrators can successfully ping the other switch's VLAN interface.

[Back to Index](../README.md)
