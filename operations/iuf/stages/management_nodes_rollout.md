# `management-nodes-rollout`

The `management-nodes-rollout` stage performs a controlled rebuild of the management NCNs in order to reboot them to a new image and configuration. A rebuild is a reboot operation that clears the persistent OverlayFS file system on
that node. IUF will account for the necessary minimum number of critical software instances running on the nodes to ensure the `management-nodes-rollout` stage operates without impacting software availability.

**`NOTE`** `management-nodes-rollout` currently does not rebuild management NCN storage nodes or `ncn-m001`. These nodes must be rebuilt using non-IUF methods described in the appropriate sections of the CSM documentation.

- [Stage 1 - Ceph image upgrade](#../../upgrade/Stage_1.md) describes the rebuild process for NCN storage nodes
- [Stage 2.3 - `ncn-m001` upgrade](#../../upgrade/Stage_2.md#stage-23---ncn-m001-upgrade) describes the rebuild process for `ncn-m001`

`management-nodes-rollout` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `management-nodes-rollout` stage changes the running state of the system.

## Input

The following arguments are most often used with the `management-nodes-rollout` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input                                    | `iuf` Argument                                        | Description                                                                            |
| ---------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------- |
| activity                                 | `-a ACTIVITY`                                         | activity created for the install or upgrade operations                                 |
| concurrent management rollout percentage | `-cmrp CONCURRENT_MANAGEMENT_ROLLOUT_PERCENTAGE`      | percentage value that limits the number of NCN management nodes rolled out in parallel |
| limit management rollout list            | `--limit-management-rollout LIMIT_MANAGEMENT_ROLLOUT` | list of NCN management nodes to be rolled out, specified by HSM role and subrole       |

## Execution details

The code executed by this stage exists within IUF. See the `management-nodes-rollout` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

There are two methods administrators can use to avoid rollouts on specific NCN management nodes: by specifying the `--limit-management-rollout` argument or by using `kubectl` to label nodes with `iuf-prevent-rollout=true`.

When NCN management nodes are being rebuilt, an additional Argo workflow will execute in addition to the standard IUF Argo workflows. It will include the string `ncn-lifecycle-rebuild` in its name.

## Example

(`ncn-m001#`) Execute the `management-nodes-rollout` stage for activity `admin-230127` using the default concurrent management rollout percentage and limiting the operation to `Management_Worker` nodes.

```bash
iuf -a admin-230127 run --limit-management-rollout Management_Worker -r management-nodes-rollout
```
