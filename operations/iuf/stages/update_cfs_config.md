# update-cfs-config

The `update-cfs-config` stage creates updated CFS configurations used for image customization and personalization of NCN, compute, and application nodes. This stage only creates the CFS configurations; the `prepare-images`, `management-nodes-rollout`, and `management-nodes-rollout` stages executed after `update-cfs-config` use the CFS configuration.

**`NOTE`** Before `update-cfs-config` is executed, any desired site configuration customizations in VCS should be performed. Refer to individual product documentation for configuration customization details.

<< TODO: add details on what determines what products/versions/branches/etc. are used to create configurations >>

The `update-cfs-config` stage does not change the running state of the system.

## Required Input

The following arguments must be specified. See `iuf -h` and `iuf run -h` for additional optional arguments.

| Input           | `iuf` Argument |
| --------------- | -------------- |
| activity        | `-a ACTIVITY`  |

## Execution Details

The code executed by this stage utilizes `sat bootprep` to create CFS configurations. See the `update-cfs-config` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(ncn-m001#) << TODO >>

```bash
<< TODO >>
```
