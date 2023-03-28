# Set NCN Image Root Password, SSH Keys, and Timezone

This page outlines procedures to modify the following things for [Non-Compute Nodes (NCNs)](../../glossary.md#non-compute-node-ncn):

- `root` user password
- `root` user SSH keys
- Timezone

All of the commands in this procedure are intended to be run on a single master or worker node.

- [Prerequisites](#prerequisites)
- [Changing `root` password and SSH keys](#changing-root-password-and-ssh-keys)
- [Changing timezone](#changing-timezone)

## Prerequisites

- This procedure can only be done after the PIT node is rebuilt to become a normal master node.
  - To change the NCN images from the PIT node during CSM installation, see [Set NCN Image Root Password, SSH Keys, and Timezone on PIT Node](Change_NCN_Image_Root_Password_and_SSH_Keys_on_PIT_Node.md).
- The Cray CLI must be configured on the node where the procedure is being done. See [Configure the Cray Command Line Interface](../configure_cray_cli.md).
- The CSM documentation RPM must be installed on the node where the procedure is being run. See [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Changing `root` password and SSH keys

In order to modify the `root` user password and/or SSH keys, first the desired values must be set in Vault. Then the
[Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
applies these changed values to the running management nodes via node personalization.

Note that this procedure does not change the `root` user password or SSH keys in the management node
images. If the management nodes are rebuilt from their images, they will use the SSH keys and `root`
user password from the image until node personalization completes via CFS.

1. Set the desired password and SSH keys in Vault.

   See [Configure the root password and SSH keys in Vault](../CSM_product_management/Configure_the_root_Password_and_SSH_Keys_in_Vault.md).

1. Make the changes on the running management nodes using node personalization.

   See [Management Node Personalization](../configuration_management/Management_Node_Personalization.md#re-run-node-personalization-on-management-nodes).

1. Make the changes to the NCN images (if desired).

   See [Management Node Image Customization](../configuration_management/Management_Node_Image_Customization.md).

## Changing timezone

The timezone only needs to be modified if a non-default (that is, non-UTC) timezone is desired. This procedure involves modifying the NCN image
artifacts, registering the modified images in the [Image Management Service (IMS)](../../glossary.md#image-management-service-ims), updating the
NCN entries in the [Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) to use the modified images,
and finally rebuilding the NCNs to make the changes take effect.

1. [Preparation](#1-preparation)
1. [Get NCN artifacts](#2-get-ncn-artifacts)
1. [Customize the images](#3-customize-the-images)
1. [Import new images into IMS](#4-import-new-images-into-ims)
1. [Update BSS](#5-update-bss)
1. [Cleanup](#6-cleanup)
1. [Rebuild NCNs](#7-rebuild-ncns)

### 1. Preparation

(`ncn-mw#`) Change to a working directory with enough space to hold the images once they have been expanded.

```bash
mkdir -pv /run/initramfs/overlayfs/workingarea && cd /run/initramfs/overlayfs/workingarea
```

### 2. Get NCN artifacts

The IMS image IDs of the current NCN images will be identified by examining the boot parameters of a Kubernetes NCN and a storage NCN in the
[Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss). This procedure can be used whether or not the NCNs in question are booted.
It obtains the boot image which will be used the next time that the NCN boots. This may not necessarily match what the NCN is currently booted with.

1. (`ncn-mw#`) Get the ID of the Kubernetes NCN image in IMS.

   1. Set `K8S_NCN_XNAME` to the [component name (xname)](../../glossary.md#xname) of a Kubernetes NCN.

      Since this procedure is being carried out on a Kubernetes NCN, the simplest thing to do is use the xname of the current node.

      ```bash
      K8S_NCN_XNAME=$(cat /etc/cray/xname)
      echo "${K8S_NCN_XNAME}"
      ```

   1. Extract the S3 path prefix for the image that will be used on the next boot of the chosen NCN.

      This prefix corresponds to the IMS image ID of the boot image.

      ```bash
      K8S_IMS_ID=$(cray bss bootparameters list --name "${K8S_NCN_XNAME}" --format json | \
                       jq -r '.[0].params' | \
                       sed 's#\(^.*[[:space:]]\|^\)metal[.]server=[^[:space:]]*/boot-images/\([^[:space:]]\+\)/rootfs.*#\2#')
      echo "${K8S_IMS_ID}"
      ```

      The output should be a UUID string. For example, `8f41cc54-82f8-436c-905f-869f216ce487`.

      > The command used in this substep is extracting the location of the NCN image from the `metal.server` boot parameter for the
      > NCN in BSS. For more information on that parameter, see [`metal.server` boot parameter](../../background/ncn_kernel.md#metalserver).

1. (`ncn-mw#`) Get the ID of the storage NCN image in IMS.

   1. Set `CEPH_NCN_XNAME` to the xname of a storage NCN.

      For example:

      ```bash
      CEPH_NCN_XNAME=$(ssh ncn-s001 cat /etc/cray/xname)
      echo "${CEPH_NCN_XNAME}"
      ```

   1. Get the IMS ID of the Ceph NCN image.

      ```bash
      CEPH_IMS_ID=$(cray bss bootparameters list --name "${CEPH_NCN_XNAME}" --format json | \
                       jq -r '.[0].params' | \
                       sed 's#\(^.*[[:space:]]\|^\)metal[.]server=[^[:space:]]*/boot-images/\([^[:space:]]\+\)/rootfs.*#\2#')
      echo "${CEPH_IMS_ID}"
      ```

      The output should be a UUID string. For example, `8f41cc54-82f8-436c-905f-869f216ce487`.

1. (`ncn-mw#`) Make temporary directories for the artifacts using the ID strings.

   ```bash
   K8S_DIR="$(pwd)/k8s/${K8S_IMS_ID}"
   CEPH_DIR="$(pwd)/ceph/${CEPH_IMS_ID}"
   mkdir -pv "${K8S_DIR}" "${CEPH_DIR}"
   ```

1. (`ncn-mw#`) Download the NCN artifacts.

   ```bash
   for art in rootfs initrd kernel ; do
       cray artifacts get boot-images "${K8S_IMS_ID}/${art}" "${K8S_DIR}/${art}"
       cray artifacts get boot-images "${CEPH_IMS_ID}/${art}" "${CEPH_DIR}/${art}"
   done
   ```

### 3. Customize the images

This is done by running the `ncn-image-modification.sh` script.

The Kubernetes NCN image location is specified with the `-k` argument to the script, and the storage NCN image location is
specified with the `-s` argument to the script. Both images should be customized with a single call to the script to ensure that
they receive matching customizations, unless specifically desiring otherwise.

The new customized images are created in their original image's directory. They have the same name as the original image, except
with the `secure-` prefix added. The original image is moved into a subdirectory named `old`, for backup purposes.

1. (`ncn-mw#`) Set the path to the script.

   ```bash
   NCN_MOD_SCRIPT=$(rpm -ql docs-csm | grep ncn-image-modification[.]sh)
   echo "${NCN_MOD_SCRIPT}"
   ```

1. (`ncn-mw#`) Designate the desired timezone for the NCN images.

   Set the `NCN_TZ` variable to the desired timezone (for example, `America/Chicago`).
   Valid timezone options can be listed by running `timedatectl list-timezones`.

   ```bash
   NCN_TZ=<desired timezone>
   echo "${NCN_TZ}"
   ```

1. (`ncn-mw#`) Run the script to change the timezone in the images.

   The default timezone in the NCN images is UTC. This is changed by passing the `-Z` argument to the script.

   ```bash
   "${NCN_MOD_SCRIPT}" -Z "${NCN_TZ}" \
                       -k ${K8S_DIR}/rootfs \
                       -s ${CEPH_DIR}/rootfs
   ```

### 4. Import new images into IMS

1. (`ncn-mw#`) Set the path to the IMS image upload script.

   ```bash
   NCN_IMS_IMAGE_UPLOAD_SCRIPT=$(rpm -ql docs-csm | grep ncn-ims-image-upload[.]sh)
   echo "$NCN_IMS_IMAGE_UPLOAD_SCRIPT}"
   ```

1. (`ncn-mw#`) Register the new Kubernetes image in IMS.

    ```bash
    NEW_K8S_IMS_ID=$( "${NCN_IMS_IMAGE_UPLOAD_SCRIPT}" --no-cpc \
                          -i "${K8S_DIR}/initrd" \
                          -k "${K8S_DIR}/kernel" \
                          -s "${K8S_DIR}/secure-rootfs" \
                          -n "rootfs-k8s-${K8S_IMS_ID}-tz" )
    echo "${NEW_K8S_IMS_ID}"
    ```

    The IMS ID (in UUID format) of the new Kubernetes image should be shown.

1. (`ncn-mw#`) Register the new Ceph image in IMS.

    ```bash
    NEW_CEPH_IMS_ID=$( "$NCN_IMS_IMAGE_UPLOAD_SCRIPT}" --no-cpc \
                          -i "${CEPH_DIR}/initrd" \
                          -k "${CEPH_DIR}/kernel" \
                          -s "${CEPH_DIR}/secure-rootfs" \
                          -n "rootfs-ceph-${CEPH_IMS_ID}-tz" )
    echo "${NEW_CEPH_IMS_ID}"
    ```

    The IMS ID (in UUID format) of the new Kubernetes image should be shown.

### 5. Update BSS

**WARNING:** If doing a CSM software upgrade, then skip this section and proceed to [Cleanup](#6-cleanup).

This step updates the entries in BSS for the NCNs to use the new images.

1. (`ncn-mw#`) Update BSS for master and worker nodes.

   1. Make a list of xnames of Kubernetes NCNs.

      ```bash
      K8S_XNAMES=( $(cray hsm state components list --role Management --type Node --format json |
                         jq -r '.Components | .[] | select( .SubRole == "Master" or .SubRole == "Worker" ) | .ID' |
                         tr '\n' ' ') )
      echo "${#K8S_XNAMES[@]} Kubernetes NCNs found: ${K8S_XNAMES[@]}"
      ```

   1. Update BSS entries for each Kubernetes NCN xname.

      > This uses the `K8S_IMS_ID` and `NEW_K8S_IMS_ID` variables defined earlier.

      ```bash
      for xname in "${K8S_XNAMES[@]}"; do
         echo "${xname}"
         cray bss bootparameters list --name "${xname}" --format json > "bss_${xname}.json" &&
         sed -i.$(date +%Y%m%d_%H%M%S%N).orig "s@/${K8S_IMS_ID}\([\"/[:space:]]\)@/${NEW_K8S_IMS_ID}\1@g" "bss_${xname}.json" &&
         kernel=$(cat "bss_${xname}.json" | jq -r '.[]  .kernel') &&
         initrd=$(cat "bss_${xname}.json" | jq -r '.[]  .initrd') &&
         params=$(cat "bss_${xname}.json" | jq -r '.[]  .params') &&
         cray bss bootparameters update --initrd "${initrd}" --kernel "${kernel}" --params "${params}" --hosts "${xname}" --format json ||
         echo "ERROR updating BSS for ${xname}"
      done
      ```

1. (`ncn-mw#`) Update BSS for utility storage nodes.

   1. Make a list of xnames of storage NCNs.

      ```bash
      CEPH_XNAMES=( $(cray hsm state components list --role Management --subrole Storage --type Node --format json | 
                          jq -r '.Components | map(.ID) | join(" ")') )
      echo "${#CEPH_XNAMES[@]} storage NCNs found: ${CEPH_XNAMES[@]}"
      ```

   1. Update BSS entries for each Kubernetes NCN xname.

      > This uses the `CEPH_IMS_ID` and `NEW_CEPH_IMS_ID` variables defined earlier.

      ```bash
      for xname in "${CEPH_XNAMES[@]}"; do
         echo "${xname}"
         cray bss bootparameters list --name "${xname}" --format json > "bss_${xname}.json" &&
         sed -i.$(date +%Y%m%d_%H%M%S%N).orig "s@/${CEPH_IMS_ID}\([\"/[:space:]]\)@/${NEW_CEPH_IMS_ID}\1@g" "bss_${xname}.json" &&
         kernel=$(cat "bss_${xname}.json" | jq -r '.[]  .kernel') &&
         initrd=$(cat "bss_${xname}.json" | jq -r '.[]  .initrd') &&
         params=$(cat "bss_${xname}.json" | jq -r '.[]  .params') &&
         cray bss bootparameters update --initrd "${initrd}" --kernel "${kernel}" --params "${params}" --hosts "${xname}" --format json ||
         echo "ERROR updating BSS for ${xname}"
      done
      ```

### 6. Cleanup

(`ncn-mw#`) Remove the temporary working area in order to reclaim the space.

```bash
rm -rvf /run/initramfs/overlayfs/workingarea
```

### 7. Rebuild NCNs

**WARNING:** If doing a CSM software upgrade, then skip this step because the upgrade process does a rolling rebuild with some additional steps.

Do a rolling rebuild of all NCNs. See [Rebuild NCNs](../node_management/Rebuild_NCNs/Rebuild_NCNs.md).
