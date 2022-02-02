# VLAN interface 

The switch also supports classic L3 VLAN interfaces. 

Relevant Configuration 

Configure the VLAN 

```
switch(config)# vlan VLAN
```

Create and enable the VLAN interface, and assign it an IP address 

```
switch(config)# interface vlan VLAN
switch(config-if-vlan)# ip address IP-ADDR/SUBNET
switch(config-if-vlan)# no shutdown
```

Show Commands to Validate Functionality 

```
switch# show vlan [VLAN|interface IFACE|summary]
```

Example Output 

```
switch(config)# vlan 10
switch(config-vlan)# exit
switch(config)# int 1/1/1
switch(config-if)# vlan access 10
switch(config-if)# int vlan 10
switch(config-if-vlan)# ip address 10.0.0.1/24
switch(config-if-vlan)# no shutdown
switch(config-if-vlan)# end
108 bytes from 10.0.0.101: icmp_seq=4 ttl=64 time=2.07 ms
108 bytes from 10.0.0.101: icmp_seq=5 ttl=64 time=1.79 ms
```

Expected Results 

* Step 1: You can configure the VLAN
* Step 2: You can enable the interface and associate it with the VLAN
* Step 3: You can create an IP-enabled VLAN interface, and it is up
* Step 4: You validate the configuration is correct
* Step 5: You can ping from the switch to the client and from the client to the switch  

[Back to Index](./index.md)