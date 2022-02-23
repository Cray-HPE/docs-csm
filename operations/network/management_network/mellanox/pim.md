# PIM-SM bootstrap router (BSR) and rendezvous-point (RP) 

"Every PIM multicast group needs to be associated with the IP address of a Rendezvous Point (RP) [...] For all senders to reach all receivers, it is crucial that all routers in the domain use the same mappings of group addresses to RP addresses. [...] The BSR mechanism provides a way in which viable group-to-RP mappings can be created and rapidly distributed to all the PIM routers in a domain." –rfc5059 

Relevant Configuration 

Enable PIM protocol

```
switch(config)# router pim
```

Configuring static address of rendevouz point for multicast group:   

```
switch (config) # ip pim rp-address 10.10.10.10
switch (config) # ip pim vrf default rp-address 100.100.100.100 group-list 233.3.3.3/32 bidir
``` 

Configure PIM BSR candidate

```
switch (config) # ip pim bsr-candidate vlan 10 priority 100
```

Configure PIM RP candidate

```
switch (config) # ip pim vrf default rp-candidate ethernet 1/12 group-list 225.1.0.0/16
switch (config) # ip pim vrf default rp-candidate ethernet 1/12 bidir
```

Show Commands to Validate Functionality 

```
switch# show ip pim protocol
```

Expected Results.

* You can configure OSPF routing for loopback1.
* You successfully enabled PIM-SM on loopback1.
* You configured loopback1 to act as a PIM-SM RP.
* You configured the specific group-prefix that will be used in the next test.
* You successfully enabled the BSR on both 8325s using loopback0 as the BSR source IP.

[Back to Index](../index.md)

