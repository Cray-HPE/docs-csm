# Create a Session Template to Boot Compute Nodes with Scalable Boot Projection Service (SBPS)

When [compute nodes](../../glossary.md#compute-node-cn) are booted, the [Scalable Boot Projection Service (SBPS)](../../glossary.md#scalable-boot-projection-service-sbps)
projects the root file system (`rootfs`) over the network to the compute nodes.

This page covers the appropriate contents for a BOS session template in order to use SBPS.

- [Boot set `rootfs_provider` parameter](#boot-set-rootfs_provider-parameter)
- [Boot set `rootfs_provider_passthrough` parameters](#boot-set-rootfs_provider_passthrough-parameters)
    - [`<transport>`](#transport)
    - [`<schema version>`](#schema-version)
    - [`<IQN Domain>`](#iqn-domain)
    - [`<DNS SRV record reference>`](#dns-service-srv-record-reference)
    - [`<client discovery timeout in seconds>`](#client-discovery-timeout-in-seconds)
    - [`<ramroot>`](#ramroot)
    - [Example `rootfs_provider_passthrough`](#example-rootfs_provider_passthrough)
- [Boot set S3 parameters](#boot-set-s3-parameters)
- [Example session template input file](#example-session-template-input-file)
- [Creating a BOS session using the new template](#creating-a-bos-session-using-the-new-template)
- [Appendix: `root=` kernel parameter](#appendix-root-kernel-parameter)

The Scalable Boot Projection Service (SBPS) is an optional provider for the `rootfs` on compute nodes.

## Boot set `rootfs_provider` parameter

The following value needs to be set in the boot set of the session template in order to make SBPS the `rootfs` provider:

- `"rootfs_provider":` Set to `"sbps"`

## Boot set `rootfs_provider_passthrough` parameters

For SBPS, the `rootfs_provider_passthrough` boot set parameter is customized according to the following format:

```text
rootfs_provider_passthrough=<transport>:<schema version>:<IQN Domain>:<DNS SRV record>:<client discovery timeout in seconds>:<ramroot>
```

The following values need to be set in the boot set of the session template in order to make SBPS the `rootfs` provider.
The DNS SRV record should contain the system's DNS domain.
Note, in this example, the `system-name` is `my-system` and the site domain name is `my-site-domain.net`. These need to be
replaced with the system's _actual_ system name and site DNS Domain.

- `"rootfs_provider":` Set to `"sbps"`
- To use the Node Management Network (NMN) for content projection,
    - `"rootfs_provider_passthrough"`: Set to `"sbps:v1:iqn.2023-06.csm.iscsi:_sbps-nmn._tcp.my-system.my-site-domain.net:300"`
- To use the High Speed Network (HSN) for content projection,
    - `"rootfs_provider_passthrough"`: Set to `"sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain.net:300"`

Note that `iqn.2023-06.csm.iscsi` is the IQN domain.

The variables used in this parameter represent the following:

### `<transport>`

File system network transport. For example, `sbps` or `dvs`.

Set to `sbps` to use SBPS.

### `<schema version>`

The version of the SBPS schema. `v1` is the only supported version.

### `<IQN Domain>`

The domain name portion of the iSCSI Qualified Name (IQN).

For example, an IQN might look like this:

```text
iqn.2023-06.csm.iscsi:ncn-w002
```

In this example:

- `iqn.2023-06.csm.iscsi` is the IQN domain.
- `ncn-w002` is a unique identifier for the storage device.

The IQN Domain helps in ensuring unique identification of iSCSI targets within a given namespace, allowing for proper routing and management of storage resources over the network

For SBPS, only the domain portion of the IQN needs to be supplied, not the entire IQN.

### `<DNS Service (SRV) record reference>`

A DNS SRV (Service) record is a type of Domain Name System (DNS) resource record used to specify information about services offered by a particular domain.

Here's how a DNS SRV record is structured:

- Service: Specifies the symbolic name of the service.
- Protocol: Specifies the transport protocol of the service, such as TCP or UDP.
- Name: The domain name for which this record is valid.
- Other elements were omitted for clarity and brevity.

For example, DNS SRV record might look like this:

```text
_sbps-hsn._tcp.my-system.my-site-domain.net
```

In this example,

- `_sbps-hsn` is the symbolic name of the service
- `_tcp` is the transport protocol
- `my-system.my-site-domain.net` is the domain name for which the record is valid. The domain name includes the system name `my-system` and the site domain name `my-site-domain.net`.

### `<client discovery timeout in seconds>`

The timeout, in seconds, for attempting to mount the `netroot` via SBPS.

Can be left as an empty string to use the default value of 300 seconds.

### `<ramroot>`

Indicates that the specified S3 path should be copied to RAM (`tmpfs`) and mounted locally instead of persisting as a remote file system mount.

Can be left empty. Any string except `"0"` is interpreted as true.

### Example `rootfs_provider_passthrough`

```text
rootfs_provider_passthrough=sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain.net:300
```

## Boot set S3 parameters

The session template boot set contains several [Simple Storage Service (S3)](../../glossary.md#simple-storage-service-s3) parameters.
These are listed below, along with the appropriate values to use.

- `type`: Set to `s3`
- `path`: Set to `s3://<BUCKET_NAME>/<KEY_NAME>/manifest.json`
    - `<BUCKET_NAME>` is set to `boot-images`
    - `<KEY_NAME>` is set to the image ID that the [Image Management Service (IMS)](../../glossary.md#image-management-service-ims) created when it generated the boot artifacts.
- `etag`: set to the `etag` of the `manifest.json` file in S3 as stored by the [Image Management Service (IMS)](../../glossary.md#image-management-service-ims)

## Example session template input file

The following is an example of an input file to use with the [Cray CLI](../../glossary.md#cray-cli-cray):

```json
{
  "enable_cfs": true,
  "description": "Template for booting compute nodes, generated by the installation",
  "boot_sets": {
    "computes": {
      "rootfs_provider": "sbps",
      "rootfs_provider_passthrough": "sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain.net:300",
      "kernel_parameters":"ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN}",
      "node_roles_groups": [
        "Compute"
      ],
      "type": "s3",
      "path": "s3://boot-images/ef97d3c4-6f10-4d58-b4aa-7b70fcaf41ba/manifest.json",
      "etag": "b0ace28163302e18b68cf04dd64f2e01"
    }
  },
  "cfs": {
    "configuration": "compute-configuration"
  }
}
```

Refer to [Manage a Session Template](Manage_a_Session_Template.md) for more information about creating a session template.

## Creating a BOS session using the new template

(`ncn-mw#`) The new CPS-based session template can be used when creating a BOS session. The following is an example of creating a reboot session using the CLI:

```bash
cray bos v2 sessions create --template-name cps_rootfs_template --operation Reboot
```

## Appendix: `root=` kernel parameter

This section supplies additional information about how BOS constructs the `root=` kernel parameter. This section does not require any
action to be taken. It is merely supplemental information.

BOS will construct the `root=` kernel parameter, which will be used by the node when it boots, based on the `rootfs_provider` and `rootfs_provider_passthrough` values.

For SBPS, BOS supplies a protocol `sbps-s3`, the S3 path to the `rootfs`, and the `etag` value (if it exists).
The rest of the parameters are supplied from the `rootfs_provider_passthrough` values as specified above.

BOS will construct it in the following format:

```text
root=sbps-s3:s3-path:<etag>:<transport>:<schema version>:<IQN Domain>:<DNS SRV record reference>:<client discovery timeout in seconds>:<ramroot>
```

### Example kernel parameter

```text
root=sbps-s3:s3://boot-images/4fab0408-0bfe-4668-b957-964f8ff0e4e9/rootfs:b6ea7a2314d54dead0c94223863b3488-1977:sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain.net:30
0```
