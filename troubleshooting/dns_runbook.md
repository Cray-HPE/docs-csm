# Runbook - DNS Troubleshooting

## 1. Confirm the status of the `cray-dns-unbound` pods/services

### 1.1 Confirm `cray-dns-unbound` pods

On any worker/manager, run:

```bash
kubectl get -n services pods | grep unbound |grep -v unbound-manager 
```

You should see the following services as output:

```text
NAME                                READY   STATUS    RESTARTS   AGE
cray-dns-unbound-6d7cdf6cdb-8cwlw   2/2     Running   0          2d13h
cray-dns-unbound-6d7cdf6cdb-nn96q   2/2     Running   0          2d13h
cray-dns-unbound-6d7cdf6cdb-xsxrr   2/2     Running   0          2d13h
```

- Confirm `Running` status for pods

### 1.3 Confirm `cray-dnspunbound-coredns` Job

```bash
kubectl get job -n services -l app.kubernetes.io/instance=cray-dns-unbound
```

Potential output:

```text
NAME                       COMPLETIONS   DURATION   AGE
cray-dns-unbound-coredns   1/1           65s        64d
```

- Confirm `COMPLETIONS` is `1/1`.

### 1.2 Confirm `cray-dns-unbound-manager` Cronjob

```bash
kubectl get cronjob -n services -l app.kubernetes.io/instance=cray-dns-unbound
```

Potential output:

```text
NAME                       SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cray-dns-unbound-manager   */2 * * * *   False     0        116s            64d
```

- Confirm `LAST SCHEDULE` is not higher than `10m`.

### 1.3 Verify DNS Records Are Being Generated

```bash
kubectl -n services get cm cray-dns-unbound -o json | jq '.binaryData."records.json.gz"' -r | base64 -d | gunzip -|jq
```

The output will be in this format:

```json
[
  {
    "hostname": "api-gw-service-nmn.local",
    "ip-address": "10.92.100.71"
  }
]
```

- If the out is `[]`. Check `cray-dns-unbound-manager` cronjob for errors in the log and last scheduled time.

## 2. Confirm Host Resolver Configuration

### 2.1 Confirm `/etc/resolv.conf`

- For the Shasta v1.4/ CSM 0.9 and newer release(s) the `/etc/resolv.conf` should contain the following in-order:

1. `/etc/resolv.conf` should only contain `cray-dns-unbound` service IP.

```text
nameserver 10.92.100.225
```

### 2.2 Confirm `cray-dns-unbound` Forwarding Information Is Correct And Accessible

```bash
kubectl get cm -n services cray-dns-unbound -o yaml|grep forward-addr
```

The output should look like:

```text
forward-addr: 172.30.84.40
```

- If the command does not return anything, that means `dns-forwarding` is not setup for a system.

- Verify DNS queries are working with `dns-forwarder`.

```bash
nslookup google.com 172.30.84.40
```

Potential output:

```text
Server: 172.30.84.40
Address: 172.30.84.40#53
 
Non-authoritative answer:
Name: google.com
Address: 172.217.1.238
Name: google.com
Address: 2607:f8b0:4009:81a::200e
```

- If the DNS query fails on the configured `dns-forwarder`. This will cause issues DNS on all of Shasta and needs to be resolved.
- A workaround is to remove `dns-forwarding` configurations in ConfigMap `cray-dns-unbound`. See example below:

```bash
        local-zone: "local" static
        local-zone: "nmn." static
        local-zone: "hmn." static
        local-zone: "10.in-addr.arpa." nodefault

    forward-zone:
        name: .
        forward-addr: 172.30.84.40
```

to

```bash
        local-zone: "local" static
        local-zone: "nmn." static
        local-zone: "hmn." static
        local-zone: "10.in-addr.arpa." nodefault
        local-zone: "."
```

## 3. Checking Hostname in DNS

### 3.1. Lookup Hostname By Querying DNS

To verify Hostname is in DNS. Query DNS with the hostname.

```bash
nslookup api-gw-service-nmn.local
```

Output should be:

