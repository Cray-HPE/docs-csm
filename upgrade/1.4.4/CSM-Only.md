# CSM Only Upgrade

This page provides guidance for systems with exclusively CSM installed that are performing an upgrade from a CSM v1.4.X release to the CSM v1.4.4 release.

The [v1.4.4 upgrade page](../1.4.4/README.md) will refer to this page
during [Update NCN images](../1.4.4/README.md#update-ncn-images).

**If other products are installed on the system, return to [Update NCN images](../1.4.4/README.md#update-ncn-images) and
choose option 2.**

## Requirements

* `CSM_RELEASE` is set in the shell environment on `ncn-m001`. See [Preparation](README.md#preparation) for details on how it should be set.

## Steps

1. (`ncn-m001#`) Generate a new [CFS](../../glossary.md#configuration-framework-service-cfs) configuration for the management nodes.

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

1. (`ncn-m001#`) Set the [IMS](../../glossary.md#image-management-service-ims) IDs for each Management node sub-role.

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

1. (`ncn-m001#`) Create CFS sessions for both Kubernetes and Storage nodes.

    1. Set variables with unique names for the CFS sessions to be created.

       ```bash
       TSTAMP=$(date "+%Y%m%d%H%M%S")
       K8S_CFS_SESSION_NAME="management-k8s-${CSM_RELEASE}-${TSTAMP}"
       CEPH_CFS_SESSION_NAME="management-ceph-${CSM_RELEASE}-${TSTAMP}"
       ```

    1. Build customized master node images.

       ```bash
       cray cfs sessions create \
           --target-group Management_Master \
           "$KUBERNETES_IMAGE_ID" \
           --target-definition image \
           --target-image-map "$KUBERNETES_IMAGE_ID" "management-kubernetes-${CSM_RELEASE}" \
           --configuration-name "management-${CSM_RELEASE}" \
           --name "${K8S_CFS_SESSION_NAME}" \
           --format json
       ```

    1. Build customized storage node images.

       ```bash
       cray cfs sessions create \
           --target-group Management_Storage \
           "$STORAGE_IMAGE_ID" \
           --target-definition image \
           --target-image-map "$STORAGE_IMAGE_ID" "management-storage-${CSM_RELEASE}" \
           --configuration-name "management-${CSM_RELEASE}" \
           --name "${CEPH_CFS_SESSION_NAME}" \
           --format json
       ```

1. (`ncn-m001#`) Wait for the image builds to complete successfully.

   > This may take over 20 minutes to complete.

   ```bash
   watch '
   cray cfs sessions describe "${K8S_CFS_SESSION_NAME}" --format json | jq -r ".status.session.succeeded"
   cray cfs sessions describe "${CEPH_CFS_SESSION_NAME}" --format json | jq -r ".status.session.succeeded"
   '
   ```

   Expected results:

   ```text
   true
   true
   ```

1. (`ncn-m001#`) Set environment variables with the IMS image IDs.

    * Kubernetes image IMS ID

      ```bash
      NEW_KUBERNETES_IMAGE_ID="$(cray cfs sessions describe "${K8S_CFS_SESSION_NAME}" --format json | jq -r '.status.artifacts[].result_id')"
      export NEW_KUBERNETES_IMAGE_ID
      echo "NEW_KUBERNETES_IMAGE_ID=$NEW_KUBERNETES_IMAGE_ID"
      ```

    * Storage image IMS ID

      ```bash
      NEW_STORAGE_IMAGE_ID="$(cray cfs sessions describe "${CEPH_CFS_SESSION_NAME}" --format json | jq -r '.status.artifacts[].result_id')"
      export NEW_STORAGE_IMAGE_ID
      echo "NEW_STORAGE_IMAGE_ID=$NEW_STORAGE_IMAGE_ID"
      ```

1. (`ncn-m001#`) Assign images in [BSS](../../glossary.md#boot-script-service-bss).

    1. Update Kubernetes management nodes:

       ```bash
       /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh \
           -mw \
           -p "$NEW_KUBERNETES_IMAGE_ID"
       ```

    1. Update storage management nodes:

       ```bash
       /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh \
           -s \
           -p "$NEW_STORAGE_IMAGE_ID"
       ```

1. Return to [](./README.md#wlm-backup)
