# VSX sync 

Configuration synchronization is one aspect of this VSX solution where the primary switch configuration is synced to the secondary switch. This allows for pseudo single pane of glass configuration and helps keep key configuration pieces in sync as operational changes are made. Since the solution is primarily for HA, it is expected that the vast majority of configuration policy is the same across both peers. 

Relevant Configuration 

Synchronize VLANs 

```
switch(config-vlan)# vsx-sync
```

Synchronize ACLs 

```
switch(config-acl-ip)# vsx-sync
```

Synchronize Classifier and Policy 

```
switch(config-class-ip)# vsx-sync
```

Synchronize PBR 

```
switch(config-pbr-action-list)# vsx-sync
```

Synchronize VLAN memberships and ACLs on physical or LAG interfaces 

```
switch(config-if)# vsx-sync access-lists vlans
```

Show commands to validate functionality:  

```
switch# show run vsx-sync
```

Example Output 

On the first switch: 

```
switch(config)# vlan 10
switch(config-vlan-10)# vsx-sync
switch(config)# access-list ip secure_mcast_sources
switch(config-acl-ip)# vsx-sync
switch(config-acl-ip)# 10 permit igmp any any
switch(config-acl-ip)# 15 comment block downstream from sourcing mcast
switch(config-acl-ip)# 20 deny any any 224.0.0.0/4
switch(config-acl-ip)# 30 permit any any
```

On the secondary switch: 

```
switch2# show run vsx-sync
Current vsx-sync configuration:
vlan 10
    vsx-sync
vlan 20
    vsx-sync
vlan 30
    vsx-sync
access-list ip secure_mcast_sources
    vsx-sync
    !
    10 comment allow igmp traffic from downstream
    10 permit igmp any any
    15 comment block downstream from sourcing mcast
    20 deny any any 224.0.0.0/240.0.0.0
    30 permit any any any
```

Expected Results 

* Step 1: You can configure the VLAN 
* Step 2: You can create the ACL 
* Step 3: Everything synchronized on the primary is now on the secondary  

[Back to Index](./index.md)