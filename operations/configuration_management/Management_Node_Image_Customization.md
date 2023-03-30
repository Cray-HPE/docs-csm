# Management Node Image Customization

This page describes the procedure to customize a management node image using the
[Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) and
the [Image Management Service (IMS)](../../glossary.md#image-management-service-ims). The procedure
has options for configuring Kubernetes master or worker nodes or Ceph storage nodes.

When performing an upgrade of CSM and/or additional HPE Cray EX software products, this procedure is
not followed end-to-end, but certain portions of the procedure are referenced. When performing an
install or upgrade, be sure to follow the appropriate procedures in
[Cray System Management Install](../../install/README.md) or [Upgrade CSM](../../upgrade/README.md).
This procedure is referenced from operational procedures that occur after CSM install or upgrade.

* [Prerequisites](#prerequisites)
* [Procedure](#procedure)
    1. [Determine management node image ID](#1-determine-management-node-image-id)
    1. [Find or create a CFS configuration](#2-find-or-create-a-cfs-configuration)
    1. [Run the CFS image customization session](#3-run-the-cfs-image-customization-session)
    1. [Update management node boot parameters](#4-update-management-node-boot-parameters)
* [Next steps](#next-steps)

## Prerequisites

* The Cray CLI must be configured and authenticated.
  * See [Configure the Cray CLI](../configure_cray_cli.md).
* SAT must be configured and authenticated.
  * See [SAT documentation](../sat/sat_in_csm.md#sat-documentation).

## Procedure

### 1. Determine management node image ID

Determine the ID of the management node boot image in the [Image Management Service (IMS)](../../glossary.md#image-management-service-ims).
There are several alternatives to find the management node image ID to use.

* [Option 1: Get IMS image ID for a management node from BSS](#option-1-get-ims-image-id-for-a-management-node-from-bss)
* [Option 2: Get IMS image ID for a booted management node](#option-2-get-ims-image-id-for-a-booted-management-node)
* [Option 3: Get IMS image ID of a base image provided by CSM](#option-3-get-ims-image-id-of-a-base-image-provided-by-csm)

#### Option 1: Get IMS image ID for a management node from BSS

Use this option to find the IMS image ID of the image which is configured to boot on a management
node the next time it boots. This may not necessarily match what the management node is currently
booted with. This procedure can be used whether the management node is booted or not.

This image is identified by examining the management node's boot parameters in the
[Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) as described in the
procedure below.

1. (`ncn-mw#`) Set `NODE_XNAME` to the [component name (xname)](../../glossary.md#xname) of the management node whose boot image is to be used.

   * If customizing a Kubernetes master node image, get the xname of `ncn-m001`.

     ```bash
     NODE_XNAME=$(ssh ncn-m001 cat /etc/cray/xname)
     echo "${NODE_XNAME}"
     ```

   * If customizing a Kubernetes worker node image, get the xname of `ncn-w001`.

     ```bash
     NODE_XNAME=$(ssh ncn-w001 cat /etc/cray/xname)
     echo "${NODE_XNAME}"
     ```

   * If customizing a Ceph storage node image, get the xname of `ncn-s001`:

     For example:

     ```bash
     NODE_XNAME=$(ssh ncn-s001 cat /etc/cray/xname)
     echo "${NODE_XNAME}"
     ```

1. (`ncn-mw#`) Extract the S3 path prefix for the image that will be used on the next boot of the chosen management node.

   This prefix corresponds to the IMS image ID of the boot image.

   ```bash
   IMS_IMAGE_ID=$(cray bss bootparameters list --name "${NODE_XNAME}" --format json | \
                        jq -r '.[0].params' | \
                        sed 's#\(^.*[[:space:]]\|^\)metal[.]server=[^[:space:]]*/boot-images/\([^[:space:]]\+\)/rootfs.*#\2#')
   echo "${IMS_IMAGE_ID}"
   ```

   The output should be a UUID string. For example, `8f41cc54-82f8-436c-905f-869f216ce487`.

   > The command used in this substep is extracting the location of the NCN image from the `metal.server` boot parameter for the
   > NCN in BSS. For more information on that parameter, see [`metal.server` boot parameter](../../background/ncn_kernel.md#metalserver).

#### Option 2: Get IMS image ID for a booted management node

Use this option to find the IMS image ID of the image which is currently booted on a management
node. In this case, the image is identified by examining the kernel command-line parameters on
the booted node.

**NOTE:** Do not use this option if either of the following are true:

* The management nodes are currently booted from the PIT node. This will be the case after an initial
  install of CSM before additional HPE Cray EX products have been installed. In this case, the boot
  parameters will be pointing at the PIT node rather than to an IMS image artifact in S3.
* The management node has been booted from disk instead of over the network. Network boots are the
  default behavior, but disk boots may be necessary in special cases.

1. (`ncn-mw#`) Set the `BOOTED_NODE` variable to the hostname of the management node that is booted
   using the image to be modified.

   > For example, `ncn-w001` or `ncn-s002`.

   ```bash
   BOOTED_NODE=ncn-<msw###>
   ```

1. (`ncn-mw#`) Extract the S3 path prefix for the image used to boot the chosen management node.

   This prefix corresponds to the IMS image ID of the boot image.

   ```bash
   IMS_IMAGE_ID=$(ssh "${BOOTED_NODE}" sed \
                            "'s#\(^.*[[:space:]]\|^\)metal[.]server=[^[:space:]]*/boot-images/\([^[:space:]]\+\)/rootfs.*#\2#'" \
                            /proc/cmdline)
   echo "${IMS_IMAGE_ID}"
   ```

   The output should be a UUID string. For example, `8f41cc54-82f8-436c-905f-869f216ce487`.

   > The command used in this substep is extracting the location of the NCN image from the `metal.server` boot parameter in
   > the `/proc/cmdline` file on the booted NCN. For more information on that parameter, see
   > [`metal.server` boot parameter](../../background/ncn_kernel.md#metalserver).

#### Option 3: Get IMS image ID of a base image provided by CSM

Use this option to find the IMS image ID of a base image provided by the CSM product. The CSM
product provides two images for management nodes. One image is for Kubernetes master and worker
nodes. The other image is for Ceph storage nodes. Starting with CSM 1.4.0, the CSM product adds
these image IDs to the `cray-product-catalog` Kubernetes ConfigMap.

These images can be used as a base for configuration if the administrator does not need to preserve any additional
customizations on the images which are currently booted or assigned to be booted on management nodes.

1. (`ncn-mw#`) Get the versions of CSM available in the `cray-product-catalog` ConfigMap:

   ```bash
   kubectl get configmap -n services cray-product-catalog -o jsonpath={.data.csm} | yq -j r - | jq -r 'keys[]'
   ```

   This will print a list of the CSM release versions installed on the system. For example:

   ```text
   1.3.0
   1.4.0
   ```

1. (`ncn-mw#`) Set the desired CSM release version as an environment variable.

   ```bash
   CSM_RELEASE=1.4.0
   ```

1. (`ncn-mw#`) Get the IMS image ID of the image for Kubernetes nodes or Ceph storage nodes.

    * To get the IMS image ID of the Kubernetes image, use the following command:

      ```bash
      IMS_IMAGE_ID=$(kubectl get configmap -n services cray-product-catalog -o jsonpath={.data.csm} | yq -j r - |
        jq -r '.["'${CSM_RELEASE}'"].images | to_entries |
               map(select(.key | startswith("secure-kubernetes"))) | first | .value.id')
      echo "${IMS_IMAGE_ID}"
      ```

    * To get the IMS image ID of the Ceph storage nodes, use the following command:

      ```bash
      IMS_IMAGE_ID=$(kubectl get configmap -n services cray-product-catalog -o jsonpath={.data.csm} | yq -j r - |
        jq -r '.["'${CSM_RELEASE}'"].images | to_entries |
               map(select(.key | startswith("secure-storage-ceph"))) | first | .value.id')
      echo "${IMS_IMAGE_ID}"
      ```

### 2. Find or create a CFS configuration

If the CFS configuration to be used for management node image customization has already been
identified, skip this step and and proceed to [Run the CFS image customization session](#3-run-the-cfs-image-customization-session).

A CFS configuration that applies to management nodes and works for both image customization and
post-boot personalization is created as part of the CSM install and upgrade procedures. Generally,
this is the configuration that should be used to perform management node image customization. The
first option below shows how to find the name of that CFS configuration. The second option describes
how to manually create a new CFS configuration that contains just the minimum CSM layers.

* [Option 1: Find the current CFS configuration for management nodes](#option-1-find-the-current-cfs-configuration-for-management-nodes)
* [Option 2: Create a new CFS configuration for management nodes](#option-2-create-a-new-cfs-configuration-for-management-nodes)

#### Option 1: Find the current CFS configuration for management nodes

Use this option to find the current CFS configuration applied to management nodes.

The following procedure describes how to find the CFS configuration applied to the management nodes.

1. (`ncn-mw#`) Use `sat status` to get the desired CFS configuration of all the management nodes.

   ```bash
   sat status --filter role=Management --fields xname,role,subrole,desiredconfig
   ```

   The output will be a table showing xname, role, subrole, and desired configuration set in CFS
   for all the management nodes on the system. For example:

   ```text
   +----------------+------------+---------+-------------------+
   | xname          | Role       | SubRole | Desired Config    |
   +----------------+------------+---------+-------------------+
   | x3000c0s1b0n0  | Management | Master  | management-23.4.0 |
   | x3000c0s2b0n0  | Management | Master  | management-23.4.0 |
   | x3000c0s3b0n0  | Management | Master  | management-23.4.0 |
   | x3000c0s4b0n0  | Management | Worker  | management-23.4.0 |
   | x3000c0s5b0n0  | Management | Worker  | management-23.4.0 |
   | x3000c0s6b0n0  | Management | Worker  | management-23.4.0 |
   | x3000c0s7b0n0  | Management | Worker  | management-23.4.0 |
   | x3000c0s8b0n0  | Management | Worker  | management-23.4.0 |
   | x3000c0s9b0n0  | Management | Worker  | management-23.4.0 |
   | x3000c0s10b0n0 | Management | Storage | management-23.4.0 |
   | x3000c0s11b0n0 | Management | Storage | management-23.4.0 |
   | x3000c0s12b0n0 | Management | Storage | management-23.4.0 |
   +----------------+------------+---------+-------------------+
   ```

   The value of the `Desired Config` column is the name of the CFS configuration currently applied
   to the nodes. There will typically be only one CFS configuration applied to all management nodes.

#### Option 2: Create a new CFS configuration for management nodes

Use this option to create a new CFS configuration for management nodes.

The following procedure describes how to create a CFS configuration that contains the minimal
layers provided by CSM.

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

    Set the `CFS_CONFIG_NAME` variable to the name of the CFS configuration identified or created
    in the previous section, [2. Find or create a CFS configuration](#2-find-or-create-a-cfs-configuration).

    ```bash
    CFS_CONFIG_NAME=management-23.4.0
    ```

1. (`ncn-mw#`) Ensure that the environment variable `IMS_IMAGE_ID` is set.

    This variable should have been set in the earlier step,
    [1. Determine management node image ID](#1-determine-management-node-image-id)

    ```bash
    echo "${IMS_IMAGE_ID}"
    ```

1. (`ncn-mw#`) Create an image customization CFS session.

    See [Create an Image Customization CFS Session](Create_an_Image_Customization_CFS_Session.md) for additional information.

    1. Set a name for the session.

        ```bash
        CFS_SESSION_NAME="management-image-customization-$(date +%y%m%d%H%M%S)"
        echo "${CFS_SESSION_NAME}"
        ```

    1. Set the `TARGET_GROUP` environment variable based on the type of management node for which the image is being customized (master, worker, or storage).

       * For worker nodes:

         ```bash
         TARGET_GROUP=Management_Worker
         ```

       * For master nodes:

        ```bash
        TARGET_GROUP=Management_Master
        ```

       * For storage nodes:

        ```bash
        TARGET_GROUP=Management_Storage
        ```

    1. Create the session.

        ```bash
        cray cfs sessions create \
            --name "${CFS_SESSION_NAME}" \
            --configuration-name "${CFS_CONFIG_NAME}" \
            --target-definition image --format json \
            --target-group "${TARGET_GROUP}" "${IMS_IMAGE_ID}"
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

### 4. Update management node boot parameters

This step describes how to update each management node to boot from a new customized image. This is
accomplished by updating the management nodes' boot parameters in BSS to use the artifacts from the
new customized image.

1. (`ncn-mw#`) Set an environment variable for the IMS image ID.

    * If executing this step in the context of
      [Stage 0.3 - Update management node CFS configuration and customize worker node image](../../upgrade/Stage_0_Prerequisites.md#stage-03---update-management-node-cfs-configuration-and-customize-worker-node-image)
      of the CSM upgrade procedure, use the appropriate IMS image ID environment variable set in that procedure.

      * For worker management nodes:

        ```bash
        NEW_IMS_IMAGE_ID="${WORKER_IMAGE_ID}"
        ```

      * For master management nodes:

        ```bash
        NEW_IMS_IMAGE_ID="${MASTER_IMAGE_ID}"
        ```

      * For storage management nodes:

        ```bash
        NEW_IMS_IMAGE_ID="${STORAGE_IMAGE_ID}"
        ```

    * If executing this step in the context of the entire procedure on this page, then use the
      `IMS_RESULTANT_IMAGE_ID` set in the previous step,
      [3. Run the CFS image customization session](#3-run-the-cfs-image-customization-session).

      ```bash
      NEW_IMS_IMAGE_ID="${IMS_RESULTANT_IMAGE_ID}"
      ```

1. (`ncn-mw#`) Determine the component names (xnames) for the management nodes which will boot from the new image.

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

1. (`ncn-mw#`) Update boot parameters for a management node.

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

            **NOTE:** This uses the `NEW_IMS_IMAGE_ID` variable set in an earlier step.

            ```bash
            S3_ARTIFACT_PATH="boot-images/${NEW_IMS_IMAGE_ID}"
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

            In the output of the `echo` command, verify that the value of `metal.server` is
            correctly set to the value of `${NEW_METAL_SERVER}`.

    1. Update BSS with the new boot parameters.

        ```bash
        cray bss bootparameters update --hosts "${XNAME}" \
            --kernel "s3://${S3_ARTIFACT_PATH}/kernel" \
            --initrd "s3://${S3_ARTIFACT_PATH}/initrd" \
            --params "${PARAMS}"
        ```

## Next steps

If a particular step of this procedure is being performed as part of a CSM upgrade, then return
to [Stage 0.3 - Update management node CFS configuration and customize worker node image](../../upgrade/Stage_0_Prerequisites.md#stage-03---update-management-node-cfs-configuration-and-customize-worker-node-image).

If this procedure is being performed as an operational task outside the context of an install or upgrade,
then proceed to [Rebuild NCNs](../node_management/Rebuild_NCNs/Rebuild_NCNs.md)
when ready to reboot the management nodes to their new images.
