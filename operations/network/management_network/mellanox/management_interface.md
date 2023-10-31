# Management interface

The management interface can be used to gain remote management access to the switch. The management interface is accessible using the `mgmt` VRF and is separate from the data plane
interfaces, which are in the `default` VRF. Mellanox switches support out-of-band (OOB) dedicated interfaces (e.g. `mgmt0`, `mgmt1`) and in-band dedicated interfaces.

Enter configuration mode.

```console
switch > enable
switch# configure terminal
```

Disable setting IP addresses using the DHCP using the following command in configuration mode:

```console
switch (config) # no interface mgmt0 dhcp
```

Define the interface IP address statically using the following command in configuration mode:

```console
switch (config) # interface mgmt0 ip address <IP address> <netmask>
```

Show interface information.

```console
switch# show interface mgmt
```
