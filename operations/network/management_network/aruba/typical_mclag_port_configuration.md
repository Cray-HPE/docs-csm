
# Typical configuration of MCLAG link connecting to NCN

The intent here is to showcase a very basic MCLAG link configuration -- your configuration may differ. Note the `multi-chassis` definition after the `interface lag xx` command. This is what defines the LAG to be able to peer both to `Spine-01` and `Spine-02`.

Spine-01
```
interface lag 1 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/1
    no shutdown
    mtu 9198
    lag 1
```

Spine-02
```
interface lag 1 multi-chassis
    no shutdown
    no routing
    vlan trunk native 1
    vlan trunk allowed 1-2,4,7,10
    lacp mode active
    lacp fallback
    spanning-tree bpdu-guard
    spanning-tree port-type admin-edge
interface 1/1/1
    no shutdown
    mtu 9198
    lag 1
```

[Back to Index](../index.md)
