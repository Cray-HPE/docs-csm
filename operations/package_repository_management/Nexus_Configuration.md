# Nexus Configuration

Expect each product to create and use its own `File` type blob store. For example, the Cray System Management \(CSM\) product uses `csm`.

The `default` blob store is also available, but Cray products are discouraged from using it.

## Repositories

CSM creates the `registry` \(format `docker`\) and `charts` \(format `helm`\) repositories for managing container images and Helm charts across all Cray products. However,
each product's release may contain a number of RPM repositories that are added to Nexus. RPM repositories are created in Nexus as `raw` repositories to support signed
repository metadata and to enable client GPG checks.

## Repository naming conventions

RPM repositories should be named in the `<product>[-<product-version>]-<os-dist>-<os-version>[-compute][-<arch>]` format. The following is a description of each component in an
RPM repository name:

| Component | Description |
| --------- | ----------- |
|`<product>` | The product. For example, `cos`, `csm`, or `sma`. |
| `<product-version>` | The product version. For example, `1.4.0`, `latest`, or `stable`. Type `hosted` repositories must specify the version relative to the patch release. Type `group` or `proxy` repositories whose sole member is a `hosted` repository (for instance, if it serves as an alias) may use a more generic version, such as `1.4`, or omit the version altogether if it represents the currently active version. |
| `<os-dist>` | The OS distribution, such as `sle`. |
| `<os-version>` | The OS version, such as `15sp1` or `15sp2`. |
| `compute` | Must be specified if the repository contains RPMs specific to compute nodes and omitted otherwise. There is no suffix for repositories containing NCN RPMs. |
| `<arch>` | Must be specified if the repository contains RPMs specific to a system architecture other than `x86_64`, such as `-aarch64`. |
