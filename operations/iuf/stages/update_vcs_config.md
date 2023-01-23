# update-vcs-config

The `update-vcs-config` stage performs a variety of update operations for each product being installed that provides a configuration management repository in VCS. It ensures new product configuration content has been uploaded to VCS in
a pristine branch and attempts to merge the new product configuration content into a corresponding customer branch.

**`NOTE`** After `update-vcs-config` has completed and before proceeding to additional stages, any desired site configuration customizations should be performed. Refer to individual product documentation for configuration customization details.

`update-vcs-config` details are explained in the following sections:

- [Impact](#impact)
- [Prerequisites](#prerequisites)
- [Terminology](#terminology)
- [Branch Creation and Modification](#branch-creation-and-modification)
- [Customer Branch Name](#customer-branch-name)
- [Input](#input)
- [Execution Details](#execution-details)
- [Example](#example)

## Impact

The `update-vcs-config` stage does not change the running state of the system.

## Prerequisites

Before executing the `update-vcs-config` stage, ensure any desired site variables have been defined. [Site variables and/or recipe variables](../IUF.md#site-and-recipe-variables) are passed to `iuf` as parameters to customize
product, product version, and branch values used by IUF when executing stages such as `update-vcs-config`.

## Terminology

- **Pristine branch**: the branch provided by HPE for a given product, e.g. `cray/cos/2.4.79`
- **Customer branch**: the customer's working branch for a given product, e.g. `integration-2.4.79`
- **Previous customer branch**: the latest existing customer branch for a given product which predates the specified customer branch, e.g. `integration-2.3.50`

## Branch Creation and Modification

The following describes how `update-vcs-config` determines how to create or merge VCS content to the customer branch:

- If no customer branch has been specified, `update-vcs-config` with display a warning, perform no operations, and exits without error. While it is valid not to specify a customer branch in certain cases, the administrator should
  verify that this is the desired behavior and that the VCS configuration and the corresponding CFS configurations to be used in the `update-cfs-config` stage match and are valid.
- If the specified customer branch exists, the content from the pristine branch will be merged into the customer branch.
- If the specified customer branch does not exist, `update-vcs-config` will attempt to identify branches that matches the pattern of the customer branch, select the matching branch with the most recent version, and consider it the
  previous customer branch. The specified customer branch will be branched from the previous customer branch, and the content from the pristine branch will be merged into the specified customer branch.
- If the specified customer branch does not exist and a previous customer branch cannot be identified, the specified customer branch will be branched from the pristine branch.

`update-vcs-config` will display information describing the operations performed. In the case of an error, such as a merge conflict, error information will be displayed and `iuf` will exit so the administrator can resolve the issue.
Once it is resolved, the session can be continued with `iuf resume` or can be abandoned with `iuf abort`.

**`NOTE`** Any product-specific stage hooks specified for `update-vcs-config` will also be executed and may also create or modify VCS content. Refer to individual product documentation for information on any stage hook operations performed by the product.

## Customer Branch Name

The customer branch name is determined through one or a combination of the following sources:

### Recipe Variables

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

### Site Variables

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

### Session Variables

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
{{version}} - version from the product manifest
{{version_x_y}} - x.y portion of the product version
{{version_x_y_z}} - x.y.z portion of the product version
{{working_branch}} - default working branch
```

## Input

The following arguments are most often used with the `update-vcs-config` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input            | `iuf` Argument | Description   |
| ---------------- | -------------- |-------------- |
| activity         | `-a ACTIVITY`  | activity created for the install or upgrade operations |
| site variables   | `--site-vars`  | path to YAML file containing site defaults and any overrides |
| recipe variables | `--bootprep-config-dir` | Path to `vcs` directory within the expanded HPC CSM Software Recipe product distribution file. If no `sat bootprep` related arguments are supplied, a copy of the contents from VCS will be used if present. |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `update-vcs-config` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Run all stages up to and including `update-vcs-config` using the specified `site_vars.yaml` file and the `product_vars.yaml` file found in the `hpc-csm-software-recipe-23.03.0/vcs` directory of the 22.03.0 HPC CSM Software Recipe distribution file.

```bash
iuf -a test-activity-20230123 -m /etc/cray/upgrade/csm/test-activity-20230123 run --site-vars /etc/cray/upgrade/csm/iuf/site_vars.yaml --bootprep-config-dir /etc/cray/upgrade/csm/test-activity-20230123/hpc-csm-software-recipe-23.03.0/vcs -e update-vcs-config
```
