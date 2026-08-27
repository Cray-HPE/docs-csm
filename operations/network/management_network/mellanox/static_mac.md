# MAC Address Table

Static MAC addresses can be configured for unicast traffic.
This feature improves security and reduces unknown unicast flooding.

(`switch (config) #`) Configure unicast static MAC address:

```console
mac-address-table static unicast <destination mac address> vlan <vlan identifier(1-4094)> interface ethernet <slot>/<port>
```

For example:

```console
mac-address-table static 00:11:22:33:44:55 vlan 1 interface ethernet 1/1
```

[Back to Index](../README.md)
