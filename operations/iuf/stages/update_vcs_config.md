# update-vcs-config

The `update-vcs-config` stage updates the customer branches of configuration management repositories in VCS.

<< TODO: add details on the VCS branch creation/merging logic and where branch name input comes from >>

The `update-vcs-config` stage does not change the running state of the system.

## Required Input

The following arguments must be specified. See `iuf -h` and `iuf run -h` for additional optional arguments.

| Input           | `iuf` Argument |
| --------------- | -------------- |
| activity        | `-a ACTIVITY`  |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `update-vcs-config` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(ncn-m001#) << TODO >>

```bash
<< TODO >>
```
