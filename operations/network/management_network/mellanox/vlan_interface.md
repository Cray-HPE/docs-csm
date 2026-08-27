# VLAN Interface

The switch supports classic L3 VLAN interfaces.

## Relevant configuration

(`switch (config)#`) Configure the VLAN:

```console
vlan 6
```

(`switch(config vlan 6)#`) Create and enable the VLAN interface, and assign it an IP address:

```console
ip address 10.1.0.2/16
```

## Show commands to validate functionality

```console
show vlan
```

## Expected results

* Administrators can configure the VLAN
* Administrators can enable the interface and associate it with the VLAN
* Administrators can create an IP-enabled VLAN interface, and it is up
* Administrators validate the configuration is correct
* Administrators can ping from the switch to the client and from the client to the switch

[Back to Index](../README.md)
