# TAPMS (Tenant and Partition Management System) Overview

- [TAPMS (Tenant and Partition Management System) Overview](#tapms-tenant-and-partition-management-system-overview)
  - [Overview](#overview)
  - [Tenant schema](#tenant-schema)
  - [Reconcile operations](#reconcile-operations)
  - [Tenant states](#tenant-states)

## Overview

`tapms` is the primary Kubernetes operator through which tenant creation and management is handled. This operator
interacts with several other services in the CSM software stack to provision the necessary components for a given
tenant. This document gives an overview of its functionality.

## Tenant schema

See
the [Tenant Custom Resource Definition](https://github.com/Cray-HPE/cray-tapms-operator/blob/main/config/crd/bases/tapms.hpe.com_tenants.yaml)
for the full schema. Below is a description of the required fields for a tenant:

| Field                                         | Description                                                                                                                                                                         |
|-----------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `tenantname`                                  | Name of the tenant. See [Tenant naming requirements](CrayHncManager.md#tenant-naming-requirements) for restrictions on tenant naming.                                               |
| `childnamespaces`                             | List of namespaces that should be created for the tenant. These namespaces be created with the name specified here, prepended with the required HNC prefix.                         |
| `tenantresources`.`type`                      | Only `compute` and `application` are supported in the current release of `tapms`.                                                                                                   |
| `tenantresources`.`hsmgrouplabel`             | The name of the HSM group label for the `xnames` specified below (mutually exclusive from `hsmpartitionname`).                                                                      |
| `tenantresources`.`hsmpartitionname`          | The name of the HSM partition to create and assignments for the `xnames` specified below  (mutually exclusive from `hsmgrouplabel`).                                                |
| `tenantresources`.`enforceexclusivehsmgroups` | If `true`, tenants that share this setting will not be allowed to specify the same `xname` (only appropriate if `hsmgrouplabel` is also specified).                                 |
| `tenantresources`.`xnames`                    | List of compute or application component names (xnames) that this tenant is allowed to use for running jobs.                                                                        |
| `tenantresources`.`forcepoweroff`             | If `true`, when the xname is powered off, the `force-off` option is passed to PCS (Power Control Service) and subsequently the Redfish endpoint, instead of a graceful shutdown.    |
| `tenantkms`.`enablekms`                       | Create a Vault transit engine for the tenant if this setting is `true`. By default, this is `false`. If enabled, the transit name and other details will be shown in the CR status. |
| `tenantkms`.`keyname`                         | Optional name for the transit engine key. If not provided, a default will be used and shown in the CR status. This is only used when `enablekms` is `true`.                         |
| `tenantkms`.`keytype`                         | Optional transit engine key type. If not provided, a default will be used and shown in the CR status. This is only used when `enablekms` is `true`.                                 |

## Reconcile operations

When a tenant CR is applied, `tapms` will:

1. Create a tenant and Kubernetes namespace with the specified `name`. Note that when `hnc` is deployed, it will be
   configured with a required prefix for tenant names ensuring that namespaces not associated with multi-tenancy are not
   managed by `hnc`. The default prefix is `vcluster`, and this can be changed during the deployment of
   the `cray-hnc-manager` Helm chart.
1. Create namespaces specified in the `childnamespaces` with the tenant-specific prefix.
1. Add the specified `xnames` to an HSM group or partition.
1. Apply the valued specified in `hsmgrouplabel`
1. If the `enforceexclusivehsmgroups` flag is `true`, `tapms` will ensure `xnames` cannot be specified in multiple
   tenants (that also have the flag set to `true` for their `hsmgrouplabel`).
1. Create a Keycloak group with the name `<tenant-name>-tenant-admin` which can be assigned to users intended to be
   tenant administrators.
1. If the `tenantkms`.`enablekms` flag is `true`, `tapms` will create a Vault transit engine with the
   name `cray-tenant-<tenant-uuid>`. See the tenant schema description above (and the CRD) for more details. The created
   transit engine details will be available in the Tenant CR under the `status`.`tenantkms` section.
1. Power off the xname(s) that are members of the tenant.

## Tenant states

`tapms` will report one of the following states for a tenant, depending on the current state of the tenant:

| State       | Description                                                              |
|-------------|--------------------------------------------------------------------------|
| `New`       | `tapms` has begun reconciliation for a newly created tenant.             |
| `Deploying` | `tapms` is in the process of deploying the tenant.                       |
| `Deployed`  | The tenant reconciliation is complete (from the perspective of `tapms`). |
| `Deleting`  | `tapms` has begun deleting the tenant.                                   |
