# TAPMS (Tenant and Partition Management System)

- [Overview](#overview)
- [Tenant schema](#tenant-schema)
- [Reconcile operations](#reconcile-operations)
- [Tenant states](#tenant-states)

## Overview

TAPMS is the primary Kubernetes operator through which tenant creation and management is handled. This operator
interacts with several other services in the CSM software stack to provision the necessary components for a given
tenant. This document gives an overview of its functionality.

## Tenant schema

See the
[Tenant Custom Resource Definition](https://github.com/Cray-HPE/cray-tapms-operator/blob/main/config/crd/bases/tapms.hpe.com_tenants.yaml)
for the full schema. Below is a description of the required fields for a tenant:

| Field                                         | Description                                                                                                                                                 |
|-----------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `tenantname`                                  | Name of the tenant. See [Tenant naming requirements](CrayHncManager.md#tenant-naming-requirements) for restrictions on tenant naming.                       |
| `childnamespaces`                             | List of namespaces that should be created for the tenant. These namespaces be created with the name specified here, prepended with the required HNC prefix. |
| `tenantresources`.`type`                      | Only `compute` is supported in the initial release of TAPMS.                                                                                                |
| `tenantresources`.`hsmgrouplabel`             | The name of the HSM group label for the xnames specified below (mutually exclusive from `hsmpartitionname`).                                                |
| `tenantresources`.`hsmpartitionname`          | The name of the HSM partition to create and assignments for the xnames specified below  (mutually exclusive from `hsmgrouplabel`).                          |
| `tenantresources`.`enforceexclusivehsmgroups` | If `true`, tenants that share this setting will not be allowed to specify the same xname (only appropriate if `hsmgrouplabel` is also specified).           |
| `tenantresources`.`xnames`                    | List of compute component names (xnames) that this tenant is allowed to use for running jobs.                                                               |

## Reconcile operations

When a tenant CR is applied, TAPMS will:

1. Create a tenant and Kubernetes namespace with the specified name. Note that when HNC is deployed, it will be
   configured with a required prefix for tenant names ensuring that namespaces not associated with multi-tenancy are not
   managed by HNC. The default prefix is `vcluster`, and this can be changed during the deployment of
   the `cray-hnc-manager` Helm chart.
1. Create namespaces specified in the `childnamespaces` with the tenant-specific prefix.
1. Add the specified xnames to an [HSM group or partition](../hardware_state_manager/Component_Groups_and_Partitions.md).
1. Apply the valued specified in `hsmgrouplabel`
1. If the `enforceexclusivehsmgroups` flag is `true`, TAPMS will ensure xnames cannot be specified in multiple
   tenants (that also have the flag set to `true` for their `hsmgrouplabel`).
1. Create a Keycloak group with the name `<tenant-name>-tenant-admin` which can be assigned to users intended to be
   tenant administrators.

## Tenant states

TAPMS will report one of the following states for a tenant, depending on the current state of the tenant:

| State       | Description                                                              |
|-------------|--------------------------------------------------------------------------|
| `New`       | TAPMS has begun reconciliation for a newly created tenant.               |
| `Deploying` | TAPMS is in the process of deploying the tenant.                         |
| `Deployed`  | The tenant reconciliation is complete (from the perspective of TAPMS).   |
| `Deleting`  | TAPMS has begun deleting the tenant.                                     |
