# Multi-Chassis Link Aggregation Group (MCLAG)

Multi-Chassis Link Aggregation Group (MCLAG) is a link aggregation technique where two or more links across two switches are aggregated together to form a trunk. 

## Configuration Commands 

Create the MCLAG interface: 

```bash
switch(config)# interface lag LAG multi-chassis 
switch(config-lag-if)# no shutdown
```

Associate member links with the MCLAG interface: 

```bash
switch(config)# interface IFACE 
switch(config-if)# no shutdown switch(config-if)# lag LAG 
```

Show commands to validate functionality:  

```bash
switch# show mclag <brief|configuration|status>
```

## Example Output 

```bash
switch(config)# interface lag 23 multi-chassis
switch(config-lag-if)# no shutdown
switch(config-lag-if)# exit
switch(config)# interface 1/1/10
switch(config-if)# no shutdown
switch(config-if)# lag 23
switch(config-if)# end
```

## Expected Results 

1. You can configure MCLAG
2. You can create an MCLAG interface
3. You can add ports to the MCLAG interface
4. The output of the `show` commands is correct   

	
[Back to Index](index_aruba.md)
