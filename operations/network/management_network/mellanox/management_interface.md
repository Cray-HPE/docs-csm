# Management interface 

The management interface can be used to gain remote management access to the switch. The management interface is accessible using the “mgmt” VRF and is separate from the data plane interfaces, which are in the “default” VRF. Mellanox switches support out-of-band (OOB) dedicated interfaces (e.g. mgmt0, mgmt1) and in-band dedicated interfaces.

Relevant Configuration

Enter Config configuration mode. Run: 

```
switch > enable
switch # configure terminal
```

Disable setting IP addresses using the DHCP using the following command: 

```
switch (config) # no interface mgmt0 dhcp
```

Define your interface IP statically using the following command: 

```
switch (config) # interface mgmt0 ip address <IP address> <netmask>
```

Show Commands to Validate Functionality

```
switch# show interface mgmt
```

* Step 1: You can enable/disable the management interface.
* Step 2: You can assign an IP address to the management interface 
*  Step 3: You can configure a loopback interface to be use for Switch management. 

[Back to Index](./index.md)