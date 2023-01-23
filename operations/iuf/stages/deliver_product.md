# `deliver-product`

The `deliver-product` stage delivers the content provided in the product distribution file to the system. Artifacts will be uploaded to the following locations based on entries specified in the product `iuf-product-manifest.yaml` file.

| Location                      | `iuf-product-manifest.yaml` Entry |
| ----------------------------- | --------------------------------- |
| S3 Content                    | `s3`                              |
| S3 Loftsman Manifests         | `loftsman`                        |
| Nexus Docker Registries       | `docker`                          |
| Nexus Helm Chart Repositories | `helm`                            |
| Nexus RPM Blob Stores         | `nexus_blob_stores`               |
| Nexus RPM Repositories        | `nexus_repositories`              |
| Nexus RPMs                    | `rpms`                            |
| VCS Content                   | `vcs`                             |
| IMS Images and Recipes        | `ims`                             |

The versioned product catalog entry for the product is updated as the new content is uploaded.

## Impact

The `deliver-product` stage does not change the running state of the system as the new content has been uploaded but has not been deployed.

## Input

The following arguments are most often used with the `deliver-product` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description |
| --------------- | -------------- | ----------- |
| activity        | `-a ACTIVITY`  | activity created for the install or upgrade operations|

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `deliver-product` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(ncn-m001#) Execute the `deliver-product` stage.

```bash
iuf -a joe-install-20230107 run -r deliver-product
```
