# prepare-images

The `prepare-images` stage configures NCN management node images and builds and configures compute node, application node, and GPU images. It also creates new BOS session templates corresponding to the new node and image content.
The `prepare-images` stage does not reboot nodes to the new images; however, that is done by the `management-nodes-rollout` and `managed-nodes-rollout` stages.

The product content used to create the images is defined in `sat bootprep` input files. The `sat bootprep` input files used can be specified by `-bc`, `-bm`, and/or `-bpcd` as described below. Variables within the `sat bootprep`
files can be substituted with values found in the recipe variables (`-rv`) and/or site variables (`-sv`) files.

`prepare-images` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution Details](#execution-details)
- [Example](#example)

## Impact

The `prepare-images` stage does not change the running state of the system as it does not deploy the newly created images; that is done by the `management-nodes-rollout` and `managed-nodes-rollout` stages.

## Input

The following arguments are most often used with the `prepare-images` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input                                  | `iuf` Argument                   | Description                                                                                           |
| -------------------------------------- | -------------------------------- | ----------------------------------------------------------------------------------------------------- |
| activity                               | `-a ACTIVITY`                    | activity created for the install or upgrade operations                                                |
| managed `sat bootprep` config files    | `-bc BOOTPREP_CONFIG_MANAGED`    | list of `sat bootprep` config files used for managed images                                           |
| management `sat bootprep` config files | `-bm BOOTPREP_CONFIG_MANAGEMENT` | list of `sat bootprep` config files used for management NCN images                                    |
| `sat bootprep` config directory        | `-bpcd BOOTPREP_CONFIG_DIR`      | directory containing `sat bootprep` config files and recipe variables                                 |
| recipe variables                       | `-rv RECIPE_VARS`                | path to YAML file containing recipe variables file provided by HPE                                    |
| site variables                         | `-sv SITE_VARS`                  | path to YAML file containing site defaults and any overrides                                          |
| recipe variables product mask          | `-mrp MASK_RECIPE_PRODS`         | mask the recipe variables file entries for the products specified, use product catalog values instead |

## Execution Details

The code executed by this stage utilizes `sat bootprep` to build and customize images. See the `prepare-images` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

See the [HPE Cray EX System Admin Toolkit (SAT) Guide](https://cray-hpe.github.io/docs-sat/) documentation for details on `sat bootprep`.

## Example

(`ncn-m001#`) Execute the `prepare-images` stage for activity `admin-230127` using the specified `site_vars.yaml` file and the managed and management `sat bootprep` config files and the `product_vars.yaml` config file
found in the `hpc-csm-software-recipe-23.05.0/vcs` directory of the 23.05.0 HPC CSM Software Recipe distribution file.

```bash
iuf -a admin-230127 run -sv ./site_vars.yaml -bpcd ./hpc-csm-software-recipe-23.05.0/vcs -r prepare-images
```
