# TAPMS (Tenant and Partition Management System) Overview

`tapms` is the primary Kubernetes Operator through which tenant creation and management is handled.
This operator interacts with several other services in the CSM software stack to provision the necessary components for a given tenant.
This document will give an overview of its functionality.

## Table of Contents

* [Tenant Schema](#tenant-schema)
* [Reconcile Operations](#reconcile-operations)
* [Tenant States](#tenant-states)

## Tenant Schema

See the [Tenant Custom Resource Definition](https://github.com/Cray-HPE/cray-tapms-operator/blob/main/config/crd/bases/tapms.hpe.com_tenants.yaml) for the full schema. Below is a description of the required fields for a tenant:

* `tenantname`: Name of the tenant.  See [Tenant Naming Requirements](CrayHncManager.md#tenant-naming-requirements) for restrictions on tenant naming.
* `childnamespaces`: List of namespaces that should be created for the tenant. These namespaces be created with the name specified here, prepended with the required HNC prefix.
* `tenantresources`:
  * `type`: Only `compute` is supported in the initial release of `tapms`.
  * `hsmgrouplabel`: The name of the HSM group label for the `xnames` specified below (mutually exclusive from `hsmpartitionname`).
  * `hsmpartitionname`: The name of the HSM partition to create and assignments for the `xnames` specified below  (mutually exclusive from `hsmgrouplabel`).
  * `enforceexclusivehsmgroups`: If `true`, tenants that share this setting will not be allowed to specify the same `xname` (only appropriate if `hsmgrouplabel` is also specified).
  * `xnames`: List of compute `xnames` that this tenant is allowed to use for running jobs.

## Reconcile Operations

When a tenant CR is applied, `tapms` will:

1) Create a tenant and Kubernetes namespace with the specified `name`.
Note that when `hnc` is deployed, it will be configured with a required prefix for tenant names ensuring that namespaces not associated with multi-tenancy are not managed by `hnc`.
The default prefix is `vcluster`, and this can be changed during the deployment of the `cray-hnc-manager` Helm chart.
1) Create namespaces specified in the `childnamespaces` with the tenant-specific prefix.
1) Add the specified `xnames` to an HSM group or partition.
1) Apply the valued specified in `hsmgrouplabel`
1) If the `enforceexclusivehsmgroups` flag is `true`, `tapms` will ensure `xnames` cannot be specified in multiple tenants (that also have the flag set to `true` for their `hsmgrouplabel`).
1) Create a Keycloak group with the name *&lt;tenant-name&gt;-tenant-admin* which can be assigned to users intended to be tenant administrators.

## Tenant States

`tapms` will report one of the following states for a tenant, depending on the current state of the tenant:

* `New`: `tapms` has begun reconciliation for a newly created tenant.
* `Deploying`: `tapms` is in the process of deploying the tenant.
* `Deployed`: The tenant reconciliation is complete (from the perspective of `tapms`).
* `Deleting`: `tapms` has begun deleting the tenant.
