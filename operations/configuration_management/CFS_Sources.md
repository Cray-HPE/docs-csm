# CFS Sources

* [Overview](#overview)
* [Describe a CFS source](#describe-a-cfs-source)
* [Create a CFS source](#create-a-cfs-source)
* [Update a CFS source](#update-a-cfs-source)
* [Add CA certificates](#add-ca-certificates)
* [Additional inventory source](#additional-inventory-source)

## Overview

The Configuration Framework Service \(CFS\) allows users to define optional sources.
Sources contain all the information needed to clone information from a repository, and
can be used when the repository does not share the default credentials or CA certificate
as the [Version Control Service (VCS)](Version_Control_Service_VCS.md).
The username and password for cloning a repository can be specified in a CFS source,
and CFS will store them in a [Vault](../security_and_authentication/HashiCorp_Vault.md)
secret, only recording the secret name in the source record. It is also possible to
provide a CA certificate for CFS to use when cloning the repository. Sources can then be
[referenced in CFS configurations](CFS_Configurations.md#using-sources-in-a-configuration-layer).

Sources are not a required component in CFS and are only necessary for more complex setups,
including cloning from external repositories.

## Describe a CFS source

(`ncn-mw#`) Describe an existing CFS source.

```bash
cray cfs v3 sources describe example --format json
```

Example output:

```json
{
  "ca_cert": {
    "configmap_name": "cray-configmap-ca-public-key",
    "configmap_namespace": "example"
  },
  "clone_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
  "credentials": {
    "authentication_method": "password",
    "secret_name": "cfs-source-credentials-49ec8f0e-efe4-44d1-97ee-a49ef99e761b"
  },
  "last_updated": "2023-10-03T16:20:00Z",
  "name": "example"
}
```

## Create a CFS source

(`ncn-mw#`) Create a new CFS source.

```bash
cray cfs v3 sources create --name example \
   --clone-url https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git \
   --credentials-username user --credentials-password pass
```

Example output:

```json
{
  "clone_url": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
  "credentials": {
    "authentication_method": "password",
    "secret_name": "cfs-source-credentials-b79af11d-a6b2-4585-8746-735b4a1881cd"
  },
  "last_updated": "2023-10-23T16:40:31Z",
  "name": "example"
}
```

## Update a CFS source

(`ncn-mw#`) Update an existing CFS source.

> **Note**:
>
> * Source names cannot be updated
> * The username and password can only be updated together -- not separately.

```bash
cray cfs v3 sources update example --clone-url new-url --format json
```

Example output:

```json
{
  "clone_url": "new-url",
  "credentials": {
    "authentication_method": "password",
    "secret_name": "cfs-source-credentials-b79af11d-a6b2-4585-8746-735b4a1881cd"
  },
  "last_updated": "2023-10-23T16:40:31Z",
  "name": "example"
}
```

## Add CA certificates

This procedure requires the desired CA certificate to exist in a file on
the system where the procedure is being run. In the example commands,
`example.crt` is used, but should be replaced with the actual path and name
of the CA certificate file.

1. (`ncn-mw#`) View the CA certificate file to verify that it exists.

    ```bash
    cat example.crt
    ```

    Example output:

    ```text
    -----BEGIN CERTIFICATE-----
    MIIEkjCCAvqgAwIBAgIUBGHYeepYg6S8y98T1AUK/+/i3qUwDQYJKoZIhvcNAQEL
    BQAwYTEPMA0GA1UECgwGU2hhc3RhMREwDwYDVQQLDAhQbGF0Zm9ybTE7MDkGA1==
    -----END CERTIFICATE-----
    ```

1. (`ncn-mw#`) Store the CA certificate in a Kubernetes ConfigMap.

    ```bash
    kubectl create configmap example-ca-cert --from-file=example.crt
    ```

1. (`ncn-mw#`) Either create a new source, or update an existing source with the new ConfigMap.

    > **`NOTE`** If the Kubernetes ConfigMap contains more than one file, then only the first
    > file will be used.

    * Create a new source.

        ```bash
        cray cfs v3 sources create --name example \
            --clone-url https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git \
            --credentials-username user --credentials-password pass \
            --ca-cert-configmap-name example-ca-cert
        ```

    * Update an existing source.

        ```bash
        cray cfs v3 sources update example --ca-cert-configmap-name example-ca-cert
        ```

    * If the ConfigMap was created in a particular Kubernetes namespace, use `--ca-cert-configmap-namespace`
      to specify the namespace.

        > This example is updating an existing source, but the same argument can be used when creating a source.

        ```bash
        cray cfs v3 sources update example --ca-cert-configmap-name example-ca-cert \
            --ca-cert-configmap-namespace services
        ```

## Additional inventory source

The additional inventory source [CFS Global Option](CFS_Global_Options.md) allows administrators to specify
a CFS source to supply additional inventory content to all CFS sessions.

For more information, see [Additional inventory source](CFS_Global_Options.md#additional_inventory_source)
and [Using sources in additional inventory](Adding_Additional_Inventory.md#using-sources-in-additional-inventory).
