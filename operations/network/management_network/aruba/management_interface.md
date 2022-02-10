# Management Interface 

The management interface can be used to gain remote management access to the switch. The management interface is accessible using the “mgmt” VRF and is separate from the data plane interfaces, which are in the “default” VRF. 

Alternatively, a loopback interface can be configured to be used as management interface.

```
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

## Configuration Commands

Enable/disable the management interface: 

```bash
switch(config)# interface mgmt 
switch(config-if-mgmt)# no shutdown
switch(config)# interface mgmt 
switch(config-if-mgmt)# shutdown
```

Assign an IP address to the interface:

```bash
switch(config-if-mgmt)# ip <dhcp|static IP-ADDR> 
```

Show commands to validate functionality: 

```bash
switch# show interface mgmt
switch# show interface loopback 0
```

Create and configure loopback interface: 

```bash
switch(config)# interface loopback 0 
8325-Core1(config-loopback-if)# ip address <IP-ADDR> 
```

## Expected Results 

1. Administrators can enable/disable the management interface.
2. Administrators can assign an IP address to the management interface 
3. Administrators can configure a loopback interface to be use for Switch management. 

[Back to Index](../index.md)