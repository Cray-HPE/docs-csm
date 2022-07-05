# Check DHCP Lease is Getting Allocated

## Checking

Check the Kea logs and verify that the DHCP lease is getting allocated.

```bash
ncn-mw# KEA_POD=$(kubectl get pods -n services -l app.kubernetes.io/name=cray-dhcp-kea -o custom-columns=:.metadata.name --no-headers)
ncn-mw# echo "${KEA_POD}"
ncn-mw# kubectl logs -n services pod/"${KEA_POD}" -c cray-dhcp-kea
```

The following example shows that Kea is allocating a lease to `10.104.0.23`. The lease **must** say `DHCP4_LEASE_ALLOC`; if it says `DHCP4_LEASE_ADVERT`, then there is likely a problem.

```text
2021-04-21 00:13:05.416 INFO  [kea-dhcp4.leases/24.139710796402304] DHCP4_LEASE_ ***ALLOC*** [hwtype=1 02:23:28:01:30:10], cid=[00:78:39:30:30:30:63:31:73:30:62:31], tid=0x21f2433a: lease 10.104.0.23 has been allocated for 300 seconds
```

The following is an example of the lease showing `DHCP4_LEASE_ADVERT`:

```text
2021-06-21 16:44:31.124 INFO  [kea-dhcp4.leases/18.139837089017472] DHCP4_LEASE_ ***ADVERT*** [hwtype=1 14:02:ec:d9:79:88], cid=[no info], tid=0xe87fad10: lease 10.252.1.16 will be advertised
```

## Remediation

Restarting Kea will fix the `DHCP4_LEASE_ADVERT` issue in most cases.

1. Restart Kea.

    ```bash
    ncn-mw# kubectl rollout restart deployment -n services cray-dhcp-kea
    ```

1. Wait for deployment to restart.

    ```bash
    ncn-mw# kubectl rollout status deployment -n services cray-dhcp-kea
    ```

[Back to index](index.md).
