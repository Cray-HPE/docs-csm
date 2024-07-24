# Management rollout

This section updates the software running on management NCNs.

- [1. Perform Slingshot switch firmware updates](#1-perform-slingshot-switch-firmware-updates)
- [2. Update management host firmware (FAS)](#2-update-management-host-firmware-fas)
- [3. Execute the IUF `management-nodes-rollout` stage](#3-execute-the-iuf-management-nodes-rollout-stage)
    - [3.1 `management-nodes-rollout` with CSM upgrade](#31-management-nodes-rollout-with-csm-upgrade)
    - [3.2 `management-nodes-rollout` without CSM upgrade](#32-management-nodes-rollout-without-csm-upgrade)
    - [3.3 NCN worker nodes](#33-ncn-worker-nodes)
    - [3.4 Personalize NCN storage nodes](#34-personalize-ncn-storage-nodes)
- [4. Update management host Slingshot NIC firmware](#4-update-management-host-slingshot-nic-firmware)
- [5. Next steps](#5-next-steps)

## 1. Perform Slingshot switch firmware updates

Instructions to perform Slingshot switch firmware updates are provided in the "Upgrade Slingshot Switch Firmware on HPE Cray EX" section of the _HPE Slingshot Operations Guide_.

Once this step has completed:

- Slingshot switch firmware has been updated

## 2. Update management host firmware (FAS)

Refer to [Update Non-Compute Node (NCN) BIOS and BMC Firmware](../../firmware/FAS_Use_Cases.md#update-non-compute-node-ncn-bios-and-bmc-firmware) for details on how to upgrade the firmware on management nodes.

Once this step has completed:

- Host firmware has been updated on management nodes

## 3. Execute the IUF `management-nodes-rollout` stage

This section describes how to update software on management nodes. It describes how to test a new image and CFS configuration on a single node first to ensure they work as expected before rolling the changes out to the other management
nodes. This initial test node is referred to as the "canary node". Modify the procedure as necessary to accommodate site preferences for rebuilding management nodes. The images and CFS configurations used are created by the
`prepare-images` and `update-cfs-config` stages respectively; see the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation for details on how to query the images and CFS configurations and see the
[update-cfs-config](../stages/update_cfs_config.md) documentation for details about how the CFS configuration is updated.

**`NOTE`** Additional arguments are available to control the behavior of the `management-nodes-rollout` stage, for example `--limit-management-rollout` and `-cmrp`. See the
[`management-nodes-rollout` stage documentation](../stages/management_nodes_rollout.md) for details and adjust the examples below if necessary.

**`IMPORTANT`** There is a different procedure for `management-nodes-rollout` depending on whether or not CSM is being upgraded. The two procedures differ in the handling of NCN master nodes. If CSM is not
being upgraded, then NCN master nodes will not be upgraded with new images and will be updated by the CFS configuration created in [update-cfs-config](../stages/update_cfs_config.md) only. If CSM is being
upgraded, the NCN master nodes will be upgraded with new images and the new CFS configuration. Both procedures use the same steps for rebuilding/upgrading NCN worker nodes and personalizing NCN storage nodes. Select **one** of the following
procedures based on whether or not CSM is being upgraded:

- [`management-nodes-rollout` with CSM upgrade](#31-management-nodes-rollout-with-csm-upgrade)
- [`management-nodes-rollout` without CSM upgrade](#32-management-nodes-rollout-without-csm-upgrade)

### 3.1 `management-nodes-rollout` with CSM upgrade

NCN master nodes and NCN worker nodes will be upgraded to a new image because CSM itself is being upgraded. NCN master nodes, excluding `ncn-m001`, and NCN worker nodes will be upgraded with IUF.
`ncn-m001` will be upgraded with manual commands.
NCN storage nodes are not upgraded as part of the CSM 1.3 to CSM 1.4 upgrade, but they will be personalized with a CFS configuration created during IUF.
This section describes how to test a new image and CFS configuration on a single canary node for NCN master nodes and NCN worker nodes first before rolling it out to the other NCN master nodes and NCN worker nodes.
Follow the steps below to upgrade NCN master and worker nodes and to personalize NCN storage nodes.

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `management-nodes-rollout` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Personalize NCN storage nodes. Follow the procedure in section [3.4 Personalize NCN storage nodes](#34-personalize-ncn-storage-nodes) and then return to this procedure to complete the next step.

1. Perform the NCN master node upgrade on `ncn-m002` and `ncn-m003`.

    1. Use `kubectl` to label `ncn-m003` with `iuf-prevent-rollout=true` to ensure `management-nodes-rollout` only rebuilds the single NCN master node `ncn-m002`.

        (`ncn-m001#`) Label `ncn-m003` to prevent it from rebuilding.

        ```bash
        kubectl label nodes "ncn-m003" --overwrite iuf-prevent-rollout=true
        ```

        (`ncn-m001#`) Verify the IUF node label is present on the desired node.

        ```bash
        kubectl get nodes --show-labels | grep iuf-prevent-rollout
        ```

    1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on `ncn-m002`. This will rebuild `ncn-m002` with the
    new CFS configuration and image built in previous steps of the workflow.

        > **`NOTE`** If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../../kubernetes/encryption/README.md),
        then backup the `/etc/cray/kubernetes/encryption` directory on the master node before upgrading and restore the directory after the node has been upgraded.

        (`ncn-m001#`) Execute the `management-nodes-rollout` stage with `ncn-m002`.

        ```bash
        iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout --limit-management-rollout Management_Master
        ```

        > **`NOTE`** The `/etc/cray/kubernetes/encryption` directory should be restored if it was backed up. Once it is restored, the `kube-apiserver` on the rebuilt node should be restarted.
        See [Kubernetes `kube-apiserver` Failing](../../../troubleshooting/kubernetes/Kubernetes_Kube_apiserver_failing.md) for details on how to restart the `kube-apiserver`.

    1. Verify that `ncn-m002` booted successfully with the desired image and CFS configuration.

    1. Use `kubectl` to remove the `iuf-prevent-rollout=true` label from `ncn-m003` and add it to `ncn-m002`.

        (`ncn-m001#`) Remove label from `ncn-m003` and add it to `ncn-m002` to prevent it from rebuilding.

        ```bash
        kubectl label nodes "ncn-m002" --overwrite iuf-prevent-rollout=true
        kubectl label nodes "ncn-m003" --overwrite iuf-prevent-rollout-
        ```

        (`ncn-m001#`) Verify the IUF node label is present on the desired node.

        ```bash
        kubectl get nodes --show-labels | grep iuf-prevent-rollout
        ```

    1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on `ncn-m003`. This will rebuild `ncn-m003` with the new CFS configuration and image built in
    previous steps of the workflow.

        > **`NOTE`** If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../../kubernetes/encryption/README.md),
        then backup the `/etc/cray/kubernetes/encryption` directory on the master node before upgrading and restore the directory after the node has been upgraded.

        (`ncn-m001#`) Execute the `management-nodes-rollout` stage with `ncn-m003`.

        ```bash
        iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout --limit-management-rollout Management_Master
        ```

        > **`NOTE`** The `/etc/cray/kubernetes/encryption` directory should be restored if it was backed up. Once it is restored, the `kube-apiserver` on the rebuilt node should be restarted.

    1. Use `kubectl` to remove the `iuf-prevent-rollout=true` label from `ncn-m002`.

        (`ncn-m001#`) Remove label from `ncn-m002`.

        ```bash
        kubectl label nodes "ncn-m002" --overwrite iuf-prevent-rollout-
        ```

        (`ncn-m001#`) Verify the IUF node label is no longer set on `ncn-m002`.

        ```bash
        kubectl get nodes --show-labels | grep iuf-prevent-rollout
        ```

1. Perform the NCN worker node upgrade. To upgrade worker nodes, follow the procedure in section [3.3 NCN worker nodes](#33-ncn-worker-nodes) and then return to this procedure to complete the next step.

1. Upgrade `ncn-m001`.

    1. Follow the steps documented in [Stage 1.3 - `ncn-m001` upgrade](../../../upgrade/Stage_1.md#stage-13---ncn-m001-upgrade).
    **Stop** before performing the specific [upgrade `ncn-m001`](../../../upgrade/Stage_1.md#upgrade-ncn-m001) step and return to this document.

    1. Set the CFS configuration on `ncn-m001`.

        1. Get the image ID and CFS configuration created for management nodes during the `prepare-images` and `update-cfs-config` stages. Follow the instructions in the
        [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation to get the values for `final_image_id` and `configuration` with a
        `configuration_group_name` value matching `Management_Master`. These values will be used in the following steps.

        1. (`ncn-m#`) Set `CFS_CONFIG_NAME` to be the value for `configuration` found for `Management_Master` nodes in the the previous step.

            ```bash
            CFS_CONFIG_NAME=<appropriate configuration value>
            ```

        1. (`ncn-m#`) Get the xname of `ncn-m001`.

            ```bash
            XNAME=$(ssh ncn-m001 'cat /etc/cray/xname')
            echo "${XNAME}"
            ```

        1. (`ncn-m#`) Set the CFS configuration on `ncn-m001`.

            ```bash
            /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
            --no-config-change --config-name "${CFS_CONFIG_NAME}" --xnames "${XNAME}" --no-enable --no-clear-err
            ```

            The expected output is:

              ```bash
              All components updated successfully.
              ```

    1. Set the image in BSS for `ncn-m001` by following the [Set NCN boot image for `ncn-m001` and NCN storage nodes](../stages/management_nodes_rollout.md#set-ncn-boot-image-for-ncn-m001-or-ncn-storage-nodes)
    section of the [Management nodes rollout stage documentation](../stages/management_nodes_rollout.md).
    Set the `IMS_RESULTANT_IMAGE_ID` variable to the `final_image_id` for `Management_Master` found in the previous step.

    1. (`ncn-m002#`) Upgrade `ncn-m001`. This **must** be executed on **`ncn-m002`**.

        > **`NOTE`** If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../../kubernetes/encryption/README.md),
        then backup the `/etc/cray/kubernetes/encryption` directory on the master node before upgrading and restore the directory after the node has been upgraded.

        ```bash
        /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m001
        ```

        > **`NOTE`** The `/etc/cray/kubernetes/encryption` directory should be restored if it was backed up. Once it is restored, the `kube-apiserver` on the rebuilt node should be restarted.
        See [Kubernetes `kube-apiserver` Failing](../../../troubleshooting/kubernetes/Kubernetes_Kube_apiserver_failing.md) for details on how to restart the `kube-apiserver`.

1. Follow the steps documented in [Stage 1.4 - Upgrade `weave` and `multus`](../../../upgrade/Stage_1.md#stage-14---upgrade-weave-and-multus)

1. Follow the steps documented in [Stage 1.5 - `coredns` anti-affinity](../../../upgrade/Stage_1.md#stage-15---coredns-anti-affinity)

1. Follow the steps documented in [Stage 1.6 - Complete Kubernetes upgrade](../../../upgrade/Stage_1.md#stage-16---complete-kubernetes-upgrade).

Once this step has completed:

- NCN master nodes and NCN worker nodes have been upgraded to the image and CFS configuration created in the previous steps of this workflow. NCN storage nodes have been personalized.
- Per-stage product hooks have executed for the `management-nodes-rollout` stage

Continue to the next section [4. Update management host Slingshot NIC firmware](#4-update-management-host-slingshot-nic-firmware).

### 3.2 `management-nodes-rollout` without CSM upgrade

This is the procedure to rollout management nodes if CSM is not being upgraded. NCN worker node images contain kernel module content from non-CSM products and need to be rebuilt as part of the workflow.
Unlike NCN worker nodes, NCN master nodes and storage nodes do not contain kernel module content from non-CSM products. However, user-space non-CSM product content is still provided on NCN master nodes and storage nodes and thus the `prepare-images` and `update-cfs-config`
stages create a new image and CFS configuration for NCN master nodes and storage nodes. The CFS configuration layers ensure the non-CSM product content is applied correctly for both
image customization and node personalization scenarios. As a result, the administrator
can update NCN master and storage nodes using CFS configuration only.
Follow the following steps to complete the `management-nodes-rollout` stage.

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `management-nodes-rollout` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Rebuild the NCN worker nodes. Follow the procedure in section [3.3 NCN worker nodes](#33-ncn-worker-nodes) and then return to this procedure to complete the next step.

1. Personalize NCN storage nodes. Follow the procedure in section [3.4 Personalize NCN storage nodes](#34-personalize-ncn-storage-nodes) and then return to this procedure to complete the next step.

1. Personalize NCN master nodes.

    1. (`ncn-m#`) Get a comma-separated list of the xnames for all NCN master nodes and verify they are correct.

        ```bash
        MASTER_XNAMES=$(cray hsm state components list --role Management --subrole Master --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
        echo "Master node xnames: ${MASTER_XNAMES}"
        ```

    1. Get the CFS configuration created for management nodes during the `prepare-images` and `update-cfs-config` stages. Follow the instructions in the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created)
       documentation to get the value for `configuration` for any image with a `configuration_group_name` value matching `Management_Master`,`Management_Worker`, or `Management_Storage` (since `configuration` is the same for all
       management nodes).

    1. (`ncn-m#`) Set `CFS_CONFIG_NAME` to the value for `configuration` found in the previous step.

        ```bash
        CFS_CONFIG_NAME=<appropriate configuration value>
        ```

    1. (`ncn-m#`) Apply the CFS configuration to NCN master nodes.

        ```bash
        /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
        --no-config-change --config-name "${CFS_CONFIG_NAME}" --xnames "${MASTER_XNAMES}" --clear-state
        ```

        The expected output is:

          ```bash
          Configuration complete. 3 component(s) completed successfully.  0 component(s) failed.
          ```

Once this step has completed:

- Management NCN worker nodes have been rebuilt with the image and CFS configuration created in previous steps of this workflow
- Management NCN storage and NCN master nodes have be updated with the CFS configuration created in the previous steps of this workflow.
- Per-stage product hooks have executed for the `management-nodes-rollout` stage

Continue to the next section [4. Update management host Slingshot NIC firmware](#4-update-management-host-slingshot-nic-firmware).

### 3.3 NCN worker nodes

NCN worker node images contain kernel module content from non-CSM products and need to be rebuilt as part of the workflow. This section describes how to test a new image and CFS configuration on a single canary node (`ncn-w001`) first before
rolling it out to the other NCN worker nodes. Modify the procedure as necessary to accommodate site preferences for rebuilding NCN worker nodes. Since the default node target for the `management-nodes-rollout` is `Management_Worker`
nodes, the `--limit-management-rollout` argument is not used in the instructions below.

The images and CFS configurations used are created by the `prepare-images` and `update-cfs-config` stages respectively; see the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation
for details on how to query the images and CFS configurations and see the [update-cfs-config](../stages/update_cfs_config.md) documentation for details about how the CFS configuration is updated.

**`NOTE`** The `management-nodes-rollout` stage creates additional separate Argo workflows when rebuilding NCN worker nodes. The Argo workflow names will include the string `ncn-lifecycle-rebuild`. If monitoring progress with the Argo UI,
remember to include these workflows.

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `management-nodes-rollout` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Use `kubectl` to label all NCN worker nodes but one with `iuf-prevent-rollout=true` to ensure `management-nodes-rollout` only rebuilds a single NCN worker node. This node is referred to as the canary node in the remainder of
this section and the steps are documented with `ncn-w001` as the canary node.

    (`ncn-m001#`) Label a NCN to prevent it from rebuilding. Replace the example value of `${HOSTNAME}` with the appropriate value. **Repeat this step for all NCN worker nodes except for the canary node.**

    ```bash
    HOSTNAME=ncn-w002
    kubectl label nodes "${HOSTNAME}" --overwrite iuf-prevent-rollout=true
    ```

    (`ncn-m001#`) Verify the IUF node labels are present on the desired node.

    ```bash
    kubectl get nodes --show-labels | grep iuf-prevent-rollout
    ```

1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on the canary node. This will rebuild the canary node with the new CFS configuration and image built in
previous steps of the workflow.

    (`ncn-m001#`) Execute the `management-nodes-rollout` stage with a single NCN worker node.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout
    ```

1. Verify the canary node booted successfully with the desired image and CFS configuration.

1. Use `kubectl` to remove the `iuf-prevent-rollout=true` label from all NCN worker nodes and apply it to the canary node to prevent it from unnecessarily rebuilding again.

    (`ncn-m001#`) Remove the label from a NCN to allow it to rebuild. Replace the example value of `${HOSTNAME}` with the appropriate value. **Repeat this step for all NCN worker nodes except for the canary node.**

    ```bash
    HOSTNAME=ncn-w002
    kubectl label nodes "${HOSTNAME}" --overwrite iuf-prevent-rollout-
    ```

    (`ncn-m001#`) Label the canary node to prevent it from rebuilding. Replace the example value of `${HOSTNAME}` with the hostname of the canary node.

    ```bash
    HOSTNAME=ncn-w001
    kubectl label nodes "${HOSTNAME}" --overwrite iuf-prevent-rollout=true
    ```

1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on all remaining NCN worker nodes. This will rebuild the nodes with the new CFS configuration and
image built in previous steps of the workflow.

    (`ncn-m001#`) Execute the `management-nodes-rollout` stage on all remaining worker and master nodes.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout
    ```

1. Use `kubectl` to remove the `iuf-prevent-rollout=true` label from the canary node. Replace the example value of `${HOSTNAME}` with the hostname of the canary node.

    ```bash
    HOSTNAME=ncn-w001
    kubectl label nodes "${HOSTNAME}" --overwrite iuf-prevent-rollout-
    ```

Once this step has completed:

- Management NCN worker nodes have been rebuilt with the image and CFS configuration created in previous steps of this workflow
- Per-stage product hooks have executed for the `management-nodes-rollout` stage

Return to the procedure that was being followed for `management-nodes-rollout` to complete the next step, either [Management-nodes-rollout with CSM upgrade](#31-management-nodes-rollout-with-csm-upgrade) or
[Management-nodes-rollout without CSM upgrade](#32-management-nodes-rollout-without-csm-upgrade).

## 3.4 Personalize NCN Storage Nodes

> **`NOTE`**
> A customized image is created for NCN storage nodes during the prepare images stage. For the upgrade from CSM 1.3 to CSM 1.4, that image is the same image that is running on NCN storage nodes so there is no need to 'upgrade' into that image.
> However, if it is desired to rollout the NCN storage nodes with the customized image, this can be done by following [upgrade NCN storage nodes into the customized image](../stages/management_nodes_rollout.md#upgrade-ncn-storage-nodes-into-the-customized-image).
> This is not the recommended procedure. It is recommended to personalize the NCN storage nodes by following the steps below.

1. Personalize NCN storage nodes.

    1. (`ncn-m#`) Get a comma-separated list of the xnames for all NCN storage nodes and verify they are correct.

        ```bash
        STORAGE_XNAMES=$(cray hsm state components list --role Management --subrole Storage --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
        echo "Storage node xnames: ${STORAGE_XNAMES}"
        ```

    1. Get the CFS configuration created for management nodes during the `update-cfs-config` stage. Follow the instructions in the
        [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created)
        documentation to get the value for `configuration` for images with a `configuration_group_name` value matching `Management_Storage`. This value will be needed in the following step.

    1. (`ncn-m#`) Set `CFS_CONFIG_NAME` to the value for `configuration` found in the previous step.

        ```bash
        CFS_CONFIG_NAME=<appropriate configuration value>
        ```

    1. (`ncn-m#`) Apply the CFS configuration to NCN storage nodes.

        ```bash
        /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
        --no-config-change --config-name "${CFS_CONFIG_NAME}" --xnames "${STORAGE_XNAMES}" --clear-state
        ```

        The expected output is:

          ```bash
          Configuration complete. 6 component(s) completed successfully.  0 component(s) failed.
          ```

Once this step has completed:

- NCN storage nodes have been updated with the CFS configuration created during update-CFS-config.

Return to the procedure that was being followed for `management-nodes-rollout` to complete the next step, either [Management-nodes-rollout with CSM upgrade](#31-management-nodes-rollout-with-csm-upgrade) or
[Management-nodes-rollout without CSM upgrade](#32-management-nodes-rollout-without-csm-upgrade).

## 4. Update management host Slingshot NIC firmware

If new Slingshot NIC firmware was provided, refer to the "200Gbps NIC Firmware Management" section of the  _HPE Slingshot Operations Guide_ for details on how to update NIC firmware on management nodes.

After updating management host Slingshot NIC firmware, all nodes where the firmware was updated must be power cycled.
Follow the [reboot NCNs procedure](../../node_management/Reboot_NCNs.md#ncn-worker-nodes) for all nodes where the firmware was updated.

Once this step has completed:

- New versions of product microservices have been deployed
- Service checks have been run to verify product microservices are executing as expected
- Per-stage product hooks have executed for the `deploy-product` and `post-install-service-check` stages

## 5. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM, return to the
  [Upgrade CSM and additional products with IUF](upgrade_csm_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.
