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

The versioned product catalog entry for the product is updated as content is uploaded.

The `deliver-product` stage does not change the running state of the system.

## Required Input

The following arguments must be specified. See `iuf -h` and `iuf run -h` for additional optional arguments.

| Input           | `iuf` Argument |
| --------------- | -------------- |
| activity        | `-a ACTIVITY`  |

## Execution Details

The code executed by this stage primarily exists with IUF itself. See the `deliver-product` entry in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding file(s) in `/usr/share/doc/csm/workflows/iuf/operations/` for details on the commands executed.

## Example

(ncn-m001#) Execute the `deliver-product` stage.

```bash
iuf -a joe-install-20230107 run -r deliver-product
INFO All logs will be stored in /etc/cray/upgrade/csm/iuf/joe-install-20230107/log/20230107234030
INFO MONITORING SESSION: joe-install-20230107kq3cr
INFO BEGINNING STAGE: deliver-product
INFO     WORKFLOW ID: joe-install-20230107kq3cr-deliver-product-qfj9s
INFO         BEGIN PHASE: cos-add-product-to-product-catalog
INFO         BEGIN PHASE: [0]
INFO         BEGIN PHASE: start-operation
INFO      FINISHED PHASE: [0] [Succeeded]
INFO      FINISHED PHASE: start-operation [Succeeded]
INFO         BEGIN PHASE: [1]
INFO         BEGIN PHASE: update-product-catalog
INFO      FINISHED PHASE: [1] [Succeeded]
INFO      FINISHED PHASE: update-product-catalog [Succeeded]
INFO         BEGIN PHASE: [2]
INFO         BEGIN PHASE: end-operation
INFO      FINISHED PHASE: [2] [Succeeded]
INFO      FINISHED PHASE: end-operation [Succeeded]
INFO         BEGIN PHASE: [3]
INFO         BEGIN PHASE: prom-metrics
INFO      FINISHED PHASE: cos-add-product-to-product-catalog [Succeeded]
INFO      FINISHED PHASE: [3] [Succeeded]
INFO      FINISHED PHASE: prom-metrics [Succeeded]
INFO         BEGIN PHASE: cos-loftsman-manifest-upload
INFO         BEGIN PHASE: [0]
INFO         BEGIN PHASE: loftsman-manifest-upload
INFO         BEGIN PHASE: loftsman-manifest-upload(0)
INFO      FINISHED PHASE: cos-loftsman-manifest-upload [Succeeded]
INFO      FINISHED PHASE: [0] [Succeeded]
INFO      FINISHED PHASE: loftsman-manifest-upload [Succeeded]
INFO      FINISHED PHASE: loftsman-manifest-upload(0) [Succeeded]
INFO         BEGIN PHASE: cos-s3-upload
INFO         BEGIN PHASE: [0]
INFO         BEGIN PHASE: s3-upload
INFO         BEGIN PHASE: s3-upload(0)
INFO      FINISHED PHASE: cos-s3-upload [Succeeded]
INFO      FINISHED PHASE: [0] [Succeeded]
INFO      FINISHED PHASE: s3-upload [Succeeded]
INFO      FINISHED PHASE: s3-upload(0) [Succeeded]
INFO         BEGIN PHASE: cos-nexus-setup
INFO         BEGIN PHASE: [0]
INFO         BEGIN PHASE: nexus-get-prerequisites
INFO         BEGIN PHASE: nexus-get-prerequisites(0)
INFO      FINISHED PHASE: [0] [Succeeded]
INFO      FINISHED PHASE: nexus-get-prerequisites [Succeeded]
INFO      FINISHED PHASE: nexus-get-prerequisites(0) [Succeeded]
INFO         BEGIN PHASE: [1]
INFO         BEGIN PHASE: nexus-setup
INFO      FINISHED PHASE: nexus-setup [Succeeded]
INFO         BEGIN PHASE: nexus-setup.onExit
INFO      FINISHED PHASE: cos-nexus-setup [Succeeded]
INFO      FINISHED PHASE: [1] [Succeeded]
INFO      FINISHED PHASE: nexus-setup.onExit [Succeeded]
INFO         BEGIN PHASE: cos-nexus-rpm-upload
INFO         BEGIN PHASE: [0]
INFO         BEGIN PHASE: nexus-get-prerequisites
INFO         BEGIN PHASE: nexus-get-prerequisites(0)
INFO      FINISHED PHASE: [0] [Succeeded]
INFO      FINISHED PHASE: nexus-get-prerequisites [Succeeded]
INFO      FINISHED PHASE: nexus-get-prerequisites(0) [Succeeded]
INFO         BEGIN PHASE: [1]
INFO         BEGIN PHASE: nexus-rpm-load
INFO      FINISHED PHASE: nexus-rpm-load [Succeeded]
INFO         BEGIN PHASE: nexus-rpm-load.onExit
INFO      FINISHED PHASE: cos-nexus-rpm-upload [Succeeded]
INFO      FINISHED PHASE: [1] [Succeeded]
INFO      FINISHED PHASE: nexus-rpm-load.onExit [Succeeded]
INFO         BEGIN PHASE: cos-nexus-docker-upload
INFO         BEGIN PHASE: [0]
INFO         BEGIN PHASE: nexus-get-prerequisites
INFO         BEGIN PHASE: nexus-get-prerequisites(0)
INFO      FINISHED PHASE: [0] [Succeeded]
INFO      FINISHED PHASE: nexus-get-prerequisites [Succeeded]
INFO      FINISHED PHASE: nexus-get-prerequisites(0) [Succeeded]
INFO         BEGIN PHASE: [1]
INFO         BEGIN PHASE: nexus-docker-load
INFO      FINISHED PHASE: nexus-docker-load [Succeeded]
INFO         BEGIN PHASE: nexus-docker-load.onExit
INFO      FINISHED PHASE: cos-nexus-docker-upload [Succeeded]
INFO      FINISHED PHASE: [1] [Succeeded]
INFO      FINISHED PHASE: nexus-docker-load.onExit [Succeeded]
INFO         BEGIN PHASE: cos-nexus-helm-upload
INFO         BEGIN PHASE: [0]
INFO         BEGIN PHASE: nexus-get-prerequisites
INFO         BEGIN PHASE: nexus-get-prerequisites(0)
INFO      FINISHED PHASE: [0] [Succeeded]
INFO      FINISHED PHASE: nexus-get-prerequisites [Succeeded]
INFO      FINISHED PHASE: nexus-get-prerequisites(0) [Succeeded]
INFO         BEGIN PHASE: [1]
INFO         BEGIN PHASE: nexus-helm-load
INFO      FINISHED PHASE: nexus-helm-load [Succeeded]
INFO         BEGIN PHASE: nexus-helm-load.onExit
INFO      FINISHED PHASE: cos-nexus-helm-upload [Succeeded]
INFO      FINISHED PHASE: [1] [Succeeded]
INFO      FINISHED PHASE: nexus-helm-load.onExit [Succeeded]
INFO         BEGIN PHASE: cos-vcs-upload
INFO         BEGIN PHASE: [0]
INFO         BEGIN PHASE: get-vcs-secrets
INFO         BEGIN PHASE: get-vcs-secrets(0)
INFO      FINISHED PHASE: [0] [Succeeded]
INFO      FINISHED PHASE: get-vcs-secrets [Succeeded]
INFO      FINISHED PHASE: get-vcs-secrets(0) [Succeeded]
INFO         BEGIN PHASE: [1]
INFO         BEGIN PHASE: gitea-upload-content
INFO      FINISHED PHASE: [1] [Succeeded]
INFO      FINISHED PHASE: gitea-upload-content [Succeeded]
INFO         BEGIN PHASE: [2]
INFO         BEGIN PHASE: cleanup
INFO      FINISHED PHASE: cos-vcs-upload [Succeeded]
INFO      FINISHED PHASE: [2] [Succeeded]
INFO      FINISHED PHASE: cleanup [Succeeded]
INFO         BEGIN PHASE: cos-ims-upload
INFO         BEGIN PHASE: [0]
INFO         BEGIN PHASE: get-s3-secrets
INFO         BEGIN PHASE: get-s3-secrets(0)
INFO      FINISHED PHASE: [0] [Succeeded]
INFO      FINISHED PHASE: get-s3-secrets [Succeeded]
INFO      FINISHED PHASE: get-s3-secrets(0) [Succeeded]
INFO         BEGIN PHASE: [1]
INFO         BEGIN PHASE: ims-upload-content
INFO      FINISHED PHASE: ims-upload-content [Succeeded]
INFO         BEGIN PHASE: ims-upload-content.onExit
INFO      FINISHED PHASE: [1] [Succeeded]
INFO      FINISHED PHASE: ims-upload-content.onExit [Succeeded]
INFO         BEGIN PHASE: [2]
INFO         BEGIN PHASE: ims-update-product-catalog
INFO      FINISHED PHASE: cos-ims-upload [Succeeded]
INFO      FINISHED PHASE: [2] [Succeeded]
INFO      FINISHED PHASE: ims-update-product-catalog [Succeeded]
INFO         BEGIN PHASE: cos-post-hook-deliver-product
INFO         BEGIN PHASE: [0]
INFO         BEGIN PHASE: call-hook-script
INFO         BEGIN PHASE: call-hook-script(0)
INFO      FINISHED PHASE: cos-post-hook-deliver-product [Succeeded]
INFO      FINISHED PHASE: [0] [Succeeded]
INFO      FINISHED PHASE: call-hook-script [Succeeded]
INFO      FINISHED PHASE: call-hook-script(0) [Succeeded]
INFO          RESULT: Succeeded
INFO        DURATION: 0:07:14
INFO Install completed in 0:07:17
----------------
Stage Summary
activity session: joe-install-20230107
command line: iuf -a joe-install-20230107 run -r deliver-product
log dir: /etc/cray/upgrade/csm/iuf/joe-install-20230107/log
media dir: /opt/cray/iuf/joe-install-20230107
ran stages: process-media pre-install-check deliver-product
----------------
```
