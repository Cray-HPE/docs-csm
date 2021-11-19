# Link aggregation group (LAG) 

Link Aggregation allows you to assign multiple physical links to one logical link that functions as a single, higher-speed link providing dramatically increased bandwidth. 

Relevant Configuration 

Create and configure the LAG interface 

```
switch(config)# interface lag LAG 
switch(config-lag-if)# no shutdown 
switch(config-lag-if)# lacp mode active 
```

Associate member links with the LAG interface switch(config)# interface IFACE

```
switch(config-if)# no shutdown 
switch(config-if)# lag LAG 
```

Show Commands to Validate Functionality 

```
switch# show lacp <interfaces|aggregates|configuration>
```

Example Output 

```
switch# show interface lag1
Aggregate-name lag1
Aggregated-interfaces : 1/1/1 1/1/4
Aggregation-key : 1
Aggregate mode : active
 Speed 0 Mb/s
 qos trust none
 qos queue-profile default
 qos schedule-profile default
 RX
TX 
409 input packets
  0 input error
  0 CRC/FCS
530 output packets
  0 input error
  0 collision
47808 bytes
    0 dropped
56975 bytes
    0 dropped
switch# show lacp interfaces
State abbreviations :
A - Active        P - Passive
S - Short-timeout L - Long-timeout N - InSync     O - OutofSync
C - Collecting    D - Distributing
X - State m/c expired              E - Default neighbor state
Actor details of all interfaces:
------------------------------------------------------------------------------
Intf Aggregate  Port    Port     State   System-id         System   Aggr
     name       id      Priority                           Priority Key
------------------------------------------------------------------------------
1/1/1lag1       59      1        ALFOE   70:72:cf:4d:bb:53 65534    1
1/1/4lag1       41      1        ALFOE   70:72:cf:4d:bb:53 65534    1
Partner details of all interfaces:
------------------------------------------------------------------------------
Intf Aggregate  Partner Port     State   System-id         System   Aggr
     name       Port-id Priority                           Priority Key
------------------------------------------------------------------------------
1/1/1lag1       0       65534    PLFOEX  00:00:00:00:00:00 65534    0
1/1/4lag1       0       65534    PLFOEX  00:00:00:00:00:00 65534    0
switch# show lacp aggregates
Aggregate-name        : lag1
Aggregated-interfaces : 1/1/1 1/1/4
Heartbeat rate        : slow
Aggregate mode        : active
F - Aggregable I - Individual
```

Expected Results 

* Step 1: You can create and configure a LAG 
* Step 2: You can add ports to a LAG
* Step 3: You can configure a LAG interface  
	
[Back to Index](./index.md)
