# Multi-tenancy with BOS

`BOS` v2 supports multi-tenancy, allowing multiple tenants to coexist on a system with access to only their own separate
resources. For more information on multi-tenancy see the [Multi-Tenancy Overview](../multi-tenancy/Overview.md) For
systems without tenants, this functionality can be ignored.

## Tenant administrators

Tenant administrators should be able to view their components, session templates and sessions normally. They will not be able to
view the resources of another tenant, and will have restricted or no access to some `BOS` endpoints such the components
endpoint which can be viewed but not patched, and the options endpoint which is blocked entirely.

## System administrators

Systems administrators have complete access to the `BOS` API, and can view and edit all resources for all tenants, including
tenant-less resources. However, some endpoints require the administrator to masquerade as a tenant in order to update resource.
This can mean passing the tenant ID in the query header, or authenticating the CLI as a specific tenant.
See [Tenant Admin Configuration](../multi-tenancy/TenantAdminConfig.md) for information on authenticating the CLI as a
specific tenant. While masquerading as a tenant, the system administrator will only have the ability to view and update
resources specific to that tenant.

### Components

Component ownership is not directly tracked by `BOS` to avoid duplicating information stored in `TAPMS` and HSM. As a result
the system administrator will not see any tenant information in the component records and the components endpoint will function
normally for system administrators. To determine which components belong to which tenant, the administrator will need to query `TAPMS`.

## Sessions and session templates

Both session and session template records now contain information on the tenant that owns them. System administrators can list
all sessions and session templates across all tenants. However, system administrators will not be able to create, retrieve,
update, or delete specific records that belong to a tenant without authenticating to that specific tenant. This is
because the resources are name-spaced to avoid naming collisions between tenants. The name-spacing means that there can
be two or more records with the same name, and `BOS` does not know which resource is requested unless the tenant is
specified. To access tenant owned resources, the system administrator will need to masquerade as that tenant.

## BOS API Access with Tenancy

The `BOS` v2 API identifies the tenant based on information passed in the request. A tenant must always pass information 
identifying itself -- their tenant ID -- when making a request. If you have tenant information forwarded to the `BOS`
api service through use of the `cray init` command, `BOS` will contextually operate on behalf of that tenant. Otherwise, 
if you are interacting with the API directly or are scripting against it, the same information may be provided with your
request as part of a header that accompanies your request.

Note: HPE Authored `OPA` rules prevent unauthorized tenant requests from accessing the `BOS` API, so the value you 
choose for `Cray-Tenant-Name: ` must match your user provided access token within your request. If your user access 
token is not part of the tenant name you are issuing, your command will fail. This allows users who are part of multiple
tenancies to select the specific tenant that they are operating under, as it is possible for one user to be a part of 
multiple tenant groups. In the case of `BOS`, even if you are part of multiple individual tenant groups, only the 
resources that are allocated to a specifically provided tenant, as referenced by name, are affected.

1. (`ncn-mw#`) Administrators may provide tenant information via an HTTP verb in the form of a header to affect resources
that are part of a specific `TAPMS` tenant.

    ```bash
    curl -H "Cray-Tenant-Name: red" -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' https://api-gw-service-nmn.local/apis/bos/v2/components/
    ```
