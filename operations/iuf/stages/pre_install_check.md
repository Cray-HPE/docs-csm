# `pre-install-check`

The `pre-install-check` stage ensures that CSM is operating properly so that products can be installed. For example, it verifies that S3 storage is functional, that CFS, VCS, and IMS microservices are functional, etc. Products may
provide hook scripts to perform additional product-specific system checks.

## Impact

The `pre-install-check` stage does not change the running state of the system.

## Input

The following arguments are most often used with the `pre-install-check` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description |
| --------------- | -------------- | ----------- |
| activity        | `-a ACTIVITY`  | activity created for the install or upgrade operations |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `pre-install-check` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `pre-install-check` stage.

```bash
iuf -a joe-install-20230107 run -r pre-install-check
```
