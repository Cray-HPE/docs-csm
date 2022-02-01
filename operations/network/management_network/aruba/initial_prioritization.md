# Initial prioritization 

For most switches, the local-priority has eight levels (0-7). Zero is the lowest priority. The allowed maximum will vary per product family. Local priority is used to determine which queue a packet will use. There are multiple options to configure the local-priority:
 
* qos cos-map: maps CoS values from VLAN tags in incoming packets to specific local priorities 
* qos dscp-map: maps the DSCP from incoming packets to specific local priorities 
* qos trust: assumes incoming packets are marked correctly, and takes the local-priority from either the Class of Services (CoS) or Differentiated Service Code-Points (DSCP) field of the packet, or ignores any values set on incoming packets and places the packets into the default local-priority queue if the none option is given 

Relevant Configuration 

Map incoming 802.1p values to a local priority 

```
switch(config)# qos cos-map <0-7> local-priority VALUE [color COLOR] [name NAME]
```

Map incoming DSCP to a local priority 

```
switch(config)# qos dscp-map <0-63> local-priority VALUE [color COLOR] [name NAME]
```

Configure QoS trust 

```
switch(config)# qos trust [none|cos|dscp]
switch(config-if)# qos trust [none|cos|dscp]
```

Show Commands to Validate Functionality 

```
switch# show qos [cos-map|dscp-map|trust]
```

Expected Results 

* Step 1: You can enable QoS trust to CoS on an interface
* Step 2: You can map incoming 802.1p values to local priorities 
* Step 3: The output of all show commands is correct
 
Example Output 

```
switch(config)# qos dscp-map 46 local-priority 7 color green name VOICE
switch # show qos cos-map
code_point local_priority color   name
---------- -------------- ------- ----
0          1              green   Best_Effort
1          0              green   Background
2          2              green   Excellent_Effort
3          3              green   Critical_Applications
4          4              green   Video
5          5              green   Voice
6          6              green   Internetwork_Control
7          7              green   Network_Control
```

[Back to Index](../index.md)