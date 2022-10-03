# Multi-Tenancy Support

This page will provide an overview of the multi-tenancy feature.

## Table of Contents

- [Disclaimer](#disclaimer)
- [Components](#components)
  - [Hierarchical Namespace Controller (HNC)](#hierarchical-namespace-controller-hnc)
  - [Tenant and Partition Management System (TAPMS)](#tenant-and-partition-management-system-tapms)
  - [Slurm Operator](#slurm-operator)
- [Getting Started](#getting-started)
  - [Create a Tenant](#create-a-tenant)
  - [Modify a Tenant](#modify-a-tenant)
  - [Remove a Tenant](#remove-a-tenant)
  - [Tenant Administrator Configuration](#tenant-administrator-configuration)

## Disclaimer

**`IMPORTANT`** Beginning in the CSM 1.3 release, this feature is offered as a preview only, and is not considered production-ready.
This first release should be considered _soft_ multi-tenancy, with additional functionality which hardens this feature in subsequent releases.
_Soft_ multi-tenancy is defined as tenants that are hospitable, analogous to business units (as opposed to different companies), and the tenants are not considered to have malicious intent.

## Components

### Hierarchical Namespace Controller (HNC)

See [Cray HNC Manager](CrayHncManager.md) for specifics of how to configure the HNC for CSM deployments.

### Tenant and Partition Management System (TAPMS)

`tapms` is the primary Kubernetes Operator for the multi-tenancy solution. Creating and modifying a tenant is accomplished by creating a `Tenant` custom resource, which is managed and reconciled by `tapms`.
See [`TAPMS` Overview](Tapms.md) for details on this Kubernetes Operator.

### Slurm Operator

The Slurm operator can be used to deploy the Slurm workload manager within a
tenant. See [Slurm Operator](SlurmOperator.md) for details.

## Getting Started

Below are common activities performed by an infrastructure administrator for managing a tenant's lifecycle.

### Create a Tenant

Follow instructions at [Create a Tenant](Create_a_Tenant.md) for how to create a tenant using the `Tenant` custom resource definition (CRD) which is managed by the `tapms`.

### Modify a Tenant

Follow instructions at [Modify a Tenant](Modify_a_Tenant.md) for how to modify a tenant after initial creation.  Tenants can be modified to add/remove `xnames` from the tenant, as well as additions/deletions to the `childNamespaces` list.

### Remove a Tenant

Follow instructions at [Remove a Tenant](Remove_a_Tenant.md) for how to remove a tenant when it is no longer needed.

### Tenant Administrator Configuration

For information on how to configure a user to perform tenant administration functions, see [Tenant Administrator Configuration](TenantAdminConfig.md).
Users configured as `Tenant Administrators` can modify `xname` assignments (and other changes to the `tapms` custom resource) for one or more tenants.
