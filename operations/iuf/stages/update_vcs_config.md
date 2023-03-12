# `update-vcs-config`

The `update-vcs-config` stage performs a variety of update operations for each product being installed that provides a configuration management repository in VCS. It ensures new product configuration content has been uploaded to VCS in
a pristine branch and attempts to merge the new product configuration content into a corresponding customer branch.

**`NOTE`** After `update-vcs-config` has completed and before proceeding to additional stages, any desired site configuration customizations should be performed. Refer to individual product documentation for configuration customization details.

`update-vcs-config` details are explained in the following sections:

- [Impact](#impact)
- [Prerequisites](#prerequisites)
- [Terminology](#terminology)
- [Branch creation and modification](#branch-creation-and-modification)
- [Customer branch name](#customer-branch-name)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `update-vcs-config` stage does not change the running state of the system.

## Prerequisites

Before executing the `update-vcs-config` stage, ensure any desired site variables have been defined. [Site variables and/or recipe variables](../IUF.md#site-and-recipe-variables) are passed to `iuf` as parameters to customize
product, product version, and branch values used by IUF when executing stages such as `update-vcs-config`.

## Terminology

| Term                     | Example              | Meaning |
| ------------------------ | -------------------- | ------- |
| Pristine branch          | `cray/cos/2.4.79`    | The branch provided by HPE for a given product |
| Customer branch          | `integration-2.4.79` | The customer's working branch for a given product |
| Previous customer branch | `integration-2.3.50` | The latest existing customer branch for a given product which predates the specified customer branch |

## Branch creation and modification

The following describes how `update-vcs-config` determines how to create or merge VCS content to the customer branch:

- If no customer branch has been specified, `update-vcs-config` displays a warning, performs no operations, and exits without error. While it is valid not to specify a customer branch in certain cases, the administrator should
  verify that this is the desired behavior and that the VCS configuration and the corresponding CFS configurations to be used in the `update-cfs-config` stage match and are valid.
- If the specified customer branch exists, the content from the pristine branch will be merged into the customer branch.
- If the specified customer branch does not exist, `update-vcs-config` will attempt to identify branches that match the pattern of the customer branch, select the matching branch with the most recent version, and consider it the
  previous customer branch. The specified customer branch will be branched from the previous customer branch, and the content from the pristine branch will be merged into the specified customer branch.
- If the specified customer branch does not exist and a previous customer branch cannot be identified, the specified customer branch will be branched from the pristine branch.

`update-vcs-config` will display information describing the operations performed. In the case of an error, such as a merge conflict, error information will be displayed and `iuf` will exit so the administrator can resolve the issue.
Once it is resolved, the session can be continued with `iuf resume`, restarted with `iuf restart`, or abandoned with `iuf abort`.

**`NOTE`** Any product-specific stage hooks specified for `update-vcs-config` will also be executed and may also create or modify VCS content. Refer to individual product documentation for information on any stage hook operations performed by the product.

## Customer branch name

The customer branch name is determined through one or a combination of the following sources:

### Recipe variables

Recipe variables are provided via the `product_vars.yaml` file in the HPC CSM Software Recipe and provide a list of products and versions intended to be used together. `product_vars.yaml` also contains default settings and
`working_branch` variable entries for products. These values are intended as defaults and can be overridden with site variables.

Overall defaults are defined in default section of `product_vars.yaml`, for example:

```yaml
# set site specific default working_branch with an entry in a default section in site_vars.yaml
default:
  working_branch: "integration-{{version_x_y_z}}"
```

Each product that utilizes a working branch will contain a `working_branch` entry in `product_vars.yaml`, for example:

```yaml
cos:
  version: 2.4.86
  working_branch: "{{ working_branch }}"
```

In this example, the COS reference to `{{ working_branch}}` will be substituted with the value specified in the default section for `working_branch`. Thus, the COS value for `working_branch` will be `integration-{{version_x_y_z}}`,
which will in turn be substituted with the actual product value, resulting in the final value `integration-2.4.86`.

### Site variables

Site variables, typically specified in a `site_vars.yaml` file, allow the administrator to override values provided by recipe variables, including both default values and product-specific entries.

Variable substitutions can be used in `site_vars.yaml` to specify the desired branching values, minimizing the need to make updates to the file. For example, to change the working branch for all products that use a default
working branch, the administrator can simply provide a default section in `site_vars.yaml` with a new value for `working_branch`. In the following example, adding this section in `site_vars.yaml` will result in all products
using the default branch to only use the `x.y` portion of the version instead of the `x.y.z` values specified in the `product_vars.yaml` file.

```yaml
default:
  working_branch: "integration-{{version_x_y}}"
```

In a similar fashion, product-specific entries can be made in `site_vars.yaml` to override individual products, for example:

```yaml
cos:
  working_branch: "test-{{ version_x_y_z }}"
```

Remember that content in `site_vars.yaml` overrides entries in `product_vars.yaml`, e.g. if a product entry in `site_vars.yaml` contained a `version` entry, that value would mask the `version` entry present in `product_vars.yaml`.

### Session variables

Session variables are the set of product/version combinations being installed by the current activity. These values are internal to `iuf`.

### Mechanics

`iuf` builds a set of effective site variables utilized by back-end IUF operations by performing a set of merges and substitutions:

1. The base set of data is created from the most recent product entries in the product catalog.
1. Recipe variables, if specified, will be merged, overriding any matching entries. **Caveat**: Any product specified with the `iuf run` `--mask-recipe-prods` argument will be omitted from this merge, i.e. the version found in step 1 will be used instead.
1. Site variables, if specified, will be merged, overriding any matching entries.
1. Session variables will be merged, overriding any matching entries.

Once `iuf` has performed the merges, it performs substitutions based on the following supported variables:

```yaml
{{name}} - product name from the product manifest
{{version_x_y}} - x.y portion of the product version
{{version_x_y_z}} - x.y.z portion of the product version
{{working_branch}} - default working branch
```

## Input

The following arguments are most often used with the `update-vcs-config` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input                                  | `iuf` Argument              | Description   |
| -------------------------------------- | --------------------------- |-------------- |
| Activity                               | `-a ACTIVITY`               | Activity created for the install or upgrade operations |
| Site variables                         | `-sv SITE_VARS`             | Path to YAML file containing site defaults and any overrides |
| Recipe variables                       | `-rv RECIPE_VARS`           | Path to YAML file containing recipe variables provided by HPE |
| `sat bootprep` configuration directory | `-bpcd BOOTPREP_CONFIG_DIR` | Directory containing `sat bootprep` configuration files and recipe variables |

## Execution details

The code executed by this stage exists within IUF. See the `update-vcs-config` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `update-vcs-config` stage for activity `admin-230127` using the `/etc/cray/upgrade/csm/admin/site_vars.yaml` file and the `product_vars.yaml` file found in the `/etc/cray/upgrade/csm/admin` directory.

```bash
iuf -a admin-230127 run -sv /etc/cray/upgrade/csm/admin/site_vars.yaml -bpcd /etc/cray/upgrade/csm/admin -r update-vcs-config
```
