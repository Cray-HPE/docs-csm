# Configure Domain Name System (DNS) Client

The Domain Name System (DNS) translates domain and host names to and from IP addresses.
A DNS client resolves hostnames to IP addresses by querying assigned DNS servers for the appropriate IP address.

## Configuration Commands

Enter a domain name in CONFIGURATION mode (up to 64 alphanumeric characters):

```text
# ip domain-name NAME
```

Add names to complete unqualified host names in CONFIGURATION mode:

```text
# ip domain-list NAME
```

## Expected Results

1. Administrators can configure the DNS client
2. The output is correct
3. Administrators can ping the device

[Back to Index](index.md)
