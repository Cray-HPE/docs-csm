
# Port Security 

Port security allows user to do the following:
* Configure each switch port with a list of unique MAC addresses
* Limit network access to authorized MAC addresses
* Detect, prevent, and log unauthorized access of devices on individual ports
* Limit the number of MACs learned 

Intrusion detection enables a device to notify the user or shutdown the port in the case of a violation, and a timer can be configured to allow auto-recovery of ports shutdown in a violation state to come back up after the timer expires. 

The violation state of a port is reset with the port is administratively shutdown, port security is disabled on the port, or the port comes back up due to auto-recovery. 

**IMPORTANT:**

  * Port security is only supported on physical ports and is mutually exclusive with dot1x and MAC auth
  * Port security is feature of "edge" switches such as 63/6400 and not available on 83xx

## Configuration Commands 

Enable port security globally: 

```bash
switch(config)# port-access port-security enable
```

Enable port security on an interface: 

```bash
switch(config-if)# port-access port-security
```

Configure port access security violation action: 

```bash
switch(config-if)# port-access security violation action <notify|shutdown>
```

Configure port access security violation recovery timer: 

```bash
switch(config-if)# port-access security violation action shutdown recovery-timer <10-600>
```

Configure port access security violation auto recovery: 

```bash
switch(config-if)# port-access security violation action shutdown auto-recovery enable
```

Configure port security: 

```bash
switch(config-if-port-security)# mac-address <MAC-ADDR>
switch(config-if-port-security)# client-limit <1-64>
```

Show commands to validate functionality:  

```bash
switch# show port-access port-security interface <all|IFACE> <client-status|portstatistics>
```

## Example Output 

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

[Back to Index](../index_aruba.md)