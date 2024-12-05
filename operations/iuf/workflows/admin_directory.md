# Populate admin directory with files defining site preferences

IUF activities use `${ADMIN_DIR}` to retain files that define site preferences for IUF. `${ADMIN_DIR}` is defined separately from `${ACTIVITY_DIR}` and `${MEDIA_DIR}` based on the assumption that the files in `${ADMIN_DIR}` will be
used when performing future IUF operations unrelated to this workflow.

**`NOTE`** The following steps assume `${ADMIN_DIR}` is empty. If this is not the case, i.e. `${ADMIN_DIR}` has been populated by previous IUF workflows, ensure the content in `${ADMIN_DIR}` is up to date with the latest content
provided by the HPC CSM Software Recipe release content being installed. This may involve merging new content provided in the latest branch of the `hpc-csm-software-recipe` repository in VCS or provided in the files extracted from
the HPC CSM Software Recipe with the existing content in `${ADMIN_DIR}`.

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
    ```

    Example output:

    ```text
    ./bootprep/management-bootprep.yaml
    ./bootprep/compute-and-uan-bootprep.yaml
    ./product_vars.yaml
    ```

1. Edit the `compute-and-uan-bootprep.yaml` and `management-bootprep.yaml` files to account for any site deviations from the default values. For example:
    - Comment out the `slurm-site` CFS configuration layer and uncomment the `pbs-site` CFS configuration layer in `compute-and-uan-bootprep.yaml` if PBS is the preferred workload manager
    - Uncomment the `gpu-{{recipe.version}}` CFS configuration layer and `gpu-image` image definition in `compute-and-uan-bootprep.yaml` if the system has GPU hardware
    - Comment out any CFS configuration layers in `compute-and-uan-bootprep.yaml` and `management-bootprep.yaml` files for products that are not needed on the system
    - Any other changes needed to reflect site preferences

1. Create a `site_vars.yaml` file in `${ADMIN_DIR}`. This file will contain key/value pairs for any configuration changes that should override entries in the `default` section of the HPE-provided `product_vars.yaml` file.
   There are comments at the top of the `product_vars.yaml` file that describe the variables and related details. The following are a few examples of `site_vars.yaml` changes:
    - Add a `default` section containing a `network_type: "cassini"` entry to designate that Cassini is the desired Slingshot network type to be used when executing CFS configurations later in the workflow
    - Add a `suffix` entry to the `default` section to append a string to the names of CFS configuration, image, and BOS session template artifacts created during the workflow to make them easy to identify

   Additional information on `site_vars.yaml` files can be found in the [Site and recipe variables](../IUF.md#site-and-recipe-variables) and [`update-vcs-config`](../stages/update_vcs_config.md) sections.

    1. Create a `site_vars.yaml` file with desired key/value pairs

    2. Ensure the `site_vars.yaml` file contents are formatted correctly. The following text is an example for verification purposes only.

       (`ncn-m001#`) Display the contents of an **example** `site_vars.yaml` file

       ```bash
       cat site_vars.yaml
       ```

       Example output:

       ```text
       default:
         network_type: "cassini"
         suffix: "-test01"
       ```

       **NOTE:** When installing USS 1.1 or higher, select either SLURM or PBS Pro Products to use on the system before running this stage. For more information, see the `deliver-product` stage
       details in the "Install and Upgrade Framework" section of the _HPE Cray Supercomputing User Services Software Administration Guide: CSM on HPE Cray Supercomputing EX Systems (S-8063)_.
       If installing USS 1.1 or higher, the `deploy_slurm` and `deploy_pbs` keys should be in the `site_vars.yaml` file as shown below.

       ```text
       default:
        network_type: "cassini"
        suffix: "-test01"
        system_name: "my-system"
        site_domain: "my-site-domain.net"
       uss:
        deploy_slurm: true
        deploy_pbs: true
        ```

    3. Ensure the expected files are present in the admin directory after performing the steps in this section.

       (`ncn-m001#`) Examine the contents of `${ADMIN_DIR}` to verify the expected content is present

       ```bash
       find . -type f
       ```

       Example output:

       ```text
       ./bootprep/management-bootprep.yaml
       ./bootprep/compute-and-uan-bootprep.yaml
       ./product_vars.yaml
       ./site_vars.yaml
       ```

Once this step has completed:

- `${ADMIN_DIR}` is populated with `product_vars.yaml`, `site_vars.yaml`, and `sat bootprep` input files
- The aforementioned configuration files have been updated to reflect site preferences
