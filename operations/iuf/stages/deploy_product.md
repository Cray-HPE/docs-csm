# `deploy-product`

The `deploy-product` stage uses Loftsman to deploy product microservices to the system. The microservices are specified in the `loftsman` entry in each product's `iuf-product-manifest.yaml` file within the product distribution file.

`deploy-product` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `deploy-product` stage changes the running state of the system.

## Input

The following arguments are most often used with the `deploy-product` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description                                            |
| --------------- | -------------- | ------------------------------------------------------ |
| Activity        | `-a ACTIVITY`  | Activity created for the install or upgrade operations |

## Execution details

The code executed by this stage exists within IUF. See the `deploy-product` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `deploy-product` stage for activity `admin-230127`.

```bash
iuf -a admin-230127 run -r deploy-product
```
