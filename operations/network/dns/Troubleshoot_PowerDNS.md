# Troubleshoot PowerDNS

## List DNS Zone Contents

The PowerDNS zone database is populated with data from two sources:

* The cray-powerdns-manager service creates the zones and DNS records based on data sourced from the System Layout Service (SLS)
* The external DNS records are populated by the cray-externaldns-external-dns service using data sourced from Kubernetes annotations and virtual service definitions

Use the `cray-powerdns-visualizer` command to view the zone structure that cray-powerdns-manager will create.

```
ncn-m001# kubectl -n services exec deployment/cray-powerdns-manager \
-c cray-powerdns-manager -- cray-powerdns-visualizer
```

Example output:

```
.
├── 252.10.in-addr.arpa.
│   ├── [PTR]  5.252.10.in-addr.arpa.
│   │   └── sw-leaf-002.nmn.system.dev.cray.com.
│   ├── [PTR]  4.252.10.in-addr.arpa.
│   │   └── sw-leaf-001.nmn.system.dev.cray.com.
│   ├── [PTR]  3.252.10.in-addr.arpa.
│   │   └── sw-spine-002.nmn.system.dev.cray.com.
│   ├── [PTR]  6.2.252.10.in-addr.arpa.
│   │   └── pbs_comm_service.nmn.system.dev.cray.com.
│   ├── [PTR]  5.2.252.10.in-addr.arpa.
│   │   └── pbs_service.nmn.system.dev.cray.com.
│   ├── [PTR]  4.2.252.10.in-addr.arpa.
│   │   └── slurmdbd_service.nmn.system.dev.cray.com.
│   ├── [PTR]  3.2.252.10.in-addr.arpa.
│   │   └── slurmctld_service.nmn.system.dev.cray.com.
│   ├── [PTR]  2.2.252.10.in-addr.arpa.
│   │   └── uai_macvlan_bridge.nmn.system.dev.cray.com.

[...]
```

For more information on External DNS and troubleshooting steps, see the [External DNS documentation](../external_dns/External_DNS.md).

## PowerDNS Logging

When troubleshooting DNS problems, it may prove helpful to increase the level of logging from the default value of 3 (error).

1. Edit the cray-dns-powerdns ConfigMap.

   ```
   ncn-m001# kubectl -n services edit cm cray-dns-powerdns
   ```

1. Set the `loglevel` parameter in `pdns.conf` to the desired setting.

   ```
   pdns.conf: |
      config-dir=/etc/pdns
      include-dir=/etc/pdns/conf.d
      guardian=yes
      loglevel=3
      setgid=pdns
      setuid=pdns
      socket-dir=/var/run
      version-string=anonymous
   ```

1. Restart the PowerDNS service.

   ```
   ncn-m001# kubectl -n services rollout restart deployment cray-dns-powerdns
   ```

   Example output:

   ```
   deployment.apps/cray-dns-powerdns restarted
   ```

