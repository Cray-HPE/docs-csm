# Domain Name System (DNS) Client

The Domain Name Service (DNS) translates domain and host names to and from IP addresses.
A DNS client resolves hostnames to IP addresses by querying assigned DNS servers for the appropriate IP address.

## Configuration commands

(`switch#`) Enter a domain name in configuration mode (up to 64 alphanumeric characters):

```text
ip domain-name NAME
```

(`switch#`) Add names to complete unqualified host names in configuration mode:

```text
ip domain-list NAME
```

## Expected results

* Administrators can configure the DNS client.
* The output of all commands is correct.
* Administrators can ping the device.

[Back to Index](../README.md)
