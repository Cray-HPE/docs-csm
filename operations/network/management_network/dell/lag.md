# Link aggregation group (LAG)

Link Aggregation allows you to assign multiple physical links to one logical link that functions as a single, higher-speed link providing dramatically increased bandwidth.

Relevant Configuration

Create and configure the LAG interface

```
switch(config)# interface port-channel 10
switch(config-if-po-1)# no shutdown
```

Associate member links with the LAG interface switch(config)# interface IFACE

```
switch(config)# interface ethernet 1/1/1
switch(conf-if-eth1/1/1)# channel-group 10
```

To enable LACP on the LAG

```
switch(config)# interface ethernet 1/1/1
switch(conf-if-eth1/1/1)#channel-group 10 mode active
```

Show Commands to Validate Functionality

```
switch# show interface port-channel
```

Expected Results

* Step 1: You can create and configure a LAG
* Step 2: You can add ports to a LAG
* Step 3: You can configure a LAG interface

[Back to Index](../index.md)

