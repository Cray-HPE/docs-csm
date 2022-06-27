# Troubleshoot Common DNS Issues

The Domain Name Service \(DNS\) is part of an integrated infrastructure set designed to provide dynamic host discovery, addressing, and naming.
There are several different place to look for troubleshooting as DNS interacts with Dynamic Host Configuration Protocol \(DHCP\), the Hardware
Management Service \(HMS\), the System Layout Service \(SLS\), and the State Manager Daemon \(SMD\).

The information below describes what to check when experiencing issues with DNS.

## Troubleshoot an invalid hostname

It is important to verify if a hostname is correct. The values in the `networks.yml` or `networks_derived.yml` files are sometimes inaccurate.

The formats show below are valid hostnames:

- Component names (xnames)
  - Node Management Network \(NMN\):
    - `<xname\>`
    - `<xname\>.local`
  - Hardware Management Network \(HMN\):
    - `<xname\>-mgmt`
    - `<xname\>-mgmt.local`
- NID
  - Node Management Network \(NMN\):
    - `nid<nid\_number\>-nmn`
    - `nid<nid\_number\>-nmn.local`

Additional steps are needed if a hostname or component name (xname) is either listed incorrectly or not listed at all in the `networks.yml` or `networks_derived.yml` files.
In that case, the following actions must be taken:

1. Update the hostname in the Hardware State Manager \(HSM\).
1. Re-run any Ansible plays that require the data in these files.

## Check if a host is in DNS

(`ncn#`) Use the `dig` or `nslookup` commands directly against the Unbound resolver. A host is correctly in DNS if the response from the `dig` command includes the following:

- The `ANSWER SECTION` value exists with a valid hostname and IP address.
- A `QUERY` value exists that has the `status: NOERROR` message.

```bash
dig HOSTNAME @10.92.100.225
```

Example output:

```text
; <<>> DiG 9.11.2 <<>> x3000c0r41b0 @10.92.100.225
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 57196
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;x3000c0r41b0.                  IN      A

;; ANSWER SECTION:
x3000c0r41b0.           3600    IN      A       10.254.127.200

;; Query time: 0 msec
;; SERVER: 10.92.100.225#53(10.92.100.225)
;; WHEN: Fri Jul 17 18:49:48 UTC 2020
;; MSG SIZE  rcvd: 57
```

If either of the commands fail to meet the two conditions mentioned above, then collect the logs to troubleshoot.

(`ncn-mw#`) If there no record in the Unbound pod, that is also an indication that the host is not in DNS.

```bash
kubectl -n services get cm cray-dns-unbound -o jsonpath='{.binaryData.records\.json\.gz}' |
    base64 --decode | gzip -dc | jq -c '.[]' | grep XNAME
```

Example output excerpt:

```text
{"hostname": "x1003c7s7b0", "ip-address": "10.104.12.191"}
```

## Check the `cray-dns-unbound` logs for errors

(`ncn-mw#`) Use the following command to check the logs. Any logs with a message saying `ERROR` or `Exception` are an indication that the Unbound service is not healthy.

```bash
kubectl logs -n services -l app.kubernetes.io/instance=cray-dns-unbound -c cray-dns-unbound
```

Example output excerpt:

```text
[1596224129] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224129] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224135] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224135] unbound[8:0] debug: using localzone health.check.unbound. transparent
```

(`ncn-mw#`) To view the DNS Helper logs:

```bash
kubectl logs -n services pod/$(kubectl get -n services pods |
    grep unbound | tail -n 1 | cut -f 1 -d ' ') -c manager | tail -n4
```

Example output:

```text
  uid: bc1e8b7f-39e2-49e5-b586-2028953d2940

Comparing new and existing DNS records.
    No differences found. Skipping DNS update
```

## Verify that MetalLB/BGP peering and routes are correct

Log in to the spine switches and verify that MetalLB is peering to the spines via BGP.

(`sw-spine#`) Check both spines if they are available and powered up. All worker nodes should be peered with the spine BGP.

