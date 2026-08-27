# Domain Name System (DNS) Client

The Domain Name System (DNS) translates domain and host names to and from IP addresses.
A DNS client resolves hostnames to IP addresses by querying assigned DNS servers for the appropriate IP address.

(`switch(config)#`) Configure the switch to resolve queries via a DNS server.

```console
ip name-server <IPv4/IPv6 address>
```

(`switch(config)#`) Configure a domain name.

```console
ip domain-list mydomain2.com
```

## Show commands to validate functionality

```console
show hosts
```

## Expected results

* The DNS client can be configured.
* The output is correct.
* The device can be pinged.

[Back to Index](../README.md)
