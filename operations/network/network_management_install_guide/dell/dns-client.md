# Domain name system (DNS) client

The Domain Name System (DNS) translates domain and host names to and from IP addresses. A DNS client resolves hostnames to IP addresses by querying assigned DNS servers for the appropriate IP address.

Relevant Configuration

Enter a domain name in CONFIGURATION mode (up to 64 alphanumeric characters).

```
ip domain-name name
```

Add names to complete unqualified host names in CONFIGURATION mode.

```
ip domain-list name
```

Expected Results

* Step 1: You can configure the DNS client
* Step 2: The output is correct
* Step 3: You can ping the device

[Back to Index](/docs-csm/operations/network/network_management_install_guide/dell/
index)

