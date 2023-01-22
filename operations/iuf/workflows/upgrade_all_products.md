# Upgrade All Products Provided in a HPC CSM Software Recipe

The following example describes a hypothetical upgrade procedure of all non-CSM product content provided with a HPC CSM Software Recipe release. CSM itself is not upgraded. All stages of `iuf` are executed to perform a complete upgrade. All of the new software provided in the release is deployed and all management NCNs and managed compute and application (UAN) nodes are rebooted to new images and CFS configurations.

1. Create a timestamped directory on ncn-m001 and copy all distribution files from the HPC CSM Software Recipe to it.

   (ncn-m001#) Populate activity directory with product content.

    ```bash
    DATE=`date +%Y%m%d%H%M%S`
    ACTIVITY_DIR=/etc/cray/upgrade/csm/iuf/${DATE}
    mkdir ${ACTIVITY_DIR}
    cd ${ACTIVITY_DIR}
    scp <HPC CSM Software Recipe content path> .
    ```

1. Create a `site_vars.yaml` file in the `/etc/cray/upgrade/csm/iuf` directory and define variables to reflect site preferences.

    (ncn-m001#) Prepare site variables file.

    ```bash
    SITE_VARS_FILE=/etc/cray/upgrade/csm/iuf/site_vars.yaml
    vi ${SITE_VARS_FILE}
    ```

1.  Invoke `iuf run` to create an activity named `activity-all-products-upgrade` and use `-e` to execute the [`process-media`](../stages/process_media.md), [`pre-install-check`](../stages/pre_install_check.md), [`deliver-product`](../stages/deliver_product.md), and [`update-vcs-config`](../stages/update_vcs_config.md) stages. Perform the upgrade using product content found in the `${ACTIVITY_DIR}` directory. Use site variables from the `${SITE_VARS_FILE}` file and recipe variables from the `product_vars.yaml` file found in the `${ACTIVITY_DIR}/hpc-csm-software-recipe-23.03.0/vcs` `sat bootprep` configuration directory.

    (ncn-m001#) Execute the stages beginning with `process-media` and ending with `update-vcs-config`.

    ```bash
    iuf -a activity-all-products-upgrade -m ${ACTIVITY_DIR} run --site-vars ${SITE_VARS_FILE} --bootprep-config-dir ${ACTIVITY_DIR}/hpc-csm-software-recipe-23.03.0/vcs -e update-vcs-config
    ```

    Once this step has completed:

    - product content has been extracted from the product distribution files in `${ACTIVITY_DIR}`
    - pre-install checks have been performed for CSM and all products found in `${ACTIVITY_DIR}`
    - product content for all products found in `${ACTIVITY_DIR}` has been uploaded to the system
    - product content uploaded to the system has been recorded in the product catalog
    - product configuration content has been merged to VCS branches as described in the [update-vcs-config stage documentation](../stages/update_vcs_config.md)
    - per-stage product hooks have executed for the `process-media`, `pre-install-check`, `deliver-product`, and `update-vcs-config` stages

1. Before executing the `update-cfs-config` stage, make any site customizations to product content stored in VCS to ensure CFS configurations and any resulting images are created with the correct content and configuration values.

1. Invoke `iuf run` with `-r` to execute the [`update-cfs-config`](../stages/update_cfs_config.md) and [`prepare-images`](../stages/prepare_images.md) stages. The `-m`, `--site-vars`, and `--bootprep-config-dir` arguments are the same as the initial invocation of `iuf run` as all steps in this example use the same IUF activity, media, and variables.

    (ncn-m001#) Execute the `update-cfs-config` and `prepare-images` stages.

    ```bash
    iuf -a activity-all-products-upgrade -m ${ACTIVITY_DIR} run --site-vars ${SITE_VARS_FILE} --bootprep-config-dir ${ACTIVITY_DIR}/hpc-csm-software-recipe-23.03.0/vcs -r update-cfs-config prepare-images
    ```

    Once this step has completed:

    - new CFS configurations have been created for management NCNs and managed compute and application (UAN) nodes
    - new images have been created for management NCNs and managed compute and application (UAN) nodes
    - new BOS session templates have been created to boot managed compute and application (UAN) nodes with the new images and CFS configurations
    - per-stage product hooks have executed for the `update-cfs-config` and `prepare-images` stages

1. Inspect the newly-created management NCN and managed node images and CFS configurations to ensure they are correct before rebooting to the new content.

1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage. The `-m`, `--site-vars`, and `--bootprep-config-dir` arguments are the same as the initial invocation of `iuf run` as all steps in this example use the same IUF activity, media, and variables.

    (ncn-m001#) Execute the `management-nodes-rollout` stage.

    ```bash
    iuf -a activity-all-products-upgrade -m ${ACTIVITY_DIR} run --site-vars ${SITE_VARS_FILE} --bootprep-config-dir ${ACTIVITY_DIR}/hpc-csm-software-recipe-23.03.0/vcs -r management-nodes-rollout
    ```

    Once this step has completed:

    - all management NCN nodes have been rebooted to the images and CFS configurations created in previous steps in this example
    - per-stage product hooks have executed for the `management-nodes-rollout` stage

1. Invoke `iuf run` with `-r` to execute the [`deploy-product`](../stages/deploy_product.md) and [`post-install-service-check`](../stages/post_install_service_check.md) stages. The `-m`, `--site-vars`, and `--bootprep-config-dir` arguments are the same as the initial invocation of `iuf run` as all steps in this example use the same IUF activity, media, and variables.

    (ncn-m001#) Execute the `deploy-product` and `post-install-service-check` stages.

    ```bash
    iuf -a activity-all-products-upgrade -m ${ACTIVITY_DIR} run --site-vars ${SITE_VARS_FILE} --bootprep-config-dir ${ACTIVITY_DIR}/hpc-csm-software-recipe-23.03.0/vcs -r deploy-product post-install-service-check
    ```

    Once this step has completed:

    - new versions of product microservices have been deployed
    - service checks have been run to verify product microservices are executing as expected
    - per-stage product hooks have executed for the `deploy-product` and `post-install-service-check` stages

1. Invoke `iuf run` with `-r` to execute the [`managed-nodes-rollout`](../stages/managed_nodes_rollout.md) stage. The `-m`, `--site-vars`, and `--bootprep-config-dir` arguments are the same as the initial invocation of `iuf run` as all steps in this example use the same IUF activity, media, and variables.

    (ncn-m001#) Execute the `managed-nodes-rollout` stage.

    ```bash
    iuf -a activity-all-products-upgrade -m ${ACTIVITY_DIR} run --site-vars ${SITE_VARS_FILE} --bootprep-config-dir ${ACTIVITY_DIR}/hpc-csm-software-recipe-23.03.0/vcs -r managed-nodes-rollout
    ```

    Once this step has completed:

    - all managed compute and application (UAN) nodes have been rebooted to the images and CFS configurations created in previous steps in this example
    - per-stage product hooks have executed for the `managed-nodes-rollout` stage

1. Invoke `iuf run` with `-r` to execute the [`post-install-check`](../stages/post_install_check.md) stage. The `-m`, `--site-vars`, and `--bootprep-config-dir` arguments are the same as the initial invocation of `iuf run` as all steps in this example use the same IUF activity, media, and variables.

    (ncn-m001#) Execute the `post-install-check` stage.

    ```bash
    iuf -a activity-all-products-upgrade -m ${ACTIVITY_DIR} run --site-vars ${SITE_VARS_FILE} --bootprep-config-dir ${ACTIVITY_DIR}/hpc-csm-software-recipe-23.03.0/vcs -r post-install-check
    ```

    Once this step has completed:

    - per-stage product hooks have executed to verify product software is executing as expected
