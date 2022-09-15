# BOS Session Templates

Session templates are a reusable collection of boot, configuration, and component information.
After creation they can be combined with a boot operation to create a BOS session that will apply the desired changes to the specified components.
Session templates can be created via the API by providing JSON data or via the CLI by writing the JSON data to a file, which can then be referenced using the `--file` parameter.

## Structure of a session template

The following is an example BOS session template:

```json
{
  "name": "session-template-example",
  "description": "session template example", <<-- Optional description of the template
  "boot_sets": {
    "boot_set1": {
      "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node  oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999",
      "rootfs_provider": "cpss3",
      "node_list": [   <<-- List of individual nodes
        "x3000c0s19b1n0"
      ],
      "etag": "foo", <<-- Used to identify the version of the manifest.json file
      "path": "s3://boot-images/e06530f1-fde2-4ca5-9148-7e84f4857d17/manifest_sans_boot_parameters.json", <<-- The path to the manifest.json file in S3
      "rootfs_provider_passthrough": "66666666:dvs:api-gw-service-nmn.local:300:eth0",
      "type": "s3" <<-- Type of storage
    },
    "boot_set2": {
      // ...
    }
  },
  "cfs": {
      "configuration": "example-configuration" <<-- The name of the CFS configuration to apply
  },
  "enable_cfs": true, <<-- Invokes CFS
}
```

### Boot sets

BOS session templates contain one or more boot sets, which each contain information on the kernel parameters that nodes should boot with, as well as information on the nodes the boot set should apply to.
Optionally, with BOS v2, configuration information can also be overwritten on a per boot set basis.

#### Boot artifacts and S3

Boot sets specify a set of parameters that point to a `manifest.json` file stored in the Simple Storage Service \(S3\).  This file is created by IMS and contains links to all of the boot artifacts. The following S3 parameters are used to specify this file:

* type: This is the type of storage used. Currently, the only allowable value is `s3`.
* path: This is the path to the `manifest.json` file in S3. The path will follow the `s3://<BUCKET\_NAME\>/<KEY\_NAME\>` format.
* `etag`: This entity tag helps identify the version of the `manifest.json` file. Currently, it issues a warning if the manifest's `etag` does not match. This can be an empty string, but cannot be left blank.

This boot artifact information from the files stored in S3 is then written to the Boot Script Service \(BSS\) where it is retrieved when these nodes boot.

#### Specifying nodes

Each boot set also specifies a set of nodes to be applied to.  There are three different ways to specify the nodes. The `node_list`, `node_groups`, or `node_role` values can each be specified as a comma-separated list.

* **Node list**

    `node_list` value is a list of nodes identified by component `xnames`.

    For example:

    ```bash
    "node_list": ["x3000c0s19b1n0", "x3000c0s19b1n1", "x3000c0s19b2n0"]
    ```

* **Node groups**

    `node_groups` is a list of groups defined by the Hardware State Manager \(HSM\). Each group may contain zero or more nodes. Groups can be arbitrarily defined by users.

    For example:

    ```bash
    "node_groups": ["green", "white", "pink"]
    ```

    (`ncn-mw#`) To retrieve the current list of HSM groups, run following command:

    ```bash
    cray hsm groups list --format json | jq .[].label
    ```

* **Node roles groups**

    `node_roles_groups` is a list of groups based on a node's designated role. Each node's role is specified in the HSM database. `node_roles_groups` also supports node sub-roles, which are specified as a combination of the node role and sub-role.  e.g. `Application_UAN`

    For example:

    ```bash
    "node_roles_groups": ["Compute"]
    ```

    See [HSM Roles and Subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md) for more information.

    Consult the `cray-hms-base-config` Kubernetes ConfigMap in the `services` namespace for a listing of the available roles and sub-roles on the system.

#### Overriding configuration (V2 only)

It is also possible to specify CFS configuration in the boot set.  If specified, this will override whatever value is set in the base session template.
