# Spire Database Cluster DNS Lookup Failure

## Description

There is a known issue where if Unbound is configured to forward to an invalid or inaccessible site DNS server, the Spire server may be unable to resolve the hostname of its PostgreSQL cluster.

## Symptoms

* The `spire-server` pods may be in a `CrashLoopBackOff` state.
* API calls to services may fail with HTTP `503` errors.
* The `spire-server` pods contain the following error in the logs.

  ```text
  time="2022-06-13T15:43:49Z" level=error msg="Fatal run error" error="datastore-sql: dial tcp: lookup spire-postgres-pooler.spire.svc.cluster.local: Try again"
  ```

## Solution

1. Check to see if `cray-dns-unbound` has a `forward-addr` configured.

   Command:

   ```bash
   ncn-mw# kubectl -n services get cm cray-dns-unbound -o yaml | grep forward-addr
   ```

   Example output:

   ```yaml  
   forward-addr: 172.30.84.40
   ```

1. Check to see if the `forward-addr` is accessible from the worker nodes.

   * Attempt to ping it.

     ```bash
     ncn-w# ping -c 1 172.30.84.40
     ```

     Example output:

     ```text
     PING 172.30.84.40 (172.30.84.40) 56(84) bytes of data.
     64 bytes from 172.30.84.40: icmp_seq=1 ttl=58 time=0.175 ms
     
     --- 172.30.84.40 ping statistics ---
     1 packets transmitted, 1 received, 0% packet loss, time 0ms
     rtt min/avg/max/mdev = 0.175/0.175/0.175/0.000 ms
     ```

   * Attempt to resolve a hostname external to the system.

     ```bash
     ncn-w# host www.google.com 172.30.84.40
     ```

     Example output:

     ```text
     Using domain server:
     Name: 172.30.84.40
     Address: 172.30.84.40#53
     Aliases:
     
     www.google.com has address 209.85.234.106
     www.google.com has address 209.85.234.103
     www.google.com has address 209.85.234.147
     www.google.com has address 209.85.234.105
     www.google.com has address 209.85.234.99
     www.google.com has address 209.85.234.104
     www.google.com has IPv6 address 2607:f8b0:4001:c17::63
     www.google.com has IPv6 address 2607:f8b0:4001:c17::93
     www.google.com has IPv6 address 2607:f8b0:4001:c17::6a
     www.google.com has IPv6 address 2607:f8b0:4001:c17::67
     ```

   If the above checks fail, then verify that the Customer Management Network \(CMN\) is working correctly. See [Troubleshoot CMN issues](../../operations/network/customer_accessible_networks/Troubleshoot_CMN_Issues.md) for more information.

If it is not possible to restore access to the `forward-addr`, then reconfigure Unbound to point to a working DNS server, or temporarily remove the forwarder configuration.
See "Change the Site DNS Server" in [Manage the DNS Unbound Resolver](../../operations/network/dns/Manage_the_DNS_Unbound_Resolver.md) for more information.
