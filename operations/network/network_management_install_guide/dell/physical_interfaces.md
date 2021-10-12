
# Physical interfaces

Ethernet port interfaces are enabled by default. 

Relevant Configuration

Enable the interface

```
switch(config)# interface ethernet 1/1/1
switch(conf-if-eth1/1/1)# no shutdown
```

Disable the interface

```
switch(config)# interface ethernet 1/1/1
switch(conf-if-eth1/1/1)# shutdown
```

Show Commands to Validate Functionality

```
switch# show configuration
```

Expected Results

* Step 1: The switch recognizes the transceiver without errors
* Step 2: You can enter the interface context for the port and enable it
* Step 3: You can establish a link with a partner
* Step 4: You can pass traffic as expected

[Back to Index](./index.md)