# CSM Only Upgrade

This page provides guidance exclusively for systems upgrading CSM v1.4.X to CSM v1.4.4.

The [v1.4.4](../1.4.4/README.md) upgrade page will refer to this page
during [Update NCN images](../1.4.4/README.md#update-ncn-images).

**If other products are installed on the system, return to [Update NCN images](../1.4.4/README.md#update-ncn-images) and
choose option 2.**

## Requirements

* `CSM_RELEASE` is set in the shell environment on `ncn-m001`.

## Steps

1. (`ncn-m001#`) Generate a new CFS configuration for the management nodes.

   This script creates a new CFS configuration that includes the CSM version in its name and applies it to the
   management nodes. This leaves the management node components in CFS disabled. They will be automatically enabled when
   they are rebooted at a later stage in the upgrade.

   ```bash
   /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
       --no-enable --config-name "management-${CSM_RELEASE}"
   ```

   Successful output should end with the following line:

   ```text
   All components updated successfully.
   ```

1. Set the IMS IDs for each Management node sub-role.

   ```bash
   export MASTER_IMAGE_ID=""
   ```

   ```bash
   export WORKER_IMAGE_ID=""
   ```

   ```bash
   export STORAGE_IMAGE_ID=""
   ```

1. Create new CFS sessions for both Kubernetes and Storage nodes.

    1. Build master images.

       ```bash
       cray cfs sessions create \
           --target-group Management_Master \
           "$MASTER_IMAGE_ID" \
           --target-definition image \
           --target-image-map "$MASTER_IMAGE_ID" "" \
           --configuration-name "management-${CSM_RELEASE}" \
           --name "management-master-${CSM_RELEASE}-upgrade" \
           --format json
       ```

    1. Build storage images.

       ```bash
       cray cfs sessions create \
           --target-group Management_Storage \
           "$STORAGE_IMAGE_ID" \
           --target-definition image \
           --target-image-map "$STORAGE_IMAGE_ID" "" \
           --configuration-name "management-${CSM_RELEASE}" \
           --name "management-storage-${CSM_RELEASE}-upgrade" \
           --format json
       ```

    1. Build worker images.

       ```bash
       cray cfs sessions create \
           --target-group Management_Worker \
           "$WORKER_IMAGE_ID" \
           --target-definition image \
           --target-image-map"$WORKER_IMAGE_ID" "" \
           --configuration-name "management-${CSM_RELEASE}" \
           --name "management-worker-${CSM_RELEASE}-upgrade" \
           --format json
       ```

1. Wait forever for images to build.

1. Set the new IMS Image IDs

   ```bash
   export NEW_MASTER_IMAGE_ID=""
   ```

   ```bash
   export NEW_WORKER_IMAGE_ID=""
   ```

   ```bash
   export NEW_STORAGE_IMAGE_ID=""
   ```

1. Assign images in BSS

    1. Update master management nodes:

       ```bash
       /usr/share/doc/csm/scripts/operations/configuration/node_management/assign-ncn-images.sh \
           -m \
           -p "$NEW_MASTER_IMAGE_ID"
       ```

    1. Update storage management nodes:

       ```bash
       /usr/share/doc/csm/scripts/operations/configuration/node_management/assign-ncn-images.sh \
           -s \
           -p "$NEW_STORAGE_IMAGE_ID"
       ```

    1. Update worker management nodes:

       ```bash
       /usr/share/doc/csm/scripts/operations/configuration/node_management/assign-ncn-images.sh \
           -w \
           -p "$NEW_WORKER_IMAGE_ID"
       ```

1. Return to [](./README.md#wlm-backup)
