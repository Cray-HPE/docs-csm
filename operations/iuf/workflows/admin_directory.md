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
    - Comment out the SBPS `rootfs_provider` and `rootfs_provider_passthrough` parameters and uncomment the CPS `rootfs_provider` and `rootfs_provider_passthrough` parameters, if DVS with CPS is the preferred method to project content.
    - Comment the several sections with GPU_SUPPORT (between BEGIN_GPU_SUPPORT and END_GPU_SUPPORT) tags if the system has no GPU hardware.
        The sections are identified with BEGIN_GPU_SUPPORT and END_GPU_SUPPORT comments like this example.

        ```bash
        # The gpu_customize_driver_playbook.yml playbook will install GPU driver and
        # SDK/toolkit software into the compute boot image if GPU content is available
        # in the expected Nexus repo targets. If GPU content has not been uploaded to
        # Nexus this play will be skipped automatically. If GPU content is available in
        # Nexus but a non-gpu image is wanted this layer can be commented out.
        #BEGIN_GPU_SUPPORT
          - name: uss-gpu-customize-driver-playbook-{{uss.working_branch}}
            playbook: gpu_customize_driver_playbook.yml
            product:
              name: uss
              version: "{{uss.version}}"
              branch: "{{uss.working_branch}}"
            special_parameters:
              ims_require_dkms: true
        #END_GPU_SUPPORT
        ```

    - Comment out any CFS configuration layers in `compute-and-uan-bootprep.yaml` and `management-bootprep.yaml` files for products that are not needed on the system
    - Any other changes needed to reflect site preferences

1. Create a `site_vars.yaml` file in `${ADMIN_DIR}`. This file will contain key/value pairs for any configuration changes that should override entries in the `default` section of the HPE-provided `product_vars.yaml` file.
   There are comments at the top of the `product_vars.yaml` file that describe the variables and related details. The following are a few examples of `site_vars.yaml` changes:
    - Add a `default` section containing a `network_type: "cassini"` entry to designate that Cassini is the desired Slingshot network type to be used when executing CFS configurations later in the workflow
    - Add a `suffix` entry to the `default` section to append a string to the names of CFS configuration, image, and BOS session template artifacts created during the workflow to make them easy to identify
    - Add a `system_name` entry to the `default` section. The Scalable Boot Projection Service (SBPS) uses this system name as the first part of the domain name. Do not add if not using SBPS.
      - See the procedure [Create a Session Template to Boot Compute Nodes with SBPS](../../../operations/boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md#boot-set-rootfs_provider_passthrough-parameter)
        for more information.
        - If the `docs-csm` RPM is installed on a node, then this page can be found under `/usr/share/doc/csm/operations/boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md`. See the
          "Boot set `rootfs_provider_passthrough` parameter" section for more details.
        - Otherwise, it can be found under the appropriate release branch in <https://github.com/Cray-HPE/docs-csm>.
      - This documentation indicates how to find the `system_name`.
    - Add a `site_domain` entry to the `default` section. The Scalable Boot Projection Service (SBPS) uses this domain name as the second part of the domain name. Do not add if not using SBPS.
      - See the procedure [Create a Session Template to Boot Compute Nodes with SBPS](../../../operations/boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md#boot-set-rootfs_provider_passthrough-parameter)
        for more information.
        - If the `docs-csm` RPM is installed on a node, then this page can be found under `/usr/share/doc/csm/operations/boot_orchestration/Create_a_Session_Template_to_Boot_Compute_Nodes_with_SBPS.md`.
          See the "Boot set `rootfs_provider_passthrough` parameter"section for more details.
        - Otherwise, it can be found under the appropriate release branch in <https://github.com/Cray-HPE/docs-csm>.
      - This documentation indicates how to find the `site_domain`.

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