```text
show ip bgp neighbors
```

Example output:

```text
BGP neighbor: 10.252.0.4, remote AS: 65533, link: internal:
  Route-map (in/out)                                   : rm-ncn-w001
  BGP version                                          : 4
  Configured hold time in seconds                      : 180
  keepalive interval in seconds (configured)           : 60
  keepalive interval in seconds (established with peer): 30
  Minimum holdtime from neighbor in seconds            : 90BGP neighbor: 10.252.0.5, remote AS: 65533, link: internal:
  Route-map (in/out)                                   : rm-ncn-w002
  BGP version                                          : 4
  Configured hold time in seconds                      : 180
  keepalive interval in seconds (configured)           : 60
  keepalive interval in seconds (established with peer): 30
  Minimum holdtime from neighbor in seconds            : 90BGP neighbor: 10.252.0.6, remote AS: 65533, link: internal:
  Route-map (in/out)                                   : rm-ncn-w003
  BGP version                                          : 4
  Configured hold time in seconds                      : 180
  keepalive interval in seconds (configured)           : 60
  keepalive interval in seconds (established with peer): 30
  Minimum holdtime from neighbor in seconds            : 90
```

(`sw-spine#`) Confirm that routes to Kea \(`10.92.100.222`\) via all the NCN worker nodes are available:

```text
show ip route 10.92.100.222
```

Example output:

```text
Flags:
  F: Failed to install in H/W
  B: BFD protected (static route)
  i: BFD session initializing (static route)
  x: protecting BFD session failed (static route)
  c: consistent hashing
  p: partial programming in H/W
VRF Name default:
  ------------------------------------------------------------------------------------------------------
  Destination       Mask              Flag     Gateway           Interface        Source     AD/M
  ------------------------------------------------------------------------------------------------------
  default           0.0.0.0           c        10.102.255.9      eth1/16          static     1/1
  10.92.100.222     255.255.255.255   c        10.252.0.4        vlan2            bgp        200/0
                                      c        10.252.0.5        vlan2            bgp        200/0
                                      c        10.252.0.6        vlan2            bgp        200/0
```

## `tcpdump`

(`ncn-mw#`) Verify that the NCN is receiving DNS queries. On an NCN worker or manager with `kubectl` installed, run the following command:

```bash
tcpdump -envli bond0.nmn0 port 53
```

## The `ping` and `ssh` commands fail for hosts in DNS

(`ncn#`) If the IP address returned by the `ping` command is different than the IP address returned by the `dig` command, then restart `nscd` on the impacted node. This is done with the following command:

```bash
systemctl restart nscd.service
```

Attempt to `ping` or `ssh` to the IP address that was experiencing issues after restarting `nscd`.

## Check for missing DHCP leases

(`ncn#`) Search for a DHCP lease by checking active leases for the service:

```bash
curl -s -k -H "Authorization: Bearer ${TOKEN}" -X POST -H \
    "Content-Type: application/json" \-d '{ "command": "lease4-get-all",  "service": \
    [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea | jq
```

For example:

```bash
curl -s -k -H "Authorization: Bearer ${TOKEN}" -X \
    POST -H "Content-Type: application/json" \-d '{ "command": "lease4-get-all",  "service": \
    [ "dhcp4" ] }' https://api-gw-service-nmn.local/apis/dhcp-kea \
    | jq | grep x3000c0s19b4 -A 6 -B 4
```

Example output:

```json
{
"cltt": 1597777241,
"fqdn-fwd": true,
"fqdn-rev": true,
"hostname": "x3000c0s19b4",
"hw-address": "a4:bf:01:3e:d2:94",
"ip-address": "10.254.127.205",
"state": 0,
"subnet-id": 1,
"valid-lft": 300
}
```

If there is not a DHCP lease found, then:

- Ensure the system is running and that its DHCP client is still sending requests. Reboot the system via Redfish/IPMI if required.
- See [Troubleshoot DHCP Issues](../dhcp/Troubleshoot_DHCP_Issues.md) for more information.
