# Physical Interfaces 

Configure the physical interfaces for a switch.

## Configuration Commands

Enable the interface: 

```bash
switch(config)# interface IFACE
switch(config-if)# no shutdown
```

Show commands to validate functionality:  

```bash
switch# show interface IFACE [transceiver|brief|dom|extended]
```

## Expected Results 

1. The switch recognizes the transceiver without errors
2. You can enter the interface context for the port and enable it
3. You can establish a link with a partner
4. You can pass traffic as expected 

[Back to Index](index_aruba.md)