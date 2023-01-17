# managed-nodes-rollout

The `managed-nodes-rollout` stage performs a controlled reboot of the managed compute and application nodes in order to reboot them to a new image and configuration.

The `managed-nodes-rollout` stage changes the running state of the system.

## Required Input

The following arguments must be specified. See `iuf -h` and `iuf run -h` for additional optional arguments.

| Input           | `iuf` Argument |
| --------------- | -------------- |
| activity        | `-a ACTIVITY`  |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `managed-nodes-rollout` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.


## Example

(ncn-m001#) << TODO >>

```bash
<< TODO >>
```
