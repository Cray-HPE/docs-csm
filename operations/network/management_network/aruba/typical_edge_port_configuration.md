# Typical Edge Port Configuration

The following is a very basic configuration for devices that are single homed to the network.
For instance, network ILO cards, BMCs, PDUs, and so on.

## `Leaf-01`

```console
interface 1/1/47
    no shutdown
    mtu 9198
    description HMN
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
```

## `Leaf-02`

```console
interface 1/1/47
    no shutdown
    mtu 9198
    description BMC
    no routing
    vlan access 4
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
```

[Back to Index](../README.md)
