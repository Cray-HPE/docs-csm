# VLAN Interface

The switch supports classic L3 VLAN interfaces.

## Configuration commands

(`switch#`) Configure the VLAN:

```text
vlan VLAN
```

(`switch#`) Create and enable the VLAN interface, and assign it an IP address:

```text
interface vlan VLAN
ip address IP-ADDR/SUBNET
no shutdown
```

## Show commands to validate functionality

(`switch#`)

```text
show vlan [VLAN|interface IFACE|summary]
```

Example output:

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

* Administrators can configure the VLAN.
* Administrators can enable the interface and associate it with the VLAN.
* Administrators can create an IP-enabled VLAN interface, and it is up.
* Administrators validate the configuration is correct.
* Administrators can ping from the switch to the client and from the client to the switch.

[Back to Index](../README.md)
