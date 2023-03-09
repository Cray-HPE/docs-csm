# `post-install-check`

The `post-install-check` stage validates that the managed compute and application nodes deployed by the preceding `managed-nodes-rollout` stage are executing correctly. It primarily executes pre- and post-stage hook scripts
provided by products in their `iuf-product-manifest.yaml` file.

`post-install-check` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `post-install-check` stage does not change the running state of the system.

## Input

The following arguments are most often used with the `post-install-check` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description |
| --------------- | -------------- | ----------- |
| Activity        | `-a ACTIVITY`  | Activity created for the install or upgrade operations |

## Execution details

The code executed by this stage exists within IUF. See the `post-install-check` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `post-install-check` stage for activity `admin-230127`.

```bash
iuf -a admin-230127 run -r post-install-check
```
