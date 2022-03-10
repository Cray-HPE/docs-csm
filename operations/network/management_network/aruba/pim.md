# PIM-SM Bootstrap Router (BSR) and Rendezvous Point (RP) 

 “Every PIM multicast group needs to be associated with the IP address of a Rendezvous Point (RP) [...] For all senders to reach all receivers, it is crucial that all routers in the domain use the same mappings of group addresses to RP addresses. [...] The BSR mechanism provides a way in which viable group-to-RP mappings can be created and rapidly distributed to all the PIM routers in a domain.” –rfc5059 
 

## Configuration Commands

Configure the BSR and RP 

```
switch(config)# router pim
switch(config-pim)# bsr-candidate source-ip-interface IFACE
switch(config-pim)# rp-candidate source-ip-interface IFACE
```

Show commands to validate functionality:  

```
switch# show ip pim bsr
switch# show ip pim rp-candidate
switch# show ip pim rp-set
```

## Test Steps

1. Use the previous IGMP, MSDP configuration and topology.
2. On both Core Switches create loopback1 interface using the same IP for both devices.
3. Enable OSPF on loopback interface and make sure route redistribution is configured.
4. Enable PIM-SM on loopback1
5. Configure loopback1 to act as RP for both 8325s using: rp-candidate source-ip-interface loopback1
6. Configure both core devices to advertise the same specific multicast subnet (which we will use later) by typing "rp-candidate group-prefix 239.1.1.0/24".
7. Enable BSR on both routers using: bsr-candidate source-ip-interface loopback0 in the router pim context.


## Expected Results

* Administrators can configure loopback1 on both 8325s using the same IP address 
* Administrators can configure OSPF routing for loopback1
* Administrators successfully enabled PIM-SM on loopback1
* Administrators configured loopback1 to act as a PIM-SM RP
* Administrators configured the specific group-prefix that will be used in the next test
* Administrators successfully enabled the BSR on both 8325s using loopback0 as the BSR source IP
  
[Back to Index](../index.md)