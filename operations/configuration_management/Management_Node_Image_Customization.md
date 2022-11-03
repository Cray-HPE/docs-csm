# Management Node Image Customization

**NOTE:** Some of the documentation linked from this page mentions use of the Boot Orchestration Service (BOS). The use of BOS
is only relevant for booting compute nodes and can be ignored when working with NCN images.

This document describes the configuration of a Kubernetes NCN image. The same steps could be used to modify a Ceph NCN image.

1. Identify the NCN image to be modified.

    This example assumes that the administrator wants to modify the Kubernetes image that is currently in use by Kubernetes NCNs.
    However, the steps are the same for any Management NCN SquashFS image.

    If the image to be modified is the image currently booted on a Kubernetes NCN, the value for `ARTIFACT_VERSION` can be found by looking
    at the boot parameters for the NCNs, or from `/proc/cmdline` on a booted Kubernetes NCN. The version has the form of `X.Y.Z`.
    See: [boot parameters](../../background#metalserver)

1. (`ncn-mw#`) Obtain the NCN image's associated artifacts (SquashFS, kernel, and `initrd`).

    These example commands show how to download these artifacts from S3, which is where the NCN image artifacts are stored.

    ```bash
    ARTIFACT_VERSION=<artifact-version>

    cray artifacts get boot-images "k8s/${ARTIFACT_VERSION}/rootfs" "./${ARTIFACT_VERSION}-rootfs"

    cray artifacts get boot-images "k8s/${ARTIFACT_VERSION}/kernel" "./${ARTIFACT_VERSION}-kernel"

    cray artifacts get boot-images "k8s/${ARTIFACT_VERSION}/initrd" "./${ARTIFACT_VERSION}-initrd"

    export IMS_ROOTFS_FILENAME="${ARTIFACT_VERSION}-rootfs"

    export IMS_KERNEL_FILENAME="${ARTIFACT_VERSION}-kernel"

    export IMS_INITRD_FILENAME="${ARTIFACT_VERSION}-initrd"
    ```

1. Import the NCN image into IMS.

    Perform the [Import External Image to IMS](../image_management/Import_External_Image_to_IMS.md) procedure, except
    skip the following sections:

    * [Set helper variables](../image_management/Import_External_Image_to_IMS.md#2-set-helper-variables)
      * Skip this section because the variables have already been set above, in the previous step.
    * [Upload artifacts to S3](../image_management/Import_External_Image_to_IMS.md#5-upload-artifacts-to-s3)
      * Skip this section because the artifacts are already in S3.

1. (`ncn-m001#`) If `sat bootprep` was not used in [Worker Image Customization](Worker_Image_Customization.md) to create a CFS
   configuration for management node image customization, then execute the following two substeps:

    1. Clone the `csm-config-management` repository.

        ```bash
        VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
        VCS_PASS=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
        git clone "https://${VCS_USER}:${VCS_PASS}@api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
        ```

        A Git commit hash from this repository is needed in the following step.

    1. [Create a CFS Configuration](Create_a_CFS_Configuration.md).

        The first layer in the CFS configuration should be similar to this:

        ```json
        {
          "name": "csm-ncn-workers",
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
          "playbook": "ncn-worker_nodes.yml",
          "commit": "<git commit hash>"
        }
        ```

        The last layer in the CFS configuration should be similar to this:

        ```json
        {
          "name": "csm-ncn-initrd",
          "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
          "playbook": "ncn-initrd.yml",
          "commit": "<git commit hash>"
        }
        ```

1. (`ncn-mw#`) Ensure that the environment variable `$IMS_IMAGE_ID` was set during
   [Import an External Image to IMS](../image_management/Import_External_Image_to_IMS.md).

    ```bash
    echo "${IMS_IMAGE_ID}"
    ```

1. (`ncn-mw#`) Create an image customization CFS session.

    See [Create an Image Customization CFS Session](Create_an_Image_Customization_CFS_Session.md) for additional information
    on creating an image customization CFS session.

    ```bash
    cray cfs sessions create \
        --name "ncn-image-customization-session-$(date +%Y%m%d_%H%M%S)" \
        --configuration-name ncn-image-customization \
        --target-definition image --format json \
        --target-group Management_Worker "${IMS_IMAGE_ID}"
    ```

1. (`ncn-mw#`) Determine the component names (xnames) for the NCNs which will boot from the new image.

   > If being done as part of a CSM upgrade, this will be the NCN worker nodes.  

   Options to determine node xnames:

   - Get a comma-separated list of all worker NCN xnames:

      ```bash
      cray hsm state components list --role Management --subrole Worker --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")'
      ```

   - Get a comma-separated list of all master NCN xnames:

      ```bash
      cray hsm state components list --role Management --subrole Master --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")'
      ```

   - Get a comma-separated list of all storage NCN xnames:

      ```bash
      cray hsm state components list --role Management --subrole Storage --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")'
      ```

   - Get the xname for a specific NCN:

      > In this example, the xname for `ncn-w001` is being found.

      ```bash
      ssh ncn-w001 cat /etc/cray/xname
      ```

1. (`ncn-mw#`) Update boot parameters for a Kubernetes NCN.

    1. Get the existing `metal.server` setting for the component name (xname) of the node of interest:

        ```bash
        XNAME=<node-xname>
        METAL_SERVER=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' \
            | awk -F 'metal.server=' '{print $2}' \
            | awk -F ' ' '{print $1}')
        echo "${METAL_SERVER}"
        ```

    1. Update the kernel, `initrd`, and metal server to point to the new artifacts.

        **NOTE:** `${IMS_RESULTANT_IMAGE_ID}` is the `result_id` returned in the output of the last command
        in the "Create an Image Customization CFS Session" procedure, repeated here for convenience:

        ```bash
        cray cfs sessions describe ncn-image-customization-session --format json | jq .status.artifacts
        ```

        ```bash
        S3_ARTIFACT_PATH="boot-images/${IMS_RESULTANT_IMAGE_ID}"
        NEW_METAL_SERVER="s3://${S3_ARTIFACT_PATH}/rootfs"

        PARAMS=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' | \
            sed "/metal.server/ s|${METAL_SERVER}|${NEW_METAL_SERVER}|" | \
            sed "s/metal.no-wipe=1/metal.no-wipe=0/" | \
            tr -d \")
        echo "${PARAMS}"
        ```

        In the output of the final `echo` command, verify that the value of `metal.server` was correctly set to `${NEW_METAL_SERVER}`.

    1. Update BSS with the new boot parameters.

        ```bash
        cray bss bootparameters update --hosts "${XNAME}" \
            --kernel "s3://${S3_ARTIFACT_PATH}/kernel" \
            --initrd "s3://${S3_ARTIFACT_PATH}/initrd" \
            --params "${PARAMS}"
        ```

   **NOTE**: If the worker node image is being customized as part of a Cray EX initial install or upgrade involving multiple products,
   then refer to the `HPE Cray EX System Software Getting Started Guide (S-8000)` for details on when to reboot the worker nodes to the new image.

   If this procedure is being followed outside of the `S-8000` document, then proceed to [rebuild the NCN](../node_management/Rebuild_NCNs/Rebuild_NCNs.md).
