
ACLs are used to help improve network performance and restrict network usage by creating policies to eliminate unwanted IP traffic by filtering packets where they enter the switch on layer 2 and layer 3 interfaces. An ACL is an ordered list of one or more access control list entries (ACEs) prioritized by sequence number. An incoming packet is matched sequentially against each entry in an ACL.


Relevant Configuration

Create an ACL

```
switch(config)# ip access-list name
switch(conf-ipv4-acl)# permit ip 1.1.1.0/24 any
```

Show Commands to Validate Functionality

```
switch# show ip access-list name
```

[Back to Index](./index.md)

