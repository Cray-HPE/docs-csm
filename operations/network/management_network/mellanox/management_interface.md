# Management interface

The management interface can be used to gain remote management access to the switch. The management interface is accessible using the `mgmt` VRF and is separate from the data plane
interfaces, which are in the `default` VRF. Mellanox switches support out-of-band (OOB) dedicated interfaces (e.g. `mgmt0`, `mgmt1`) and in-band dedicated interfaces.

(`sw#`) Enter configuration mode.

```console
enable
configure terminal
```

(`sw#`) Disable setting IP addresses using the DHCP using the following command in configuration mode:

```console
no interface mgmt0 dhcp
```

(`sw#`) Define the interface IP address statically using the following command in configuration mode:

```console
interface mgmt0 ip address <IP address> <netmask>
```

(`sw#`) Show interface information.

```console
show interface mgmt
```
