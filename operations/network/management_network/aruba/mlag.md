# Multi-Chassis link aggregation group (MCLAG)

Multi-Chassis Link Aggregation Group (MCLAG) is a link aggregation technique where two or more links across two switches are aggregated together to form a trunk. 

Relevant Configuration 

Create the MCLAG interface 

```
switch(config)# interface lag LAG multi-chassis 
switch(config-lag-if)# no shutdown
```

Associate member links with the MCLAG interface 

```
switch(config)# interface IFACE 
switch(config-if)# no shutdown switch(config-if)# lag LAG 
```

Show Commands to Validate Functionality 

```
switch# show mclag <brief|configuration|status>
```

Example Output 

```
switch(config)# interface lag 23 multi-chassis
switch(config-lag-if)# no shutdown
switch(config-lag-if)# exit
switch(config)# interface 1/1/10
switch(config-if)# no shutdown
switch(config-if)# lag 23
switch(config-if)# end
```

Expected Results 

* Step 1: You can configure MCLAG
* Step 2: You can create an MCLAG interface
* Step 3: You can add ports to the MCLAG interface
* Step 4: The output of the show commands is correct   

	
[Back to Index](../index.md)