```text
Server: 10.92.100.225
Address: 10.92.100.225#53

Name: api-gw-service-nmn.local
Address: 10.92.100.71
```

- If you get `** server can't find $HOSTNAME: NXDOMAIN`. That is a failed DNS query.

### 3.2 Lookup Hostname In Unbound ConfigMap

Verify the hostname is being generated and loaded into `cray-dns-unbound` ConfigMap

```bash
kubectl -n services get cm cray-dns-unbound -o json | jq '.binaryData."records.json.gz"' -r | base64 -d | gunzip - | jq | grep -A 1 $HOSTNAME
```

Example:

```bash
ncn-m001:~ # kubectl -n services get cm cray-dns-unbound -o json | jq '.binaryData."records.json.gz"' -r | base64 -d | gunzip -|jq | grep -A 1 x3000c0s38b0n0
    "hostname": "x3000c0s38b0n0",
    "ip-address": "10.252.1.12"
--
    "hostname": "x3000c0s38b0n0",
    "ip-address": "10.252.1.12"
--
    "hostname": "x3000c0s38b0n0h0",
    "ip-address": "10.253.0.9"
--
    "hostname": "x3000c0s38b0n0h0.hsn",
    "ip-address": "10.253.0.9"
ncn-m001:~ # 
```

- If hostname is not showing up in the ConfigMap. `cray-dns-unbound` will not have a DNS record for the host.

### 3.3 Reset `cray-dns-unbound` ConfigMap

Reset DNS record data for `cray-dns-unbound` to force a complete DNS record generation with `cray-dns-unbound-manager`
Verify which version of `cray-dns-unbound` is running the system by running this command:

```bash
kubectl get cm -n services cray-dns-unbound -o yaml | yq r - binaryData
```

The output should look like this:

```text
records.json.gz: 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
```

- If the output is blank. Confirms you are running the none compressed data version of `cray-dns-unbound`
- Run the following command to reset DNS records in `cray-dns-unbound`
  - Compressed data version
  
  ```bash
  kubectl -n services patch configmaps cray-dns-unbound --type merge -p '{"binaryData":{"records.json.gz":"H4sICLQ/Z2AAA3JlY29yZHMuanNvbgCLjuUCAETSaHADAAAA"}}'
  ```
  
  - No compression on `cray-dns-unbound` DNS records
  
  ```bash
  kubectl -n services patch configmaps cray-dns-unbound --type merge -p '{"data":{"records.json":"[]"}}'
  ```

- Wait for `cray-dns-unbound-manager` to run and repopulate DNS records in `cray-dns-unbound` ConfigMap
- Check hostname with sections 3.1 and 3.2

### 3. Check cray-dns-unbound logs

```bash
kubectl logs -n services -l app.kubernetes.io/instance=cray-dns-unbound -c unbound
```

Example:

```text
[1596224129] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224129] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224135] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224135] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224140] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224140] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224145] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224145] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224149] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224149] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224128] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224128] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224134] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224134] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224138] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224138] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224144] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224144] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224148] unbound[8:0] debug: using localzone health.check.unbound. transparent
[1596224148] unbound[8:0] debug: using localzone health.check.unbound. transparent
```

Any logs with ERROR or Exception are an indication that the Unbound service is not healthy.

### 4.1. `cray-dns-unbound-manager` Logs

```bash
kubectl logs -n services pod/$(kubectl get -n services pods | grep unbound | tail -n 1 | cut -f 1 -d ' ') -c manager | tail -n4
```

Example:

```text
  uid: bc1e8b7f-39e2-49e5-b586-2028953d2940

Comparing new and existing DNS records.
    No differences found. Skipping DNS update
```

Any log with ERROR or Exception are an indication that DNS is not healthy.

## 5. Continue Troubleshooting By Following

`dhcp_runbook.md` `cray-dhcp-kea`, `cray-sls` and `cray-smd` are data sources for `cray-dns-unbound`.

Follow the `dhcp_runbook.md` for steps to confirming `cray-dhcp-kea` health, discovery state and network troubleshooting [DHCP run book](../troubleshooting/dhcp_runbook.md).
