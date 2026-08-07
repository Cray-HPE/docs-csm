# Troubleshoot Kubernetes Encryption Status Stuck at `current: unknown`

Use this procedure to diagnose and resolve a Kubernetes encryption status mismatch where `current` remains `unknown`.

## Symptoms

One or more of the following issues are possible symptoms:

- `/usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --status` reports:

```text
current: unknown
goal: identity
etcd: identity
interim state detected, ensure all control plane nodes are in sync
```

- `cray-k8s-encryption` logs show RBAC failure when rewriting secrets:

```text
failed to list CRDs: customresourcedefinitions.apiextensions.k8s.io is forbidden
User "system:serviceaccount:kube-system:cray-k8s-encryption" cannot list resource "customresourcedefinitions"
```

- Upgrade workflow is blocked by encryption status checks.

## Procedure

In the following procedure, run commands on any management NCN with a working `kubectl` context.

### Fix encryption status

Use this workaround only if all control-plane nodes, `goal`, and `etcd` are already `identity`.

1. (`ncn-mw#`) Set the `current` annotation manually.

   ```bash
   kubectl annotate secret --overwrite -n kube-system cray-k8s-encryption current=identity
   ```

2. (`ncn-mw#`) Re-run status.

   ```bash
   /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --status
   ```

### Validate the fix

1. (`ncn-mw#`) Confirm final status convergence.

    ```text
    current: identity
    goal: identity
    etcd: identity
    ```
