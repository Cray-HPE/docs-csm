
# Classifier Policies 

Classifier policies allow a network administrator to define sets of rules based on network traffic addressing or other header content and use these rules to restrict or alter the passage of traffic through the switch. 

Choosing the rule criteria is called classification, and one such rule, or list, is called a policy. 

Classification is achieved by creating a traffic class. There are three types of classes – MAC, IPv4, and IPv6 – which are each focused on relevant frame/packet characteristics. Classes can be configured to match or ignore almost any frame or packet header field. 

A policy contains one or more policy entries which are listed according to priority by sequence number. A single policy entry contains a class and corresponding policy action. Policy action is taken on traffic matched by its corresponding class. 

## Configuration Commands

Create a class: 

```
switch(config)# class <all|ip|ip6|mac> NAME
```

Configure a class: 

```
switch(config-class-ip)# [SEQ] <match|ignore> <any|PROTOCOL> <any|SRC-IP> <any|DST-IP> switch(config-class-ip)# [SEQ] comment TEXT
```

Create a policy: 

```
switch(config)# policy NAME
```

Configure a policy:

```
switch(config-policy)#  [SEQ] class <ip|ipv6|mac> NAME [action [ip-precedence VALUE|pcp VALUE|dsc VALUE|cir kbps RATE cbs BYTES exceed drop|mirror MIRROR|drop] ...]
```

Apply a policy: 

```
switch(config-if)# apply policy NAME [in|routed-in]
switch(config-vlan)# apply policy NAME [in|routed-in]
switch(config-tunnel)# apply policy NAME [in|routed-in]
```

Show commands to validate functionality: : 

```
switch# show class [ip|ipv6|mac] [NAME]
switch# show policy [NAME]
```

## Expected Results
 
1. You can configure a class
2. You can configure a policy
3. You can apply a policy to an interface
4. The output of the `show` commands is correct  

## Example Output 

```bash
switch(config)# class ip BROWSER
switch(config-class-ip)# match tcp any any eq 80
switch(config-class-ip)# match tcp any any eq 8080
switch(config-class-ip)# match tcp any any eq 8081
switch(config-class-ip)# exit
switch(config)# class ip NMS_CLASS
switch(config-class-ip)# match udp any any eq 161
switch(config-class-ip)# exit
switch(config)# policy USERPORTS
switch(config-policy)# class ip NMS_CLASS action dscp CS6 action pcp 6
switch(config-policy)# class ip BROWSER action dscp CS1 action pcp 1
switch(config-policy)# exit
switch(config)# interface 1/1/1
switch(config-if)# apply policy USERPORTS i
switch(config-if)# end
switch# show class ip BROWSER
Type       Name
Sequence Comment
         Action
         Source IP Address
         Destination IP Address
         Additional Parameters
L3 Protocol
Source L4 Port(s)
Destination L4 Port(s)
-------------------------------------------------------------------------------
IPv4       BROWSER
10 match any 
any 20 match 
any 
any 30 match 
any 
tcp 
= 80 tcp 
= 8080 tcp 
           any
-------------------------------------------------------------------------------
switch# show class ip NMS_CLASS
Type       Name
Sequence Comment
         Action
         Source IP Address
         Destination IP Address
         Additional Parameters
= 8081 
L3 Protocol
Source L4 Port(s)
Destination L4 Port(s)
-------------------------------------------------------------------------------
IPv4       NMS_CLASS
        10 match                           udp
           any
           any                              =   161
-------------------------------------------------------------------------------
switch# show policy USERPORTS
           Name
  Sequence Comment
           Class Type
                    action 
-------------------------------------------------------------------------------
           USERPORTS
        10
           NMS_CLASS ipv4
pcp 6 dscp CS6 
        20
           BROWSER ipv4
pcp 1 dscp CS1 
-------------------------------------------------------------------------------
switch# show policy configuration commands
policy USERPORTS
    10 class ip NMS_CLASS action pcp 6 action dscp CS6
    20 class ip BROWSER action pcp 1 action dscp CS1
interface 1/1/1
    apply policy USERPORTS in
switch# show policy hitcounts USERPORTS
Statistics for Policy USERPORTS:
Interface 1/1/1* (in):
           Hit Count  Configuration
10 class ip NMS_CLASS action pcp 6 action dscp CS6
                   -  10 match udp any any  eq 161
20 class ip BROWSER action pcp 1 action dscp CS1
- 10matchtcpanyany eq80 - 20 match tcp any any eq 8080 - 30 match tcp any any eq 8081 - 40 (null) any any any 
* policy statistics are shared among all applied interfaces
  use 'policy NAME copy' to create a uniquely-named policy
```

[Back to Index](../index.md)