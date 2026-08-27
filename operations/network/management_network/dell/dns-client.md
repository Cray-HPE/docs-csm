# Configure Domain Name System (DNS) Client

The Domain Name System (DNS) translates domain and host names to and from IP addresses.
A DNS client resolves hostnames to IP addresses by querying assigned DNS servers for the appropriate IP address.

## Configuration commands

Enter a domain name in configuration mode (up to 64 alphanumeric characters):

```text
ip domain-name NAME
```

Add names to complete unqualified host names in configuration mode:

```text
ip domain-list NAME
```

## Expected results

1. Administrators can configure the DNS client
1. The output is correct
1. Administrators can ping the device

[Back to Index](../README.md)
