# Management Node Image Customization

**NOTE:** Some of the documentation linked from this page mentions use of the Boot Orchestration Service (BOS). The use of BOS
is only relevant for booting compute nodes and can be ignored when working with NCN images.

This document describes the configuration of a Kubernetes NCN image. The same steps could be used to modify a Ceph NCN image
with minor command modifications.

* [Prerequisites](#prerequisites)
* [Procedure](#procedure)
    1. [Obtain NCN image artifacts](#1-obtain-ncn-image-artifacts)
    1. [Import the NCN image into IMS](#2-import-the-ncn-image-into-ims)
    1. [Create a CFS configuration, if needed](#3-create-a-cfs-configuration-if-needed)
    1. [Run the CFS image customization session](#4-run-the-cfs-image-customization-session)
    1. [Update NCN boot parameters](#5-update-ncn-boot-parameters)
* [Next steps](#next-steps)

## Prerequisites

The Cray CLI must be configured on the node where the commands are being run. See [Configure the Cray CLI](../configure_cray_cli.md).

## Procedure

### 1. Obtain NCN image artifacts

1. (`ncn-mw#`) Identify the NCN image to be modified.

    If this procedure is being done as part of a CSM upgrade, then the documentation which linked to this procedure will have
    provided instructions for how to set the `NCN_IMS_IMAGE_ID` variable.

    Otherwise, if the image to be modified is the image currently booted on an NCN, then find the value for `NCN_IMS_IMAGE_ID`
    by looking at the boot parameters for the NCNs, or by reading  `/proc/cmdline` on a booted NCN. The version is a UUID value.
    See [`metal.server` boot parameter](../../background/ncn_kernel.md#metalserver).

    ```bash
    NCN_IMS_IMAGE_ID=<UUID-value>
    ```

### 2. Create a CFS configuration, if needed

If `sat bootprep` was used to create a CFS configuration for management node image customization, then one does not
need to be created now. For example. this will be the case if this procedure is being followed as part of
[Worker Image Customization](Worker_Image_Customization.md). If `sat bootprep` was used to create the CFS configuration,
then skip this step and proceed to [Run the CFS image customization session](#4-run-the-cfs-image-customization-session).

1. (`ncn-mw#`) Clone the `csm-config-management` repository.

    ```bash
    VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
    VCS_PASS=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
    git clone "https://${VCS_USER}:${VCS_PASS}@api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
    ```

    A Git commit hash from this repository is needed in the following step.

1. (`ncn-mw#`) Create the CFS configuration to use for image customization.

    See [Create a CFS Configuration](Create_a_CFS_Configuration.md).

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

### 3. Run the CFS image customization session

1. (`ncn-mw#`) Record the name of the CFS configuration to use for image customization.

    If the CFS configuration was created in the previous section, then set the `CFS_CONFIG_NAME` variable to the
    name of that CFS configuration. If the CFS configuration was created by `sat bootprep` (for example, as part
    of [Worker Image Customization](Worker_Image_Customization.md)), then set the `CFS_CONFIG_NAME` variable to the
    CFS configuration name specified in that procedure.

    ```bash
    CFS_CONFIG_NAME=ncn-image-customization
    ```

1. (`ncn-mw#`) Ensure that the environment variable `NCN_IMS_IMAGE_ID` is set.

    ```bash
    echo "${NCN_IMS_IMAGE_ID}"
    ```

1. (`ncn-mw#`) Create an image customization CFS session.

    See [Create an Image Customization CFS Session](Create_an_Image_Customization_CFS_Session.md) for additional information.

    1. Set a name for the session.

        ```bash
        CFS_SESSION_NAME="ncn-image-customization-session-$(date +%y%m%d%H%M%S)"
        echo "${CFS_SESSION_NAME}"
        ```

    1. Create the session.

        ```bash
        cray cfs sessions create \
            --name "${CFS_SESSION_NAME}" \
            --configuration-name "${CFS_CONFIG_NAME}" \
            --target-definition image --format json \
            --target-group Management_Worker "${NCN_IMS_IMAGE_ID}"
        ```

    1. Monitor the CFS session until it completes successfully.

        See [Track the Status of a Session](Track_the_Status_of_a_Session.md).

    1. Obtain the IMS resultant image ID.

        ```bash
        IMS_RESULTANT_IMAGE_ID=$(cray cfs sessions describe "${CFS_SESSION_NAME}" --format json |
                                   jq -r '.status.artifacts[] | select(.type == "ims_customized_image") | .result_id')
        echo "${IMS_RESULTANT_IMAGE_ID}"
        ```

        Example output:

        ```text
        a44ff301-6232-46b4-9ba6-88ee1d19e2c2
        ```

### 4. Update NCN boot parameters

Every NCN which will be booting from the customized image must have its boot parameters updated in BSS to use the artifacts of the customized image.

1. (`ncn-mw#`) Determine the component names (xnames) for the NCNs which will boot from the new image.

    > If being done as part of a CSM upgrade, then this will be the NCN worker nodes.

    Options to determine node xnames:

    * Get a comma-separated list of all worker NCN xnames:

        ```bash
        cray hsm state components list --role Management --subrole Worker --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")'
        ```

    * Get a comma-separated list of all master NCN xnames:

        ```bash
        cray hsm state components list --role Management --subrole Master --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")'
        ```

    * Get a comma-separated list of all storage NCN xnames:

        ```bash
        cray hsm state components list --role Management --subrole Storage --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")'
        ```

    * Get the xname for a specific NCN:

        > In this example, the xname for `ncn-w001` is being found.

        ```bash
        ssh ncn-w001 cat /etc/cray/xname
        ```

1. (`ncn-mw#`) Update boot parameters for an NCN.

    > If being done as part of a CSM upgrade, then update the boot parameters for the NCN worker nodes.
    > Master and storage NCNs are managed automatically in later stages of the CSM upgrade.

    Perform the following procedure **for each xname** identified in the previous step.

    1. Get the existing `metal.server` setting for the component name (xname) of the node of interest.

        ```bash
        XNAME=<node-xname>
        METAL_SERVER=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' \
            | awk -F 'metal.server=' '{print $2}' \
            | awk -F ' ' '{print $1}')
        echo "${METAL_SERVER}"
        ```

    1. Create updated boot parameters that point to the new artifacts.

        1. Set the path to the artifacts in S3.

            **NOTE:** This uses the `IMS_RESULTANT_IMAGE_ID` variable set in an earlier step.

            ```bash
            S3_ARTIFACT_PATH="boot-images/${IMS_RESULTANT_IMAGE_ID}"
            echo "${S3_ARTIFACT_PATH}"
            ```

        1. Set the new `metal.server` value.

            ```bash
            NEW_METAL_SERVER="s3://${S3_ARTIFACT_PATH}/rootfs"
            echo "${NEW_METAL_SERVER}"
            ```

        1. Determine the modified boot parameters for the node.

            ```bash
            PARAMS=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' | \
                sed "/metal.server/ s|${METAL_SERVER}|${NEW_METAL_SERVER}|" | \
                sed "s/metal.no-wipe=1/metal.no-wipe=0/" | \
                tr -d \")
            echo "${PARAMS}"
            ```

            In the output of the `echo` command, verify that the value of `metal.server` is correctly set to the value of `${NEW_METAL_SERVER}`.

    1. Update BSS with the new boot parameters.

        ```bash
        cray bss bootparameters update --hosts "${XNAME}" \
            --kernel "s3://${S3_ARTIFACT_PATH}/kernel" \
            --initrd "s3://${S3_ARTIFACT_PATH}/initrd" \
            --params "${PARAMS}"
        ```

## Next steps

If the worker node image is being customized as part of a Cray EX initial install or upgrade involving multiple products,
then refer to the `HPE Cray EX System Software Getting Started Guide (S-8000)` for details on when to reboot the worker nodes to the new image.

If this procedure is being followed outside of the `S-8000` document, then proceed to [rebuild the NCN](../node_management/Rebuild_NCNs/Rebuild_NCNs.md).
