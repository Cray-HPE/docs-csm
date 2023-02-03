# `prepare-images`

The `prepare-images` stage configures NCN management node images and builds and configures compute node, application node, and GPU images. It also creates new BOS session templates corresponding to the new node and image content.
The `prepare-images` stage does not reboot nodes to the new images; however, that is done by the `management-nodes-rollout` and `managed-nodes-rollout` stages.

The product content used to create the images is defined in `sat bootprep` input files. The `sat bootprep` input files used can be specified by `-bc`, `-bm`, and/or `-bpcd` as described below. Variables within the `sat bootprep`
files can be substituted with values found in the recipe variables (`-rv`) and/or site variables (`-sv`) files.

`prepare-images` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `prepare-images` stage does not change the running state of the system as it does not deploy the newly created images; that is done by the `management-nodes-rollout` and `managed-nodes-rollout` stages.

## Input

The following arguments are most often used with the `prepare-images` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input                                         | `iuf` Argument                   | Description                                                                                           |
| --------------------------------------------- | -------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Activity                                      | `-a ACTIVITY`                    | Activity created for the install or upgrade operations                                                |
| Managed `sat bootprep` configuration files    | `-bc BOOTPREP_CONFIG_MANAGED`    | List of `sat bootprep` configuration files used for managed images                                    |
| Management `sat bootprep` configuration files | `-bm BOOTPREP_CONFIG_MANAGEMENT` | List of `sat bootprep` configuration files used for management NCN images                             |
| `sat bootprep` configuration directory        | `-bpcd BOOTPREP_CONFIG_DIR`      | Directory containing `sat bootprep` configuration files and recipe variables                          |
| Recipe variables                              | `-rv RECIPE_VARS`                | Path to YAML file containing recipe variables provided by HPE                                         |
| Site variables                                | `-sv SITE_VARS`                  | Path to YAML file containing site defaults and any overrides                                          |
| Recipe variables product mask                 | `-mrp MASK_RECIPE_PRODS`         | Mask the recipe variables file entries for the products specified, use product catalog values instead |

## Execution details

The code executed by this stage utilizes `sat bootprep` to build and customize images. See the `prepare-images` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

See the [HPE Cray EX System Admin Toolkit (SAT) Guide](https://cray-hpe.github.io/docs-sat/) documentation for details on `sat bootprep`.

## Example

(`ncn-m001#`) Execute the `prepare-images` stage for activity `admin-230127` using the specified `site_vars.yaml` file and the managed and management `sat bootprep` configuration files and the `product_vars.yaml` configuration file
found in the `hpc-csm-software-recipe-23.05.0/vcs` directory of the 23.05.0 HPC CSM Software Recipe distribution file.

```bash
iuf -a admin-230127 run -sv ./site_vars.yaml -bpcd ./hpc-csm-software-recipe-23.05.0/vcs -r prepare-images
```
