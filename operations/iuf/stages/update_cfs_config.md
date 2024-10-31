# `update-cfs-config`

The `update-cfs-config` stage creates updated CFS configurations used for image customization and personalization of management NCNs and managed (compute and application) nodes. This stage only creates the CFS configurations; the `prepare-images`,
`management-nodes-rollout`, and `management-nodes-rollout` stages executed after `update-cfs-config` use the CFS configurations.

The product content used to create the CFS configurations is defined in `sat bootprep` input files. The `sat bootprep` input files used can be specified by `-bc`, `-bm`, and/or `-bpcd` as described below. Variables within the `sat bootprep`
files can be substituted with values found in the recipe variables (`-rv`) and/or site variables (`-sv`) files.

**`NOTE`** Before `update-cfs-config` is executed, any desired site configuration customizations in VCS should be performed. Refer to individual product documentation for configuration customization details.

`update-cfs-config` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `update-cfs-config` stage does not change the running state of the system as it does not deploy the newly created CFS configurations; that is done by the `management-nodes-rollout` and `managed-nodes-rollout` stages.

## Input

The following arguments are most often used with the `update-cfs-config` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input                                         | `iuf` Argument                   | Description                                                                                           |
|-----------------------------------------------|----------------------------------|-------------------------------------------------------------------------------------------------------|
| Activity                                      | `-a ACTIVITY`                    | Activity created for the install or upgrade operations                                                |
| Managed `sat bootprep` configuration files    | `-bc BOOTPREP_CONFIG_MANAGED`    | The `sat bootprep` configuration file used for managed nodes                                          |
| Management `sat bootprep` configuration files | `-bm BOOTPREP_CONFIG_MANAGEMENT` | The `sat bootprep` configuration file used for management nodes                                       |
| `sat bootprep` configuration directory        | `-bpcd BOOTPREP_CONFIG_DIR`      | Directory containing `sat bootprep` configuration files and recipe variables                          |
| Recipe variables                              | `-rv RECIPE_VARS`                | Path to YAML file containing recipe variables provided by HPE                                         |
| Site variables                                | `-sv SITE_VARS`                  | Path to YAML file containing site defaults and any overrides                                          |
| Recipe variables product mask                 | `-mrp MASK_RECIPE_PRODS`         | Mask the recipe variables file entries for the products specified, use product catalog values instead |

## Execution details

The code executed by this stage utilizes `sat bootprep` to create CFS configurations. See the `update-cfs-config` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in
`/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

For more information, see [SAT Bootprep](../../../operations/system_admin_toolkit/usage/SAT_Bootprep.md).

## Example

(`ncn-m001#`) Execute the `update-cfs-config` stage for activity `admin-230127` using the `/etc/cray/upgrade/csm/admin/site_vars.yaml` file and the managed and management `sat bootprep` configuration files and the `product_vars.yaml`
configuration file found in the `/etc/cray/upgrade/csm/admin` directory.

```bash
iuf -a admin-230127 run -sv /etc/cray/upgrade/csm/admin/site_vars.yaml -bpcd /etc/cray/upgrade/csm/admin -r update-cfs-config
```
