# Typical Configuration of MLAG Between Switches

This document showcases a very basic MLAG configuration between two spine switches.

## `Spine-01`

```console
mlag-vip cray-mlag-domain ip 192.168.255.242 /29 force
no mlag shutdown
mlag system-mac 00:00:5E:00:01:01
interface port-channel 100 ipl 1
interface vlan 4000 ipl 1 peer-address 192.168.255.253
```

## `Spine-02`

```console
mlag-vip cray-mlag-domain ip 192.168.255.242 /29 force
no mlag shutdown
mlag system-mac 00:00:5E:00:01:5D
interface port-channel 100 ipl 1
interface vlan 4000 ipl 1 peer-address 192.168.255.254
```

[Back to Index](../README.md)
