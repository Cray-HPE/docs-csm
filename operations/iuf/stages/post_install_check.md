# post-install-check

The `post-install-check` stage validates that the managed compute and application nodes deployed by the preceding `managed-node-rollout` stage are executing correctly. It primarily executes pre- and post-stage hook scripts
provided by products in their `iuf-product-manifest.yaml` file.

## Impact

The `post-install-check` stage does not change the running state of the system.

## Input

The following arguments are most often used with the `post-install-check` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description |
| --------------- | -------------- | ----------- |
| activity        | `-a ACTIVITY`  | activity created for the install or upgrade operations |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `post-install-check` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `post-install-check` stage.

```bash
iuf -a joe-install-20230107 run -r post-install-check
```
