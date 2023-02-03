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
| --------------------------------------------- | -------------------------------- | ----------------------------------------------------------------------------------------------------- |
| activity                                      | `-a ACTIVITY`                    | activity created for the install or upgrade operations                                                |
| managed `sat bootprep` configuration files    | `-bc BOOTPREP_CONFIG_MANAGED`    | list of `sat bootprep` configuration files used for managed images                                    |
| management `sat bootprep` configuration files | `-bm BOOTPREP_CONFIG_MANAGEMENT` | list of `sat bootprep` configuration files used for management NCN images                             |
| `sat bootprep` configuration directory        | `-bpcd BOOTPREP_CONFIG_DIR`      | directory containing `sat bootprep` configuration files and recipe variables                          |
| recipe variables                              | `-rv RECIPE_VARS`                | path to YAML file containing recipe variables file provided by HPE                                    |
| site variables                                | `-sv SITE_VARS`                  | path to YAML file containing site defaults and any overrides                                          |
| recipe variables product mask                 | `-mrp MASK_RECIPE_PRODS`         | mask the recipe variables file entries for the products specified, use product catalog values instead |

## Execution details

The code executed by this stage utilizes `sat bootprep` to create CFS configurations. See the `update-cfs-config` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in
`/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

See the [HPE Cray EX System Admin Toolkit (SAT) Guide](https://cray-hpe.github.io/docs-sat/) documentation for details on `sat bootprep`.

## Example

(`ncn-m001#`) Execute the `update-cfs-config` stage for activity `admin-230127` using the specified `site_vars.yaml` file and the managed and management `sat bootprep` configuration files and the `product_vars.yaml` configuration file
found in the `hpc-csm-software-recipe-23.05.0/vcs` directory of the 23.05.0 HPC CSM Software Recipe distribution file.

```bash
iuf -a admin-230127 run -sv ./site_vars.yaml -bpcd ./hpc-csm-software-recipe-23.05.0/vcs -r update-cfs-config
```
