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

In the following procedure, unless otherwise directed, run commands on any management NCN with a working `kubectl` context.

### Identify the RBAC issue

1. (`ncn-mw#`) Confirm the encryption status pattern.

   ```bash
   /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --status
   ```

2. (`ncn-mw#`) Check recent controller logs.

   ```bash
   kubectl logs -n kube-system -l app=cray-k8s-encryption --tail=200
   ```

3. (`ncn-mw#`) Verify effective permissions for the service account.

   ```bash
   kubectl auth can-i --as=system:serviceaccount:kube-system:cray-k8s-encryption list customresourcedefinitions.apiextensions.k8s.io
   kubectl auth can-i --as=system:serviceaccount:kube-system:cray-k8s-encryption get customresourcedefinitions.apiextensions.k8s.io
   ```

   Expected result for this issue: one or both commands return `no`.

4. (`ncn-mw#`) Inspect existing role and binding.

   ```bash
   kubectl get clusterrole cray-k8s-encryption -o yaml
   kubectl get clusterrolebinding cray-k8s-encryption -o yaml
   ```

   Confirm whether this rule is missing from `ClusterRole`:

   ```yaml
   - apiGroups: ["apiextensions.k8s.io"]
     resources: ["customresourcedefinitions"]
     verbs: ["get", "list"]
   ```

### Apply the permanent fix

1. (`ncn-mw#`) Update the `cray-k8s-encryption` `ClusterRole` with required RBAC rules.

   ```bash
   kubectl apply -f - <<'EOF'
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: cray-k8s-encryption
   rules:
   - apiGroups: [""]
     resources: ["nodes", "secrets"]
     verbs: ["get", "list", "create", "delete", "patch", "update"]
   - apiGroups: ["apps"]
     resources: ["daemonsets"]
     verbs: ["get", "list", "create", "delete", "patch", "update"]
   - apiGroups: ["apiextensions.k8s.io"]
     resources: ["customresourcedefinitions"]
     verbs: ["get", "list"]
   EOF
   ```

2. (`ncn-mw#`) Restart the DaemonSet and wait for rollout.

   ```bash
   kubectl rollout restart daemonset/cray-k8s-encryption -n kube-system
   kubectl rollout status daemonset/cray-k8s-encryption -n kube-system
   ```

### Optional workaround to unblock upgrade

Use this workaround only if all control-plane nodes, `goal`, and `etcd` are already `identity`.

1. (`ncn-mw#`) Set the `current` annotation manually.

   ```bash
   kubectl annotate secret --overwrite -n kube-system cray-k8s-encryption current=identity
   ```

2. (`ncn-mw#`) Re-run status.

   ```bash
   /usr/share/doc/csm/scripts/operations/kubernetes/encryption.sh --status
   ```

> This workaround may unblock the process but does not replace the RBAC fix.

### Validate the fix

1. (`ncn-mw#`) Confirm authorization checks now pass.

   ```bash
   kubectl auth can-i --as=system:serviceaccount:kube-system:cray-k8s-encryption list customresourcedefinitions.apiextensions.k8s.io
   kubectl auth can-i --as=system:serviceaccount:kube-system:cray-k8s-encryption get customresourcedefinitions.apiextensions.k8s.io
   ```

2. (`ncn-mw#`) Confirm logs do not show CRD permission failures.

    ```bash
    kubectl logs -n kube-system -l app=cray-k8s-encryption --tail=200
    ```

3. (`ncn-mw#`) Confirm final status convergence.

    ```text
    current: identity
    goal: identity
    etcd: identity
    ```
