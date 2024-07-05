# CSM Only Upgrade on a System with Other Products

This page provides guidance for systems with products installed that are performing an upgrade from a CSM `v1.5.X` release to the CSM `v1.5.2` release.

The [`v1.5.2` upgrade page](../1.5.2/README.md) will refer to this page
during [Update NCN images](../1.5.2/README.md#update-ncn-images).

**If exclusively CSM is installed on the system, return to [Update NCN images](../1.5.2/README.md#update-ncn-images) and
choose option 2.**

## Requirements

* `CSM_RELEASE_VERSION` is set in the shell environment on `ncn-m001`. See [Preparation](README.md#preparation) for details on how it should be set.

* Set `CSM_RELEASE` in the shell environment to the same value as `CSM_RELEASE_VERSION`.

    ```bash
   export CSM_RELEASE="${CSM_RELEASE_VERSION}"
   echo "${CSM_RELEASE}"
   ```

## Overview

This process creates new NCN node images and CFS configurations in order to acquire any changes from CSM config.
These images and CFS configurations will be assigned to the NCNs during this process.
Later in the CSM `v1.5.2` patch process, nodes will be rebooted into these images and the CFS configuration will be applied to the nodes.

## Steps

### Using `sat bootprep` with IUF generated input files

The name of the IUF activity used to install the HPE Cray EX software products must be known before proceeding. See the
[Activities](../../operations/iuf/IUF.md#activities) section of the IUF documentation for more
information on IUF activities. See [`list-activities`](../../operations/iuf/IUF.md#list-activities)
for information about listing the IUF activities on the system. The first step provides an
example showing how to find the IUF activity.

1. (`ncn-m001#`) Find the IUF activity used for the most recent install of the system.

   ```bash
   iuf list-activities
   ```

   This will output a list of IUF activity names. For example, if only a single install has been
   performed on this system of the 24.01 recipe, the output may show a single line like this:

   ```text
   24.01-recipe-install
   ```

1. (`ncn-m001#`) Record the most recent IUF activity name and directory in environment variables.

   ```bash
   export ACTIVITY_NAME=
   ```

   ```bash
   export ACTIVITY_DIR="/etc/cray/upgrade/csm/iuf/${ACTIVITY_NAME}"
   ```

1. (`ncn-m001#`) Record the media directory used for this activity in an environment variable.

   ```bash
   export MEDIA_DIR="$(yq r "${ACTIVITY_DIR}/state/stage_hist.yaml" 'summary.media_dir')"
   echo "${MEDIA_DIR}"
   ```

   This should display a path to a media directory. For example:

   ```text
   /etc/cray/upgrade/csm/media/24.01-recipe-install
   ```

1. (`ncn-m001#`) Create a directory for the `sat bootprep` input files and the `session_vars.yaml` file.

   This example uses a directory under the RBD mount used by the IUF:

   ```bash
   export BOOTPREP_DIR="/etc/cray/upgrade/csm/admin/bootprep-csm-${CSM_RELEASE}"
   mkdir -pv "${BOOTPREP_DIR}"
   ```

1. (`ncn-m001#`) Copy the `sat bootprep` input file for management nodes into the directory.

   It is possible that the file name will differ from `management-bootprep.yaml` if a different
   file was used during the IUF activity.

   ```bash
   cp -pv "${MEDIA_DIR}/.bootprep-${ACTIVITY_NAME}/management-bootprep.yaml" "${BOOTPREP_DIR}"
   ```

1. (`ncn-m001#`) Copy the `session_vars.yaml` file into the directory.

   ```bash
   cp -pv "${ACTIVITY_DIR}/state/session_vars.yaml" "${BOOTPREP_DIR}"
   ```

   > Update the `session_vars.yaml` file as needed based on the product
   > versions that are installed on the system.

1. (`ncn-m001#`) Modify the CSM version in the copied `session_vars.yaml`:

   ```bash
   yq w -i "${BOOTPREP_DIR}/session_vars.yaml" 'csm.version' "${CSM_RELEASE}"
   ```

1. (`ncn-m001#`) Update the `working_branch` if one is used for the CSM product.

   By default, a `working_branch` is not used for the CSM product. Check if there is a
   `working_branch` specified for CSM:

   ```bash
   yq r "${BOOTPREP_DIR}/session_vars.yaml" 'csm.working_branch'
   ```

   If this produces no output, a `working_branch` is not in use for the CSM product, and this step
   can be skipped. Otherwise, it shows the name of the working branch. For example:

   ```text
   integration-1.4.0
   ```

   In this case, be sure to manually update the version string in the working branch to match the
   new working branch. Then check it again. For example:

   ```bash
   yq w -i "${BOOTPREP_DIR}/session_vars.yaml" 'csm.working_branch' "integration-${CSM_RELEASE}"
   yq r "${BOOTPREP_DIR}/session_vars.yaml" 'csm.working_branch'
   ```

   This should output the name of the new CSM working branch.

1. (`ncn-m001#`) Modify the `default.suffix` value in the copied `session_vars.yaml`:

   As long as the `sat bootprep` input file uses `{{default.suffix}}` in the names of the CFS
   configurations and IMS images, this will ensure new CFS configurations and IMS images are created
   with different names from the ones created in the IUF activity.

   ```bash
   yq w -i -- "${BOOTPREP_DIR}/session_vars.yaml" 'default.suffix' "-csm-${CSM_RELEASE}"
   ```

1. (`ncn-m001#`) Change directory to the `BOOTPREP_DIR` and run `sat bootprep`.

   This will create a CFS configuration for management nodes, and it will use that CFS configuration
   to customize the images for the master, worker, and storage management nodes.

   ```bash
   cd "${BOOTPREP_DIR}"
   sat bootprep run --vars-file session_vars.yaml management-bootprep.yaml
   ```

1. (`ncn-m001#`) Gather the CFS configuration name, and the IMS image names from the output of `sat bootprep`.

   `sat bootprep` will print a report summarizing the CFS configuration and IMS images it created.
   For example:

   ```text
   ################################################################################
   CFS configurations
   ################################################################################
   +-----------------------------+
   | name                        |
   +-----------------------------+
   | management-22.4.0-csm-x.y.z |
   +-----------------------------+
   ################################################################################
   IMS images
   ################################################################################
   +-----------------------------+--------------------------------------+--------------------------------------+-----------------------------+----------------------------+
   | name                        | preconfigured_image_id               | final_image_id                       | configuration               | configuration_group_names  |
   +-----------------------------+--------------------------------------+--------------------------------------+-----------------------------+----------------------------+
   | master-secure-kubernetes    | c1bcaf00-109d-470f-b665-e7b37dedb62f | a22fb912-22be-449b-a51b-081af2d7aff6 | management-22.4.0-csm-x.y.z | Management_Master          |
   | worker-secure-kubernetes    | 8b1343c4-1c39-4389-96cb-ccb2b7fb4305 | 241822c3-c7dd-44f8-98ca-0e7c7c6426d5 | management-22.4.0-csm-x.y.z | Management_Worker          |
   | storage-secure-storage-ceph | f3dd7492-c4e5-4bb2-9f6f-8cfc9f60526c | 79ab3d85-274d-4d01-9e2b-7c25f7e108ca | storage-22.4.0-csm-x.y.z    | Management_Storage         |
   +-----------------------------+--------------------------------------+--------------------------------------+-----------------------------+----------------------------+
   ```

   1. Save the names of the CFS configurations from the `configuration` column:

      > Note that the storage node configuration might be titled `minimal-management-` or `storage-` depending on the value
      > set in the sat `bootprep` file.
      >
      > The following uses the values from the example output above. Be sure to modify them
      > to match the actual values.

      ```bash
      export KUBERNETES_CFS_CONFIG_NAME="management-22.4.0-csm-x.y.z"
      export STORAGE_CFS_CONFIG_NAME="storage-22.4.0-csm-x.y.z"
      ```

   1. Save the name of the IMS images from the `final_image_id` column:

      > The following uses the values from the example output above. Be sure to modify them
      > to match the actual values.

      ```bash
      export MASTER_IMAGE_ID="a22fb912-22be-449b-a51b-081af2d7aff6"
      export WORKER_IMAGE_ID="241822c3-c7dd-44f8-98ca-0e7c7c6426d5"
      export STORAGE_IMAGE_ID="79ab3d85-274d-4d01-9e2b-7c25f7e108ca"
      ```

1. (`ncn-m001#`) Assign the images to the management nodes in BSS.

   * Master management nodes:

      ```bash
      /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -m -p "$MASTER_IMAGE_ID"
      ```

   * Storage management nodes:

      ```bash
      /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -s -p "$STORAGE_IMAGE_ID"
      ```

   * Worker management nodes:

      ```bash
      /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -w -p "$WORKER_IMAGE_ID"
      ```

1. (`ncn-m001#`) Assign the CFS configuration to the management nodes.

   This deliberately only sets the desired configuration of the components in CFS. It
   disables the components and does not clear their configuration states or error counts. When the
   nodes are rebooted to their new images later in the CSM upgrade, they will automatically be
   enabled in CFS, and node personalization will occur.
  
   1. Get the xnames of the master and worker management nodes.

      ```bash
      WORKER_XNAMES=$(cray hsm state components list --role Management --subrole Worker --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")')
      MASTER_XNAMES=$(cray hsm state components list --role Management --subrole Master --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")')
      echo "${MASTER_XNAMES},${WORKER_XNAMES}"
      ```

   1. Apply the CFS configuration to master nodes and worker nodes using the xnames and CFS configuration name found in the previous steps.

      ```bash
      /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
          --no-config-change --config-name "${KUBERNETES_CFS_CONFIG_NAME}" --no-enable --no-clear-err \
          --xnames ${MASTER_XNAMES},${WORKER_XNAMES}
      ```

      Successful output will end with the following:

      ```text
      All components updated successfully.
      ```

   1. Get the xnames of the storage management nodes.

      ```bash
      STORAGE_XNAMES=$(cray hsm state components list --role Management --subrole Storage --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")')
      echo $STORAGE_XNAMES
      ```

   1. Apply the CFS configuration to storage nodes using the xnames and CFS configuration name found in the previous steps.

      ```bash
      /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
          --no-config-change --config-name "${STORAGE_CFS_CONFIG_NAME}" --no-enable --no-clear-err \
          --xnames ${STORAGE_XNAMES}
      ```

      Successful output will end with the following:

      ```text
      All components updated successfully.
      ```

## Return to CSM `1.5.2` patch

Return to [Update test suite packages](./README.md#update-test-suite-packages).
