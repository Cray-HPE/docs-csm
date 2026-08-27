# VLAN Interface

The switch also supports classic L3 VLAN interfaces.

## Configuration commands

Configure the VLAN:

```text
vlan VLAN
```

Create and enable the VLAN interface, and assign it an IP address:

```text
interface vlan VLAN
ip address IP-ADDR/SUBNET
no shutdown
```

Show commands to validate functionality:

```text
show vlan [VLAN|interface IFACE|summary]
```

## Example output

```text
vlan 10
exit
int 1/1/1
vlan access 10
int vlan 10
ip address 10.0.0.1/24
no shutdown
end
108 bytes from 10.0.0.101: icmp_seq=4 ttl=64 time=2.07 ms
108 bytes from 10.0.0.101: icmp_seq=5 ttl=64 time=1.79 ms
```

## Expected results

1. Administrators can configure the VLAN
1. Administrators can enable the interface and associate it with the VLAN
1. Administrators can create an IP-enabled VLAN interface, and it is up
1. Administrators validate the configuration is correct
1. Administrators can ping from the switch to the client and from the client to the switch

[Back to Index](../README.md)
