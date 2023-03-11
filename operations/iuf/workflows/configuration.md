# Configuration

This section ensures product configuration have been defined, customized, and is available for later steps in the workflow.

This workflow uses `${ADMIN_DIR}` to retain files that define site preferences for IUF. `${ADMIN_DIR}` is defined separately from `${ACTIVITY_DIR}` and `${MEDIA_DIR}` based on the assumption that the files in `${ADMIN_DIR}` will be
used when performing future IUF operations unrelated to this workflow.

**`NOTE`** The following steps assume `${ADMIN_DIR}` is empty. If this is not the case, i.e. `${ADMIN_DIR}` has been populated by previous IUF workflows, ensure the content in `${ADMIN_DIR}` is up to date with the latest content
provided by the HPC CSM Software Recipe release content being installed. This may involve merging new content provided in the latest branch of the `hpc-csm-software-recipe` repository in VCS with the existing content in `${ADMIN_DIR}`.

- [1. Populate admin directory with files defining site preferences](#1-populate-admin-directory-with-files-defining-site-preferences)
- [2. Execute the IUF `update-vcs-config` stage](#2-execute-the-iuf-update-vcs-config-stage)
- [3. Perform manual product configuration operations](#3-perform-manual-product-configuration-operations)
- [4. Next steps](#4-next-steps)

## 1. Populate admin directory with files defining site preferences

1. Change directory to `${ADMIN_DIR}`

    (`ncn-m001#`) Change directory

    ```bash
    cd ${ADMIN_DIR}
    ```

1. Copy the `sat bootprep` and `product_vars.yaml` files from the uncompressed HPC CSM Software Recipe distribution file in the media directory to the current directory.

    (`ncn-m001#`) Copy `sat bootprep` and `product_vars.yaml` files

    ```bash
    cp "${MEDIA_DIR}"/hpc-csm-software-recipe-*/vcs/product_vars.yaml .
    cp -r "${MEDIA_DIR}"/hpc-csm-software-recipe-*/vcs/bootprep .
    ```

    (`ncn-m001#`) Examine the contents of `${ADMIN_DIR}` to verify the expected content is present

    ```bash
    find . -type f
    ./bootprep/management-bootprep.yaml
    ./bootprep/compute-and-uan-bootprep.yaml
    ./product_vars.yaml
    ```

1. Edit the `compute-and-uan-bootprep.yaml` and `management-bootprep.yaml` files to account for any site deviations from the default values. For example:
    - Comment out the `slurm-site` CFS configuration layer and uncomment the `pbs-site` CFS configuration layer in `compute-and-uan-bootprep.yaml` if PBS is the preferred workload manager
    - Uncomment the `gpu-{{recipe.version}}` CFS configuration layer and `gpu-image` image definition in `compute-and-uan-bootprep.yaml` if the system has GPU hardware
    - Comment out any CFS configuration layers in `compute-and-uan-bootprep.yaml` and `management-bootprep.yaml` files for products that are not needed on the system
    - Any other changes needed to reflect site preferences

1. Create a `site_vars.yaml` file in `${ADMIN_DIR}`. This file will contain key/value pairs for any configuration changes that should override the HPE-provided `product_vars.yaml` content. For example:
    - Add a `default` section containing a `network_type: "cassini"` entry to designate that Cassini is the desired Slingshot network type to be used when executing CFS configurations later in the workflow
    - Add a `suffix` entry to the `default` section to append a string to the names of CFS configuration, image, and BOS session template artifacts created during the workflow to make them easy to identify
    - Any other changes needed to reflect site preferences

    (`ncn-m001#`) Display the contents of an **example** `site_vars.yaml` file

    ```bash
    cat site_vars.yaml
    default:
      network_type: "cassini"
      suffix: "-test01"
    ```

    (`ncn-m001#`) List contents of `${ADMIN_DIR}` to verify content is present

    ```bash
    ls
    compute-and-uan-bootprep.yaml  management-bootprep.yaml  product_vars.yaml  site_vars.yaml
    ```

Once this step has completed:

- `${ADMIN_DIR}` is populated with `product_vars.yaml`, `site_vars.yaml`, and `sat bootprep` input files
- The aforementioned configuration files have been updated to reflect site preferences

## 2. Execute the IUF `update-vcs-config` stage

**`NOTE`** Additional arguments are available to control the behavior of the `update-vcs-config` stage, for example `-rv`. See the [`update-vcs-config` stage
documentation](../stages/update_vcs_config.md) for details and adjust the examples below if necessary.

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `update-vcs-config` stage.

1. Invoke `iuf run` with `-r` to execute the [`update-vcs-config`](../stages/update_vcs_config.md) stage. Use site variables from the `site_vars.yaml` file found in `${ADMIN_DIR}` and recipe variables from the `product_vars.yaml`
file found in `${ADMIN_DIR}`.

    (`ncn-m001#`) Execute the `update-vcs-config` stage.

    ```bash
    iuf -a ${ACTIVITY_NAME} -m "${MEDIA_DIR}" run --site-vars "${ADMIN_DIR}/site_vars.yaml" -bpcd "${ADMIN_DIR}" -r update-vcs-config
    ```

Once this step has completed:

- Product configuration content has been merged to VCS branches as described in the [update-vcs-config stage documentation](../stages/update_vcs_config.md)
- Per-stage product hooks have executed for the `update-vcs-config` stage

## 3. Perform manual product configuration operations

Some products must be manually configured prior to the creation of CFS configurations and images. The "Install and Upgrade Framework" section of each individual product's installation documentation will refer to instructions for product-specific
configuration, if any. The following highlights some of the areas that most often require manual configuration changes **but is not intended to be a comprehensive list.** Note that many of the configuration changes are only
required for initial installation scenarios.

- Products that most often require site customizations to Ansible content in VCS
  - COS
  - CPE
  - Slingshot Host Software
  - UAN
  - Slurm and PBS workload managers
- Initial install configuration changes (not required for upgrade scenarios)
  - SAT
    - Configure SAT authentication via `sat auth`
    - Generate SAT S3 credentials
    - Configure system revision information via `sat setrev`
  - SDU
    - Configure SDU via `sdu setup`
  - COS
    - Set the COS root password in HashiCorp Vault
  - UAN
    - Set the UAN root password in HashiCorp Vault

Once this step has completed:

- Product configuration has been completed

## 4. Next steps

- If performing an initial install, return to [Initial install](initial_install.md) to continue the install.

- If performing an upgrade, return to [Upgrade](upgrade.md) to continue the upgrade.
