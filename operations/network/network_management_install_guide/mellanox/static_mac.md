# Mac address Table 

You can configure static MAC addresses for unicast traffic. This feature improves security and reduces unknown unicast flooding.

To configure Unicast Static MAC address: 

```
Switch (config) # mac-address-table static unicast <destination mac address> vlan <vlan identifier(1-4094)> interface ethernet <slot>/<port>
```

For example: 

```
switch (config) # mac-address-table static 00:11:22:33:44:55 vlan 1 interface ethernet 1/1
```

[Back to Index](./index.md)

