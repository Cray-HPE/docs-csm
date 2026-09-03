# PIM-SM Bootstrap Router (BSR) and Rendezvous Point (RP)

"Every PIM multicast group needs to be associated with the IP address of a Rendezvous Point (RP)
...
For all senders to reach all receivers, it is crucial that all routers in the domain use the same mappings
of group addresses to RP addresses.
...
The BSR mechanism provides a way in which viable group-to-RP mappings can be created and rapidly distributed
to all the PIM routers in a domain." – RFC 5059

## Configuration commands

(`switch(config)#`) Enable PIM protocol:

```console
router pim
```

(`switch(config)#`) Configuring static address of rendezvous point for multicast group:

```console
ip pim rp-address 10.10.10.10
ip pim vrf default rp-address 100.100.100.100 group-list 233.3.3.3/32 bidir
```

(`switch(config)#`) Configure PIM BSR candidate:

```console
ip pim bsr-candidate vlan 10 priority 100
```

(`switch(config)#`) Configure PIM RP candidate:

```console
ip pim vrf default rp-candidate ethernet 1/12 group-list 225.1.0.0/16
ip pim vrf default rp-candidate ethernet 1/12 bidir
```

## Show commands to validate functionality

(`switch(config)#`)

```console
show ip pim protocol
```

## Expected results

* The administrator can configure OSPF routing for `loopback1`.
* The administrator successfully enabled `PIM-SM` on `loopback1`.
* The administrator configured `loopback1` to act as a `PIM-SM` RP.
* The administrator configured the specific group prefix that will be used in the next test.
* The administrator successfully enabled the BSR on both `8325`s using `loopback0` as the BSR source IP address.

[Back to Index](../README.md)
