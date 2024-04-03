# `management-nodes-rollout`

The `management-nodes-rollout` stage performs a controlled update of management NCNs by configuring them with a new CFS
configuration and/or rebuilding or upgrading them to a new image. A "rebuild" is a reboot operation that clears the
persistent OverlayFS file system on that node, i.e. all data on node-local storage will be discarded. An "upgrade" is
similar to a rebuild, but it intentionally does not clear all information off of NCN storage and master nodes. IUF will
account for the necessary minimum number of critical software instances running on the nodes to ensure
the `management-nodes-rollout` stage operates without impacting software availability.

**`NOTE`** `management-nodes-rollout` has a different procedure depending on whether or not CSM itself is being
upgraded. The two procedures differ in the handling of NCN storage nodes and NCN master nodes, but both procedures use
the same steps for rebuilding/upgrading NCN worker nodes.

1. If CSM **is not** being upgraded, then NCN storage and master nodes will not be upgraded with a new image but will be
   updated with a CFS configuration created in [update-cfs-config](../stages/update_cfs_config.md).

1. If CSM **is** being upgraded, then NCN storage and master nodes will be upgraded with a new image and CFS
   configuration.

See
the [3. Execute the IUF `management-nodes-rollout` stage](../workflows/management_rollout.md#3-execute-the-iuf-management-nodes-rollout-stage)
documentation for more information.

`management-nodes-rollout` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Manually upgrade or rebuild NCN worker node with specific image and CFS configuration outside of IUF](#manually-upgrade-or-rebuild-ncn-worker-node-with-specific-image-and-cfs-configuration-outside-of-iuf)
- [Action needed if a worker rebuild fails](#action-needed-if-a-worker-rebuild-fails)
- [Examples](#examples)
- [Set NCN boot image for `ncn-m001`](#set-ncn-boot-image-for-ncn-m001)

## Impact

The `management-nodes-rollout` stage changes the running state of the system.

## Input

The following arguments are most often used with the `management-nodes-rollout` stage. See `iuf -h` and `iuf run -h` for
additional arguments.

| Input                                    | `iuf` Argument                                        | Description                                                                                                                                                                                              |
|------------------------------------------|-------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Activity                                 | `-a ACTIVITY`                                         | Activity created for the install or upgrade operations                                                                                                                                                   |
| Concurrent management rollout percentage | `-cmrp CONCURRENT_MANAGEMENT_ROLLOUT_PERCENTAGE`      | Percentage value that limits the number of NCN worker nodes rolled out in parallel                                                                                                                       |
| Limit management rollout list            | `--limit-management-rollout LIMIT_MANAGEMENT_ROLLOUT` | List of NCN management nodes to be rolled out, specified by HSM role and subrole (`Management_Master`, `Management_Worker`, `Management_Storage`) or by NCN hostname (e.g. `ncn-w003`, `ncn-s001`, etc.) |

## Execution details

The code executed by this stage exists within IUF. See the `management-nodes-rollout` entry
in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files
in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

There are two methods administrators can use to avoid rollouts on specific NCN management nodes: by specifying
the `--limit-management-rollout` argument for specifying which group(s) of nodes should be rebuilt or by using `kubectl`
to label nodes with `iuf-prevent-rollout=true`.

When NCN worker nodes are being rebuilt/upgraded and when NCN storage nodes are being upgraded, an additional Argo
workflow will execute in addition to the standard IUF Argo workflows. It will include the string `ncn-lifecycle-rebuild`
in its name.

The `-cmrp` argument limits the percentage of worker nodes rolled out in parallel. The worker node rebuild can
coordinate rebuilding multiple worker nodes at once. It starts by rebuilding one worker node. Once that node has been
removed from the system, the workflow checks if it is safe to rebuild the next worker node based on what services are
running in the system. If it is safe, it will proceed to rebuild the next node, partially in parallel with the first
worker node rebuild. If it is unsafe to rebuild in parallel because the system could get into a bad state, then it waits
to rebuild the second node until it is safe. The `-cmrp` parameter selects the percentage of worker nodes that the
worker node rebuild should coordinate rebuilding at one time. For example, if there are 15 worker nodes and `-cmrp 33`
is specified, then 5 worker nodes will be rebuilt at once and with as much parallelization as possible given the state
of the system. **Note** that the system admin's discretion should be used when deciding the value of `-cmrp`.
The largest number of management worker nodes that has been tested rebuilding in parallel is 5 nodes.

Management master and storage nodes only need to upgraded when performing a CSM upgrade. If not performing a CSM upgrade,
then NCN master nodes should not be upgraded with a new image and should only be configured with the new CFS configuration
created during the [update-cfs-config](../stages/update_cfs_config.md) stage.

## Manually upgrade or rebuild NCN worker node with specific image and CFS configuration outside of IUF

**NOTE** This section describes how to manually rebuild/upgrade a worker node outside of IUF with an image and CFS
configuration created through IUF. **This is not the normal procedure that IUF uses for rebuilding/upgrading NCN worker
nodes.** This procedure should be followed if NCN worker nodes need to be rebuilt or upgraded outside of IUF.

The upgrade and rebuild procedures for NCN worker nodes are identical. These instructions apply to both NCN worker node
upgrades and NCN worker node rebuilds. The words 'rebuild' and 'upgrade' are exchangeable in this section.

1. Get the image ID and CFS configuration created for worker nodes during the `prepare-images` and `update-cfs-config`
   stages. Follow the instructions in the [`prepare-images` Artifacts created](prepare_images.md#artifacts-created)
   documentation to get the values for `final_image_id` and `configuration` for images with a `configuration_group_name`
   value matching `Management_Worker`. These values will be used in the next step.

1. Upgrade/rebuild the worker node. The worker node is automatically rebuilt using Argo workflows. If rebuilding
   multiple worker nodes at once, see [this page](../../node_management/Rebuild_NCNs/Rebuild_NCNs.md#restrictions) for
   restrictions.

   (`ncn-m001#`) Rebuild a worker node. Use the values acquired in the previous step in place of `<final_image_id>`
   and `<configuration>`.

    ```bash
    /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-w001 --image-id <final_image_id> --desired-cfs-conf <configuration>
    ```

## Action needed if a worker rebuild fails

In general, worker node rebuilds should complete successfully before starting another rebuild. A worker node can get
into a bad state if it has been partially rebuilt and an attempt is made to restart the rebuild on that same node. As a
result, it is not possible to start another worker node rebuild if there is an existing incomplete worker node rebuild
workflow, where "incomplete" means it has stopped before successfully completing the full workflow. If an incomplete
workflow exists and an attempt is made to start another worker rebuild workflow, the original incomplete worker rebuild
workflow will continue and no new workflow will be created.

If it is necessary to start an entirely new worker rebuild workflow after a previous worker rebuild workflow failed, the
failed workflow must be deleted from Kubernetes first.

**`WARNING`** Deleting a workflow will delete information about the state of that workflow and the steps that have been
completed. Deleting a partially complete workflow should be done cautiously and only if needed.

To delete a failed Argo workflow, complete the following steps.

1. Get the name of the failed workflow. All worker rebuild workflows start with `ncn-lifecycle-rebuild`. The name of the
   worker rebuild workflow can be found in the Argo UI or by searching workflows in Kubernetes with the following
   command.

   (`ncn-m#`) List failed worker rebuild workflows. Note that NCN storage upgrade workflows will also
   contain `ncn-lifecycle-rebuild` in their name and may be present in this list.

    ```bash
    kubectl get workflows -n argo | grep 'ncn-lifecycle-rebuild' | grep 'Fail'
    ```

1. (`ncn-m#`) Delete the failed workflow.

    ```bash
    kubectl delete workflows -n argo <failed workflow>
    ```

   After deleting the failed workflow, a new worker rebuild workflow can be started.

## Examples

(`ncn-m001#`) Execute the `management-nodes-rollout` stage for activity `admin-230127` using the default concurrent
management rollout percentage and limiting the operation to `Management_Worker` nodes.

```bash
iuf -a admin-230127 run --limit-management-rollout Management_Worker -r management-nodes-rollout
```

Expected behavior: All NCN worker nodes will be rebuilt. Each set of worker nodes that is being rebuilt will contain 20%
of the total number of worker nodes. For example, if there are 10 total worker nodes, then 2 will be rebuilt at a time.

---

(`ncn-m001#`) Execute the `management-nodes-rollout` stage for activity `admin-230127` using the default concurrent
management rollout percentage and limiting the operation to `ncn-s001 ncn-s002` nodes.

```bash
iuf -a admin-230127 run --limit-management-rollout ncn-s001 ncn-s002  -r management-nodes-rollout
```

Expected behavior:

1. `ncn-s001` will be upgraded
1. `ncn-s002` will be upgraded

---

(`ncn-m001#`) Execute the `management-nodes-rollout` stage for activity `admin-230127` using the following parameters.

- Assume 10 worker nodes (`ncn-w001` through `ncn-w010`)
- `--limit-management-rollout Management_Worker`
- `-cmrp 33`
- `ncn-w004` is labeled with `iuf-prevent-rollout=true`

First, label `ncn-w004` with `iuf-prevent-rollout=true`. Then execute the following command.

```bash
iuf -a admin-230127 run --limit-management-rollout Management_Worker --cmrp 33 -r management-nodes-rollout
```

Expected behavior:

1. Worker nodes `ncn-w001,ncn-w002,ncn-w003` will be upgraded
1. Worker nodes `ncn-w005,ncn-w006,ncn-w007` will be upgraded
1. Worker nodes `ncn-w008,ncn-w009,ncn-w010` will be upgraded

## Set NCN boot image for `ncn-m001`

Follow these steps when upgrading `ncn-m001`
during [3.1 `management-nodes-rollout` with CSM upgrade](../workflows/management_rollout.md#31-management-nodes-rollout-with-csm-upgrade)
when following the procedures in
[Install or upgrade additional products with IUF](../workflows/install_or_upgrade_additional_products_with_iuf.md)
or [Upgrade CSM and additional products with IUF](../workflows/upgrade_csm_and_additional_products_with_iuf.md).

  1. (`ncn-mw#`) Set the `IMS_RESULTANT_IMAGE_ID` to be the `final_image_id` found
    in [3.1 `management-nodes-rollout` with CSM upgrade](../workflows/management_rollout.md#31-management-nodes-rollout-with-csm-upgrade). Then update the BSS parameters for `ncn-m001`.

      ```bash
      IMS_RESULTANT_IMAGE_ID=<value of final_image_id>
      XNAME=$(ssh ncn-m001 cat /etc/cray/xname)
      echo $XNAME
      /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh \
          -p $IMS_RESULTANT_IMAGE_ID $XNAME
      ```
