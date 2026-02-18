# TAPMS (Tenant and Partition Management System)

- [Overview](#overview)
- [Tenant schema](#tenant-schema)
- [Reconcile operations](#reconcile-operations)
- [Tenant states](#tenant-states)
- [Tenant key rotation](#tenant-key-rotation)
- [Webhook payload](#webhook-payload)

## Overview

TAPMS is the primary Kubernetes operator through which tenant creation and management is handled. This operator
interacts with several other services in the CSM software stack to provision the necessary components for a given
tenant. This document gives an overview of its functionality.

## Tenant schema

See the
[Tenant Custom Resource Definition](https://github.com/Cray-HPE/cray-tapms-operator/blob/main/config/crd/bases/tapms.hpe.com_tenants.yaml)
for the full schema. Below is a description of the required fields for a tenant:

| Field                                             | Description                                                                                                                                                                         |
|---------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `tenantname`                                      | Name of the tenant. See [Tenant naming requirements](CrayHncManager.md#tenant-naming-requirements) for restrictions on tenant naming.                                               |
| `childnamespaces`                                 | List of namespaces that should be created for the tenant. These namespaces will be created with the name specified here, prepended with the required HNC prefix.                    |
| `tenantresources`.`type`                          | Only `compute` and `application` are supported in the current release of TAPMS.                                                                                                     |
| `tenantresources`.`hsmgrouplabel`                 | The name of the HSM group label for the xnames specified below (mutually exclusive from `hsmpartitionname`).                                                                        |
| `tenantresources`.`hsmpartitionname`              | The name of the HSM partition to create and assignments for the xnames specified below  (mutually exclusive from `hsmgrouplabel`).                                                  |
| `tenantresources`.`enforceexclusivehsmgroups`     | If `true`, tenants that share this setting will not be allowed to specify the same xname (only appropriate if `hsmgrouplabel` is also specified).                                   |
| `tenantresources`.`xnames`                        | List of compute or application component names (xnames) that this tenant is allowed to use for running jobs.                                                                        |
| `tenantkms`.`enablekms`                           | Create a Vault transit engine for the tenant if this setting is `true`. By default, this is `false`. If enabled, the transit name and other details will be shown in the CR status. |
| `tenantkms`.`keyname`                             | Optional name for the transit engine key. If not provided, a default will be used and shown in the CR status. This is only used when `enablekms` is `true`.                         |
| `tenantkms`.`keytype`                             | Optional transit engine key type. If not provided, a default will be used and shown in the CR status. This is only used when `enablekms` is `true`.                                 |
| `tenanthooks`.`name`                              | Name of the webhook to be called by TAPMS.                                                                                                                                          |
| `tenanthooks`.`url`                               | URL to inform/POST tenant creation, updates, and deletion.                                                                                                                          |
| `tenanthooks`.`blockingcall`                      | If true, TAPMS will wait for call to return prior to applying a tenant change. By default, this is `false`.                                                                         |
| `tenanthooks`.`eventtypes`                        | Type of event the URL should be called for. Valid values are `CREATE`, `UPDATE`, `DELETE`.                                                                                          |
| `tenanthooks`.`hookcredentials`.`secretname`      | Name of the Kubernetes secret containing webhook credentials.                                                                                                                       |
| `tenanthooks`.`hookcredentials`.`secretnamespace` | Namespace of the Kubernetes secret containing webhook credentials.                                                                                                                  |

## Reconcile operations

When a tenant CR is applied, TAPMS will:

1. If the tenant declaration includes any `TenantHooks` or if any `GlobalTenantHooks` have been created,
   TAPMS will first call the specified endpoints.
   If the endpoint returns an HTTP code other than 200 and `blockingCall` is `true`, the tenant creation request will fail.
1. Create a tenant and Kubernetes namespace with the specified name. Note that when HNC is deployed, it will be
   configured with a required prefix for tenant names ensuring that namespaces not associated with multi-tenancy are not
   managed by HNC. The default prefix is `vcluster`, and this can be changed during the deployment of
   the `cray-hnc-manager` Helm chart.
1. Create namespaces specified in the `childnamespaces` with the tenant-specific prefix.
1. Add the specified xnames to an [HSM group or partition](../hardware_state_manager/Component_Groups_and_Partitions.md).
1. Apply the value specified in `hsmgrouplabel`
1. If the `enforceexclusivehsmgroups` flag is `true`, TAPMS will ensure xnames cannot be specified in multiple
   tenants (that also have the flag set to `true` for their `hsmgrouplabel`).
1. Create a Keycloak group with the name `<tenant-name>-tenant-admin` which can be assigned to users intended to be
   tenant administrators.
1. If the `tenantkms`.`enablekms` flag is `true`, then TAPMS will create a Vault transit engine with the
   name `cray-tenant-<tenant-uuid>`. See the [Tenant schema](#tenant-schema) (and the CRD) for more details. The created
   transit engine details will be available in the Tenant CR under the `status`.`tenantkms` section.

## Tenant states

TAPMS will report one of the following states for a tenant, depending on the current state of the tenant:

| State       | Description                                                              |
|-------------|--------------------------------------------------------------------------|
| `New`       | TAPMS has begun reconciliation for a newly created tenant.               |
| `Deploying` | TAPMS is in the process of deploying the tenant.                         |
| `Deployed`  | The tenant reconciliation is complete (from the perspective of TAPMS).   |
| `Deleting`  | TAPMS has begun deleting the tenant.                                     |

## Tenant key rotation

Authenticating with Vault is necessary in order to send commands with the Vault CLI and
rotate the key in Vault. In order to run Vault commands as an administrator,
first acquire a Vault token and define the `vault_cmd` function. For more details,
see [HashiCorp Vault](../security_and_authentication/HashiCorp_Vault.md).

```bash
VAULT_TOKEN=$(kubectl get secrets cray-vault-unseal-keys -n vault -o jsonpath={.data.vault-root} | base64 -d)
function vault_cmd() { kubectl exec -it -n vault -c vault cray-vault-0 -- sh -c "VAULT_ADDR=http://localhost:8200 VAULT_TOKEN=$VAULT_TOKEN vault $*"; }
```

To test that this operation worked, run the following command:

```bash
vault_cmd secrets list
```

Once the function is working, define the following variables in preparation for the key rotation:

```bash
TENANT_NAME="tenant-name" # set the specific tenant name
TRANSIT_PATH=$(kubectl get tenants.tapms.hpe.com -n tenants $TENANT_NAME -ojson | jq -r '.status.tenantkms.transitname')
TENANT_KEYNAME=$(kubectl get tenants.tapms.hpe.com -n tenants $TENANT_NAME -ojson | jq -r '.status.tenantkms.keyname')
```

The rotation of the transit engine key pair can be initiated by using the following command:

```bash
vault_cmd write -f $TRANSIT_PATH/keys/$TENANT_KEYNAME/rotate
```

Finally, patch the tenant with the following command:

```bash
kubectl patch tenant -n tenants $TENANT_NAME --type=merge -p '{"spec":{"requiresVaultKeyUpdate":true}}'
```

**NOTE**: These next steps are not required for standard key rotation, but may help with multiple key pair versions.

A transit engine can have multiple key pair versions.  At rotation time, a new
version of the key pair is created. It is also possible to rewrap (convert) data
encrypted with a previous key pair version to the latest using the rewrap
endpoint by running the following command:

```bash
vault_cmd write $TRANSIT_PATH/rewrap/$TENANT_KEYNAME ciphertext=<previous-version-ciphertext>
```

The minimum decryption version can also be set after rotation when it is decided that the previous version is no longer needed by running the following command:

```bash
vault_cmd write $TRANSIT_PATH/keys/$TENANT_KEYNAME/config min_decryption_version=2
```

Rotation will require some coordination around disabling older key versions and rewrapping any previous ciphertext as required.

## Webhook payload

If any `TenantHooks` are specified for a tenant, the following data will be sent to the endpoint via the HTTP POST method:

   ```json
   {
      "eventtype":"UPDATE",
      "tenantspec":{
         "tenantname":"vcluster-blue",
         "state":"Deployed",
         "childnamespaces":[
            "slurm",
            "user"
         ],
         "tenantresources":[
            {
               "type":"compute",
               "xnames":[
                  "x1000c0s0b0n0"
               ],
               "hsmgrouplabel":"blue",
               "enforceexclusivehsmgroups":true
            }
         ],
         "tenantkms":{
            "enablekms":true,
            "keyname":"key1",
            "keytype":"rsa-3072"
         },
         "tenanthooks":[
            {
               "name":"blocking-hook",
               "blockingcall":true,
               "url":"http://10.19.12.61:6000/block",
               "eventtypes":[
                  "UPDATE",
                  "DELETE"
               ],
               "hookcredentials":{
                  "secretname":"blocking-hook-cm",
                  "secretnamespace":"services"
               }
            },
            {
               "name":"notify-hook",
               "blockingcall":false,
               "url":"http://10.19.12.61:6000",
               "eventtypes":[
                  "UPDATE",
                  "DELETE"
               ],
               "hookcredentials":{
                  "secretname":"notify-hook-cm",
                  "secretnamespace":"services"
               }
            }
         ]
      }
   }
   ```
