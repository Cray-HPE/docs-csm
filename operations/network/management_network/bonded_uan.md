# Bonded UAN Configuration

This document shows how to configure the management network when bonded UANs are used.
These configurations should be implemented via the [custom configuration](canu/custom_config.md) feature in CANU.
There are two ways to implement bonded UAN configuration.

1. [25GB Bonded UAN Configuration](#25gb-bonded-uan-configuration) (Most commonly used)
    - The only difference between this configuration and the default configuration is that OCP & PCIe port 1 are in a bond.
    - These connections are plugged into a spine (TDS) or leaf (FULL) switch.
2. [1GB or 10GB Bonded UAN](#1gb-or-10gb-bonded-uan) (Not commonly used)
    - These use a RJ45 NIC to connect to a pair of Aruba 8360 switches that are used as `leaf-bmc` switches.
    - For high availability VSX needs to be configured. This is not typically done on `leaf-bmc` switches so it will require additional custom configuration.

## 25GB Bonded UAN Configuration

This is the primary configuration for bonded UAN.

Notice that `sw-spine-002` does NOT have `lacp fallback` enabled. This allows the UAN to boot over the first interface and avoids PXE/BSS issues. If `lacp fallback` is enabled on the secondary switch there will be booting issues.

```yaml
sw-spine-001: |
  interface 1/1/16
      description uan001:ocp:1<==sw-spine-001
      no shutdown
      mtu 9198
      lag 17
      exit
  interface lag 16 multi-chassis
      description uan001:ocp:1<==sw-spine-001
      no shutdown
      no routing
      vlan access 2
      lacp mode active
      lacp fallback
      spanning-tree port-type admin-edge

sw-spine-002: |
  interface 1/1/16
      description uan001:pcie-slot1:1<==sw-spine-002
      no shutdown
      mtu 9198
      lag 17
      exit
  interface lag 16 multi-chassis
      description uan001:pcie-slot1:1<==sw-spine-002
      no shutdown
      no routing
      vlan access 2
      lacp mode active
      spanning-tree port-type admin-edge
```

## 1GB or 10GB Bonded UAN

This is using a pair of Aruba 8360 switches as `sw-leaf-bmc`.
The `system-mac` NEEDS to be unique across the system. This should NOT match any other `system-mac` on the system.

```yaml
sw-leaf-bmc-001: |
  interface lag 1 multi-chassis
      no shutdown
      description gateway001
      no routing
      vlan trunk native 2
      vlan trunk allowed 2
      lacp mode active
      lacp fallback
      spanning-tree port-type admin-edge
  interface lag 255 multi-chassis
      no shutdown
      description leaf_bmc_to_leaf_lag
      no routing
      vlan trunk native 1
      vlan trunk allowed 1-2,4,7
      lacp mode active
  interface lag 256
      no shutdown
      description ISL link
      no routing
      vlan trunk native 1 tag
      vlan trunk allowed all
      lacp mode active
  interface 1/1/1
      no shutdown
      mtu 9198
      description gateway001:ocp:1<==sw-leaf-bmc-001
      lag 1
  interface 1/1/48
      no shutdown
      vrf attach keepalive
      description VSX keepalive
      ip address 192.168.255.1/31
  interface 1/1/49
      no shutdown
      mtu 9198
      description VSX isl
      lag 256
  interface 1/1/50
      no shutdown
      mtu 9198
      description VSX isl
      lag 256
  interface 1/1/51
      no shutdown
      mtu 9198
      description sw-leaf-001:51<==sw-leaf-bmc-001
      lag 255
  interface 1/1/52
      no shutdown
      mtu 9198
      description sw-leaf-002:51<==sw-leaf-bmc-001
      lag 255
  vsx
      system-mac 02:01:00:00:09:00
      inter-switch-link lag 256
      role primary
      keepalive peer 192.168.255.0 source 192.168.255.1 vrf keepalive
      linkup-delay-timer 600
      vsx-sync vsx-global

sw-leaf-bmc-002: |
  interface lag 1 multi-chassis
      no shutdown
      description gateway001
      no routing
      vlan trunk native 2
      vlan trunk allowed 2
      lacp mode active
      lacp fallback
      spanning-tree port-type admin-edge
  interface lag 255 multi-chassis
      no shutdown
      description leaf_bmc_to_leaf_lag
      no routing
      vlan trunk native 1
      vlan trunk allowed 1-2,4,7
      lacp mode active
  interface lag 256
      no shutdown
      description ISL link
      no routing
      vlan trunk native 1 tag
      vlan trunk allowed all
      lacp mode active
  interface 1/1/1
      no shutdown
      mtu 9198
      description gateway001:ocp:1<==sw-leaf-bmc-002
      lag 1
  interface 1/1/48
      no shutdown
      vrf attach keepalive
      description VSX keepalive
      ip address 192.168.255.0/31
  interface 1/1/49
      no shutdown
      mtu 9198
      description VSX isl
      lag 256
  interface 1/1/50
      no shutdown
      mtu 9198
      description VSX isl
      lag 256
  interface 1/1/51
      no shutdown
      mtu 9198
      description sw-leaf-001:51<==sw-leaf-bmc-002
      lag 255
  interface 1/1/52
      no shutdown
      mtu 9198
      description sw-leaf-002:51<==sw-leaf-bmc-002
      lag 255
  vsx
      system-mac 02:01:00:00:09:00
      inter-switch-link lag 256
      role primary
      keepalive peer 192.168.255.1 source 192.168.255.0 vrf keepalive
      linkup-delay-timer 600
      vsx-sync vsx-global
```