Refer to the external [PowerDNS documentation](https://doc.powerdns.com/authoritative/settings.html#loglevel) for more information.

## Verify DNSSEC Operation

### Verify Zones are Being Signed with the Zone Signing Key

Check that the required zone has a DNSKEY entry; this should match the public key portion of the zone signing key.

```
ncn-m001# kubectl -n services exec deployment/cray-dns-powerdns \
-c cray-dns-powerdns -- pdnsutil show-zone system.dev.cray.com
```

Example output:

```
This is a Master zone
Last SOA serial number we notified: 2021090901 == 2021090901 (serial in the database)
Zone has following allowed TSIG key(s): system-key
Zone uses following TSIG key(s): system-key
Metadata items:
	AXFR-MASTER-TSIG	system-key
	SOA-EDIT-API	DEFAULT
	TSIG-ALLOW-AXFR	system-key
Zone has NSEC semantics
keys:
ID = 1 (CSK), flags = 257, tag = 26690, algo = 13, bits = 256	  Active	 Published  ( ECDSAP256SHA256 )
CSK DNSKEY = system.dev.cray.com. IN DNSKEY 257 3 13 TAi+aXL+Z8ZSFHxz+iEWB3MEdi1JWgM/tb3Q1M76yVOq5Kaur9k+oIAHXvCSR19Iuu+0ZUAyLB0vKkhScJp3Tw== ; ( ECDSAP256SHA256 )
DS = system.dev.cray.com. IN DS 26690 13 1 8c926281afb822a2bea767f08c79b856a2427c26 ; ( SHA1 digest )
DS = system.dev.cray.com. IN DS 26690 13 2 2bfd71e5403f99d25496f5f7f352e71747bb72ee6eb240dcaf8b56b95d18ef6c ; ( SHA256 digest )
DS = system.dev.cray.com. IN DS 26690 13 4 df40f23a7ee051d7e3d40d4059640bda3558cd74a37110b25f7b8cf4e60506c77bf33a660400710d397df0a1cde26d70 ; ( SHA-384 digest )
```
If the DNSKEY record is incorrect, verify that the zone name is correct in the `dnssec` SealedSecret in `customizations.yaml` and that the desired zone signing key was used. Please see the [PowerDNS Configuration Guide](./PowerDNS_Configuration.md) for more information.

### Verify TSIG Operation

> **IMPORTANT:** These examples are for informational purposes only. The use of the `dig` command `-y` option to present the key should be avoided in favor of the `-k` option with the secret in a file to avoid the key being displayed in `ps` command output or the shell history.

1. Determine the IP address of the external DNS service.

   ```
   ncn-m001# kubectl -n services get service cray-dns-powerdns-can-tcp
   ```

   Example output:

   ```
   NAME                        TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
   cray-dns-powerdns-can-tcp   LoadBalancer   10.27.91.157   10.101.8.113   53:30726/TCP   6d
   ```

2. Verify that an AXFR query to the external DNS service works when the correct TSIG key is presented.

   ```
   $ dig -t axfr system.dev.cray.com @10.101.8.113 -y \ "hmac-sha256:system-key:dnFC5euKixIKXAr6sZhI7kVQbQCXoDG5R5eHSYZiBxY=" +nocrypto | head
   ```

   Example output:

   ```
   ; <<>> DiG 9.10.6 <<>> -t axfr system.dev.cray.com @10.101.8.113 -y hmac-sha256:system-key:dnFC5euKixIKXAr6sZhI7kVQbQCXoDG5R5eHSYZiBxY= +nocrypto
   ;; global options: +cmd
   system.dev.cray.com.	3600	IN	SOA	a.misconfigured.dns.server.invalid. hostmaster.system.dev.cray.com. 2021090901 10800 3600 604800 3600
   system.dev.cray.com.	3600	IN	RRSIG	SOA 13 4 3600 20210930000000 20210909000000 26690 system.dev.cray.com. [omitted]
   system-key.		0	ANY	TSIG	hmac-sha256. 1632302505 300 32 XoySAOtCD52OzO/2MeFk0/x7MG6m93IxtWaNfhzaRkg= 44483 NOERROR 0
   system.dev.cray.com.	3600	IN	DNSKEY	257 3 13 [key id = 26690]
   system.dev.cray.com.	3600	IN	RRSIG	DNSKEY 13 4 3600 20210930000000 20210909000000 26690 system.dev.cray.com. [omitted]
   sma-kibana.system.dev.cray.com. 300 IN	A	10.101.8.128
   sma-kibana.system.dev.cray.com. 300 IN	RRSIG	A 13 5 300 20210930000000 20210909000000 26690 system.dev.cray.com. [omitted]
   ```

   When presented with an invalid key the transfer should fail.

   ```
   $ dig -t axfr system.dev.cray.com @10.101.8.113 \
   -y "hmac-sha256:system-key:B7n/sK74pa7r0ygOZkKpW9mWkPjq8fV71j1SaTpzJMQ="
   ```

   Example output:

   ```
   ;; Couldn't verify signature: expected a TSIG or SIG(0)

   ; <<>> DiG 9.10.6 <<>> -t axfr system.dev.cray.com @10.101.8.113 -y hmac-sha256:system-key:B7n/sK74pa7r0ygOZkKpW9mWkPjq8fV71j1SaTpzJMQ=
   ;; global options: +cmd
   ; Transfer failed.
   ```
   
   The `cray-dns-powerdns` pod log will also indicate that the request failed.

   ```
   ncn-m001# kubectl -n services logs cray-dns-powerdns-64fdf6597c-pqgdt -c cray-dns-powerdns
   ```

   Example output:

   ```
   ---
   Sep 22 09:31:17 Packet for 'system.dev.cray.com' denied: Signature with TSIG key 'system-key' failed to validate
   ```
