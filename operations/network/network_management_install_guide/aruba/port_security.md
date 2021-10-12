# Port security 

Port security allows user to configure each switch port with a list of unique MAC addresses; limit network access to authorized MAC addresses; detect, prevent, and log unauthorized access of devices on individual ports; and limit the number of MACs learned. 

Intrusion detection enables a device to notify the user or shutdown the port in the case of a violation, and a timer can be configured to allow auto-recovery of ports shutdown in a violation state to come back up after the timer expires. 

The violation state of a port is reset with the port is administratively shutdown, port security is disabled on the port, or the port comes back up due to auto-recovery. 

Important:

* Port security is only supported on physical ports and is mutually exclusive with dot1x and MAC auth.
* Port security is feature of "edge" switches such as 63/6400 and not available on 83xx.

Relevant Configuration 

Enable Port Security Globally 

```
switch(config)# port-access port-security enable
```

Enable Port Security on an Interface 

```
switch(config-if)# port-access port-security
```

Configure port access security violation action 

```
switch(config-if)# port-access security violation action <notify|shutdown>
```

Configure port access security violation recovery timer 

```
switch(config-if)# port-access security violation action shutdown recovery-timer <10-600>
```

Configure port access security violation auto recovery 

```
switch(config-if)# port-access security violation action shutdown auto-recovery enable
```

Configure Port Security 

```
switch(config-if-port-security)# mac-address <MAC-ADDR>
switch(config-if-port-security)# client-limit <1-64>
```

Show Commands to Validate Functionality 

```
switch# show port-access port-security interface <all|IFACE> <client-status|portstatistics>
```

Example Output 

```
switch(config)# port-access port-security enable
switch(config)# interface 1/1/1
switch(config-if)# port-access port-security
switch(config-if-port-security)# client-limit 64
switch(config-if-port-security)# mac-address aa:bb:cc:dd:ee:ff
switch(config-if-port-security)# end
switch# show port-access port-security interface all client-status
Port Security Client Status Details
  Authorized-Clients    Port
  ----------------------------
  AB:CD:DE:FF:AA:BB     1/1/1
  DD:CD:AB:CD:EE:O1     1/1/2
show port-access port-security interface 1/1/1 client-status mac ab:cd:de:ff:aa:bb
Port Security Client Status Details
  Authorized-Clients    Port
  ----------------------------
  AB:CD:DE:FF:AA:BB     1/1/1
switch#show port-access port-security interface all port-statistics
Port 1/1/1
==========
  Client Details
  --------------
Number of authorized clients
: 2 
```

[Back to Index](./index.md)