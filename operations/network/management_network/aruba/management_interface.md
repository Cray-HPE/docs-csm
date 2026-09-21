# Management Interface

The management interface can be used to gain remote management access to the switch.
The management interface is accessible using the `mgmt` VRF and is separate from the
data plane interfaces, which are in the `default` VRF.

Alternatively, a loopback interface can be configured to be used as management interface.

```text
Address Mode
Admin State
Mac Address
IPv4 address/subnet-mask
Default gateway IPv4
IPv6 address/prefix
IPv6 link local address/prefix: fe10::96f1:28ff:fe1d:a901/64
Default gateway IPv6
Primary Nameserver
Secondary Nameserver
:
: 10.110.135.51
: 10.110.135.52
: dhcp
: up
: 94:f1:28:1d:a9:01
: 10.93.61.227/21
: 10.93.56.1
```

## Configuration commands

(`switch(config)#`) Enable the management interface:

```text
interface mgmt
no shutdown
```

(`switch(config)#`) Disable the management interface:

```text
interface mgmt
shutdown
```

(`switch(config-if-mgmt)#`) Assign an IP address to the interface:

```text
ip <dhcp|static IP-ADDR>
```

(`switch(config)#`) Create and configure loopback interface:

```text
interface loopback 0
ip address <IP-ADDR>
```

## Show commands to validate functionality

(`switch(config)#`)

```text
show interface mgmt
show interface loopback 0
```

## Expected results

* Administrators can enable/disable the management interface.
* Administrators can assign an IP address to the management interface
* Administrators can configure a loopback interface to be use for switch management.

[Back to Index](../README.md)
