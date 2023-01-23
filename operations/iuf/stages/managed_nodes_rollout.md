# managed-nodes-rollout

The `managed-nodes-rollout` stage performs a controlled reboot of the managed compute and application nodes in order to reboot them to a new image and configuration.

## Impact

The `managed-nodes-rollout` stage changes the running state of the system.

## Input

The following arguments are most often used with the `managed-nodes-rollout` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description |
| --------------- | -------------- | ----------- |
| activity        | `-a ACTIVITY`  | activity created for the install or upgrade operations |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `managed-nodes-rollout` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `managed-nodes-rollout` stage.

```bash
iuf -a joe-install-20230107 run -r managed-nodes-rollout
```
