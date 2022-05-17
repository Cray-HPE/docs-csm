# Configure Domain Name Service (DNS) Clients

The Domain Name Service (DNS) translates domain and host names to and from IP addresses.
A DNS client resolves hostnames to IP addresses by querying assigned DNS servers for the appropriate IP address.

## Configuration Commands

Configure the switch to resolve queries via a DNS server:

```tex
switch(config)# ip dns server-address IP-ADDR [vrf VRF]
```

Configure a domain name:

```text
switch(config)# ip dns domain-name NAME
```

Show commands to validate functionality:

```text
switch# show ip dns
```

## Expected Results

1. Administrators can configure the DNS client
1. The output is correct
1. Administrators can ping the device

[Back to Index](../index.md)