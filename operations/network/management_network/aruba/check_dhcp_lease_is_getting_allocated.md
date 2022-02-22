# Check DHCP lease is getting allocated

* Check the KEA logs and verify that the lease is getting allocated.

```
kubectl logs -n services pod/$(kubectl get -n services pods | grep kea | head -n1 | cut -f 1 -d ' ') -c cray-dhcp-kea
```

2021-04-21 00:13:05.416 INFO  [kea-dhcp4.leases/24.139710796402304] DHCP4_LEASE_ ***ALLOC*** [hwtype=1 02:23:28:01:30:10], cid=[00:78:39:30:30:30:63:31:73:30:62:31], tid=0x21f2433a: lease 10.104.0.23 has been allocated for 300 seconds


* Here we can see that KEA is allocating a lease to 10.104.0.23.
* The lease MUST say DHCP4_LEASE_ALLOC, if it says DHCP4_LEASE_ADVERT, there is likely a problem. Restarting KEA will fix this issue most of the time.


2021-06-21 16:44:31.124 INFO  [kea-dhcp4.leases/18.139837089017472] DHCP4_LEASE_ ***ADVERT*** [hwtype=1 14:02:ec:d9:79:88], cid=[no info], tid=0xe87fad10: lease 10.252.1.16 will be advertised

[Back to Index](./index.md)
