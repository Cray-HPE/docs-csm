# `cray-vault-operator` chart upgrade error

## Description

On a system that was originally installed with CSM 1.3, when upgrading to CSM 1.7,
during the IUF [Management Nodes Rollout](../../operations/iuf/workflows/management_rollout.md) the
`cray-vault-operator` chart may fail to upgrade due to an invalid value of `true` for the field
`spec.preserveUnknownFields` in the `vaults.vault.banzaicloud.com` CRD.

The `spec.preserveUnknownFields` field in the `vaults.vault.banzaicloud.com` CRD was deprecated
in the `apiextenstions.k8s.io/v1beta1` API version and disallowed when creating CRD objects with
`apiextensions.k8s.io/v1`.

## Symptoms

During CSM services upgrade as part of the IUF Management Nodes Rollout, the `helm upgrade` of the
`cray-vault-operator` chart will fail with a message like the following:

```console
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Releasing cray-vault-operator v1.5.2
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

2025-12-01T23:38:17Z INF Running helm install/upgrade with arguments: upgrade --install cray-vault-operator helm/cray-vault-operator-1.5.2.tgz --namespace vault --create-namespace --set global.chart.name=cray-vault-operator --set global.chart.version=1.5.2 chart=cray-vault-operator command=ship namespace=vault version=1.5.2
2025-12-01T23:43:21Z ERR Error releasing chart cray-vault-operator v1.5.2: Shell error: Error: UPGRADE FAILED: pre-upgrade hooks failed: 1 error occurred:
        * timed out waiting for the condition chart=cray-vault-operator command=ship namespace=vault version=1.5.2 
```

The `cray-vault-operator-pre-upgrade-crd-upgrade-crd-hook` pods in `vault` namespace will be in Error status:

```console
ncn-m001:~ # kubectl get pods -n vault
NAME                                             READY   STATUS      RESTARTS   AGE
cray-vault-0                                     5/5     Running     0          6d6h
cray-vault-1                                     5/5     Running     0          6d6h
cray-vault-2                                     5/5     Running     0          6d6h
cray-vault-configurer-bdd54b45-vj2th             2/2     Running     0          6d6h
cray-vault-operator-844dc748b4-qd7tv             2/2     Running     0          6d6h
cray-vault-operator-pre-upgrade-crd-hook-6trs8   0/1     Error       0          6h28m
cray-vault-operator-pre-upgrade-crd-hook-c6qxp   0/1     Error       0          6h28m
cray-vault-operator-pre-upgrade-crd-hook-hssmr   0/1     Error       0          6h27m
cray-vault-operator-pre-upgrade-crd-hook-k6zq8   0/1     Error       0          6h27m
cray-vault-operator-pre-upgrade-crd-hook-lsrqd   0/1     Error       0          6h28m
cray-vault-operator-pre-upgrade-crd-hook-t46r5   0/1     Error       0          6h25m
cray-vault-operator-pre-upgrade-crd-hook-twdt5   0/1     Error       0          6h22m
```

The logs of the `cray-vault-operator-pre-upgrade-crd-hook` pods will contain this message:

```console
ncn-m001:~ # kubectl logs -n vault cray-vault-operator-pre-upgrade-crd-hook-6trs8
The CustomResourceDefinition "vaults.vault.banzaicloud.com" is invalid: spec.preserveUnknownFields: Invalid value: true: must be false in order to use defaults in the schema 
```

## Solution

Because the `apiextenstion.k8s.io/v1` CRD API in the new chart doesn't know what to do with the
`spec.preserveUnknownFields` field in the CRD on the system, delete the CRD on the system and re-run
the IUF Management Nodes Rollout.

1. (`ncn-m#`) Delete the `vaults.vault.banzaicloud.com` CRD

   ```bash
   kubectl delete crd vaults.vault.banzaicloud.com
   ```

   Example Output:

   ```console
   ncn-m001:~ # kubectl delete crd vaults.vault.banzaicloud.com
   customresourcedefinition.apiextensions.k8s.io "vaults.vault.banzaicloud.com" deleted
   ```

1. (`ncn-m001`) Re-run the IUF [Management Nodes Rollout](../../operations/iuf/workflows/management_rollout.md)

   When the `cray-vault-operator` is deployed as part of the `management-nodes-rollout-prehook`, it should succeed.
