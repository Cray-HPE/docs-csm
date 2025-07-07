# NMN Isolation

## NMN Isolation Overview

Three main components:

1. Allow traffic only to required CSM services - management node access controls.
2. Prevent Mountain compute nodes from communicating with each other - Mountain managed node access controls.
3. Prevent River compute, and user nodes (UAN, Login, Gateway, etc...) from communicating with each other - River managed node access controls.

## Components

TODO - INSERT DIAGRAM and describe components

### Management Node Access Controls

TODO

### Mountain Cabinet Node Access Controls

Denied the access between Cabinets.
e.g

```text
160 comment BLOCK traffic between NMN_MTN_CABINETS
170 deny any 10.100.0.0/255.255.252.0 10.100.4.0/255.255.252.0
180 deny any 10.100.4.0/255.255.252.0 10.100.0.0/255.255.252.0
```

### River Managed Node Access Controls

TODO

## CANU normal mode

`canu generate switch config ... --enable-nmn-isolation`
`canu generate network config <snip> --enable-nmn-isolation`
`canu validate switch config ... --enable-nmn-isolation`
`canu validate network config <snip> --enable-nmn-isolation`

The `--enable-nmn-isolation` flag enables all three components of NMN Isolation in the switch configurations.

## CANU expert mode

Custom configs, `custom-config.yaml` in the documentation, are an expert mode for those customers who want more control over their management network switch configurations.

https://github.com/Cray-HPE/canu/blob/main/docs/network_configuration_and_upgrade/custom_config.md

Customer can insert site-specific configurations into CANU switch configurations. Examples include:

* Uplinks from the system spine switches to edge, or site switching.
* Limited overrides of CANU defaults.

Custom configuration also allows customers to individually feature flag NMN Isolation components, overriding command line flag behavior.

```yaml
features:
    nmn_isolation:
        services: true|false
        rvr_isolation: true|false
            rvr_isolation_pvlan: <vlan_number>
        mtn_isolation: true|false
sw-spine-001:  |
    ip route 0.0.0.0/0 10.103.15.185
    interface 1/1/36
        no shutdown
        ip address 10.103.15.186/30
        exit
    system interface-group 3 speed 10g
    interface 1/1/2
        no shutdown
        mtu 9198
        description sw-spine-001:16==>ion-node
        no routing
        vlan access 7
        spanning-tree bpdu-guard
        spanning-tree port-type admin-edge
sw-spine-002:  |
    ip route 0.0.0.0/0 10.103.15.189
    interface 1/1/36
        no shutdown
        ip address 10.103.15.190/30
        exit
    system interface-group 3 speed 10g
```
