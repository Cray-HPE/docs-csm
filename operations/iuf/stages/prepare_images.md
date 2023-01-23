# prepare-images

The `prepare-images` stage configures NCN management node images and builds and configures compute node, application node, and GPU images. It also creates new BOS session templates corresponding to the new node and image content.
The `prepare-images` stage does not reboot nodes to the new images however.

<< TODO: add details on determines what products/configurations/etc. are used to create images >>

## Impact

The `prepare-images` stage does not change the running state of the system as it does not deploy the newly created images.

## Input

The following arguments are most often used with the `prepare-images` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description |
| --------------- | -------------- | ----------- |
| activity        | `-a ACTIVITY`  | activity created for the install or upgrade operations |

## Execution Details

The code executed by this stage utilizes `sat bootprep` to build and customize images. See the `prepare-images` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

## Example

(`ncn-m001#`) Execute the `prepare-images` stage.

```bash
iuf -a joe-install-20230107 run -r prepare-images
```
