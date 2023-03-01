# `deliver-product`

The `deliver-product` stage delivers the content provided in the product distribution files to the system. The versioned product catalog entry for each product is updated as the new content is uploaded.

`deliver-product` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `deliver-product` stage does not change the running state of the system as the new content has been uploaded, but not deployed.

## Input

The following arguments are most often used with the `deliver-product` stage. See `iuf -h` and `iuf run -h` for additional arguments.

| Input           | `iuf` Argument | Description                                           |
| --------------- | -------------- | ----------------------------------------------------- |
| Activity        | `-a ACTIVITY`  | Activity created for the install or upgrade operations|

## Execution details

The code executed by this stage exists within IUF. See the `deliver-product` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

Artifacts will be uploaded to the following locations based on entries specified in the products' `iuf-product-manifest.yaml` files.

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

The following table describes upload behavior when the artifact being uploaded already exists on the system.

| Artifact                      | Upload Behavior                                          |
| ----------------------------- | ---------------------------------                        |
| S3 Content                    | overwrite existing artifact                              |
| S3 Loftsman Manifests         | overwrite existing artifact                              |
| Nexus Docker Registries       | new artifact uploaded with same tag as previous artifact |
| Nexus Helm Chart Repositories | skip upload                                              |
| Nexus RPM Blob Stores         | update existing blob store with new definition           |
| Nexus RPM Repositories        | update existing repository with new definition           |
| Nexus RPMs                    | skip upload                                              |
| VCS Content                   | skip upload                                              |
| IMS Images and Recipes        | skip upload                                              |

## Example

(`ncn-m001#`) Execute the `deliver-product` stage for activity `admin-230127`.

```bash
iuf -a admin-230127 run -r deliver-product
```
