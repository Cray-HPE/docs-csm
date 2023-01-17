# post-install-service-check

The `post-install-service-check` stage validates that the microservices deployed by the preceding `deploy-product` stage are executing correctly. It primarily executes pre- and post-stage hook scripts provided by products in their `iuf-product-manifest.yaml` file.

The `post-install-service-check` stage does not change the running state of the system.

## Required Input

The following arguments must be specified. See `iuf -h` and `iuf run -h` for additional optional arguments.

| Input           | `iuf` Argument |
| --------------- | -------------- |
| activity        | `-a ACTIVITY`  |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `post-install-service-check` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(ncn-m001#) << TODO >>

```bash
<< TODO >>
```
