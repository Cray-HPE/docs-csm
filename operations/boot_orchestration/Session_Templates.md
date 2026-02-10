# BOS Session Templates

Session templates in the Boot Orchestration Service (BOS) are a reusable collection of boot, configuration, and component information.
After creation they can be combined with a boot operation to create a BOS session that will apply the desired changes to the specified components.
Session templates can be created via the API by providing JSON data or via the CLI by writing the JSON data to a file, which can then be referenced using the `--file` parameter.

* [Session template structure](#session-template-structure)
* [Boot sets](#boot-sets)
    * [Boot artifacts](#boot-artifacts)
    * [Specifying nodes](#specifying-nodes)
        * [Node list](#node-list)
        * [Node groups](#node-groups)
        * [Node roles groups](#node-roles-groups)
    * [Architecture](#architecture)
    * [`rootfs` providers](#rootfs-providers)
        * [`root` kernel parameter example](#root-kernel-parameter-example)
    * [Overriding configuration](#overriding-configuration)

## Session template structure

The following is an example BOS session template:

```json
{
  "boot_sets": {
    "arm_boot_set": {
      "arch": "ARM"
      "etag": "foo",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node  oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999",
      "node_roles_groups": [
        "Compute"
      ],
      "path": "s3://boot-images/e06530f1-fde2-4ca5-9148-7e84f4857d17/manifest.json",
      "rootfs_provider": "sbps",
      "rootfs_provider_passthrough": "sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain:300",
      "type": "s3"
    },
    "x86_boot_set": {
      "arch": "X86",
      "etag": "bar",
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node  oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999",
      "node_roles_groups": [
        "Compute"
      ],
      "path": "s3://boot-images/f17631a1-fed1-5cb5-0aa8-7aaaf4123411/manifest.json",
      "rootfs_provider": "sbps",
      "rootfs_provider_passthrough": "sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain:300",
      "type": "s3"
    }
  },
  "cfs": {
      "configuration": "example-configuration"
  },
  "description": "session template example",
  "enable_cfs": true,
  "name": "session-template-example",
  "tenant": ""
}
```

* The `description` field is an optional text description of the template.
* The `node_list` field (under `boot_sets`) is a list of individual node component names (xnames).
* The `etag` field is used to identify the version of the `manifest.json` file in S3.
* The `path` field is the path to the `manifest.json` file in S3.
* The `type` field is the type of storage where the boot image resides.
* The `configuration` field (under `cfs`) is the name of the
  [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) configuration to apply.
* The `enable_cfs` field indicates whether or not CFS should be invoked.
* The `tenant` field indicates which tenant owns this session template.
    * An empty or null value indicates that the template is not owned by a tenant.
    * For more information on tenants, see [Multi-tenancy with BOS](Multi_tenancy_with_BOS.md).
* The `boot_sets` field is discussed in the following section: [Boot sets](#boot-sets).

## Boot sets

A boot set in a BOS session template contains information on the boot artifacts and kernel parameters that nodes should boot with,
as well as information on the nodes the boot set should apply to.
Optionally, configuration information can also be overwritten on a per boot set basis.

Every BOS session template is required to include at least one boot set entry.
As the example in the [Session template structure](#session-template-structure) section shows,
it is legal to have multiple boot set entries in a single session template;
however, many session templates only have a single boot set.

### Boot artifacts

Boot artifacts allow a node to boot. They consist of a kernel, an `initrd`, and a root file system (`rootfs`). These three artifacts are
listed in a `manifest.json` file.

Boot sets specify a set of parameters that point to a `manifest.json` file stored in the
[Simple Storage Service (S3)](../../glossary.md#simple-storage-service-s3).
This file is created by the [Image Management Service (IMS)](../../glossary.md#image-management-service-ims)
and contains links to all of the boot artifacts.

The following S3 parameters are used to specify this file:

* type: This is the type of storage used. Currently, the only allowable value is `s3`.
* path: This is the path to the `manifest.json` file in S3. The path will follow the `s3://<BUCKET_NAME>/<KEY_NAME>` format.
    * `<BUCKET_NAME>` is set to `boot-images`
    * `<KEY_NAME>` is set to the image ID that the [Image Management Service (IMS)](../../glossary.md#image-management-service-ims) created when it generated the boot artifacts.
* `etag`: This entity tag helps identify the version of the `manifest.json` file. Its value can be an empty string, but cannot be left blank. However, the `etag` line can be omitted entirely.

This boot artifact information from the files stored in S3 is then written to the
[Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) where it is retrieved when these nodes boot.

> Also see the [Architecture](#architecture) section for information on how that field relates to the boot artifacts.

### Specifying nodes

Each boot set also specifies a set of nodes that are the targets of the boot set.
There are three different fields used to specify the nodes: `node_list`, `node_groups`, or `node_roles_groups`.

> Also see the [Architecture](#architecture) section for information on how that field relates to specifying nodes.

#### Node list

`node_list` maps to a list of nodes identified by component names (xnames).

For example:

```text
"node_list": ["x3000c0s19b1n0", "x3000c0s19b1n1", "x3000c0s19b2n0"]
```

NIDs are not supported.
The [`reject_nids` option](Options.md#reject-nids) can be enabled in order to prevent accidental creation of session templates that reference NIDs.

#### Node groups

`node_groups` maps to a list of [component groups](../hardware_state_manager/Component_Groups_and_Partitions.md) defined by the
[Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm).
Each group may contain zero or more nodes. Groups can be arbitrarily defined by users.

For example:

```text
"node_groups": ["green", "white", "pink"]
```

(`ncn-mw#`) To retrieve the current list of HSM groups, run following command:

```bash
cray hsm groups list --format json | jq .[].label
```

For more information on HSM groups, see [Manage Component Groups](../hardware_state_manager/Manage_Component_Groups.md).

#### Node roles groups

`node_roles_groups` is a list of [HSM roles and sub-roles](../hardware_state_manager/HSM_Roles_and_Subroles.md).
Each node's role and sub-role is specified in the HSM database.
An entry in this list may be just a role (for example, `Compute`)
or it may be a role and sub-role joined by an underscore character (for example, `Application_UAN`).

For example:

```text
"node_roles_groups": ["Compute"]
```

Consult the `cray-hms-base-config` Kubernetes ConfigMap in the `services` namespace for a listing of the available roles and sub-roles on the system.

See [HSM Roles and Subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md) for more information.

### Architecture

The `arch` field is the only boot set field which plays a role in both the [boot artifacts](#boot-artifacts)
and [specifying nodes](#specifying-nodes). It specifies the hardware architecture both of the target nodes
and of the boot artifacts. Supported values are `X86` and `ARM`.

When a boot set is validated, it will contact IMS to make sure that the boot image being used has an architecture matching
what is specified in the boot set. Boot set validation happens when creating a session template, validating a session template, or
creating a session. In cases where BOS is unable to perform this validation, the behavior of BOS is controlled by
the [`ims_errors_fatal` option](Options.md#ims-errors-fatal) and [`ims_images_must_exist` option](Options.md#ims-images-must-exist).

Unlike the fields discussed in the [Specifying nodes](#specifying-nodes) section, the `arch` field is not used to specify additional
nodes. Instead, it acts as a filter, removing any specified nodes that do not have a matching architecture.

### `rootfs` providers

The `rootfs` is the root file system.

`rootfs_provider` identifies the mechanism that provides the root file system for the node.

In the case of the [User Services Software (USS)](../../glossary.md#user-services-software-uss) image, the `rootfs_provider` is HPE's
[iSCSI SBPS (Scalable Boot Content Projection Service)](../iscsi_sbps/README.md).
SBPS projects the root file system onto the nodes as a SquashFS image. This is provided via an overlay file system which is set up in dracut.

`rootfs_provider_passthrough` is a string that is passed through to the provider of the `rootfs`. This string can contain additional information that the provider will act upon.

Both the `rootfs_provider` and `rootfs_provider_passthrough` parameters are used to construct the value of the kernel boot parameter `root` that BOS sends to the node.

BOS constructs the kernel boot parameter `root` per the following syntax.

```text
root=<Protocol>:<Root FS location>:<Etag>:<RootFS-provider-passthrough parameters>
```

BOS fills in the protocol based on the value provided in `rootfs_provider`. If BOS does not know the `rootfs_provider`, then it omits the protocol field.
BOS finds the `rootfs_provider` and `etag` values in the manifest file in the session template in the boot set.
The `rootfs_provider_passthrough` parameters are appended to the `root` parameter without modification. They are "passed through", as the name implies.

Currently, the only `rootfs` provider that BOS recognizes is `sbps`.
For more information on `sbps`, see [Create a Session Template to Boot Compute Nodes with SBPS](Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md).

#### `root` kernel parameter example

```text
root=sbps-s3:s3://boot-images/4fab0408-0bfe-4668-b957-964f8ff0e4e9/rootfs:b6ea7a2314d54dead0c94223863b3488-1977:sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain:300
```

The following table explains the different pieces in the preceding example.

| Field                                    | Example Value                                                              | Explanation                                                                                                             |
|------------------------------------------|----------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| Protocol                                 | `sbps-s3`                                                                  | The protocol used to mount the root file system, using SBPS in this example.                                            |
| `rootfs_provider` location               | `s3://boot-images/4fab0408-0bfe-4668-b957-964f8ff0e4e9/rootfs`             | The `rootfs_provider` location is a SquashFS image stored in S3.                                                        |
| `etag`                                   | `b6ea7a2314d54dead0c94223863b3488-1977`                                    | The `Etag` (entity tag) is the identifier of the SquashFS image in S3.                                                  |
| `rootfs_provider_passthrough` parameters | `sbps:v1:iqn.2023-06.csm.iscsi:_sbps-hsn._tcp.my-system.my-site-domain:30` | These are additional parameters passed through to SBPS in this example.                                                 |

### Overriding configuration

It is also possible to specify CFS configuration in the boot set. This is done by setting the `cfs` field inside the boot set.
It follows the same format as the `cfs` field at the top level of the session template.
If specified, this will override (for that boot set entry) whatever value is set in the base session template.
