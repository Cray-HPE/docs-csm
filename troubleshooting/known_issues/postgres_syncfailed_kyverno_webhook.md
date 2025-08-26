# PostgreSQL Clusters in `SyncFailed` State Due to Kyverno Webhook

## Description

Sometimes after PostgreSQL clusters upgrade from version 11 to 14 (CSM 1.4 to CSM 1.5),
clusters fall into a `SyncFailed` state due to admission webhook conflicts with Kyverno policies.
The issue occurs when the Kyverno mutating webhook `mutate.kyverno.svc-fail` denies requests
during PostgreSQL pod updates, preventing the clusters from maintaining their healthy state.

## Symptoms

PostgreSQL clusters display `SyncFailed` state instead of `Running` after upgrade completion.

Command:

```bash
kubectl get postgresql -A
```

Example output:

```text
NAMESPACE   NAME                         TEAM                VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE   STATUS
argo        cray-nls-postgres            cray-nls            14        3      2Gi                                     12h   Running
services    cfs-ara-postgres             cfs-ara             14        3      50Gi     100m          100Mi            12h   SyncFailed
services    cray-console-data-postgres   cray-console-data   14        3      2Gi      100m          256Mi            12h   SyncFailed
services    cray-dns-powerdns-postgres   cray-dns-powerdns   14        3      10Gi     100m          100Mi            12h   SyncFailed
services    cray-sls-postgres            cray-sls            14        3      1Gi      100m          128Mi            12h   SyncFailed
services    cray-smd-postgres            cray-smd            14        3      100Gi    1             100Mi            12h   SyncFailed
services    gitea-vcs-postgres           gitea-vcs           14        3      50Gi     100m          256Mi            12h   SyncFailed
services    keycloak-postgres            keycloak            14        3      10Gi                                    12h   SyncFailed
spire       cray-spire-postgres          cray-spire          14        3      60Gi     1             1Gi              9h    SyncFailed
spire       spire-postgres               spire               14        3      60Gi     1             4Gi              12h   SyncFailed
```

In addition, Postgres pod logs show errors related to Kyverno admission webhook failures.

Command:

```bash
kubectl -n spire logs -f spire-postgres-0 -c postgres
```

Example output:

```text
HTTP response body: b'{"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure","message":"admission webhook \\"mutate.kyverno.svc-fail\\" denied the request: mutation policy pod-sec-ctxt-spire error: failed to validate resource mutated by policy pod-sec-ctxt-spire: ValidationError(io.k8s.api.core.v1.Pod.metadata.managedFields[1]): unknown field \\"subresource\\" in io.k8s.apimachinery.pkg.apis.meta.v1.ManagedFieldsEntry\\n\\nValidationError(io.k8s.api.core.v1.Pod.metadata.managedFields[2]): unknown field \\"subresource\\" in io.k8s.apimachinery.pkg.apis.meta.v1.ManagedFieldsEntry","code":400}\n'
```

## Solution

The issue can be resolved by temporarily removing Kyverno webhook configurations and restarting
the Kyverno deployment to reset the webhook state.

1. (`ncn-mw#`) Remove the Kyverno webhook configurations.

   Commands:

   ```bash
   kubectl delete validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg
   kubectl delete mutatingwebhookconfiguration kyverno-resource-mutating-webhook-cfg
   ```

1. (`ncn-mw#`) Scale down the Kyverno deployment.

   Command:

   ```bash
   kubectl scale deploy cray-kyverno -n kyverno --replicas 0
   ```

1. (`ncn-mw#`) Scale up the Kyverno deployment.

   Command:

   ```bash
   kubectl scale deploy cray-kyverno -n kyverno --replicas 3
   ```

1. (`ncn-mw#`) Wait approximately 5 minutes and verify that PostgreSQL clusters return to
   `Running` state.

   Command:

   ```bash
   kubectl get postgresql -A
   ```

   Example output:

   ```text
   NAMESPACE   NAME                         TEAM                VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE   STATUS
   argo        cray-nls-postgres            cray-nls            14        3      2Gi                                     12h   Running
   services    cfs-ara-postgres             cfs-ara             14        3      50Gi     100m          100Mi            12h   Running
   services    cray-console-data-postgres   cray-console-data   14        3      2Gi      100m          256Mi            12h   Running
   services    cray-dns-powerdns-postgres   cray-dns-powerdns   14        3      10Gi     100m          100Mi            12h   Running
   services    cray-sls-postgres            cray-sls            14        3      1Gi      100m          128Mi            12h   Running
   services    cray-smd-postgres            cray-smd            14        3      100Gi    1             100Mi            12h   Running
   services    gitea-vcs-postgres           gitea-vcs           14        3      50Gi     100m          256Mi            12h   Running
   services    keycloak-postgres            keycloak            14        3      10Gi                                    12h   Running
   spire       cray-spire-postgres          cray-spire          14        3      60Gi     1             1Gi              9h    Running
   spire       spire-postgres               spire               14        3      60Gi     1             4Gi              12h   Running
   ```

This workaround is based on the [Kyverno troubleshooting guide](https://kyverno.io/docs/troubleshooting/)
and will be resolved in a future CSM release.
