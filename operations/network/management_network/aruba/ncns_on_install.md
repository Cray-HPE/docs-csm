
# NCNs on Install

Use this procedure to verify the DNSMASQ config file on the NCNs is accurate.

## Procedure

1. Verify the DNSMASQ config file matches what is configured on the switches.

    The following is a DNSMASQ config file for the Metal network (VLAN1). The router is 10.1.0.1, which has to match what the IP address is on the switches doing the routing for the Metal (MTL) network.  

    Example MTL DNSMASQ file:

    ```
    # MTL:
    server=/mtl/
    address=/mtl/
    domain=mtl,10.1.1.0,10.1.1.233,local
    dhcp-option=interface:bond0,option:domain-search,mtl
    interface=bond0
    interface-name=pit.mtl,bond0
    ```

    This is most commonly on the spines. This configuration is commonly missed on the CSI input file.

1. Verify it points to the LiveCD IP address for provisioning in bare-metal environments:

    ```
    dhcp-option=interface:bond0,option:dns-server,10.1.1.2
    dhcp-option=interface:bond0,option:ntp-server,10.1.1.2
    ```

1. Verify it points at the router for the network; the L3/IP for the VLAN:

    ```
    dhcp-option=interface:bond0,option:router,10.1.0.1
    dhcp-range=interface:bond0,10.1.1.33,10.1.1.233,10m
    ```

## Configuration Example

The following is an example Aruba configuration for the spine:

```bash
sw-spine-001# show run int vlan 1
interface vlan1
    vsx-sync active-gateways
    ip address 10.1.0.2/16
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.1.0.1
    ip mtu 9198
    ip bootp-gateway 10.1.0.2
    ip helper-address 10.92.100.222
    exit
 
sw-spine-002# show run int vlan 1
interface vlan1
    vsx-sync active-gateways
    ip address 10.1.0.3/16
    active-gateway ip mac 12:01:00:00:01:00
    active-gateway ip 10.1.0.1
    ip mtu 9198
    ip helper-address 10.92.100.222
    exit
```

[Back to Index](index_aruba.md)