# Cilium Migration Failure Due to Missing BSS Global Metadata Parameter

## Description

On a system that was originally installed with CSM 1.3 or earlier, when upgrading to CSM 1.7,
the Cilium migration process can fail if the `k8s-primary-cni` BSS Global meta-data parameter is not set.

The `k8s-primary-cni` parameter was added in CSM 1.4. Systems installed at CSM 1.3 or earlier will
not have this parameter defined, causing the migration script to fail with an unsupported value of `null`.

## Symptoms

During the CSM 1.6 to 1.7 upgrade, the Cilium migration process will fail with an error indicating
an unsupported `k8s-primary-cni` value.

(`ncn-m#`)

```bash
/usr/share/doc/csm/scripts/cilium_migration.sh
```

Example output:

```console
INFO Checking current k8s-primary-cni value in BSS
ERROR Unsupported k8s-primary-cni value: 'null'. Only migration from 'weave' to 'cilium' is supported.
```

## Solution

Set the `k8s-primary-cni` parameter to `weave` in the BSS Global metadata, then re-run the migration process.

1. (`ncn-m#`) Set the `k8s-primary-cni` parameter to `weave`.

   ```bash
   csi handoff bss-update-cloud-init --limit Global --set meta-data.k8s-primary-cni=weave
   ```

   Example output:

   ```console
   2025/12/12 10:57:42 TOKEN was not set. Attempting to read API token from Kubernetes directly ...
   2025/12/12 10:57:42 Getting management NCNs from SLS...
   12
   2025/12/12 10:57:42 Done getting management NCNs from SLS.
   2025/12/12 10:57:42 Updating NCN cloud-init parameters...
   2025/12/12 10:57:42 Successfully PUT BSS entry for Global
   2025/12/12 10:57:42 Done updating NCN cloud-init parameters.
   ```

1. (`ncn-m#`) Verify the parameter change was successful.

   ```bash
   cray bss bootparameters list --hosts Global --format json | jq '.[]["cloud-init"]["meta-data"]["k8s-primary-cni"]'
   ```

   Example output:

   ```console
   "weave"
   ```

1. (`ncn-m#`) Re-run the Cilium migration script.

   ```bash
   /usr/share/doc/csm/scripts/cilium_migration.sh
   ```

   The migration process should now proceed successfully.
