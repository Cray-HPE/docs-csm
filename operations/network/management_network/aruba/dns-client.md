# Domain Name System (DNS) Client

The Domain Name Service (DNS) translates domain and host names to and from IP addresses.
A DNS client resolves hostnames to IP addresses by querying assigned DNS servers for the appropriate IP address.

## Configuration commands

(`switch#`) Configure the switch to resolve queries via a DNS server:

```tex
ip dns server-address IP-ADDR [vrf VRF]
```

(`switch#`) Configure a domain name:

```text
ip dns domain-name NAME
```

## Show commands to validate functionality

(`switch#`)

```text
show ip dns
```

## Expected results

* Administrators can configure the DNS client.
* The output of all commands is correct.
* Administrators can ping the device.

[Back to Index](../README.md)
