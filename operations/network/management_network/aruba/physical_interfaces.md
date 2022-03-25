# Physical Interfaces 

Configure the physical interfaces for a switch.

## Configuration Commands

Enable the interface: 

```text
switch(config)# interface IFACE
switch(config-if)# no shutdown
```

Show commands to validate functionality:  

```text
switch# show interface IFACE [transceiver|brief|dom|extended]
```

## Expected Results 

1. The switch recognizes the transceiver without errors
2. Administrators can enter the interface context for the port and enable it
3. Administrators can establish a link with a partner
4. Administrators can pass traffic as expected 

[Back to Index](../index.md)