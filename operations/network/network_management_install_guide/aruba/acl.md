#Access control lists (ACLs)

ACLs are used to help improve network performance and restrict network usage by creating policies to eliminate unwanted IP traffic by filtering packets where they enter the switch on layer 2 and layer 3 interfaces. An ACL is an ordered list of one or more access control list entries (ACEs) prioritized by sequence number. An incoming packet is matched sequentially against each entry in an ACL. 

When a match is made, the action of that ACE is taken and the packet is not compared against any other ACEs in the list. 

For ACL filtering to take effect, configure an ACL and then assign it in the inbound or outbound direction on an L2 or L3 interface with IPV4 traffic, and inbound-only for IPv6. 


Relevant Configuration 

Create an ACL 

```
switch(config)# access-list <ip|ipv6|mac> ACL
```

Copy an existing ACL 

```
switch(config)# access-list <ip|ipv6|mac> ACL copy NEW-ACL
```

Resequence an ACL 

```
switch(config)# access-list <ip|ipv6|mac> ACL resequence VALUE INC
```

Apply an ACL to the control plane 

```
switch(config)# apply access-list <ip|ipv6> ACL control-plane [vrf VRF]
```

Add ACEs in the appropriate order 

```
switch(config-acl-ip)#  [SEQ] <deny|permit> <any|PROTOCOL> <any|SRC> <any|DST> [count] [log]
switch(config-acl-ip)#  [SEQ] comment TEXT
```

Apply the ACL to a physical interface, a logical interface or a VLAN (please note: ACLs on L3 VLAN interfaces are not supported) 

```
switch(config-if)# apply access-list <ip|ipv6|mac> ACL <in|out>
switch(config-vlan)# apply access-list <ip|ipv6|mac> ACL <in|out>
```

Show Commands to Validate Functionality 

```
switch# show access-list [hitcounts] [ip|ipv6|mac ACL] [control-plane vrf VRF]
```

[Back to Index](./index.md)