
# Configure Physical Interfaces

Ethernet port interfaces are enabled by default.

## Configuration Commands

Enable the interface:

```
switch(config)# interface ethernet 1/1/1
switch(conf-if-eth1/1/1)# no shutdown
```

Disable the interface:

```
switch(config)# interface ethernet 1/1/1
switch(conf-if-eth1/1/1)# shutdown
```

Show commands to validate functionality:

```
switch# show configuration
```

## Expected Results

1. The switch recognizes the transceiver without errors
2. Administrators can enter the interface context for the port and enable it
3. Administrators can establish a link with a partner
4. Administrators can pass traffic as expected

[Back to Index](index.md)