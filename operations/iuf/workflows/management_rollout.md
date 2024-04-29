# Management rollout

This section updates the software running on management NCNs.

- [1. Perform Slingshot switch firmware updates](#1-perform-slingshot-switch-firmware-updates)
- [2. Update management host firmware (FAS)](#2-update-management-host-firmware-fas)
- [3. Execute the IUF `management-nodes-rollout` stage](#3-execute-the-iuf-management-nodes-rollout-stage)
    - [3.1 `management-nodes-rollout` with CSM upgrade](#31-management-nodes-rollout-with-csm-upgrade)
    - [3.2 `management-nodes-rollout` without CSM upgrade](#32-management-nodes-rollout-without-csm-upgrade)
    - [3.3 NCN worker nodes](#33-ncn-worker-nodes)
- [4. Update management host Slingshot NIC firmware](#4-update-management-host-slingshot-nic-firmware)
- [5. Next steps](#5-next-steps)

## 1. Perform Slingshot switch firmware updates

Instructions to perform Slingshot switch firmware updates are provided in the "Upgrade Slingshot Switch Firmware on HPE Cray EX" section of the _Slingshot Operations Guide for Customers_.

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

**`IMPORTANT`** There is a different procedure for `management-nodes-rollout` depending on whether or not CSM is being upgraded. The two procedures differ in the handling of NCN storage nodes and NCN master nodes. If CSM is not
being upgraded, then NCN storage nodes and NCN master nodes will not be upgraded with new images and will be updated by the CFS configuration created in [update-cfs-config](../stages/update_cfs_config.md) only. If CSM is being
upgraded, the NCN storage nodes and NCN master nodes will be upgraded with new images and the new CFS configuration. Both procedures use the same steps for rebuilding/upgrading NCN worker nodes. Select **one** of the following
procedures based on whether or not CSM is being upgraded:

- [`management-nodes-rollout` with CSM upgrade](#31-management-nodes-rollout-with-csm-upgrade)
- [`management-nodes-rollout` without CSM upgrade](#32-management-nodes-rollout-without-csm-upgrade)

### 3.1 `management-nodes-rollout` with CSM upgrade

All management nodes will be upgraded to a new image because CSM itself is being upgraded. All management nodes, excluding `ncn-m001`, will be upgraded with IUF.
`ncn-m001` will be upgraded with manual commands.
This section describes how to test a new image and CFS configuration on a single canary node first before rolling it out to the other management nodes of the same management type.
Follow the steps below to upgrade all management nodes.

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `management-nodes-rollout` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Perform the NCN storage node upgrades. This upgrades a single storage node first to test the storage node image and then upgrades the remaining storage nodes.

    **`NOTE`** The `management-nodes-rollout` stage creates additional separate Argo workflows when rebuilding NCN storage nodes. The Argo workflow names will include the string `ncn-lifecycle-rebuild`.
    If monitoring progress with the Argo UI, remember to include these workflows.

    1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage with a single NCN storage node.

        ```bash
        STORAGE_CANARY=ncn-s001
        ```

        ```bash
        iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout --limit-management-rollout ${STORAGE_CANARY}
        ```

    1. (`ncn-m#`) Verify that the storage canary node booted successfully with the desired CFS configuration.

        ```bash
        XNAME=$(ssh $STORAGE_CANARY 'cat /etc/cray/xname')
        echo "${XNAME}"
        cray cfs components describe "${XNAME}"
        ```

        The desired value for `configuration_status` is `configured`. If it is `pending`, then wait for the status to change to `configured`.

    1. (`ncn-m001#`) Upgrade the remaining NCN storage nodes once the first has upgraded successfully. This upgrades NCN storage nodes serially.
    Get the number of storage nodes based on the cluster and verify that it is correct. The storage canary node should not be in the list since it has already been upgraded.
    The list of storage nodes can be manually entered if it is not desired to upgrade all of the remaining storage nodes.

        ```bash
        STORAGE_NODES="$(ceph orch host ls | grep ncn-s | grep -v "$STORAGE_CANARY" | awk '{print $1}' | xargs echo)"
        echo "$STORAGE_NODES"
        ```

        ```bash
        iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout --limit-management-rollout ${STORAGE_NODES}
        ```

    1. (`ncn-m001#`) Verify that all storage nodes configured successfully.

        ```bash
        for ncn in $(cray hsm state components list --subrole Storage --type Node \
           --format json | jq -r .Components[].ID | grep b0n | sort); do cray cfs components describe \
           $ncn --format json | jq -r ' .id+" "+.desiredConfig+" status="+.configurationStatus'; done
        ```

1. Perform the NCN master node upgrade on `ncn-m002` and `ncn-m003`.

    1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on `ncn-m002`. This will rebuild `ncn-m002` with the new CFS configuration and image built in
    previous steps of the workflow.

        (`ncn-m001#`) Execute the `management-nodes-rollout` stage with `ncn-m002`.

        ```bash
        iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout --limit-management-rollout ncn-m002
        ```

    1. Verify that `ncn-m002` booted successfully with the desired image and CFS configuration.

        ```bash
        XNAME=$(ssh ncn-m002 'cat /etc/cray/xname')
        echo "${XNAME}"
        cray cfs components describe "${XNAME}"
        ```

    1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on `ncn-m003`. This will rebuild `ncn-m003` with the new CFS configuration and image built in
    previous steps of the workflow.

        (`ncn-m001#`) Execute the `management-nodes-rollout` stage with `ncn-m003`.

        ```bash
        iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout --limit-management-rollout ncn-m003
        ```

    1. Verify that `ncn-m003` booted successfully with the desired image and CFS configuration.

        ```bash
        XNAME=$(ssh ncn-m003 'cat /etc/cray/xname')
        echo "${XNAME}"
        cray cfs components describe "${XNAME}"
        ```

1. Perform the NCN worker node upgrade. To upgrade worker nodes, follow the procedure in section [3.3 NCN worker nodes](#33-ncn-worker-nodes) and then return to this procedure to complete the next step.

1. Upgrade `ncn-m001`.

    1. Follow the steps documented in [Stage 3.3 - `ncn-m001` upgrade](../../../upgrade/Stage_3.md#stage-33---ncn-m001-upgrade).
    **Stop** before performing the specific [upgrade `ncn-m001`](../../../upgrade/Stage_3.md#upgrade-ncn-m001) step and return to this document.

    1. Get the image ID and CFS configuration created for NCN master nodes during the `prepare-images` and `update-cfs-config` stages. Follow the instructions in the
    [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation to get the values for `final_image_id` and `configuration` for images with a `configuration_group_name` value matching `Management_Master`.
    These values will be needed for upgrading `ncn-m001` in the following steps.

    1. Set the CFS configuration on `ncn-m001`.

        1. (`ncn-m#`) Set `CFS_CONFIG_NAME` to be the value for `configuration` found for `Management_Master` nodes in the the second step.

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

    1. Set the image in BSS for `ncn-m001` by following the [Set NCN boot image for `ncn-m001`](../stages/management_nodes_rollout.md#set-ncn-boot-image-for-ncn-m001)
    section of the [Management nodes rollout stage documentation](../stages/management_nodes_rollout.md).
    Set the `IMS_RESULTANT_IMAGE_ID` variable to the `final_image_id` for `Management_Master` found in the second step.

    1. (`ncn-m002#`) Upgrade `ncn-m001`. This **must** be executed on **`ncn-m002`**.

        ```bash
        /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m001
        ```

1. Follow the steps documented in [Stage 3.4 - Upgrade `weave` and `multus`](../../../upgrade/Stage_3.md#stage-34---upgrade-weave-and-multus)

1. Follow the steps documented in [Stage 3.5 - `coredns` anti-affinity](../../../upgrade/Stage_3.md#stage-35---coredns-anti-affinity)

Once this step has completed:

- All management NCNs have been upgraded to the image and CFS configuration created in the previous steps of this workflow
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

1. Configure NCN master and NCN storage nodes.

    1. (`ncn-m#`) Create a comma-separated list of the xnames for all NCN master and NCN storage nodes and verify they are correct.

        ```bash
        MASTER_XNAMES=$(cray hsm state components list --role Management --subrole Master --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
        STORAGE_XNAMES=$(cray hsm state components list --role Management --subrole Storage --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
        MASTER_STORAGE_XNAMES="${MASTER_XNAMES},${STORAGE_XNAMES}"
        echo "Master node xnames: $MASTER_XNAMES"
        echo "Storage node xnames: $STORAGE_XNAMES"
        echo "Master and storage node xnames: $MASTER_STORAGE_XNAMES"
        ```

    1. Get the CFS configuration created for management nodes during the `prepare-images` and `update-cfs-config` stages. Follow the instructions in the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created)
       documentation to get the value for `configuration` for any image with a `configuration_group_name` value matching `Management_Master`,`Management_Worker`, or `Management_Storage` (since `configuration` is the same for all
       management nodes).

    1. (`ncn-m#`) Set `CFS_CONFIG_NAME` to the value for `configuration` found in the previous step.

        ```bash
        CFS_CONFIG_NAME=<appropriate configuration value>
        ```

    1. (`ncn-m#`) Apply the CFS configuration to NCN master nodes and NCN storage nodes.

        ```bash
        /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
        --no-config-change --config-name "${CFS_CONFIG_NAME}" --xnames $MASTER_STORAGE_XNAMES --clear-state
        ```

        Sample output for configuring multiple management nodes is:

          ```bash
          Taking snapshot of existing management-23.11.0 configuration to /root/apply_csm_configuration.20240305_173700.vKxhqC backup-management-23.11.0.json
          Setting desired configuration, clearing state, clearing error count, enabling components in CFS
          desiredConfig = "management-23.11.0"
          enabled = true
          errorCount = 0
          id = "x3700c0s16b0n0"
          state = []

          [tags]

          desiredConfig = "management-23.11.0"
          enabled = true
          errorCount = 0
          id = "x3701c0s16b0n0"
          state = []

          [tags]

          desiredConfig = "management-23.11.0"
          enabled = true
          errorCount = 0
          id = "x3702c0s16b0n0"
          state = []

          [tags]

          Waiting for configuration to complete. 3 components remaining.
          Configuration complete. 3 component(s) completed successfully.  0 component(s) failed.
          ```

Once this step has completed:

- Management NCN worker nodes have been rebuilt with the image and CFS configuration created in previous steps of this workflow
- Management NCN storage and NCN master nodes have be updated with the CFS configuration created in the previous steps of this workflow.
- Per-stage product hooks have executed for the `management-nodes-rollout` stage

Continue to the next section [4. Update management host Slingshot NIC firmware](#4-update-management-host-slingshot-nic-firmware).

### 3.3 NCN worker nodes

NCN worker node images contain kernel module content from non-CSM products and need to be rebuilt as part of the workflow. This section describes how to test a new image and CFS configuration on a single canary node (`ncn-w001`) first before
rolling it out to the other NCN worker nodes. Modify the procedure as necessary to accommodate site preferences for rebuilding NCN worker nodes.

The images and CFS configurations used are created by the `prepare-images` and `update-cfs-config` stages respectively; see the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation
for details on how to query the images and CFS configurations and see the [update-cfs-config](../stages/update_cfs_config.md) documentation for details about how the CFS configuration is updated.

**`NOTE`** The `management-nodes-rollout` stage creates additional separate Argo workflows when rebuilding NCN worker nodes. The Argo workflow names will include the string `ncn-lifecycle-rebuild`. If monitoring progress with the Argo UI,
remember to include these workflows.

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `management-nodes-rollout` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage with a single NCN worker node.
This will rebuild the canary node with the new CFS configuration and image built in previous steps of the workflow.
The worker canary node can be any worker node and does not have to be `ncn-w001`.

    ```bash
    WORKER_CANARY=ncn-w001
    ```

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout --limit-management-rollout ${WORKER_CANARY}
    ```

1. Verify the canary node booted successfully with the desired image and CFS configuration.

    ```bash
    XNAME=$(ssh $WORKER_CANARY 'cat /etc/cray/xname')
    echo "${XNAME}"
    cray cfs components describe "${XNAME}"
    ```

1. (`ncn-m001#`) Use `kubectl` to apply the `iuf-prevent-rollout=true` label to the canary node to prevent it from unnecessarily rebuilding again.

    ```bash
    kubectl label nodes "${WORKER_CANARY}" --overwrite iuf-prevent-rollout=true
    ```

1. (`ncn-m001#`) Verify the IUF node labels are present on the desired node.

    ```bash
    kubectl get nodes --show-labels | grep iuf-prevent-rollout
    ```

1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage on all remaining worker nodes.

    **`NOTE`** For this step, the argument to `--limit-management-rollout` can be `Management_Worker` or a list of worker
    node names seperated by spaces. If `Management_Worker` is supplied, all worker nodes that are not labeled
    with `iuf-prevent-rollout=true` will be rebuilt/upgraded. If a list of worker node names is supplied, then those worker nodes will be rebuilt/upgraded.

    **Choose one** of the following two options. The difference between the options is the `limit-management-rollout` argument, but the two options do the same thing.

    1. (`ncn-m001#`) Execute `management-nodes-rollout` on all `Management_Worker` nodes.

        ```bash
        iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout --limit-management-rollout Management_Worker
        ```

    1. (`ncn-m001#`) Execute `management-nodes-rollout` on a group of worker nodes. The list of worker nodes can be manually edited if it is undesirable to rebuild/upgrade all of the workers with one execution.

        ```bash
        WORKER_NODES=$(kubectl get node | grep -P 'ncn-w\d+' | grep -v $WORKER_CANARY |  awk '{print $1}' | xargs)
        echo $WORKER_NODES
        ```

        ```bash
        iuf -a "${ACTIVITY_NAME}" run -r management-nodes-rollout --limit-management-rollout $WORKER_NODES
        ```

1. (`ncn-m001#`) Use `kubectl` to remove the `iuf-prevent-rollout=true` label from the canary node.

    ```bash
    kubectl label nodes "${WORKER_CANARY}" --overwrite iuf-prevent-rollout-
    ```

1. (`ncn-m001#`) Verify that all worker nodes configured successfully.

    ```bash
    for ncn in $(cray hsm state components list --subrole Worker --type Node \
      --format json | jq -r .Components[].ID | grep b0n | sort); do cray cfs components describe \
      $ncn --format json | jq -r ' .id+" "+.desiredConfig+" status="+.configurationStatus'; done
    ```

Once this step has completed:

- Management NCN worker nodes have been rebuilt with the image and CFS configuration created in previous steps of this workflow
- Per-stage product hooks have executed for the `management-nodes-rollout` stage

Return to the procedure that was being followed for `management-nodes-rollout` to complete the next step, either [Management-nodes-rollout with CSM upgrade](#31-management-nodes-rollout-with-csm-upgrade) or
[Management-nodes-rollout without CSM upgrade](#32-management-nodes-rollout-without-csm-upgrade).

## 4. Update management host Slingshot NIC firmware

If new Slingshot NIC firmware was provided, refer to the "200Gbps NIC Firmware Management" section of the  _Slingshot Operations Guide for Customers_ for details on how to update NIC firmware on management nodes.

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
