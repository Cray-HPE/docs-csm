# Check for duplicate and DNS entries for NCN and UANs test failure

* [Overview](#overview)
* [Symptoms](#symptoms)
* [Workaround](#workaround)

## Overview

The `cray-dns-unbound` DNS service configuration forwards queries it cannot answer to the customer-defined DNS server.
If this upstream DNS server is configured to drop queries it cannot answer then `cray-dns-unbound` sees this as a timeout.
This can cause some of the CSM upgrade pre-flight checks to fail.

## Symptoms

* The `Check for duplicate and DNS entries for NCN and UANs` health validation test will fail.

   ```text
   Title: Check for duplicate and DNS entries for NCN and UANs
   Meta:
       desc: Checks for duplicate IP addresses in the SMD EthernetInterface table and verifies that NCN/UAN management network DNS entries resolve to only 1 IP address. 
         To manually run the test, execute /opt/cray/tests/install/ncn/scripts/python/check_ncn_uan_ip_dns.py
       sev: 0
   ip_dns_check: exit-status: Error: Command execution timed out (30s)Total Duration: 30.009s 
   ```

* (`ncn-m#`) When run, the `/opt/cray/tests/install/ncn/scripts/python/check_ncn_uan_ip_dns.py` script fails.

    ```text
    2023-07-21 13:39:13,536 - __main__ - ERROR - ERROR: ncn-m003.chn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:39:49,661 - __main__ - ERROR - ERROR: ncn-w001.chn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:40:25,819 - __main__ - ERROR - ERROR: ncn-w002.chn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:41:01,959 - __main__ - ERROR - ERROR: ncn-w003.chn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:41:38,103 - __main__ - ERROR - ERROR: ncn-s001.chn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:42:14,231 - __main__ - ERROR - ERROR: uan001.cmn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:42:50,253 - __main__ - ERROR - ERROR: uan001.chn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:43:26,395 - __main__ - ERROR - ERROR: ncn-s002.chn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:44:02,521 - __main__ - ERROR - ERROR: ncn-s003.chn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:44:38,665 - __main__ - ERROR - ERROR: ncn-m001.chn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:45:14,797 - __main__ - ERROR - ERROR: ncn-m002.chn has more than 1 DNS entry
    ;; connection timed out; no servers could be reached
    
    2023-07-21 13:45:32,819 - __main__ - ERROR - ERRORS: see above output.
    ```

## Workaround

Update the `cray-dns-unbound` configuration so that all CSM internal network suffixes are no longer forwarded to the upstream DNS server.

1. (`ncn-m#`) Edit the `cray-dns-unbound` ConfigMap.

    ```bash
    kubectl edit -n services cm cray-dns-unbound
    ```

    Add the following lines after the `local-zone: "mtl." static` line.

    ```text
    local-zone: "can." static
    local-zone: "cmn." static
    local-zone: "chn." static
    ```

1. (`ncn-m#`) Restart the `cray-dns-unbound` service.

    ```bash
    kubectl rollout restart -n services deployment/cray-dns-unbound
    ```

    Wait for the rollout to finish

    ```bash
    kubectl rollout status -n services deployment/cray-dns-unbound
    ```

1. (`ncn-m#`) Rerun the test to confirm the workaround has addressed the issue.

    ```bash
    /opt/cray/tests/install/ncn/scripts/python/check_ncn_uan_ip_dns.py
    ```
