# management-nodes-rollout

The `management-nodes-rollout` stage performs a controlled rebuild of the management worker nodes in order to reboot them to a new image and configuration. IUF will account for the necessary minimum number of critical software
instances running on worker nodes to ensure the `management-nodes-rollout` stage operates without impacting software availability.

## Impact

The `management-nodes-rollout` stage changes the running state of the system.

## Input

The following arguments are most often used with the `management-nodes-rollout` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description |
| --------------- | -------------- | ----------- |
| activity        | `-a ACTIVITY`  | activity created for the install or upgrade operations |

## Execution Details

The code executed by this stage exists within IUF. See the `management-nodes-rollout` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `management-nodes-rollout` stage.

```bash
iuf -a joe-install-20230107 run -r management-nodes-rollout
```
