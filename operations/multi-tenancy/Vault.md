# Multi-Tenancy Vault Overview

- [Overview](#overview)
- [Transit Engine Creation](#transit-engine-creation)
- [Transit Engine Modifications](#transit-engine-modifications)
- [Transit Engine Removal](#transit-engine-removal)
  
## Overview

When a tenant is created or modified, the TAPMS operator can optionally create a tenant-specific Cray Vault transit engine for the purpose of data encryption/decryption as required.
In addition to enabling the transit engine, the tenant administrator can optionally define the encryption key algorithm and name. See the [TAPMS Overview](Tapms.md) for details on the schema and links to the CRD which also documents any default values.
The transit engine name is created as `cray-tenant-<tenant-uuid>`.

The supported encryption algorithms are those available in [Vault](https://developer.hashicorp.com/vault/api-docs/secret/transit#type).

When a tenant is removed, any tenant-specific Vault content is removed.

## Transit Engine Creation

The Tenant definition example below includes a transit engine (`tenantkms`.`enablekms` is `true`) where `keytype` indicates the type of encryption key to create and `keyname` indicates the name of the encryption key.

```bash
apiVersion: tapms.hpe.com/v1alpha2
kind: Tenant
metadata:
  name: vcluster-blue
spec:
  childnamespaces:
  - slurm
  - user
  tenantname: vcluster-blue
  tenantresources:
  - enforceexclusivehsmgroups: true
    hsmgrouplabel: blue
    type: compute
    xnames:
    - x1000c0s3b0n1
  tenantkms:
    enablekms: true
    keyname: mykey
    keytype: rsa-4096
```

After successful creation of the tenant, the Kubernetes Tenant CR status will include details of the transit engine under `status`.`tenantkms`. The `kubectl` command can be used to observe the details:

```bash
kubectl -n tenants get Tenant/vcluster-blue -o yaml
```

Example output truncated to show only the `tenantkms` status:

```bash
  tenantkms:
    keyname: mykey
    keytype: rsa-4096
    publickey: '{"1":{"creation_time":"2023-06-28T23:34:26.242626404Z","name":"rsa-4096","public_key":"-----BEGIN
      PUBLIC KEY-----\nMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA3lBvxSNIdb7pn0RmJ1uB\nJwLlb8ezSMkUMqN46m7XN44sY7Efx+dDVpyBv+dfc+ZpBNcJK2Gj3LCkTM8G8Qz
0\nspkdFUlERzlz+8V98Ry0jymZ8PhcatuCIu6DH2x/j23VO6PzpTSoxCHESOn5nbx6\nbPjeqnwYeRFWq+svj3b6XzdpFXdjgyvpzMGpsu01aj4VRgbDDmXYFS5VSGnpe3UM\nJPpvu+MG7PxvhiPfM
O5LvJMnGXVaTKveqKi3+8778YOJ5jbKFciMc6uk3g6BCpFH\nOp78vpySYUVntAxFk8gPIs+GbTMylRkc/EWMX3xu3tlNjQAazpJVmqfmNgB5Q1Oh\nShYAXosiRcPc/8ENwfc1T8TJjQQlbSxjjwpIO
BchvUJ29U4lKn/W5+V2bc11RY7s\njphU9wqDTyMD2wvRIpAzXpShqFExEFCIP4YulJCr/aJH1byLMJjPdreG4Ohnc7qn\nueIDZWIbi6pVtWRJZKgu3Q4LJ/R+w0v1qtTqY5c3xoI1zQFKYvU0fQgn5
RA2EP1E\nXy2gMTYn+EVH/xrpTj1TQxP8jKUg3zzf/ITrOO7ImOmgWPg+CbBUKTkYKtqpsLL0\nevKWStoWRVZWY8hmRDT7EDIV/9WU3udAlrNPRBjhti31mR6cN8ddGr+G6TWMAQu8\nw0MgJYU1+0B
XTyWOLIhslicCAwEAAQ==\n-----END
      PUBLIC KEY-----\n"}}'
    transitname: cray-tenant-1ae9e0e9-f51c-48d9-881c-d0798c50b911
```

A transit engine may be added to an existing tenant definition if a transit engine does not already exist. This can be done by appending the `tenantkms` specification to an existing tenant CR.

This example will add a new transit engine with defaults for the encryption algorithm and key name to the `vcluster-red` tenant if it does not already exist:

```bash
kubectl -n tenants apply -f - <<EOF
apiVersion: tapms.hpe.com/v1alpha2
kind: Tenant
metadata:
  name: vcluster-red
spec:
  childnamespaces:
  - slurm
  - user
  tenantname: vcluster-red
  tenantresources:
  - enforceexclusivehsmgroups: true
    hsmgrouplabel: red
    type: compute
    xnames:
    - x1000c0s3b0n1
  tenantkms:
    enablekms: true
EOF
```

In this case, if the transit engine already exists, no action will be performed.

## Transit Engine Modifications

Currently, other than initially adding a new transit engine, modifications to an existing tenant's Vault transit engine or transit engine key are not supported through TAPMS.
This includes the creation of multiple keys or key rotation. It is envisioned that future modifications to the TAPMS operator's Vault integration or additions to this documentation will address gaps in this area.

## Transit Engine Removal

Any existing tenant transit engine and encryption key will be automatically removed by the TAPMS operator when the tenant is removed (Tenant CR deleted).
In the `vcluster-red` example above, the tenant's Vault transit engine and key will be removed from Vault when the tenant is deleted.

The command to delete the tenant in this example is:

```bash
kubectl -n tenants delete Tenant/vcluster-red
```
