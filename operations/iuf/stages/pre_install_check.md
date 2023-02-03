# `pre-install-check`

The `pre-install-check` stage ensures that CSM is operating properly so that products can be installed. It verifies that S3 storage is functional, that CFS, VCS, and IMS microservices are functional, etc. Products may
provide hook scripts to perform additional product-specific system checks.

`pre-install-check` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `pre-install-check` stage does not change the running state of the system.

## Input

The following arguments are most often used with the `pre-install-check` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description                                            |
| --------------- | -------------- | ------------------------------------------------------ |
| Activity        | `-a ACTIVITY`  | Activity created for the install or upgrade operations |

## Execution details

The code executed by this stage exists within IUF. See the `pre-install-check` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `pre-install-check` stage for activity `admin-230127`.

```bash
iuf -a admin-230127 run -r pre-install-check
```
