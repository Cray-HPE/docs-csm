# Modifying a Tenant

This page provides information about how to modify a tenant. Modifications that are supported are limited to:

 - Updating the list of component names (xnames) assigned to this tenant.
 - Adding/deleting `childNamespaces`.

## Table of Contents

- [Modifying a tenant](#modifying-a-tenant)
  - [Table of Contents](#table-of-contents)
  - [Modify the existing TAPMS Custom Resource (CR)](#modify-the-existing-tapms-custom-resource-cr)
  - [Apply the modified TAPMS Custom Resource (CR)](#apply-the-modified-tapms-custom-resource-cr)
  - [Modify the Slurm Operator Custom Resource (CR)](#modify-the-slurm-operator-custom-resource-cr)
  - [Apply the Slurm Operator Custom Resource (CR)](#apply-the-slurm-operator-custom-resource-cr)

## Modify the existing TAPMS Custom Resource (CR)

- An example of a change to add an xname to a tenant:

    ```yaml
    apiVersion: tapms.hpe.com/v1alpha1
    kind: Tenant
    metadata:
      name: vcluster-blue
    spec:
      childnamespaces:
        - user
        - slurm
      tenantname: vcluster-blue
      tenantresources:
        - type: compute
          hsmgrouplabel: blue
          enforceexclusivehsmgroups: true
          xnames:
            - x0c3s5b0n0
            - x0c3s6b0n0
            - x0c3s7b0n0 <-- Adding this xname
    ```

## Apply the modified TAPMS Custom Resource (CR)

- (`ncn-mw#`) When a tenant CRD is applied, `tapms` will determine any changes to the tenant, and reconcile any changes to `childNamespaces` and `xnames`.

    ```bash
    kubectl apply -n tenants -f <tenant.yaml>
    ```

    Example output:

    ```text
    tenant.tapms.hpe.com/vcluster-blue configured
    ```

- (`ncn-mw#`) It can take up to a minute for `tapms` to reconcile the change. The following command can be used to monitor the status of the tenant:

    ```bash
    kubectl get tenant -n tenants vcluster-blue -o yaml
    ```

    Example output:

    ```yaml
    apiVersion: tapms.hpe.com/v1alpha1
    kind: Tenant
    metadata:
      annotations:
        kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"tapms.hpe.com/v1alpha1","kind":"Tenant","metadata":{"annotations":{},"name":"vcluster-blue","namespace":"tenants"},"spec":{"childnamespaces":["user","slurm"],"tenantname":"vcluster-blue","tenantresources":[{"enforceexclusivehsmgroups":true,"hsmgrouplabel":"blue","type":"compute","xnames":["x0c3s5b0n0","x0c3s6b0n0"]}]}}
      creationTimestamp: "2022-08-23T18:37:25Z"
      finalizers:
      - tapms.hpe.com/finalizer
      generation: 3
      name: vcluster-blue
      namespace: tenants
      resourceVersion: "3157072"
      uid: 074b6db1-f504-4e9c-8245-259e9b22d2e6
    spec:
      childnamespaces:
      - user
      - slurm
      state: Deployed
      tenantname: vcluster-blue
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: compute
        xnames:
        - x0c3s5b0n0
        - x0c3s6b0n0
        - x0c3s7b0n0
    status:
      childnamespaces:
      - vcluster-blue-user
      - vcluster-blue-slurm
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: compute
        xnames:
        - x0c3s5b0n0
        - x0c3s6b0n0
        - x0c3s7b0n0
      uuid: 074b6db1-f504-4e9c-8245-259e9b22d2e6
    ```

- (`ncn-mw#`) The `cray` command can now be used to display changes to the HSM group:

    ```bash
    cray hsm groups describe blue --format toml
    ```

    Example output:

    ```toml
    label = "blue"
    description = ""
    exclusiveGroup = "tapms-exclusive-group-label"
    tags = [ "vcluster-blue",]

    [members]
    ids = [ "x0c3s5b0n0", "x0c3s6b0n0", "x0c3s7b0n0"]
    ```

## Modify the Slurm Operator Custom Resource (CR)

_placeholder for `slurm` content_

## Apply the `slurm` operator CR

_placeholder for `slurm` content_
