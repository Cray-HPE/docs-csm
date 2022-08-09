# Restore missing spire metadata

If the BSS meta-data server does contain the proper spire meta-data then
computes will fail to boot. This is due to `dracut` pulling server data from the
meta-data during startup. To fix this issue, the `spire-update-bss` job needs
to be rerun.

## Error

```text
[  557.513984] Apr 22 18:02:02 nid000004 dracut-initqueue[4177]: time="2022-04-22T18:02:02Z" level=info msg="SVID is not found. Starting node attestation" subsystem_name=attestor trust_domain_id="spiffe://null"
[  557.514000] Apr 22 18:02:07 nid000004 dracut-initqueue[4194]: Agent is unavailable.
[  557.514017] Apr 22 18:02:07 nid000004 dracut-initqueue[4174]: Warning: Spire-agent healthcheck failed, return code 1
```

## Check

(`ncn-m#`) Run `goss-spire-bss-metadata-exist` goss test

```bash
goss -g /opt/cray/tests/install/ncn/tests/goss-spire-bss-metadata-exist.yaml v
```

Example output:

```text
Failures/Skipped:

Title: Kubernetes Query BSS Cloud-init for spire meta data
Meta:
    desc: Kubernetes Query BSS Cloud-init for spire meta data
    sev: 0
Command: spire_in_bss_cloudinit: exit-status:
Expected
    <int>: 1
to equal
    <int>: 0

Total Duration: 0.387s
Count: 1, Failed: 1, Skipped: 0
```

## Solution

Run the following command on a master node to restart the job that populates
the meta-data server with the correct spire information

(`ncn-m#`) Re-run the spire-update-bss job

```bash
JOB=$(kubectl get jobs -n spire -l app.kubernetes.io/name=spire-update-bss --no-headers -oname |sort -u | tail -n1); kubectl get -n spire $JOB -o json  | jq 'del(.spec.selector,.spec.template.metadata.labels)' | kubectl replace --force -f -
```
