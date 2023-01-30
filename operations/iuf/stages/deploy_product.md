# deploy-product

The `deploy-product` stage uses Loftsman to deploy product microservices to the system. The microservices are specified in the `loftsman` entry in each product's `iuf-product-manifest.yaml` file within the product distribution file.

## Impact

The `deploy-product` stage changes the running state of the system.

## Input

The following arguments are most often used with the `deploy-product` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description |
| --------------- | -------------- | ----------- |
| activity        | `-a ACTIVITY`  | activity created for the install or upgrade operations |

## Execution Details

The code executed by this stage exists within IUF. See the `deploy-product` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `deploy-product` stage.

```bash
iuf -a joe-install-20230107 run -r deploy-product
```
