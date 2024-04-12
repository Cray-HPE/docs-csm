# SAT Bootprep

SAT provides an automated solution for creating CFS configurations, building
and configuring images in IMS, and creating BOS session templates. The
solution is based on a given input file that defines how those configurations,
images, and session templates should be created. This automated process centers
around the `sat bootprep` command. `man` page documentation for `sat bootprep`
can be viewed similar to other SAT commands.

(`ncn-m001#`) Here is an example:

```bash
sat-man sat-bootprep
```

The `sat bootprep` command helps the Install and Upgrade Framework (IUF)
install, upgrade, and deploy products on systems managed by CSM. Outside of IUF,
it is uncommon to use `sat bootprep`. For more information on this relationship,
see [SAT and IUF](SAT_and_IUF.md). For more information on IUF, see
[Install and Upgrade Framework](../../iuf/IUF.md).

## SAT `bootprep` vs SAT `bootsys`

`sat bootprep` is used to create CFS configurations, build and
rename IMS images, and create BOS session templates which tie the
configurations and images together during a BOS session.

`sat bootsys` automates several portions of the boot and shutdown processes,
including (but not limited to) performing BOS operations (such as creating BOS
sessions), powering on and off cabinets, and checking the state of the system
prior to shutdown.

## Edit a `bootprep` input file

The input file provided to `sat bootprep` is a YAML file containing information
which CFS, IMS, and BOS use to create configurations, images, and BOS session
templates respectively. Writing and modifying these input files is the main task
associated with using `sat bootprep`. An input file is composed of three main
sections, one each for configurations, images, and session templates. These
sections may be specified in any order, and any of the sections may be omitted
if desired.

### Provide a schema version

The `sat bootprep` input file is validated against a versioned schema
definition. The input file should specify the version of the schema with which
it is compatible under a `schema_version` key. For example:

```yaml
---
schema_version: 1.0.2
```

(`ncn-m001#`) The current `sat bootprep` input file schema version can be viewed with the
following command:

```bash
sat bootprep view-schema | grep '^version:'
```

Example output:

```text
version: '1.0.2'
```

