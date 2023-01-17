# deploy-product

The `deploy-product` stage uses Loftsman to deploy product microservices to the system. The microservices are specified in the `loftsman` entry in each product's `iuf-product-manifest.yaml` file within the product distribution file.

The `deploy-product` stage changes the running state of the system.

## Required Input

The following arguments must be specified. See `iuf -h` and `iuf run -h` for additional optional arguments.

| Input           | `iuf` Argument |
| --------------- | -------------- |
| activity        | `-a ACTIVITY`  |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `deploy-product` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(ncn-m001#) << TODO >>

```bash
<< TODO >>
```
