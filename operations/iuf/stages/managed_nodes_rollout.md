# `managed-nodes-rollout`

The `managed-nodes-rollout` stage performs a reboot of the managed compute and application nodes in order to reboot them to a new image and configuration. The system must be configured to use BOS V2 as
it is used to perform the reboot. The reboot operations use the BOS session templates created during the `prepare-images` stage. The `-mrs stage` argument is only valid for compute nodes, since application nodes are not controlled
by workload manager software. The `-mrs reboot` argument will reboot all compute and application nodes immediately if the `--limit-managed-rollout` argument is not specified.

`managed-nodes-rollout` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `managed-nodes-rollout` stage changes the running state of the system.

## Input

The following arguments are most often used with the `managed-nodes-rollout` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input                      | `iuf` Argument                                  | Description                                                                       |
| -------------------------- | ----------------------------------------------- | --------------------------------------------------------------------------------- |
| Activity                   | `-a ACTIVITY`                                   | Activity created for the install or upgrade operations                            |
| Managed rollout strategy   | `-mrs {reboot,stage}`                           | Reboot the managed nodes immediately or stage the new image for the WLM to reboot |
| Limit managed rollout list | `--limit-managed-rollout LIMIT_MANAGED_ROLLOUT` | List of managed nodes to be rolled out, specified by xnames or HSM node group     |

## Execution details

The code executed by this stage exists within IUF. See the `managed-nodes-rollout` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

See [Rolling Upgrades Using BOS](../../boot_orchestration/Rolling_Upgrades.md) for details on rebooting managed compute and application nodes with BOS V2.

## Example

(`ncn-m001#`) Execute the `managed-nodes-rollout` stage for activity `admin-230127` using the default `stage` rollout strategy and limiting the operation to the HSM node group `compute-partition-1`.

```bash
iuf -a admin-230127 run --limit-managed-rollout compute-partition-1 -r managed-nodes-rollout
```