The `sat bootprep run` command validates the schema version specified
in the input file. The command also makes sure that the schema version
of the input file is compatible with the schema version understood by the
current version of `sat bootprep`. For more information on schema version
validation, refer to the `schema_version` property description in the bootprep
input file schema. For more information on viewing the bootprep input file
schema in either raw form or user-friendly HTML form, see [View SAT Bootprep
Schema](#view-sat-bootprep-schema).

The default HPC CSM Software Recipe bootprep input files provided by the
`hpc-csm-software-recipe` release distribution already contain the correct
schema version.

### Define CFS configurations

The CFS configurations are defined under a `configurations` key. Under this
key, list one or more configurations to create. For each
configuration, give a name in addition to the list of layers that
comprise the configuration.

Each layer can be defined by a product name and optionally a version number,
commit hash, or branch in the product's configuration repository. If this
method is used, the layer is created in CFS by looking up relevant configuration
information (including the configuration repository and commit information) from
the `cray-product-catalog` Kubernetes ConfigMap as necessary. A version may be
supplied. However, if it is absent, the version is assumed to be the latest
version found in the `cray-product-catalog`.

Alternatively, a configuration layer can be defined by explicitly referencing
the desired configuration repository. Specify the intended version
of the Ansible playbooks by providing a branch name or commit hash with `branch`
or `commit`.

The following example shows a CFS configuration with two layers. The first
layer is defined in terms of a product name and version, and the second layer
is defined in terms of a Git clone URL and branch:

```yaml
---
configurations:
- name: example-configuration
  layers:
  - name: example-product
    playbook: example.yml
    product:
      name: example
      version: 1.2.3
  - name: another-example-product
    playbook: another-example.yml
    git:
      url: "https://vcs.local/vcs/another-example-config-management.git"
      branch: main
```

When `sat bootprep` is run against an input file, a CFS configuration is created
corresponding to each configuration in the `configurations` section. For
example, the configuration created from an input file with the layers listed
above might look something like the following:

```json
{
    "lastUpdated": "2022-02-07T21:47:49Z",
    "layers": [
        {
            "cloneUrl": "https://vcs.local/vcs/example-config-management.git",
            "commit": "<commit hash>",
            "name": "example product",
            "playbook": "example.yml"
        },
        {
            "cloneUrl": "https://vcs.local/vcs/another-example-config-management.git",
            "commit": "<commit hash>",
            "name": "another example product",
            "playbook": "another-example.yml"
        }
    ],
    "name": "example-configuration"
}
```

### Define IMS images

The IMS images are defined under an `images` key. Under the `images` key, the
user may define one or more images to be created in a list. Each element of the
list defines a separate IMS image to be built and/or configured. Images must
contain a `name` key and a `base` key.

The `name` key defines the name of the resulting IMS image. The `base` key
defines the base image to be configured or the base recipe to be built and
optionally configured. One of the following keys must be present under the
`base` key:

- Use an `ims` key to specify an existing image or recipe in IMS.
- Use a `product` key to specify an image or recipe provided by a particular
  version of a product. If a product provides more than one image or recipe,
  specify a filter to select one. For more information, see
  [Filter Base Images or Recipes from a Product](#filter-base-images-or-recipes-from-a-product).
- Use an `image_ref` key to specify another image from the input file
  using its `ref_name`.

Images may also contain the following keys:

- Use a `configuration` key to specify a CFS configuration with which to
  customize the built image. If a configuration is specified, then configuration
  groups must also be specified using the `configuration_group_names` key.
- Use a `ref_name` key to specify a unique name that can refer to this image
  within the input file in other images or in session templates. The `ref_name`
  key allows references to images from the input file that have dynamically
  generated names as described in
  [Dynamic Variable Substitutions](#dynamic-variable-substitutions).
- Use a `description` key to describe the image in the bootprep input file.
  Note that this key is not currently used.

#### Use base images or recipes from IMS

Here is an example of an image using an existing IMS recipe as its base. This
example builds an IMS image from that recipe. It then configures it with
a CFS configuration named `example-compute-config`. The `example-compute-config`
CFS configuration can be defined under the `configurations` key in the same
input file, or it can be an existing CFS configuration. Running `sat bootprep`
against this input file results in an image named `example-compute-image`.

```yaml
images:
- name: example-compute-image
  description: >
    An example compute node image built from an existing IMS recipe.
  base:
    ims:
      name: example-compute-image-recipe
      type: recipe
  configuration: example-compute-config
  configuration_group_names:
  - Compute
```

#### Use base images or recipes from a product

Here is an example showing the definition of two images. The first image is
built from a recipe provided by the `cne` product. The second image uses the
first image as a base and configures it with a configuration named
`example-compute-config`. The value of the first image's `ref_name` key is used
in the second image's `base.image_ref` key to specify it as a dependency.
Running `sat bootprep` against this input file results in two images, the
first named `example-cne-image` and the second named `example-compute-image`.

```yaml
images:
- name: example-cne-image
  ref_name: example-cne-image
  description: >
    An example image built from the recipe provided by the CNE product.
  base:
    product:
      name: cne
      version: 1.0.0
      type: recipe
- name: example-compute-image
  description: >
    An example image that is configured from an image built from the recipe provided
    by the CNE product.
  base:
    image_ref: example-cne-image
  configuration: example-compute-config
  configuration_group_names:
  - Compute
```

This example assumes that the given version of the `cne` product provides
only a single IMS recipe. If more than one recipe is provided by the
given version of the `cne` product, use a filter as described in
[Filter Base Images or Recipes from a Product](#filter-base-images-or-recipes-from-a-product).

#### Filter base images or recipes from a product

A product may provide more than one image or recipe. If this happens,
filter the product's images or recipes whenever a base image or recipe from
that product is used. Beneath the `base.product` value within an image,
specify a `filter` key to create a filter using the following criteria:

- Use the `prefix` key to filter based on a prefix matching the name of the
  image or recipe.
- Use the `wildcard` key to filter based on a shell-style wildcard matching the
  name of the image or recipe.
- Use the `arch` key to filter based on the target architecture of the image or
  recipe in IMS.

When specifying more than one filter key, all filters must match only the
desired image or recipe. An error occurs if either no images or recipes
match the given filters or if more than one image or recipe matches
the given filters.

Here is an example of three IMS images built from the Kubernetes image and the
Ceph storage image provided by the `csm` product. This example uses a prefix
filter to select from the multiple images provided by the CSM product.
The first two IMS images in the example find any image from the specified `csm`
product version whose name starts with `secure-kubernetes`. The third image in
the example finds any `csm` image whose name starts with `secure-storage-ceph`.
All three images are then configured with a configuration named
`example-management-config`. Running `sat bootprep` against this input file
results in three IMS images named `worker-example-csm-image`,
`master-example-csm-image`, and `storage-example-csm-image`.

```yaml
images:
- name: worker-example-csm-image
  base:
    product:
      name: csm
      version: 1.4.1
      type: image
      filter:
        prefix: secure-kubernetes
  configuration: example-management-config
  configuration_group_names:
  - Management_Worker

- name: master-example-csm-image
  base:
    product:
      name: csm
      version: 1.4.1
      type: image
      filter:
        prefix: secure-kubernetes
  configuration: example-management-config
  configuration_group_names:
  - Management_Master

- name: storage-example-csm-image
  base:
    product:
      name: csm
      version: 1.4.1
      type: image
      filter:
        prefix: secure-storage-ceph
  configuration: example-management-config
  configuration_group_names:
  - Management_Storage
```

Here is an example of two IMS images built from recipes provided by the `cne`
product. This example uses an architecture filter to select from the multiple
recipes provided by the CNE product. The first image will be built from the
`x86_64` version of the IMS recipe provided by the specified version of the
`cne` product. The second image will be built from the `aarch64` version of
the IMS recipe provided by the specified version of the `cne` product.

```yaml
images:
- name: example-cne-image-x86_64
  ref_name: example-cne-image-x86_64
  description: >
    An example image built from the x86_64 recipe provided by the CNE product.
  base:
    product:
      name: cne
      version: 1.0.0
      type: recipe
      filter:
        arch: x86_64

- name: example-cne-image-aarch64
  ref_name: example-cne-image-aarch64
  description: >
    An example image built from the aarch64 recipe provided by the CNE product.
  base:
    product:
      name: cne
      version: 1.0.0
      type: recipe
      filter:
        arch: aarch64
```

### Define BOS session templates

The BOS session templates are defined under the `session_templates` key. Each
session template must provide values for the `name`, `image`, `configuration`,
and `bos_parameters` keys. The `name` key defines the name of the resulting BOS
session template. The `image` key defines the image to use in the BOS session
template. One of the following keys must be present under the `image` key:

- Use an `ims` key to specify an existing image or recipe in IMS.
- Use an `image_ref` key to specify another image from the input file
  using its `ref_name`.

The `configuration` key defines the CFS configuration specified
in the BOS session template.

The `bos_parameters` key defines parameters that are passed through directly to
the BOS session template. The `bos_parameters` key should contain a `boot_sets`
key, and each boot set in the session template should be specified under
`boot_sets`. Each boot set can contain the following keys, all of
which are optional:

- Use an `arch` key to specify the architecture of the nodes that should be
  targeted by the boot set. Valid values are the same as those used by
  Hardware State Manager (HSM).
- Use a `kernel_parameters` key to specify the parameters passed to the kernel
  on the command line.
- Use a `network` key to specify the network over which the nodes boot.
- Use a `node_list` key to specify the nodes to add to the boot set.
- Use a `node_roles_groups` key to specify the HSM roles to add to the boot
  set.
- Use a `node_groups` key to specify the HSM groups to add to the boot set.
- Use a `rootfs_provider` key to specify the root file system provider.
- Use a `rootfs_provider_passthrough` key to specify the parameters to add to
  the `rootfs=` kernel parameter.

As mentioned above, the parameters under `bos_parameters` are passed through
directly to BOS. For more information on the properties of a BOS boot set,
refer to [BOS Session Templates](../../boot_orchestration/Session_Templates.md).

Here is an example of a BOS session template that refers to an existing IMS
image by name and targets nodes with the role `Compute` and the architecture
`X86` in HSM:

```yaml
session_templates:
- name: example-session-template
  image:
    ims:
      name: example-image
  configuration: example-configuration
  bos_parameters:
    boot_sets:
      example_boot_set:
        arch: X86
        kernel_parameters: ip=dhcp quiet
        node_roles_groups:
        - Compute
        rootfs_provider: cpss3
        rootfs_provider_passthrough: dvs:api-gw-service-nmn.local:300:nmn0
```

Here is an example of a BOS session template that refers to an image from the
input file by its `ref_name` and targets nodes with the role `Compute` and the
architecture `ARM` in HSM. Note that using the `image_ref` key requires that
an image defined in the input file specifies `example-image` as the value of
its `ref_name` key.

```yaml
session_templates:
- name: example-session-template
  image:
    image_ref: example-image
  configuration: example-configuration
  bos_parameters:
    boot_sets:
      example_boot_set:
        arch: ARM
        kernel_parameters: ip=dhcp quiet
        node_roles_groups:
        - Compute
        rootfs_provider: cpss3
        rootfs_provider_passthrough: dvs:api-gw-service-nmn.local:300:nmn0
```

### HPC CSM Software Recipe variable substitutions

The `sat bootprep` command takes any variables provided and substitutes them
into the input file. Variables are sourced from the command line, any variable
files directly provided, and the HPC CSM Software Recipe files used, in that
order. When providing values through a variable file, `sat bootprep`
substitutes the values with Jinja2 template syntax. The HPC CSM Software Recipe
provides default variables in a `product_vars.yaml` variable file. This file
defines information about each HPC software product included in the recipe.

Variables are primarily substituted into the default HPC CSM Software Recipe
bootprep input files through IUF. However, variable files can also be given to
`sat bootprep` directly from IUF's use of the recipe. When using variables
directly with `sat bootprep`, there are some limitations. For more
information on SAT variable limitations, see [SAT and IUF](SAT_and_IUF.md).
For more information on IUF and variable substitutions, see
[Install and Upgrade Framework](../../iuf/IUF.md).

#### Select an HPC CSM Software Recipe version

View a listing of the default HPC CSM Software Recipe variables and
their values by running `sat bootprep list-vars`. For more information on
options that can be used with the `list-vars` subcommand, refer to the man page
for the `sat bootprep` subcommand.

By default, the `sat bootprep` command uses the variables from the latest
installed version of the HPC CSM Software Recipe. Override this with the
`--recipe-version` command line argument to `sat bootprep run`.

(`ncn-m001#`) For example, to explicitly select the `22.11.0` version of the HPC CSM Software
Recipe default variables, specify `--recipe-version 22.11.0`:

```bash
sat bootprep run --recipe-version 22.11.0 compute-and-uan-bootprep.yaml
```

#### Values supporting Jinja2 template rendering

The entire `sat bootprep` input file is not rendered by the Jinja2 template
engine. Jinja2 template rendering of the input file is performed individually
for each supported value. The values of the following keys in the bootprep
input file support rendering as a Jinja2 template and thus support variables:

- The `name` key of each configuration under the `configurations` key.
- The following keys of each layer under the `layers` key in a
  configuration:
  - `name`
  - `playbook`
  - `git.branch`
  - `product.version`
  - `product.branch`
- The following keys of each image under the `images` key:
  - `name`
  - `base.product.version`
  - `base.product.filter.arch`
  - `base.product.filter.prefix`
  - `base.product.filter.wildcard`
  - `configuration`
- The following keys of each session template under the
  `session_templates` key:
  - `name`
  - `configuration`

Jinja2 built-in filters may be used in values of any of the keys listed above.
(**Note:** When the value of a key in the bootprep input file is a Jinja2
expression, it must be quoted to pass YAML syntax checking.)

In addition, Python string methods can be called on the string variables.

#### Hyphens in HPC CSM Software Recipe variables

Variable names with hyphens are not allowed in Jinja2 expressions because they
are parsed as an arithmetic expression instead of a single variable. To support
product names with hyphens, `sat bootprep` converts hyphens to underscores in
all top-level keys of the default HPC CSM Software Recipe variables. It also
converts any variables sourced from the command line or any variable files
provided directly. When referring to a variable with hyphens in the bootprep
input file, keep this in mind. For example, to refer to the product version
variable for `slingshot-host-software` in the bootprep input file, write
`"{{slingshot_host_software.version}}"`.

#### HPC CSM Software Recipe variable substitution example

The following example bootprep input file shows how a variable of a CNE version
can be used in an input file that creates a CFS configuration for computes.
Only one layer is shown for brevity.

```yaml
---
configurations:
- name: "{{default.note}}compute-{{recipe.version}}{{default.suffix}}"
  layers:
  - name: cne-compute-{{cne.working_branch}}
    playbook: cos-compute.yml
    product:
      name: cne
      version: "{{cne.version}}"
      branch: "{{cne.working_branch}}"
```

**Note:** When the value of a key in the bootprep input file is a Jinja2
expression, it must be quoted to pass YAML syntax checking.

Jinja2 expressions can also use filters and Python's built-in string methods to
manipulate the variable values. For example, suppose only the major and minor
components of a CNE version are to be used in the branch name for the CNE
layer of the CFS configuration. Use the `split` string method to
achieve this as follows:

```yaml
---
configurations:
- name: "{{default.note}}compute-{{recipe.version}}{{default.suffix}}"
  layers:
  - name: cne-compute-{{cne.working_branch}}
    playbook: cos-compute.yml
    product:
      name: cne
      version: "{{cne.version}}"
      branch: integration-{{cne.version.split('.')[0]}}-{{cne.version.split('.')[1]}}
```

### Dynamic variable substitutions

Additional variables are available besides the default variables provided by
the HPC CSM Software Recipe. (For more information, see [HPC CSM Software
Recipe Variable Substitutions](#hpc-csm-software-recipe-variable-substitutions).)
These additional variables are dynamic because their values are determined
at run-time based on the context in which they appear. Available dynamic
variables include the following:

- The variable `base.name` can be used in the `name` of an image under the
  `images` key. The value of this variable is the name of the IMS image or
  recipe used as the base of this image.
- The variable `image.name` can be used in the `name` of a session template
  under the `session_templates` key. The value of this variable is the name of
  the IMS image used in this session template.

  **Note:** The name of a session template is restricted to 45 characters. Keep
  this in mind when using `image.name` in the name of a session template.

These variables reduce the need to duplicate values throughout the `sat
bootprep` input file and make the following use cases possible:

- Building an image from a recipe provided by a product and using the
  name of the recipe in the name of the resulting image
- Using the name of the image in the name of a session template when
  the image is generated as described in the previous use case

## Example `bootprep` input files

This section provides an example bootprep input file. It also gives
instructions for obtaining the default bootprep input files delivered
with a release of the HPC CSM Software Recipe.

### Example `bootprep` input file

The following bootprep input file provides an example of using most of the
features described in previous sections. It is not intended to be a complete
bootprep file for the entire CSM product.

```yaml
---
configurations:
- name: "{{default.note}}compute-{{recipe.version}}{{default.suffix}}"
  layers:
  - name: cne-compute-{{cne.working_branch}}
    playbook: cos-compute.yml
    product:
      name: cne
      version: "{{cne.version}}"
      branch: "{{cne.working_branch}}"
  - name: cpe-pe_deploy-{{cpe.working_branch}}
    playbook: pe_deploy.yml
    product:
      name: cpe
      version: "{{cpe.version}}"
      branch: "{{cpe.working_branch}}"

images:
- name: "{{default.note}}{{base.name}}{{default.suffix}}"
  ref_name: base_cne_image
  base:
    product:
      name: cne
      type: recipe
      version: "{{cne.version}}"

- name: "compute-{{base.name}}"
  ref_name: compute_image
  base:
    image_ref: base_cne_image
  configuration: "{{default.note}}compute-{{recipe.version}}{{default.suffix}}"
  configuration_group_names:
  - Compute

session_templates:
- name: "{{default.note}}compute-{{recipe.version}}{{default.suffix}}"
  image:
    image_ref: compute_image
  configuration: "{{default.note}}compute-{{recipe.version}}{{default.suffix}}"
  bos_parameters:
    boot_sets:
      compute:
        kernel_parameters: ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN}
        node_roles_groups:
        - Compute
        rootfs_provider_passthrough: "dvs:api-gw-service-nmn.local:300:hsn0,nmn0:0"
```

### Access default `bootprep` input files

Default `bootprep` input files are delivered by the HPC CSM Software Recipe product. Access these
files by cloning the `hpc-csm-software-recipe` repository, as described in
[Accessing `sat bootprep` files](../../configuration_management/Accessing_Sat_Bootprep_Files.md).

(`ncn-m001#`) Find the default input files in the `bootprep` directory of the
cloned repository:

```bash
ls bootprep/
```

### Generate an example `bootprep` input file

The `sat bootprep generate-example` command was not updated for
recent bootprep schema changes. It is recommended to instead use the
default bootprep input files described in [Access Default Bootprep Input
Files](#access-default-bootprep-input-files). The `sat bootprep
generate-example` command will be updated in a future release of SAT.

## Summary of SAT `bootprep` results

The `sat bootprep run` command uses information from the bootprep input file to
create CFS configurations, IMS images, and BOS session templates. For easy
reference, the command also includes output summarizing the final creation
results.

(`ncn-m001#`) Here is a sample table output after running `sat bootprep run`:

```text
################################################################################
CFS configurations
################################################################################
+------------------+
| name             |
+------------------+
| example-config-1 |
| example-config-2 |
+------------------+
################################################################################
IMS images
################################################################################
+---------------+--------------------------------------+--------------------------------------+----------------+----------------------------+
| name          | preconfigured_image_id               | final_image_id                       | configuration  | configuration_group_names  |
+---------------+--------------------------------------+--------------------------------------+----------------+----------------------------+
| example-image | c1bcaf00-109d-470f-b665-e7b37dedb62f | a22fb912-22be-449b-a51b-081af2d7aff6 | example-config | Compute                    |
+---------------+--------------------------------------+--------------------------------------+----------------+----------------------------+
################################################################################
BOS session templates
################################################################################
+------------------+----------------+
| name             | configuration  |
+------------------+----------------+
| example-template | example-config |
+------------------+----------------+
```

## View SAT `bootprep` schema

The contents of the YAML input files used by `sat bootprep` must conform to a
schema which defines the structure of the data. The schema definition is written
using the JSON Schema format. (Although the format is named "JSON Schema", the
schema itself is written in YAML as well.) More information, including introductory
materials and a formal specification of the JSON Schema metaschema, can be found
[on the JSON Schema website](https://json-schema.org/specification.html).

### View the exact schema specification

(`ncn-m001#`) To view the exact schema specification, run `sat bootprep view-schema`.

```bash
sat bootprep view-schema
---
$schema: "https://json-schema.org/draft/2020-12/schema"
```

Beginning of example output:

```yaml
title: Bootprep Input File
description: >
  A description of the set of CFS configurations to create, the set of IMS
  images to create and optionally customize with the defined CFS configurations,
  and the set of BOS session templates to create that reference the defined
  images and configurations.
type: object
additionalProperties: false
```

### Generate user-friendly documentation

The raw schema definition can be difficult to understand without experience
working with JSON Schema specifications. For this reason, a feature is included
with `sat bootprep` that generates user-friendly HTML documentation for the input
file schema. This HTML documentation can be browsed with a web browser.

1. (`ncn-m001#`) Create a documentation tarball using `sat bootprep`.

   ```bash
   sat bootprep generate-docs
   ```

   Example output:

   ```text
   INFO: Wrote input schema documentation to /root/bootprep-schema-docs.tar.gz
   ```

   An alternate output directory can be specified with the `--output-dir`
   option. The generated tarball is always named `bootprep-schema-docs.tar.gz`.

   ```bash
   sat bootprep generate-docs --output-dir /tmp
   ```

   Example output:

   ```text
   INFO: Wrote input schema documentation to /tmp/bootprep-schema-docs.tar.gz
   ```

1. (`user@hostname>`) From another machine, copy the tarball to a local directory.

   ```bash
   scp root@ncn-m001:bootprep-schema-docs.tar.gz .
   ```

1. (`user@hostname>`) Extract the contents of the tarball and open the contained `index.html`.

   ```bash
   tar xzvf bootprep-schema-docs.tar.gz
   ```

   Example output:

   ```text
   x bootprep-schema-docs/
   x bootprep-schema-docs/index.html
   x bootprep-schema-docs/schema_doc.css
   x bootprep-schema-docs/schema_doc.min.js
   another-machine$ open bootprep-schema-docs/index.html
   ```
