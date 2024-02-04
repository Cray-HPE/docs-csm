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

    * Kubernetes ID

      ```bash
      KUBERNETES_IMAGE_ID="$(kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' \
        | yq r -j - '"'${CSM_RELEASE}'".images' \
        | jq -r '. as $o | keys_unsorted[] | select(startswith("secure-kubernetes")) | $o[.].id')"
      export KUBERNETES_IMAGE_ID
      echo "KUBERNETES_IMAGE_ID=$KUBERNETES_IMAGE_ID"
      ```

    * Storage-CEPH ID

      ```bash
      STORAGE_IMAGE_ID="$(kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' \
        | yq r -j - '"'${CSM_RELEASE}'".images' \
        | jq -r '. as $o | keys_unsorted[] | select(startswith("secure-storage")) | $o[.].id')"
      export STORAGE_IMAGE_ID
      echo "STORAGE_IMAGE_ID=$STORAGE_IMAGE_ID"
      ```

1. Create new CFS sessions for both Kubernetes and Storage nodes.

    1. Build master images.

       ```bash
       cray cfs sessions create \
           --target-group Management_Master \
           "$KUBERNETES_IMAGE_ID" \
           --target-definition image \
           --target-image-map "$KUBERNETES_IMAGE_ID" "" \
           --configuration-name "management-${CSM_RELEASE}" \
           --name "management-kubernetes-${CSM_RELEASE}-upgrade" \
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

1. Wait for the image builds to complete successfully

   ```bash
   watch '
   cray cfs sessions describe "management-kubernetes-${CSM_RELEASE}-upgrade" --format json | jq -r ".status.session.succeeded"
   cray cfs sessions describe "management-storage-${CSM_RELEASE}-upgrade" --format json | jq -r ".status.session.succeeded"
   '
   ```

   Expected results:

   ```text
   true
   true
   ```

1. Set the image ID

    * Kubernetes ID

      ```bash
      NEW_KUBERNETES_IMAGE_ID="$(cray cfs sessions describe "management-kubernetes-${CSM_RELEASE}-upgrade" --format json | jq -r '.status.artifacts[].image_id')"
      export NEW_KUBERNETES_IMAGE_ID
      echo "NEW_KUBERNETES_IMAGE_ID=$NEW_KUBERNETES_IMAGE_ID"
      ```

    * Storage-CEPH

      ```bash
      NEW_STORAGE_IMAGE_ID="$(cray cfs sessions describe "management-storage-${CSM_RELEASE}-upgrade" --format json | jq -r '.status.artifacts[].image_id')"
      export NEW_STORAGE_IMAGE_ID
      echo "NEW_STORAGE_IMAGE_ID=$NEW_STORAGE_IMAGE_ID"
      ```

1. Assign images in BSS

    1. Update Kubernetes management nodes:

       ```bash
       /usr/share/doc/csm/scripts/operations/configuration/node_management/assign-ncn-images.sh \
           -mw \
           -p "$NEW_KUBERNETES_IMAGE_ID"
       ```

    1. Update storage management nodes:

       ```bash
       /usr/share/doc/csm/scripts/operations/configuration/node_management/assign-ncn-images.sh \
           -s \
           -p "$NEW_STORAGE_IMAGE_ID"
       ```

1. Return to [](./README.md#wlm-backup)
