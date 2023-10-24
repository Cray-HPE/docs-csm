# CFS Sources

The Configuration Framework Service \(CFS\) allows users to define optional sources.
Sources contain all the information needed to clone information from a repo, and can be used when the repo does not share the default credentials or CA certificate as VCS.
The username and password for cloning a repo can be specified in source, and CFS will store them in a vault secret, only recording the secret name in the source record.
It is also possible to provide a CA certificate for CFS to use when cloning in a repo.
Sources can then be referenced in CFS configurations.

Sources are not a required component in CFS and are only necessary for more complex setups including cloning from external repositories.

## Example source

```bash
cray cfs v3 sources describe example
```

Example configuration:

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

(`ncn-mw#`) Use the `cray cfs v3 sources create` command to create a source.

```bash
cray cfs v3 sources create --name example \
   --clone-url https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git \
   --credentials-username user --credentials-password pass
```

Example output

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

## Update a CFS configuration

(`ncn-mw#`) Use the `cray cfs v3 sources update` command.

 ```bash
 cray cfs v3 sources update example --clone-url new-url --format json
 ```

Example output

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

Source names cannot be updated, and updating either the username or password requires both to be specified.

## Adding CA certificates

1. (`ncn-mw#`) First create a CA certificate file on your system.

   ```bash
   cat example.crt
   ```

   ```text
   -----BEGIN CERTIFICATE-----
   MIIEkjCCAvqgAwIBAgIUBGHYeepYg6S8y98T1AUK/+/i3qUwDQYJKoZIhvcNAQEL
   BQAwYTEPMA0GA1UECgwGU2hhc3RhMREwDwYDVQQLDAhQbGF0Zm9ybTE7MDkGA1==
   -----END CERTIFICATE-----
   ```

1. (`ncn-mw#`) Store the CA certificate in a Kubernetes `configmap`:

   ```bash
   kubectl create configmap example-ca-cert --from-file=example.crt
   ```

1. (`ncn-mw#`) Either create a new source, or updating an existing source with the new `configmap` map:

   ```bash
   cray cfs v3 sources create --name example \
      --clone-url https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git \
      --credentials-username user --credentials-password pass \
      --ca-cert-configmap-name example-ca-cert
   ```

    or

   ```bash
   cray cfs v3 sources update example --ca-cert-configmap-name example-ca-cert
   ```

   If the `configmap` was created in a particular Kubernetes namespace, `--ca-cert-configmap-namespace` can be used to specify the namespace.

   ```bash
   cray cfs v3 sources update example --ca-cert-configmap-name example-ca-cert \
   --ca-cert-configmap-namespace services
   ```

   > **`NOTE`** If the Kubernetes `configmap` contains more than one file, only the first file will be used.
