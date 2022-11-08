# Unbound forwarding to PowerDNS in and air-gapped environment

## Description

If Unbound is configured with no upstream DNS server to forward requests to, the forwarding of fully qualified domain name queries system components and services to PowerDNS does not work.

## Symptoms

* DNS resolution of short names (e.g. `api-gw-server-nmn.local`) works.
* DNS resolution of fully qualified domain names (e.g. `api.nmnlb.SYSTEM_DOMAIN`) does not work.

## Solution

1. (`ncn-mw#`) Edit the `cray-dns-unbound` ConfigMap.

   Command:

   ```bash
   kubectl -n services edit cm cray-dns-unbound
   ```

1. Add the following to `unbound.conf`.

   ```text
   local-zone: "mtl." static
   ```

   Example output:

   ```text
   data:
     unbound.conf: |-
       server:
       ...
        local-zone: "local" static
        local-zone: "nmn." static
        local-zone: "hmn." static
        local-zone: "mtl." static
        local-zone: "10.in-addr.arpa." nodefault
        local-zone: "." static
   ```

1. Remove the following from `unbound.conf`.

   ```text
   local-zone: "." static
   ```

1. (`ncn-mw#`) Restart the `cray-dns-unbound` service.

   ```bash
   kubectl -n services rollout restart deployment cray-dns-unbound
   ```

**IMPORTANT:** This change will need to be reapplied if the `cray-dns-unbound` helm chart is re-installed.

This will be resolved in CSM 1.3.1 and above.
