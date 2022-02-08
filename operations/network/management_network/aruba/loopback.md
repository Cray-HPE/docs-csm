# Loopback interface 

You can think of loopbacks as internal virtual interfaces. Loopback interfaces are not bound to a physical port and are used for device management and routing protocols. 

Relevant Configuration 

```
switch(config)# interface loopback LOOPBACK
switch(config-loopback-if)# ip address IP-ADDR/<SUBNET|PREFIX>
```

Example Output 

```
switch(config)# interface loopback 1
switch(config-loopback-if)# ip address 99.99.99.1/32
switch(config-loopback-if)# end
switch# show run interface loopback1
interface loopback1
   no shutdown
   ip address 99.99.99.1/32
   exit
switch# show ip interface loopback1
Interface loopback1 is up
 Admin state is up
 Hardware: Loopback
 IPv4 address 99.99.99.1/32
```

Expected Results 

* Step 1: You can create a loopback interface
* Step 2: You can give a loopback interface an IP address
* Step 3: You can validate the configuration using the show commands.

[Back to Index](../index.md)