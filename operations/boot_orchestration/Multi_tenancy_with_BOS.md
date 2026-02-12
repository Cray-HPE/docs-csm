# Multi-tenancy with BOS

* [Overview](#overview)
* [Roles](#roles)
    * [System administrators](#system-administrators)
    * [Tenant administrators](#tenant-administrators)
* [Components](#components)
* [Sessions and session templates](#sessions-and-session-templates)
    * [Session templates with tenancy](#session-templates-with-tenancy)
        * [Tenant-owned session templates](#tenant-owned-session-templates)
        * [Session templates not owned by tenants](#session-templates-not-owned-by-tenants)
    * [Sessions with tenancy](#sessions-with-tenancy)
    * [Staged sessions with tenancy](#staged-sessions-with-tenancy)
* [BOS API access with tenancy](#bos-api-access-with-tenancy)

## Overview

BOS supports multi-tenancy, allowing multiple tenants to coexist on a system with access to only their own separate
resources. For more information on multi-tenancy see the [Multi-Tenancy Overview](../multi-tenancy/Overview.md).
For systems without tenants, this functionality can be ignored.

## Roles

### System administrators

The overall administrator of a CSM system is referred to as the system administrator; that role is also
sometimes referred to as the infrastructure administrator or global administrator.

Systems administrators have complete access to the [BOS API](../../api/bos.md), and can view and edit all resources for all
tenants, as well as resources that are not assigned to a tenant. However, some endpoints require the administrator to masquerade
as a tenant in order to update resources. This can mean passing the tenant ID in the query header, or authenticating to the CLI as a
specific tenant. See [Tenant Admin Configuration](../multi-tenancy/TenantAdminConfig.md) for information on authenticating to the CLI
as a specific tenant. While masquerading as a tenant, the system administrator will only have the ability to view and update
resources specific to that tenant.

### Tenant administrators

A tenant administrator is a role that is only able to manage resources belong to a specific tenant.

[Tenant administrators](../multi-tenancy/TenantAdminConfig.md) should be able to view their
[components](Components.md), [session templates](Session_Templates.md), and [sessions](Sessions.md) normally.
Tenant administrators are not be able to view the resources of another tenant.
Tenant administrators have restricted or no access to some BOS endpoints, such as the components endpoint
(which can be viewed but not patched), and the options endpoint (which is blocked entirely).

## Components

Component ownership is not directly tracked by BOS to avoid duplicating information stored in the
[Tenant and Partition Management System (TAPMS)](../../glossary.md#tenant-and-partition-management-system-tapms)
and the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm).
As a result the system administrator will not see any tenant information in the component records, and the components endpoint
will function normally for system administrators. To determine which components belong to which tenant, the administrator will
need to query TAPMS. For information on how to perform this query, see
[Tenant command examples](../multi-tenancy/ExampleWorkflow.md#tenant-command-examples).

## Sessions and session templates

Both session and session template records contain information on the tenant that owns them (if any).

### Tenant name-spacing

System administrators can list all sessions and session templates across all tenants.
However, system administrators will not be able to create, retrieve, update, or delete specific sessions or session templates
that belong to a tenant without masquerading as that specific tenant. This is because these BOS resources are name-spaced to
avoid naming collisions between tenants. The name-spacing means that there can be two or more records with the same name, and
BOS does not know which resource is requested unless the tenant is specified. To access tenant owned BOS resources, the system
administrator will need to masquerade as that tenant.

> This is in contrast to how the [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
> implements multi-tenancy. For more information, see
> [CFS API access with tenancy](../configuration_management/Managing_Sensitive_Tenant_Information_in_VCS_with_SOPS.md#cfs-api-access-with-tenancy).

### Session templates with tenancy

#### Tenant-owned session templates

Compared to session templates that are not owned by a tenant, session templates owned by tenants have only one
extra restriction on their content. Specifically, a session template owned by a tenant should not directly specify
any [components](#components) that are not assigned to them in TAPMS. That is, if the
[`node_list`](Session_Templates.md#node-list) field is used, it should only include components that are assigned to
the tenant in TAPMS. If this restriction is not followed, then while BOS will allow the template to be created,
sessions using that template will fail when the
[`session-setup` operator](Operators.md#session-setup) runs. This will happen even if a
[session limit](Limit_the_Scope_of_a_BOS_Session.md) is specified that restricts the
session to components owned by the tenant.

A session template owned by a tenant is permitted to *indirectly* include components that are not
assigned to the tenant in TAPMS. This can be done using the
[`node_groups`](Session_Templates.md#node-groups) or
[`node_roles_groups`](Session_Templates.md#node-roles-groups) fields.
For example, the `Compute` role could be specified in the `node_roles_groups` field of the boot set. However,
sessions created by a tenant will automatically exclude any components that are not assigned to that tenant in
TAPMS. For each [boot set](Session_Templates.md#boot-sets) in the session template, the set of target components
for a session will be the intersection of the set of components determined by the boot set and the set of components
assigned to the tenant in TAPMS (also intersected with the session limit, if applicable).

For example, consider the following session template:

```json
{
  "boot_sets": {
      "compute": {
        "arch": "X86",
        "etag": "316c0976fda0ea4c229c132f1ea00af3",
        "kernel_parameters": "ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN}",
        "node_roles_groups": [
          "Compute"
        ],
        "path": "s3://boot-images/6afda9c4-297f-4d35-b104-f20ed12c4d08/manifest.json",
        "rootfs_provider": "sbps",
        "rootfs_provider_passthrough": "sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.fanta.hpc.amslabs.hpecorp.net:300",
        "type": "s3"
      }
  },
  "cfs": {
    "configuration": "harf-compute-config"
  },
  "enable_cfs": true,
  "name": "harf-x86-computes",
  "tenant": "vcluster-harf"
}
```

This template is owned by the `vcluster-harf` tenant, and it targets all X86 compute nodes (as seen by the
[`node_roles_groups` field](Session_Templates.md#node-roles-groups)
in the boot set). However, when the `vcluster-harf` tenant creates a session using this template,
the session will be limited to the compute nodes which are assigned to `vcluster-harf` in TAPMS.

#### Session templates not owned by tenants

The restriction and behavior of [Tenant-owned session templates](#tenant-owned-session-templates) does not
apply to session templates that are not owned by a tenant

* A session template that is not owned by a tenant is free to include tenant-owned components in the `node_list` field.
  This will not cause failures in the `session-setup` operator.
* No filtering of components is done on the basis of tenancy for session templates that are not owned by a tenant.
  In other words, such session templates are not limited to components that do not belong to any tenant.

For example, consider the following session template:

```json
{
  "boot_sets": {
      "compute": {
        "arch": "X86",
        "etag": "316c0976fda0ea4c229c132f1ea00af3",
        "kernel_parameters": "ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN}",
        "node_roles_groups": [
          "Compute"
        ],
        "path": "s3://boot-images/6afda9c4-297f-4d35-b104-f20ed12c4d08/manifest.json",
        "rootfs_provider": "sbps",
        "rootfs_provider_passthrough": "sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.fanta.hpc.amslabs.hpecorp.net:300",
        "type": "s3"
      }
  },
  "cfs": {
    "configuration": "harf-compute-config"
  },
  "enable_cfs": true,
  "name": "harf-x86-computes",
  "tenant": ""
}
```

This template is not owned by a tenant, and it targets all X86 compute nodes. When the system administrator creates
a session using this tenant, it will include all X86 compute nodes, regardless of tenant ownership.

### Sessions with tenancy

BOS sessions that are created without any tenant identification can only use session templates that do not belong to a tenant.
BOS sessions that are created with tenant identification can only use session templates that belong to that same tenant.

Although BOS sessions use [Tenant name-spacing](#tenant-name-spacing), unexpected behavior is possible if multiple
running sessions have the same name. These problems are even more likely in the case when one of the sessions is not owned
by a tenant. It is strongly suggested that unique names are used for sessions. If no name is explicitly created at session
creation time, the name generated by BOS is practically guaranteed to not collide with another session.

### Staged sessions with tenancy

It is possible to [Stage Changes with BOS](Stage_Changes_with_BOS.md) with tenancy. This is subject to all of the restrictions
described in [Sessions with tenancy](#sessions-with-tenancy). In addition, the request to
[apply the staged state](Stage_Changes_with_BOS.md#apply-a-staged-state) must include the tenant identification.

## BOS API access with tenancy

For details on how to make BOS API or CLI calls on behalf of a tenant, see
[Interacting with services as a tenant](../multi-tenancy/TenantAdminConfig.md#interacting-with-services-as-a-tenant).

For details on which BOS API calls support being called on behalf of a tenant, see [BOS API](../../api/bos.md).
