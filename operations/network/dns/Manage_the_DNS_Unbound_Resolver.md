# Manage the DNS Unbound Resolver

The unbound DNS instance is used to resolve names for the physical equipment on the management networks within the system, such as NCNs, UANs, switches, compute nodes, and more. This instance is accessible only within the HPE Cray EX system.

## Check the Status of the `cray-dns-unbound` Pods

Use the kubectl command to check the status of the pods:

```bash
ncn-w001# kubectl get -n services pods | grep unbound
```

Example output:

```bash
cray-dns-unbound-696c58647f-26k4c            2/2   Running      0   121m
cray-dns-unbound-696c58647f-rv8h6            2/2   Running      0   121m
cray-dns-unbound-coredns-q9lbg               0/2   Completed    0   121m
cray-dns-unbound-manager-1596149400-5rqxd    0/2   Completed    0   20h
cray-dns-unbound-manager-1596149400-8ppv4    0/2   Completed    0   20h
cray-dns-unbound-manager-1596149400-cwksv    0/2   Completed    0   20h
cray-dns-unbound-manager-1596149400-dtm9p    0/2   Completed    0   20h
cray-dns-unbound-manager-1596149400-hckmp    0/2   Completed    0   20h
cray-dns-unbound-manager-1596149400-t24w6    0/2   Completed    0   20h
cray-dns-unbound-manager-1596149400-vzxnp    0/2   Completed    0   20h
cray-dns-unbound-manager-1596222000-bcsk7    0/2   Completed    0   2m48s
cray-dns-unbound-manager-1596222060-8pjx6    0/2   Completed    0   118s
cray-dns-unbound-manager-1596222120-hrgbr    0/2   Completed    0   67s
cray-dns-unbound-manager-1596222180-sf46q    1/2   NotReady     0   7s
```

For more information about the pods displayed in the output above:

- `cray-dns-unbound-xxx` - These are the main unbound pods.
- `cray-dns-unbound-manager-yyy` - These are job pods that run periodically to update DNS from DHCP \(Kea\) and the SLS/SMD content for the Hardware State Manager \(HSM\).
   Pods will go into the `Completed` status, and then independently be reaped "later" by the Kubernetes job's processes.
- `cray-dns-unbound-coredns-zzz` - This pod is run one time during installation of Unbound \(Stage 4\) and reconfigures CoreDNS/ExternalDNS to point to Unbound for all site/internet lookups.

The table below describes what the status of each pod means for the health of the `cray-dns-unbound` services and pods. The Init and NotReady states are not necessarily bad,
but it means the pod is being started or is processing. The `cray-dns-manager` and `cray-dns-coredns` pods for `cray-dns-unbound` are job pods that run periodically.

|Pod|Healthy Status|Error Status|Other|
|---|--------------|------------|-----|
|`cray-dns-unbound`|Running|CrashLoopBackOff|
|`cray-dns-coredns`|Completed|CrashLoopBackOff|InitNotReady|
|`cray-dns-manager`|Completed|CrashLoopBackOff|InitNotReady|

## Unbound Logs

Logs for the unbound Pods will show the status and health of actual DNS lookups. Any logs with `ERROR` or `Exception` are an indication that the Unbound service is not healthy.

```bash
ncn-w001# kubectl logs -n services -l app.kubernetes.io/instance=cray-dns-unbound -c unbound
```

Example output:

```bash
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
...snip...
[1597020669] unbound[8:0] error: error parsing local-data at 33 '69.0.254.10.in-addr.arpa.  PTR  .local': Empty label
[1597020669] unbound[8:0] error: Bad local-data RR 69.0.254.10.in-addr.arpa.  PTR  .local
[1597020669] unbound[8:0] fatal error: Could not set up local zones
```

**Troubleshooting:** If there are any errors in the Unbound logs:

- The "localzone health.check.unbound. transparent" log is not an issue.
- Typically, any error seen in Unbound, including the example above, falls under one of two categories:
  - A bad configuration can come from a misconfiguration in the Helm chart. Currently, only the site/external DNS lookup can be at fault.

    **ACTION:** See the customization.yaml file and look at the `system_to_site_lookup` value\(s\). Ensure that the external lookup values are valid and working.

  - Bad data \(as shown in the above example\) comes only from the DNS Helper and can be seen in the manager logs.

    **ACTION:** Review and troubleshoot the Manager Logs as shown below.

## View Manager \(DNS Helper\) Logs

Manager logs will show the status of the latest "true up" of DNS with respect to DHCP actual leases and SLS/SMD status. The following command shows the last four lines of the last Manager run, and can be adjusted as needed.

```bash
ncn-w001# kubectl logs -n services pod/$(kubectl get -n services pods \
| grep unbound | tail -n 1 | cut -f 1 -d ' ') -c manager | tail -n4
```

