# management-nodes-rollout

The `management-nodes-rollout` stage performs a controlled rebuild of the management worker nodes in order to reboot them to a new image and configuration. IUF will account for the necessary minimum number of critical software instances running on worker nodes to ensure the `management-nodes-rollout` stage operates without impacting software availability.

The `management-nodes-rollout` stage changes the running state of the system.

## Required Input

The following arguments must be specified. See `iuf -h` and `iuf run -h` for additional optional arguments.

| Input           | `iuf` Argument |
| --------------- | -------------- |
| activity        | `-a ACTIVITY`  |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `management-nodes-rollout` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(ncn-m001#) << TODO >>

```bash
<< TODO >>
```
