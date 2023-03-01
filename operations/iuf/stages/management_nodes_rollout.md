# `management-nodes-rollout`

The `management-nodes-rollout` stage performs a controlled rebuild of the management NCNs in order to reboot them to a new image and configuration. A rebuild is a reboot operation that clears the persistent OverlayFS file system on
that node. IUF will account for the necessary minimum number of critical software instances running on the nodes to ensure the `management-nodes-rollout` stage operates without impacting software availability.

**`NOTE`** `management-nodes-rollout` currently does not rebuild management NCN storage nodes or `ncn-m001`. These nodes can be personalized with the CFS configuration created in the [update-cfs-config](update_cfs_config.md) or they can be manually rebuilt into the new customized image, both options have the same result. 

- To personalize managment storage nodes or management master nodes, follow the instructions for `management-nodes-rollout` in the [upgrade all products documentation](../workflows/upgrade_all_products.md#652-ncn-master-nodes).
- To manually rebuild the NCNs, proceed to [Manually rebuild NCNs with specific image and CFS configuration](#manually-rebuild-ncns-with-specific-image-and-cfs-configuration).

`management-nodes-rollout` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)
- [Manually rebuild NCNs with specific image and CFS configuration](#manually-rebuild-ncns-with-specific-image-and-cfs-configuration)
- [Action needed if a worker rebuild fails](#action-needed-if-a-worker-rebuild-fails)

## Impact

The `management-nodes-rollout` stage changes the running state of the system.

## Input

The following arguments are most often used with the `management-nodes-rollout` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input                                    | `iuf` Argument                                        | Description                                                                            |
| ---------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Activity                                 | `-a ACTIVITY`                                         | Activity created for the install or upgrade operations                                 |
| Concurrent management rollout percentage | `-cmrp CONCURRENT_MANAGEMENT_ROLLOUT_PERCENTAGE`      | Percentage value that limits the number of NCN worker nodes rolled out in parallel |
| Limit management rollout list            | `--limit-management-rollout LIMIT_MANAGEMENT_ROLLOUT` | List of NCN management nodes to be rolled out, specified by HSM role and subrole (Management_Master, Management_Worker)       |

## Execution details

The code executed by this stage exists within IUF. See the `management-nodes-rollout` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

There are two methods administrators can use to avoid rollouts on specific NCN management nodes: by specifying the `--limit-management-rollout` argument for specifying which group(s) of nodes should be rebuilt or by using `kubectl` to label nodes with `iuf-prevent-rollout=true`.

When NCN worker nodes are being rebuilt, an additional Argo workflow will execute in addition to the standard IUF Argo workflows. It will include the string `ncn-lifecycle-rebuild` in its name.

The `-cmrp` argument limits the percentage of worker nodes rolled out in parallel. The worker node rebuild can coordinate rebuilding multiple worker nodes at once. It starts by rebuilding one worker node. Once that node has been removed from the system, the workflow checks if it is safe to rebuild the next worker node based on what services are running in the system. If it is safe, it will proceed to rebuild the next node, partially in parallel with the first worker node rebuild. If it is unsafe to rebuild in parallel because the system could get into a bad state, then it waits to rebuild the second node until it is safe. The `-cmrp` parameter selects the percentage of worker nodes that the worker node rebuild should rebuild at one time. For example, if there are 15 worker nodes and `-cmrp 33` is specified, then 5 worker nodes will be rebuilt at once and with as much parallelization as possible given the state of the system.

## Examples

1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage for activity `admin-230127` using the default concurrent management rollout percentage and limiting the operation to `Management_Worker` nodes.

    ```bash
    iuf -a admin-230127 run --limit-management-rollout Management_Worker -r management-nodes-rollout
    ```

    Expected behavior: All NCN worker nodes will rebuilt. Each set of worker nodes that is being rebuilt will contain 20% of the total number of worker nodes. For example, if there are 10 total worker nodes, then 2 will be rebuilt at a time. 

1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage for activity `admin-230127` using the following parameters.

    - Assume 10 worker nodes (`ncn-w001` through `ncn-w010`)
    - `-limit-management-rollout [Managment_Worker Management_Master]` 
    -  `-cmrp 35`
    - `ncn-w004` and `ncn-m002` are labeled with `iuf-prevent-rollout=true` 

    First, label `ncn-w004` and `ncn-m002` with `iuf-prevent-rollout=true`. Then execute the following command.

    ```bash
    iuf -a admin-230127 run --limit-management-rollout Management_Worker Management_Master  --cmrp 33 -r management-nodes-rollout
    ```

    Expected Behavior:

    1. Worker nodes `ncn-w001,ncn-w002,ncn-w003` will be rebuilt
    1. Worker nodes `ncn-w005,ncn-w006,ncn-w007` will be rebuilt
    1. Worker nodes `ncn-w008,ncn-w009,ncn-w010` will be rebuilt
    1. `ncn-m003` will be rebuilt

## Manually rebuild NCNs with specific image and CFS configuration

1. For all managment node types, first, get the image and CFS configuration created during `prepare-images` and `update-cfs-config` stages. Follow the instructions in [prepare-images](prepare_images.md#artifacts-created) to get the artifacts for `management-node-images`. For the image with the `configuration_group_name` matching
the node type that is desired to be manually rebuilt (Management_Master, Management_Storage, Management_Worker), get the values for `final_image_id` and `configuration`.

1. Next, follow the node rebuild instructions per node type.
- Rebuild worker nodes

    Worker nodes are automatically rebuilt using argo workflows. If rebuilding multiple worker nodes at once, see [this page](../../node_management/Rebuild_NCNs/Rebuild_NCNs.md#restrictions) for restrictions.

    (`ncn-m001#`) Rebuild worker node.

    ```bash
    /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-w001 --image-id <final_image_id> --desired-cfs-conf <configuration>
    ```

- Rebuild storage nodes and master nodes

    1. Set the image and cfs config **TODO** reference changes from CASMINST-5764
    1. Follow the instructions for [NCN rebuilds](../../node_management/Rebuild_NCNs/Rebuild_NCNs.md).

## Action needed if a worker rebuild fails

In general, worker node rebuilds should complete successfully before starting another rebuild. The node can get into a bad state if it has been partially rebuilt and then it is attempted to restart the rebuild on that same node. In order to prevent this from happening, it is not possible to start another worker node rebuild if there is an incomplete worker node rebuild workflow. Incomplete meaning it has stopped before successfully completing the full workflow. If there is an incomplete workflow and it is attemted to start another worker rebuild workflow, the first, incomplete worker rebuild will continue and no workflow will be created.

In the case where it is necessary to start an entirely new worker rebuild workflow after a previous worker rebuild workflow failed, then the failed workflow must be deleted from Kubernetes. **Warning** that deleting a workflow will delete information about the state of that workflow and the steps that have been completed.

To delete a failed Argo workflow, complete the following steps.

1. Get the name of the failed workflow. All worker rebuild workflows start with `ncn-lifecycle-rebuild`. The name of the worker rebuild workflow can be found in the Argo UI or by searching workflows in Kubernetes with the following command.

(`ncn-m#`) List failed worker rebuild workflows.
```bash
kubectl get Workflows -n argo | grep 'ncn-lifecycle-rebuild' | grep 'Fail'
```

1. (`ncn-m#`) Delete the failed workflow.
```bash
kubectl delete workflows -n argo FAILED_WORKFLOW
```

After deleting the failed workflow, a new worker rebuild workflow can be restarted. 