Example output:

```bash
uid: bc1e8b7f-39e2-49e5-b586-2028953d2940

Comparing new and existing DNS records.
    No differences found. Skipping DNS update
```

Any log with `ERROR` or `Exception` is an indication that DNS is not healthy. The above example includes one of two possible reports for a healthy manager run. The healthy states are described below, as long as the write to the ConfigMap has not failed:

- No differences found. Skipping DNS update
- Differences found. Writing new DNS records to our ConfigMap.

**Troubleshooting:** The Manager runs periodically, about every minute in release v1.4. Check if this is a one-time occurrence or if it is a recurring issue.

- If the error shows in one Manager log, but not during the next one, this is likely a one-time failure. Check to see if the record exists in DNS, and if so, move on.
- If several or all Manager logs show errors, particularly the same error, this could be of several sources:
  - Bad network connections to DHCP and/or SLS/SMD.

    **ACTION:** Capture as much log data as possible and contact customer support.

  - Bad data from DHCP and/or SLS/SMD.

    **ACTION:** If connections to DHCP \(Kea\) are involved, refer to [Troubleshoot DHCP Issues](../dhcp/Troubleshoot_DHCP_Issues.md).

## Restart Unbound

If any errors discovered in the sections above have been deemed transient or have not been resolved, the Unbound pods can be restarted.

Use the following command to restart the pods:

1. Restart Unbound

    ```bash
    ncn-w001# kubectl -n services rollout restart deployment cray-dns-unbound
    ```

A rolling restart of the Unbound pods will occur, old pods will not be terminated and new pods will not be added to the load balancer until the new pods have successfully loaded the DNS records.

## Clear Bad Data in the Unbound ConfigMap

Unbound stores records it obtains from DHCP, SLS, and SMD via the Manager job in a ConfigMap. It is possible to clear this ConfigMap and allow the next Manager job to regenerate the content.

This is useful in the following cases:

- A transient failure in any Unbound process or required services has left the configuration data in a bad state.
- SLS and SMD data needed to be reset because of bad or incorrect data there.
- DHCP \(Kea\) has been restarted to clear errors.

The following clears the \(DNS Helper\) Manager generated data in the ConfigMap. This is generally safe as Unbound runtime data is held elsewhere.

```bash
ncn-w001# kubectl -n services patch configmaps cray-dns-unbound \
--type merge -p '{"binaryData":{"records.json.gz":"H4sICLQ/Z2AAA3JlY29yZHMuanNvbgCLjuUCAETSaHADAAAA"}}'
```

## Change the Site DNS Server

Use the following procedure to change the site DNS server that Unbound forwards queries to. This may be necessary if the site DNS server is moved to a different IP address.

1. Edit the `cray-dns-unbound` ConfigMap.

   ```bash
   ncn-m001# kubectl -n services edit configmap cray-dns-unbound
   ```

   Update the `forward-zone` value in `unbound.conf`.

   ```yaml
   forward-zone:
       name: .
       forward-addr: 172.30.84.40
   ```

   Multiple DNS servers can be defined if required.

   ```yaml
   forward-zone:
       name: .
       forward-addr: 172.30.84.40
       forward-addr: 192.168.0.1
   ```

1. Restart `cray-dns-unbound` for this change to take effect.

   ```bash
   ncn-m001# kubectl -n services rollout restart deployment cray-dns-unbound
   deployment.apps/cray-dns-unbound restarted
   ```

1. Update `customizations.yaml`.

   **IMPORTANT:** If this step is not performed, then the Unbound configuration will be overwritten with the previous value the next time CSM or Unbound is upgraded.

   1. Extract `customizations.yaml` from the `site-init` secret in the `loftsman` namespace.

      ```bash
      ncn-m001# kubectl -n loftsman get secret site-init -o json | jq -r '.data."customizations.yaml"' | base64 -d > customizations.yaml
      ```

   1. Update `system_to_site_lookups` with the value of the new DNS server.

      ```yaml
      spec:
        network:
          netstaticips:
            system_to_site_lookups: 172.30.84.40
      ```

      If multiple DNS servers are required, add the additional servers into the `cray-dns-unbound` service configuration.

      ```yaml
      spec:
        kubernetes:
          services:
            cray-dns-unbound:
              forwardZones:
                - name: "."
                  forwardIps:
                    - "{{ network.netstaticips.system_to_site_lookups }}"
                    - "192.168.0.1"
              domain_name: '{{ network.dns.external }}'
      ```

   1. Update the `site-init` secret in the `loftsman` namespace.

      ```bash
      ncn-m001# kubectl delete secret -n loftsman site-init
      ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
      ```
