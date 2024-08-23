# Create a Session Template to Boot Compute Nodes with Scalable Boot Projection Service (SBPS)

When [compute nodes](../../glossary.md#compute-node-cn) are booted, the [Scalable Boot Projection Service (SBPS)](../../glossary.md#scalable-boot-projection-service-sbps)
projects the root file system (`rootfs`) over the network to the compute nodes using iSCSI.

This page covers the necessary configuration of a BOS session template in order to use SBPS.

- [Boot set `rootfs_provider` parameter](#boot-set-rootfs_provider-parameter)
- [Boot set `rootfs_provider_passthrough` parameter](#boot-set-rootfs_provider_passthrough-parameter)
    - [`Setting the parameter`](#setting-the-parameter)
    - [`Detailed Explanation`](#detailed-explanation-of-each-element-of-the-parameter)
        - [`<transport>`](#transport)
        - [`<schema version>`](#schema-version)
        - [`<IQN Domain>`](#iqn-domain)
        - [`<DNS SRV record reference>`](#dns-service-srv-record-reference)
        - [`<client discovery timeout in seconds>`](#client-discovery-timeout-in-seconds)
        - [`<ramroot>`](#ramroot)
        - [Example `rootfs_provider_passthrough`](#example-rootfs_provider_passthrough)
- [Example session template input file](#example-session-template-input-file)
- [Appendix: `root=` kernel parameter](#appendix-root-kernel-parameter)

The Scalable Boot Projection Service (SBPS) is the **default**  provider for the `rootfs` on compute nodes.

Two parameters need to be set to configure SBPS, the `rootfs_provider` and the `rootfs_provider_passthrough`.

## Boot set `rootfs_provider` parameter

The following value needs to be set in the boot set of the session template in order to make SBPS the `rootfs` provider:

`"rootfs_provider":` Set to `"sbps"`

## Boot set `rootfs_provider_passthrough` parameter

### Setting the parameter

In a BOS session template, the `rootfs_provider_passthrough` parameter should be set to the following string.

```text
rootfs_provider_passthrough=sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain:300
```

The two parameters/strings that need to be customized are 'my-system' and 'my-site-domain'.
Use the following commands to find the values for these parameters/strings.

```bash
(`ncn-mw#`) craysys metadata get system-name
<my-system>
(`ncn-mw#`) craysys metadata get site-domain
<my-site-domain>
```

**Note:** These two elements should be joined with a '.' in the `rootfs_provider_passthrough` string.

```text
<my-system>.<my-site-domain>
```

### Detailed explanation of each element of the parameter

Here is a detailed explanation of each of the elements of the `rootfs_provider_passthrough` parameter.

For SBPS, the `rootfs_provider_passthrough` string should adhere to this format:

```text
rootfs_provider_passthrough=<transport>:<schema version>:<IQN Domain>:<DNS SRV record>:<client discovery timeout in seconds>:<ramroot>
```

Here is an example string for reference.

```text
rootfs_provider_passthrough=sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain:300
```

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
- `ncn-w002` is a unique identifier (e.g. hostname) of the target storage device.

The IQN domain helps in ensuring unique identification of iSCSI targets within a given namespace, allowing for proper routing and management of storage resources over the network

For SBPS, only the domain portion of the IQN needs to be supplied, not the entire IQN. The target storage device is optional does not need to be specified.

### `<DNS Service (SRV) record reference>`

A DNS SRV (Service) record is a type of Domain Name System (DNS) resource record used to specify information about services offered by a particular domain.

A DNS SRV record is structured as follows:

- Service: Specifies the symbolic name of the service.
- Protocol: Specifies the transport protocol of the service, such as TCP or UDP.
- Name: The domain name for which this record is valid.
- Other elements were omitted for clarity and brevity.

```text
<service>.<protocol>.<domain name>
```

For example, DNS SRV record might look like this:

```text
_sbps-hsn._tcp.my-system.my-site-domain
```

The following is an explanation of the values used in this example:

- `_sbps-hsn` is the symbolic name of the service.
    - In this example, the High Speed Network (HSN) is being used.
- `_tcp` is the transport protocol.
- `my-system.my-site-domain` is the domain name for which the record is valid.
    - The domain name includes the system name `my-system` and the site domain name `my-site-domain`.

To use the Node Management Network (NMN) for content projection, the service is set to `_sbps-nmn`.

- `"rootfs_provider_passthrough"`: Set to `"sbps:v1:iqn.2023-06.csm.iscsi:_sbps-nmn._tcp.my-system.my-site-domain:300"`
  
To use the High Speed Network (HSN) for content projection, the service is set to `_sbps-hsn`.

- `"rootfs_provider_passthrough"`: Set to `"sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain:300"`

**Reminder:** The DNS SRV record should contain the system's _actual_ DNS domain.
In this example, the `system-name` is `my-system` and the site domain name is `my-site-domain`. These need to be
replaced with the system's _actual_ system name and site DNS Domain. Refer to the [previous instructions](#boot-set-rootfs_provider_passthrough-parameter) to determine the system-name and site-domain.

### `<client discovery timeout in seconds>`

The timeout, in seconds, for attempting to mount the `rootfs` via SBPS.

This can be left as an empty string to use the default value of 300 seconds.

### `<ramroot>`

Indicates that the specified S3 path should be copied to RAM (`tmpfs`) and mounted locally instead of persisting as a remote file system mount.

This can be left empty. Any string except `"0"` is interpreted as true. The example above does specify a value for the ramroot.

### Example `rootfs_provider_passthrough`

Here is the example once again.

```text
rootfs_provider_passthrough=sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain:300
```

## Example session template input file

The following is an example of an input file to use with the [Cray CLI](../../glossary.md#cray-cli-cray):

```json
{
  "enable_cfs": true,
  "description": "Template for booting compute nodes, generated by the installation",
  "boot_sets": {
    "computes": {
      "rootfs_provider": "sbps",
      "rootfs_provider_passthrough": "sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain:300",
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
root=sbps-s3:s3://boot-images/4fab0408-0bfe-4668-b957-964f8ff0e4e9/rootfs:b6ea7a2314d54dead0c94223863b3488-1977:sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain:30
0```
