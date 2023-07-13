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
  * [`rootfs` providers](#rootfs-providers)
    * [`root` kernel parameter example](#root-kernel-parameter-example)
  * [Overriding configuration (BOS v2 only)](#overriding-configuration-bos-v2-only)

## Session template structure

The following is an example BOS session template:

```json
{
  "name": "session-template-example",
  "description": "session template example",
  "boot_sets": {
    "boot_set1": {
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node  oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999",
      "rootfs_provider": "cpss3",
      "node_list": [
        "x3000c0s19b1n0"
      ],
      "etag": "foo",
      "path": "s3://boot-images/e06530f1-fde2-4ca5-9148-7e84f4857d17/manifest_sans_boot_parameters.json",
      "rootfs_provider_passthrough": "66666666:dvs:api-gw-service-nmn.local:300:eth0",
      "type": "s3"
    },
    "boot_set2": {
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node  oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999",
      "rootfs_provider": "cpss3",
      "node_list": [
        "x3000c0s21b1n0",
        "x3000c0s22b1n0"
      ],
      "etag": "bar",
      "path": "s3://boot-images/f17631a1-fed1-5cb5-0aa8-7aaaf4123411/manifest.json",
      "rootfs_provider_passthrough": "66666666:dvs:api-gw-service-nmn.local:300:eth0",
      "type": "s3"
    }
  },
  "cfs": {
      "configuration": "example-configuration"
  },
  "enable_cfs": true,
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

## Boot sets

BOS session templates contain one or more boot sets, which each contain information on the kernel parameters that nodes should boot with,
as well as information on the nodes the boot set should apply to.
Optionally, with BOS v2, configuration information can also be overwritten on a per boot set basis.

### Boot artifacts

Boot sets specify a set of parameters that point to a `manifest.json` file stored in the
[Simple Storage Service (S3)](../../glossary.md#simple-storage-service-s3).
This file is created by the [Image Management Service (IMS)](../../glossary.md#image-management-service-ims)
and contains links to all of the boot artifacts. The following S3 parameters are used to specify this file:

* type: This is the type of storage used. Currently, the only allowable value is `s3`.
* path: This is the path to the `manifest.json` file in S3. The path will follow the `s3://<BUCKET_NAME>/<KEY_NAME>` format.
* `etag`: This entity tag helps identify the version of the `manifest.json` file. Currently, it issues a warning if the manifest's `etag` does not match. This can be an empty string, but cannot be left blank.

This boot artifact information from the files stored in S3 is then written to the
[Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) where it is retrieved when these nodes boot.

### Specifying nodes

Each boot set also specifies a set of nodes to be applied to. There are three different ways to specify the nodes.
The `node_list`, `node_groups`, or `node_role` values can each be specified as a comma-separated list.

#### Node list

`node_list` maps to a list of nodes identified by component names (xnames).

For example:

```text
"node_list": ["x3000c0s19b1n0", "x3000c0s19b1n1", "x3000c0s19b2n0"]
```

#### Node groups

`node_groups` maps to a list of groups defined by the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm).
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

`node_roles_groups` is a list of groups based on a node's designated role. Each node's role is specified in the HSM database.
`node_roles_groups` also supports node sub-roles, which are specified as a combination of the node role and sub-role (for example, `Application_UAN`).

For example:

```text
"node_roles_groups": ["Compute"]
```

See [HSM Roles and Subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md) for more information.

Consult the `cray-hms-base-config` Kubernetes ConfigMap in the `services` namespace for a listing of the available roles and sub-roles on the system.

### `rootfs` providers

The `rootfs` is the root file system.

`rootfs_provider` identifies the mechanism that provides the root file system for the node.

In the case of the [Cray Operating System (COS)](../../glossary.md#cray-operating-system-cos) image, the `rootfs_provider` is HPE’s
[Content Projection Service (CPS)](../../glossary.md#content-projection-service-cps), which uses HPE’s
[Data Virtualization Service (DVS)](../../glossary.md#data-virtualization-service-dvs) to deliver the content.
CPS projects the root file system onto the nodes as a SquashFS image. This is provided via an overlay file system which is set up in dracut.

`rootfs_provider_passthrough` is a string that is passed through to the provider of the `rootfs`. This string can contain additional information that the provider will act upon.

Both the `rootfs_provider` and `rootfs_provider_passthrough` parameters are used to construct the value of the kernel boot parameter `root` that BOS sends to the node.

BOS constructs the kernel boot parameter `root` per the following syntax.

```text
root=<Protocol>:<Root FS location>:<Etag>:<RootFS-provider-passthrough parameters>
```

BOS fills in the protocol based on the value provided in `rootfs_provider`. If BOS does not know the `rootfs_provider`, then it omits the protocol field.
Currently, BOS only recognizes the `rootfs_provider` `cpss3`.
BOS finds the `rootfs_provider` and `Etag` values in the manifest file in the session template in the boot set.
The `rootfs_provider_passthrough` parameters are appended to the `root` parameter without modification. They are "passed through", as the name implies.

#### `root` kernel parameter example

```text
root=craycps-s3:s3://boot-images/b9caaf66-c0b4-4231-aba7-a45f6282b21d/rootfs:f040d70bd6fabaf91838fe4e484563cf-211:dvs:api-gw-service-nmn.local:300:nmn0
```

The following table explains the different pieces in the preceding example.

|Field|Example Value|Explanation|
|-----|-------------|-----------|
|Protocol|`craycps-s3`|The protocol used to mount the root file system, using CPS in this example.|
|`rootfs_provider` location|`s3://boot-images/b9caaf66-c0b4-4231-aba7-a45f6282b21d/rootfs`|The `rootfs_provider` location is a SquashFS image stored in S3.|
|`Etag`|`f040d70bd6fabaf91838fe4e484563cf-211`|The `Etag` (entity tag) is the identifier of the SquashFS image in S3.|
|`rootfs_provider` passthrough parameters|`dvs:api-gw-service-nmn.local:300:nmn0`|These are additional parameters passed through to CPS in this example, which it uses to properly mount the file system.|

The `rootfs_provider_passthrough` parameters are explained in the following table.

|Parameter|Example|Explanation|
|---|---|---|
|Transport|`dvs`|Use DVS to project the SquashFS image down to the node.|
|Gateway|`api-gw-service-nmn.local`|This is the URL that identifies the gateway where the DVS servers are located.|
|Time-out|`300`|The number of seconds to wait to establish a contact.|
|Interface|`nmn0`|The IP interface on the node to use to contact the DVS server; This interface must be up to continue booting.|

Regarding the interface to use for contacting DVS, the possible values are:

* `nmn0` -- Ensures that the `nmn0` interface is up
* `nmn0,hsn0` -- Ensures that both the `nmn0` and `hsn0` interfaces are up. This is required for booting over the [High Speed Network (HSN)](../../glossary.md#high-speed-network-hsn).
* `hsn0` -- Ensures that the `hsn0` interface is up.

The DVS configuration files determine which interface to use (NMN or HSN). However, the CPS `dracut` ensures the that requested interfaces are up.

### Overriding configuration (BOS v2 only)

It is also possible to specify CFS configuration in the boot set. If specified, this will override whatever value is set in the base session template.
This feature is not supported for BOS v1.
