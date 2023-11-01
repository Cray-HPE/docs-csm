# Multi-Tenancy Support

- [Disclaimer](#disclaimer)
- [Components](#components)
  - [Hierarchical Namespace Controller (HNC)](#hierarchical-namespace-controller-hnc)
  - [Tenant and Partition Management System (TAPMS)](#tenant-and-partition-management-system-tapms)
  - [Slurm operator](#slurm-operator)
  - [Vault integration](#vault-integration)
- [Getting started](#getting-started)
  - [Create a tenant](#create-a-tenant)
  - [Modify a tenant](#modify-a-tenant)
  - [Remove a tenant](#remove-a-tenant)
  - [Tenant administrator configuration](#tenant-administrator-configuration)

## Disclaimer

**`IMPORTANT`** This feature is in alpha, collectively denoted by the API versioning strategy associated with TAPMS and other operators represented herein.
Users should expect breaking changes in the API across CSM releases as the feature set gains operational exposure and enhancements are introduced, ultimately leading to more stable API version series (for example, beta, and then stable).
While we do not anticipate that users will experience issues with pre-stable APIs, additional care should be taken to validate desired functionality in test environments prior to use in production.

**`IMPORTANT`** This feature is intended for _soft_ multi-tenancy use cases at this time.
_Soft_ multi-tenancy is defined as tenants that are hospitable, analogous to business units (as opposed to different companies), and the tenants are not considered to have malicious intent.

## Components

### Hierarchical Namespace Controller (HNC)

See [Cray HNC Manager](CrayHncManager.md) for specifics of how to configure the HNC for CSM deployments.

### Tenant and Partition Management System (TAPMS)

`tapms` is the primary Kubernetes Operator for the multi-tenancy solution. Creating and modifying a tenant is accomplished by creating a `Tenant` custom resource, which is managed and reconciled by `tapms`.
See [TAPMS Overview](Tapms.md) for details on this Kubernetes Operator.

### Slurm operator

The Slurm operator can be used to deploy the Slurm workload manager within a
tenant. See [Slurm Operator](SlurmOperator.md) for details.

### Vault integration

The `tapms` operator can create a Cray Vault transit engine for the tenant. Creating a transit engine is accomplished by enabling the feature in the `Tenant` custom resource, which is managed and reconciled by `tapms`.
See the [Vault Overview](Vault.md) for details.

## Getting started

Below are common activities performed by an infrastructure administrator for managing a tenant's lifecycle.

### Create a tenant

See [Create a Tenant](Create_a_Tenant.md) for how to create a tenant using the `Tenant` custom resource definition (CRD) which is managed by the `tapms`.

### Modify a tenant

See [Modify a Tenant](Modify_a_Tenant.md) for how to modify a tenant after initial creation. Tenants can be modified to add/remove `xnames` from the tenant, as well as additions/deletions to the `childNamespaces` list.

### Remove a tenant

See [Remove a Tenant](Remove_a_Tenant.md) for how to remove a tenant when it is no longer needed.

### Tenant administrator configuration

For information on how to configure a user to perform tenant administration functions, see [Tenant Administrator Configuration](TenantAdminConfig.md).
Users configured as `Tenant Administrators` can modify `xname` assignments (and other changes to the `tapms` custom resource) for one or more tenants.
