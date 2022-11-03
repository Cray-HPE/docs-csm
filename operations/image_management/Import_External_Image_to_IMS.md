# Import an External Image to IMS

The Image Management Service \(IMS\) is typically used to build images from IMS recipes and customize Images that are already known to IMS.
However, it is sometimes the case that an image is built using a mechanism other than by IMS and needs to be added to IMS. In these cases,
the following procedure can be used to add this external image to IMS and upload the image's artifact(s) to the Simple Storage Service (S3).

* [Prerequisites](#prerequisites)
* [Limitations](#limitations)
* [Procedure](#procedure)
    1. [Ensure supported format](#1-ensure-supported-format)
    1. [Set helper variables](#2-set-helper-variables)
    1. [Record artifact checksums](#3-record-artifact-checksums)
    1. [Create image record in IMS](#4-create-image-record-in-ims)
    1. [Upload artifacts to S3](#5-upload-artifacts-to-s3)
    1. [Create, upload, and register image manifest](#6-create-upload-and-register-image-manifest)

## Prerequisites

* CSM is fully installed, configured, and healthy.
  * The Image Management Service \(IMS\) is healthy.
  * The Simple Storage Service \(S3\) is healthy.
  * The NCN Certificate Authority \(CA\) public key has been properly installed into the CA cache for this system.
  * These may be validated by performing the following health checks:
    * [Platform health checks](../validate_csm_health.md#1-platform-health-checks)
    * [Software Management Service health checks](../validate_csm_health.md#3-software-management-services-sms-health-checks)
* The Cray CLI is configured.
  * See [Configure the Cray CLI](../configure_cray_cli.md).
* Image artifact files are available.
  * An image root file is required.
  * Optionally, additional image artifacts may be specified including a kernel, `initrd`, and kernel parameters file.

* A token providing S3 credentials has been generated.

## Limitations

* The commands in this procedure must be run as the `root` user.
* Images in the `.txz` compressed format need to be converted to SquashFS in order to use IMS image customization.

## Procedure

This procedure may be run on any master or worker NCN.

The procedure on this page uses example commands that assume the image has an associated kernel and `initrd` artifact. This is the case,
for example, for NCN boot images. If the actual set of image artifacts differs from this, then be sure to modify the commands accordingly.

### 1. Ensure supported format

1. Ensure that the image root is in a supported format.

    IMS requires that an image's root filesystem is in SquashFS format. Select one of the following options based on the current state of the image root being used:

    * If the image being added is in `tgz` format, then refer to [Convert TGZ Archives to SquashFS Images](Convert_TGZ_Archives_to_SquashFS_Images.md).
    * If the image being added meets the above requirements, then proceed to [Create image record in IMS](#2-create-image-record-in-ims).
    * If the image root is in a format other than `tgz` or SquashFS, then convert the image root to `tgz`/SquashFS before continuing.

### 2. Set helper variables

Set variables for all of the image artifact files, if needed. For example, `IMS_ROOTFS_FILENAME`, `IMS_INITRD_FILENAME`, and `IMS_KERNEL_FILENAME`.

If this procedure is being done as part of [Management Node Image Customization](../configuration_management/Management_Node_Image_Customization.md),
then these should already be set. In this case, skip this section and proceed to [Record artifact checksums](#3-record-artifact-checksums).

1. (`ncn-mw#`) Set the `IMS_ROOTFS_FILENAME` variable to the file name of the SquashFS image root file to be uploaded.

    For example:

    ```bash
    IMS_ROOTFS_FILENAME=sles_15_image.squashfs
    ```

1. (`ncn-mw#`) Set the `IMS_INITRD_FILENAME` variable to the file name of the `initrd` file to be uploaded.

    > Skip this if no `initrd` file is associated with this image.

    For example:

    ```bash
    IMS_INITRD_FILENAME=initrd
    ```

1. (`ncn-mw#`) Set the `IMS_KERNEL_FILENAME` variable to the file name of the kernel file to be uploaded.

    > Skip this if no kernel file is associated with this image.

    For example:

    ```bash
    IMS_KERNEL_FILENAME=vmlinuz
    ```

### 3. Record artifact checksums

1. Navigate to the directory containing the artifact files.

1. (`ncn-mw#`) Verify that all image artifacts exist in the current working directory.

    > If necessary, modify the following command to reflect the actual set of artifacts included in the image.

    ```bash
    ls -al "${IMS_ROOTFS_FILENAME}" "${IMS_INITRD_FILENAME}" "${IMS_KERNEL_FILENAME}"
    ```

1. (`ncn-mw#`) Record the checksums of all of the artifacts.

    1. Record the SquashFS image root checksum in the `IMS_ROOTFS_MD5SUM` variable.

        ```bash
        IMS_ROOTFS_MD5SUM=$(md5sum "${IMS_ROOTFS_FILENAME}" | awk '{ print $1 }')
        echo "${IMS_ROOTFS_MD5SUM}"
        ```

    1. Record the `initrd` checksum in the `IMS_INITRD_MD5SUM` variable.

        > Skip this if no `initrd` file is associated with this image.

        ```bash
        IMS_INITRD_MD5SUM=$(md5sum "${IMS_INITRD_FILENAME}" | awk '{ print $1 }')
        echo "${IMS_INITRD_MD5SUM}"
        ```

    1. Record the kernel checksum in the `IMS_KERNEL_MD5SUM` variable.

        > Skip this if no kernel file is associated with this image.

        ```bash
        IMS_KERNEL_MD5SUM=$(md5sum "${IMS_KERNEL_FILENAME}" | awk '{ print $1 }')
        echo "${IMS_KERNEL_MD5SUM}"
        ```

### 4. Create image record in IMS

1. (`ncn-mw#`) Create a new IMS image record for the image.

    ```bash
    cray ims images create --name "${IMS_ROOTFS_FILENAME}" --format toml
    ```

    Example output:

    ```toml
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    name = "sles_15_image.squashfs"
    ```

1. (`ncn-mw#`) Create an environment variable for the ID of the new IMS image record.

    Set the `IMS_IMAGE_ID` variable, using the `id` field value from the returned data in the previous step.

    ```bash
    IMS_IMAGE_ID=4e78488d-4d92-4675-9d83-97adfc17cb19
    ```

### 5. Upload artifacts to S3

If this procedure is being done as part of [Management Node Image Customization](../configuration_management/Management_Node_Image_Customization.md),
then these artifacts should already exist in S3. In this case, skip this section and proceed to
[Create image manifest file and upload to S3](#6-create-image-manifest-file-and-upload-to-s3).

1. Navigate to the directory containing the artifact files.

1. (`ncn-mw#`) Verify that all image artifacts exist in the current working directory.

    > If necessary, modify the following command to reflect the actual set of artifacts included in the image.

    ```bash
    ls -al "${IMS_ROOTFS_FILENAME}" "${IMS_INITRD_FILENAME}" "${IMS_KERNEL_FILENAME}"
    ```

1. (`ncn-mw#`) Upload the artifacts to S3.

    1. Upload the SquashFS image root to S3.

        ```bash
        cray artifacts create boot-images "${IMS_IMAGE_ID}/${IMS_ROOTFS_FILENAME}" "${IMS_ROOTFS_FILENAME}"
        ```

    1. Upload the kernel to S3.

        ```bash
        cray artifacts create boot-images "${IMS_IMAGE_ID}/${IMS_KERNEL_FILENAME}" "${IMS_KERNEL_FILENAME}"
        ```

    1. Upload the `initrd` to S3.

        ```bash
        cray artifacts create boot-images "${IMS_IMAGE_ID}/${IMS_INITRD_FILENAME}" "${IMS_INITRD_FILENAME}"
        ```

### 6. Create, upload, and register image manifest

HPE Cray uses a manifest file that associates multiple related boot artifacts \(kernel, `initrd`, image root, etc.\) into
an image description that is used by IMS and other services to boot nodes. Artifacts listed within the manifest are
identified by a `type` value:

* `application/vnd.cray.image.rootfs.squashfs`
* `application/vnd.cray.image.initrd`
* `application/vnd.cray.image.kernel`
* `application/vnd.cray.image.parameters.boot`

1. (`ncn-mw#`) Generate an image manifest file.

    > If necessary, modify the following example to reflect the actual set of artifacts included in the image.
    >
    > Note that the following command makes use of several variables that have been set during
    > this procedure. The command must be run from the Bash shell in order for them to be properly evaluated.

    ```console
    cat <<EOF> manifest.json
    {
      "created": "`date '+%Y-%m-%d %H:%M:%S'`",
      "version": "1.0",
      "artifacts": [
        {
          "link": {
              "path": "s3://boot-images/${IMS_IMAGE_ID}/${IMS_ROOTFS_FILENAME}",
              "type": "s3"
          },
          "md5": "${IMS_ROOTFS_MD5SUM}",
          "type": "application/vnd.cray.image.rootfs.squashfs"
        },
        {
          "link": {
              "path": "s3://boot-images/${IMS_IMAGE_ID}/${IMS_KERNEL_FILENAME}",
              "type": "s3"
          },
          "md5": "${IMS_KERNEL_MD5SUM}",
          "type": "application/vnd.cray.image.kernel"
        },
        {
          "link": {
              "path": "s3://boot-images/${IMS_IMAGE_ID}/${IMS_INITRD_FILENAME}",
              "type": "s3"
          },
          "md5": "${IMS_INITRD_MD5SUM}",
          "type": "application/vnd.cray.image.initrd"
        }
      ]
    }
    EOF
    ```

1. (`ncn-mw#`) Upload the manifest to S3.

    ```bash
    cray artifacts create boot-images "${IMS_IMAGE_ID}/manifest.json" manifest.json
    ```

1. (`ncn-mw#`) Update the IMS image record with the image manifest information.

    ```bash
    cray ims images update "${IMS_IMAGE_ID}" \
        --link-type s3 \
        --link-path "s3://boot-images/${IMS_IMAGE_ID}/manifest.json" \
        --format toml
    ```

    Example output:

    ```toml
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    name = "sles_15_image.squashfs"

    [link]
    type = "s3"
    path = "s3://boot-images/4e78488d-4d92-4675-9d83-97adfc17cb19/manifest.json"
    etag = ""
    ```
