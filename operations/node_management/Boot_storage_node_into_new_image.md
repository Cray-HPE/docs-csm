# Boot a storage node into new image without upgrading CSM

## Purpose

This procedure is needed anytime a storage node is booted into a new image except for during a CSM upgrade.
For example, if a storage node image been rebuilt, then this procedure is necessary to boot storage nodes into the newly built image.
This procedure is not necessary when upgrading a storage node from one CSM major release to the next major release.

Instead of following this procedure to upgrade the storage nodes into the new image, the storage nodes could also be rebuilt into the new image.
A storage node rebuild means that the storage node will be wiped and it will take Ceph longer to recover once the node is rebooted.
This procedure is beneficial in that it will not wipe the storage nodes and Ceph should recover quicker than if the nodes were rebuilt.

## Reason for error

When a storage node is booted into a new node image, the storage node is not wiped.
Because the storage node is not wiped, the `rd.live.dir` still exists when the node is rebooted.
This is due to a change in how `rd.live.overlay.reset` works in CSM 1.5 and 1.6.
If the `rd.live.dir` is not changed when booting a storage node to a new node image, the new image will not be pulled since the `rd.live.dir` still exists. This causes `cloud-init` to fail on the storage node.
To avoid this issue and ensure the new node image is pulled, the `rd.live.dir` should be set to unique value.
In this procedure, the `STORAGE_NODE_IMAGE_ID` is used as the unique value.

This issue is not hit when upgrading from one CSM major release to the next CSM major release because the `rd.live.dir` is changed on all NCNs to the new CSM major release version. This allows the node image to be pulled successfully during `cloud-init`.

> Note: In CSM 1.7, this procedure is no longer needed. Instead, a normal storage node upgrade will pull the correct image even if `rd.live.dir` did not change.

## Procedure overview

This procedure will upgrade storage nodes using the normal Argo workflow framework.
Prior to upgrading the storage node, the `rd.live.dir` will be set to the `STORAGE_NODE_IMAGE_ID`. Because this is a unique value, the node image will be pulled successfully during `cloud-init`.

This procedure can be followed prior to booting a storage node into a new image or
if a storage node has already attempted to boot into a new image and it failed in `cloud-init` due to `rd.live.dir` already existing.

If the storage node is currently being upgraded and `cloud-init` failed, it is best to leave the Argo Workflow running while following the procedure below.
It is okay if the workflow has already been stopped, a step will provide instructions for resuming it.

## Procedure

1. (`ncn-m001#`) Set `TARGET_NCN` to the storage node hostname for the node that will be booted into a new image.

    ```bash
    TARGET_NCN=ncn-s00X
    ```

1. (`ncn-m001#`) Set the image ID of the image that the node should be booted into.

    ```bash
    STORAGE_NODE_IMAGE_ID=<image_id>
    ```

1. (`ncn-m001#`) Set the `TOKEN` and `TARGET_XNAME` variables. These variables are needed in subsequent steps.

    ```bash
    export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
    -d client_id=admin-client \
    -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

    TARGET_XNAME=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" \
    | jq -r ".[] | select(.ExtraProperties.Aliases[] | contains(\"$TARGET_NCN\")) | .Xname")
    echo "TARGET_XNAME: $TARGET_XNAME"
    ```

1. (`ncn-m001#`) Set the `rd.live.dir` on the `TARGET_NCN` to the `STORAGE_NODE_IMAGE_ID`. This ensures `rd.live.dir` will be a unique value.

    ```bash
    csi handoff bss-update-param --delete rd.live.dir --limit "${TARGET_XNAME}"
    csi handoff bss-update-param --set rd.live.dir=${STORAGE_NODE_IMAGE_ID} --limit "${TARGET_XNAME}"
    ```

1. (`ncn-m001#`) Follow the steps for one of the two options depending on the status of the storage node.

    * **Option 1:** Start a new storage node upgrade if one has not already been started.

        > Note: if a new CFS configuration is also necessary, append the argument `--desired-cfs-conf <configuration>` to the command below.

        ```bash
        /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh $TARGET_NCN --upgrade --image-id $STORAGE_NODE_IMAGE_ID
        ```

    * **Option 2:** If a storage node has already attempted to boot into a new image and `cloud-init` has failed, manually power cycle the node.

        The following error will be seen in `cloud-init` if a storage node has already been attempted to be upgraded without setting `rd.live.dir` to a new unique value.
        This error can be seen for the node's console. See [log in to a node using ConMan](../conman/Log_in_to_a_Node_Using_ConMan.md).

        ```text
        [ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHETC.
        [DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHETC.
        [DEPEND] Dependency failed for /etc/ceph.
        [DEPEND] Dependency failed for Local File Systems.
        [DEPEND] Dependency failed for Early Kernel Boot Messages.
        [ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHVAR.
        [DEPEND] Dependency failed for /var/lib/ceph.
        [DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHVAR.
        ```

        1. (`ncn-m001#`) Power cycle the storage node. Follow the steps in [Power Cycle and Rebuild Nodes](./Rebuild_NCNs/Power_Cycle_and_Rebuild_Nodes.md) to power cycle the node. Do not perform steps after "wait for `cloud-init`".
        These steps are unnecessary and will be completed by the remaining steps of the storage node upgrade Argo Workflow.

        1. (`ncn-m001#`) Perform this step only if the Argo workflow for the storage node upgrade was stopped.
        Resume the workflow by simply rerunning the same command that initiated the upgrade workflow.
        When a workflow is in-progress or a workflow has failed, that same workflow will be resumed and no new workflow will be started by running the command.

            ```bash
            /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh $TARGET_NCN --upgrade --image-id $STORAGE_NODE_IMAGE_ID
            ```

1. (`ncn-m001#`) Monitor the Argo Workflow using the Argo UI. See [using the Argo UI](../argo/Using_the_Argo_UI.md) for instructions to access the Argo UI.

1. (`ncn-m001#`) Once the upgrade has succeeded, remove old images on the storage node.

    ```bash
    ssh $TARGET_NCN '/srv/cray/scripts/metal/cleanup-live-images.sh -y -o'
    ```

1. (`ncn-m001#`) Check that Ceph is healthy.

    ```bash
    ceph -s
    ```
