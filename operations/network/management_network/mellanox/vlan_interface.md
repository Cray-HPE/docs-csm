# VLAN interface 

The switch also supports classic L3 VLAN interfaces. 

Relevant Configuration 

Configure the VLAN 

```
switch (config) # vlan 6
switch (config vlan 6) #
```

Create and enable the VLAN interface, and assign it an IP address 

```
switch(config vlan 6)# ip address 10.1.0.2/16 
```

Show commands to validate functionality:  

```
switch# show vlan
```

Expected Results 

* Step 1: You can configure the VLAN
* Step 2: You can enable the interface and associate it with the VLAN
* Step 3: You can create an IP enabled VLAN interface, and it is up
* Step 4: You validate the configuration is correct
* Step 5: You can ping from the switch to the client and from the client to the switch  

[Back to Index](./index.md)