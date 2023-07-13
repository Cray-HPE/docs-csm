# Multi-tenancy with BOS

BOS v2 supports multi-tenancy, allowing multiple tenants to coexist on a system with access to only their own separate
resources. For more information on multi-tenancy see the [Multi-Tenancy Overview](../multi-tenancy/Overview.md) For
systems without tenants, this functionality can be ignored.

This is a BOS v2 feature only. The BOS v1 API will return an error if any calls are made while authenticated to a
specific tenant.

## Tenant administrators

Tenant administrators should be able to view their components, session templates and sessions normally. They will not be able to
view the resources of another tenant, and will have restricted or no access to some BOS endpoints such the components
endpoint which can be viewed but not patched, and the options endpoint which is blocked entirely.

## System administrators

Systems administrators have complete access to the BOS API, and can view and edit all resources for all tenants, including
tenant-less resources. However, some endpoints require the administrator to masquerade as a tenant in order to update resource.
This can mean passing the tenant ID in the query header, or authenticating the CLI as a specific tenant.
See [Tenant Admin Configuration](../multi-tenancy/TenantAdminConfig.md) for information on authenticating the CLI as a
specific tenant. While masquerading as a tenant, the system administrator will only have the ability to view and update
resources specific to that tenant.

### Components

Component ownership is not directly tracked by BOS to avoid duplicating information stored in TAPMS and HSM. As a result
the system administrator will not see any tenant information in the component records and the components endpoint will function
normally for system administrators. To determine which components belong to which tenant, the administrator will need to query TAPMS.

## Sessions and session templates

Both session and session template records now contain information on the tenant that owns them. System administrators can list
all sessions and session templates across all tenants. However system administrators will not be able to create, retrieve,
update, or delete specific records that belong to a tenant without authenticating to that specific tenant. This is
because the resources are name-spaced to avoid naming collisions between tenants. The name-spacing means that there can
be two or more records with the same name, and BOS does not know which resource is requested unless the tenant is
specified. To access tenant owned resources, the system administrator will need to masquerade as that tenant.
