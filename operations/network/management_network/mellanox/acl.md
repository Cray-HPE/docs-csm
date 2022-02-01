# Access control lists (ACLs)

ACLs are used to help improve network performance and restrict network usage by creating policies to eliminate unwanted IP traffic by filtering packets where they enter the switch on layer 2 and layer 3 interfaces. An ACL is an ordered list of one or more access control list entries (ACEs) prioritized by sequence number. An incoming packet is matched sequentially against each entry in an ACL. When a match is made, the action of that ACE is taken and the packet is not compared against any other ACEs in the list. For ACL filtering to take effect, configure an ACL and then assign it in the inbound or outbound direction on an L2 or L3 interface with IPV4 traffic, and inbound-only for IPv6. 

Relevant Configuration 

Create an ACL 
 
```
switch (config) mac access-list mac-acl
switch (config mac access-list mac-acl) #
```

Add a MAC / IP rules to the appropriate access-list. Run:

```
switch (config mac access-list mac-acl) # seq-number 10 deny 0a:0a:0a:0a:0a:0a mask ff:ff:ff:ff:ff:ff any vlan 6 cos 2 protocol 80
```

Bind the created access-list to an interface (port or LAG). Run:

```
switch (config) # interface ethernet 1/1
switch (config interface ethernet 1/1) # mac port access-group mac-acl
```

Show Commands to Validate Functionality 

```
switch# show ipv4 access-lists <access-list-name>
```

[Back to Index](../index.md)
