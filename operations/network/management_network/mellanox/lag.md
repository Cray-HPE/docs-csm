# Link aggregation group (LAG) 

Link Aggregation allows you to assign multiple physical links to one logical link that functions as a single, higher-speed link providing dramatically increased bandwidth. 

Relevant Configuration 

Create and configure the LAG interface 

```
switch (config) # interface port-channel 1
switch (config interface port-channel 1) #
```

Exit port-channel context

```
switch (config interface port-channel 1) # exit
switch (config) #
```

Associate member links with the LAG interface switch(config)# interface IFACE

```
switch (config interface ethernet 1/4) # channel-group 1 mode on
switch (config interface ethernet 1/4) # 
```

To enable LACP in LAG

```
switch (config interfaces ethernet 1/7)# lacp rate fast
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

