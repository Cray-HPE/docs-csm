# Creating a Tenant

This page provides information about how to create a tenant.  This procedure involves creating a custom resource for both `tapms` as well as the `slurm operator`.

## Table of contents

- [TAPMS CRD](#tapms-crd)
- [Apply the TAPMS CR](#apply-the-tapms-cr)
- [`slurm` operator CRD](#slurm-operator-crd)
- [Apply the `slurm` operator CR](#apply-the-slurm-operator-cr)

## TAPMS CRD

Tenant provisioning is handled in a declarative fashion, by creating a CR with the specification for the tenant.
The full schema is available by executing the following command on either a master or worker node:

- (`ncn-mw#`)

    ```bash
    kubectl get customresourcedefinitions.apiextensions.k8s.io tenants.tapms.hpe.com  -o yaml
    ```

Below is an example of a tenant custom resource (CR):

- (`ncn-mw#`)

    ```bash
    cat tenant.yaml
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
    ```

## Apply the TAPMS CR

Once the CR has been crafted for the tenant, the following command will begin the provisioning of the tenant (note that all tenants should be applied in the `tenants` namespace):

- (`ncn-mw#`)

    ```bash
    kubectl apply -n tenants -f <tenant.yaml>
    tenant.tapms.hpe.com/vcluster-blue created
    ```

It can take up to a minute for `tapms` to fully create the tenant.  The following command can be used to monitor the status of the tenant:

- (`ncn-mw#`)

    ```bash
    kubectl get tenant -n tenants vcluster-blue -o yaml
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
      uuid: 074b6db1-f504-4e9c-8245-259e9b22d2e6
    ```

The `cray` command can now be used to display the HSM group:

- (`ncn-mw#`)

    ```bash
    cray hsm groups describe blue
    label = "blue"
    description = ""
    exclusiveGroup = "tapms-exclusive-group-label"
    tags = [ "vcluster-blue",]

    [members]
    ids = [ "x0c3s5b0n0", "x0c3s6b0n0",]
    ```

The following command can now be used to display the namespace tree structure for the tenant:

- (`ncn-mw#`)

    ```bash
    kubectl hns tree tenants
    tenants
    └── [s] vcluster-blue
        ├── [s] vcluster-blue-slurm
        └── [s] vcluster-blue-user
    ```

## `slurm` operator CRD

_placeholder for `slurm` content_

## Apply the `slurm` operator CR

_placeholder for `slurm` content_
