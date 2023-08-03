# `management-nodes-rollout`

The `management-nodes-rollout` stage performs a controlled update of management NCNs by configuring them with a new CFS configuration and/or rebuilding or upgrading them to a new image.
A "rebuild" is a reboot operation that clears the persistent OverlayFS file system on that node, i.e. all data on node-local storage will be discarded.
An "upgrade" is similar to a rebuild, but it intentionally does not clear all information off of NCN storage and master nodes.
IUF will account for the necessary minimum number of critical software instances running on the nodes to ensure the `management-nodes-rollout` stage operates without impacting software availability.

**`NOTE`** `management-nodes-rollout` has a different procedure depending on whether or not CSM itself is being upgraded. The two procedures differ in the handling of NCN storage nodes and NCN master nodes, but both procedures use
the same steps for rebuilding/upgrading NCN worker nodes.

1. If CSM **is not** being upgraded, then NCN storage and master nodes will not be upgraded with a new image but will be updated with a CFS configuration created in [update-cfs-config](../stages/update_cfs_config.md).

1. If CSM **is** being upgraded, then NCN storage master nodes will be upgraded with a new image and CFS configuration.

See the [3. Execute the IUF `management-nodes-rollout` stage](../workflows/management_rollout.md#3-execute-the-iuf-management-nodes-rollout-stage) documentation for more information.

`management-nodes-rollout` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Manually upgrade or rebuild NCN worker node with specific image and CFS configuration outside of IUF](#manually-upgrade-or-rebuild-ncn-worker-node-with-specific-image-and-cfs-configuration-outside-of-iuf)
- [Action needed if a worker rebuild fails](#action-needed-if-a-worker-rebuild-fails)
- [Examples](#examples)
- [Set NCN boot image for NCN master or NCN storage nodes](#set-ncn-boot-image-for-ncn-m001-or-ncn-storage-nodes)
- [Upgrade NCN storage nodes into the customized image](#upgrade-ncn-storage-nodes-into-the-customized-image)

## Impact

The `management-nodes-rollout` stage changes the running state of the system.

## Input

The following arguments are most often used with the `management-nodes-rollout` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input                                    | `iuf` Argument                                        | Description                                                                            |
| ---------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Activity                                 | `-a ACTIVITY`                                         | Activity created for the install or upgrade operations                                 |
| Concurrent management rollout percentage | `-cmrp CONCURRENT_MANAGEMENT_ROLLOUT_PERCENTAGE`      | Percentage value that limits the number of NCN worker nodes rolled out in parallel |
| Limit management rollout list            | `--limit-management-rollout LIMIT_MANAGEMENT_ROLLOUT` | List of NCN management nodes to be rolled out, specified by HSM role and subrole (`Management_Master`, `Management_Worker`)       |

## Execution details

The code executed by this stage exists within IUF. See the `management-nodes-rollout` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

There are two methods administrators can use to avoid rollouts on specific NCN management nodes: by specifying the `--limit-management-rollout` argument for specifying which group(s) of nodes should be rebuilt or by using `kubectl` to label nodes with `iuf-prevent-rollout=true`.

When NCN worker nodes are being rebuilt/upgraded and when NCN storage nodes are being upgraded, an additional Argo workflow will execute in addition to the standard IUF Argo workflows. It will include the string `ncn-lifecycle-rebuild` in its name.

The `-cmrp` argument limits the percentage of worker nodes rolled out in parallel. The worker node rebuild can coordinate rebuilding multiple worker nodes at once.
It starts by rebuilding one worker node. Once that node has been removed from the system, the workflow checks if it is safe to rebuild the next worker node based on what services are running in the system.
If it is safe, it will proceed to rebuild the next node, partially in parallel with the first worker node rebuild. If it is unsafe to rebuild in parallel because the system could get into a bad state, then it waits to rebuild the second node until it is safe.
The `-cmrp` parameter selects the percentage of worker nodes that the worker node rebuild should coordinate rebuilding at one time.
For example, if there are 15 worker nodes and `-cmrp 33` is specified, then 5 worker nodes will be rebuilt at once and with as much parallelization as possible given the state of the system.
**Note** that the system admin's discretion should be used when deciding the value of `-cmrp`.
The largest number of management worker nodes that have been tested rebuilding in parallel is 5 nodes.

`-limit-management-rollout Management_Master` only needs to be specified when performing a CSM upgrade. This will upgrade `ncn-m002` and `ncn-m003` serially with a new image and configuration. This should be done before NCN worker
nodes are upgraded. If not performing a CSM upgrade, then NCN master nodes should not be upgraded with a new image and should only be configured with the new CFS configuration created during the
[update-cfs-config](../stages/update_cfs_config.md) stage.

## Manually upgrade or rebuild NCN worker node with specific image and CFS configuration outside of IUF

**NOTE** This section describes how to manually rebuild/upgrade a worker node outside of IUF with an image and CFS configuration created through IUF. **This is not the normal procedure that IUF uses for rebuilding/upgrading NCN
worker nodes.** This procedure should be followed if NCN worker nodes need to be rebuilt or upgraded outside of IUF.

The upgrade and rebuild procedures for NCN worker nodes are identical. These instructions apply to both NCN worker node upgrades and NCN worker node rebuilds.
The words 'rebuild' and 'upgrade' are exchangeable in this section.

1. Get the image ID and CFS configuration created for worker nodes during the `prepare-images` and `update-cfs-config` stages. Follow the instructions in the [`prepare-images` Artifacts created](prepare_images.md#artifacts-created)
documentation to get the values for `final_image_id` and `configuration` for images with a `configuration_group_name` value matching `Management_Worker`. These values will be used in the next step.

1. Upgrade/rebuild the worker node. The worker node is automatically rebuilt using Argo workflows. If rebuilding multiple worker nodes at once, see [this page](../../node_management/Rebuild_NCNs/Rebuild_NCNs.md#restrictions) for restrictions.

    (`ncn-m001#`) Rebuild a worker node. Use the values acquired in the previous step in place of `<final_image_id>` and `<configuration>`.

    ```bash
    /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-w001 --image-id <final_image_id> --desired-cfs-conf <configuration>
    ```

## Action needed if a worker rebuild fails

In general, worker node rebuilds should complete successfully before starting another rebuild.
A worker node can get into a bad state if it has been partially rebuilt and an attempt is made to restart the rebuild on that same node.
As a result, it is not possible to start another worker node rebuild if there is an existing incomplete worker node rebuild workflow, where "incomplete" means it has stopped before successfully completing the full workflow.
If an incomplete workflow exists and an attempt is made to start another worker rebuild workflow,
the original incomplete worker rebuild workflow will continue and no new workflow will be created.

If it is necessary to start an entirely new worker rebuild workflow after a previous worker rebuild workflow failed, the failed workflow must be deleted from Kubernetes first.

**`WARNING`** Deleting a workflow will delete information about the state of that workflow and the steps that have been completed.
Deleting a partially complete workflow should be done cautiously and only if needed.

To delete a failed Argo workflow, complete the following steps.

1. Get the name of the failed workflow. All worker rebuild workflows start with `ncn-lifecycle-rebuild`. The name of the worker rebuild workflow can be found in the Argo UI or by searching workflows in Kubernetes with the following command.

    (`ncn-m#`) List failed worker rebuild workflows. Note that NCN storage upgrade workflows will also contain `ncn-lifecycle-rebuild` in their name and may be present in this list.

    ```bash
    kubectl get workflows -n argo | grep 'ncn-lifecycle-rebuild' | grep 'Fail'
    ```

1. (`ncn-m#`) Delete the failed workflow.

    ```bash
    kubectl delete workflows -n argo <failed workflow>
    ```

    After deleting the failed workflow, a new worker rebuild workflow can be started.

## Examples

(`ncn-m001#`) Execute the `management-nodes-rollout` stage for activity `admin-230127` using the default concurrent management rollout percentage and limiting the operation to `Management_Worker` nodes.

```bash
iuf -a admin-230127 run --limit-management-rollout Management_Worker -r management-nodes-rollout
```

Expected behavior: All NCN worker nodes will be rebuilt. Each set of worker nodes that is being rebuilt will contain 20% of the total number of worker nodes. For example, if there are 10 total worker nodes, then 2 will be rebuilt at a time.

---

(`ncn-m001#`) Execute the `management-nodes-rollout` stage for activity `admin-230127` using the following parameters. Upgrading the NCN master nodes as shown, should only be done if CSM is being upgraded.

- Assume 10 worker nodes (`ncn-w001` through `ncn-w010`)
- `--limit-management-rollout Management_Worker Management_Master`
- `-cmrp 33`
- `ncn-w004` is labeled with `iuf-prevent-rollout=true`

First, label `ncn-w004` with `iuf-prevent-rollout=true`. Then execute the following command.

```bash
iuf -a admin-230127 run --limit-management-rollout Management_Worker Management_Master  --cmrp 33 -r management-nodes-rollout
```

Expected behavior:

1. `ncn-m002` will be upgraded
1. `ncn-m003` will be upgraded
1. Worker nodes `ncn-w001,ncn-w002,ncn-w003` will be upgraded
1. Worker nodes `ncn-w005,ncn-w006,ncn-w007` will be upgraded
1. Worker nodes `ncn-w008,ncn-w009,ncn-w010` will be upgraded

## Set NCN boot image for `ncn-m001` or NCN storage nodes

Follow these steps when upgrading `ncn-m001` during [3.1 `management-nodes-rollout` with CSM upgrade](../workflows/management_rollout.md#31-management-nodes-rollout-with-csm-upgrade)
when following the procedures in
[Install or upgrade additional products with IUF](../workflows/install_or_upgrade_additional_products_with_iuf.md)
or [Upgrade CSM and additional products with IUF](../workflows/upgrade_csm_and_additional_products_with_iuf.md).
Additionally, these steps can be followed if NCN storage nodes are being upgraded with the [Upgrade NCN storage nodes into the customized image](#upgrade-ncn-storage-nodes-into-the-customized-image) directions.

Only follow the below steps for the nodes being upgraded, for `ncn-m001` or NCN storage nodes.

1. Get the image ID and CFS configuration created for management nodes during the `prepare-images` and `update-cfs-config` stages. Follow the instructions in the
[`prepare-images` Artifacts created](prepare_images.md#artifacts-created) documentation to get the values for `final_image_id` and `configuration` with a
`configuration_group_name` value matching `Management_Master` or `Management_Storage`, whichever node type is being upgraded. These values will be used in the following steps.

1. (`ncn-mw#`) Set the `IMS_RESULTANT_IMAGE_ID` to be the `final_image_id` found in the previous step.

    ```bash
    IMS_RESULTANT_IMAGE_ID=<value of final_image_id>
    ```

1. (`ncn-mw#`) Determine the xnames for the NCNs which are being upgraded. These will be used in the next step.

    - Get the xname for `ncn-m001`:

        ```bash
        ssh ncn-m001 cat /etc/cray/xname
        ```

    - Get a comma-separated list of all storage NCN xnames:

        ```bash
        cray hsm state components list --role Management --subrole Storage --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")'
        ```

1. (`ncn-mw#`) Update boot parameters for an NCN. Perform the following procedure **for each xname** being upgraded
(each xname identified in the previous step).

    1. Get the existing `metal.server` setting for the xname of the node of interest.

        ```bash
        XNAME=<node-xname>
        METAL_SERVER=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' \
            | awk -F 'metal.server=' '{print $2}' \
            | awk -F ' ' '{print $1}')
        echo "${METAL_SERVER}"
        ```

    1. Create updated boot parameters that point to the new artifacts.

        1. Set the path to the artifacts in S3.

            **NOTE** This uses the `IMS_RESULTANT_IMAGE_ID` variable set in an earlier step.

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

## Upgrade NCN storage nodes into the customized image

For the CSM upgrade from CSM 1.3 to CSM 1.4, the NCN storage node image does not change so there is no need to 'upgrade' to the customized storage image.
The NCN storage nodes should not be 'upgraded'. Instead, they should be personalized by following the procedure in [management-nodes-rollout documentation](../workflows/management_rollout.md#3-execute-the-iuf-management-nodes-rollout-stage)
for [personalizing storage nodes](../workflows/management_rollout.md#34-personalize-ncn-storage-nodes).

However, the image is provided and is customized during the [prepare images](./prepare_images.md) stage.
The following steps can be followed if it is desired to 'upgrade' the storage nodes into this image.
Note that personalizing the NCN storage nodes has the same result as performing this node rollout.

1. Get the image ID and CFS configuration created for NCN storage nodes during the `prepare-images` and `update-cfs-config` stages. Follow the instructions in the
[`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation to get the value for `final_image_id` and
`configuration` for the image with a `configuration_group_name` value matching `Management_Storage`.
These values will be needed when upgrading the NCN storage nodes in the following steps.

1. Perform the NCN storage node upgrades.

    1. Set the CFS configuration on all storage nodes.

        1. (`ncn-m#`) Set `CFS_CONFIG_NAME` to be the value for `configuration` found for `Management_Storage` nodes in the previous step.

            ```bash
            CFS_CONFIG_NAME=<appropriate configuration value>
            ```

        1. (`ncn-m#`) Get all NCN storage node xnames.

            ```bash
            XNAMES=$(cray hsm state components list --role Management --subrole Storage --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
            echo "${XNAMES}"
            ```

        1. (`ncn-m#`) Set the configuration on all storage nodes.

            ```bash
            /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
            --no-config-change --config-name "${CFS_CONFIG_NAME}" --xnames "${XNAMES}" --no-enable --no-clear-err
            ```

            The expected output is:

              ```bash
              All components updated successfully.
              ```

    1. Set the image in BSS for all storage nodes by following the [Set NCN boot image for `ncn-m001` or NCN storage nodes](../stages/management_nodes_rollout.md#set-ncn-boot-image-for-ncn-m001-or-ncn-storage-nodes)
    section of this document.
    Set the `IMS_RESULTANT_IMAGE_ID` variable to the `final_image_id` value for `Management_Storage` found in step 2 above.

    1. (`ncn-m#`) Upgrade one NCN storage node (`ncn-s001`).

        **NOTE** This creates an additional, separate Argo workflow for rebuilding a NCN storage node. The Argo workflow name will include the string `ncn-lifecycle-rebuild`. If monitoring progress with the Argo UI, remember to include these workflows.

        ```bash
        /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001 --upgrade
        ```

    1. (`ncn-m#`) Verify that the storage node booted and is configured correctly. The CFS configuration can be
    verified with the command below using the xname of the node that was upgraded instead of the example value `x3000c0s13b0n0`.

        ```bash
        XNAME=x3000c0s13b0n0
        cray cfs components describe "${XNAME}"
        ```

        The desired value for `configurationStatus` is `configured`. If it is `pending`, then wait for the status to change to `configured`.

    1. (`ncn-m#`) Upgrade the remaining storage nodes serially.

        **NOTE** This creates an additional, separate Argo workflow for upgrading NCN storage nodes. The Argo workflow name will include the string `ncn-lifecycle-rebuild`. If monitoring progress with the Argo UI, remember to include these workflows.

        The remaining storage nodes should be specified in a comma seperated list.
        This example is upgrading `ncn-s002,ncn-s003,ncn-s004`. This should be changed based on the number of storage nodes on a system.

        ```bash
        /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s002,ncn-s003,ncn-s004 --upgrade
        ```

    1. (ncn-m001#) Run the following commands to enable the rbd stats collection on Ceph pools.

        ```bash
        ceph config set mgr mgr/prometheus/rbd_stats_pools "kube,smf"
        ceph config set mgr mgr/prometheus/rbd_stats_pools_refresh_interval 600
        ```
