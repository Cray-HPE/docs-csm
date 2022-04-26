# Import an External Image to IMS

The Image Management Service \(IMS\) is typically used to build images from IMS recipes and customize Images that are already known to IMS.
However, it is sometimes the case that an image is built using a mechanism other than by IMS and needs to be added to IMS. In these cases,
the following procedure can be used to add this external image to IMS and upload the image's artifact(s) to the Simple Storage Service (S3).

## Prerequisites

* System management services \(SMS\) are running in a Kubernetes cluster on non-compute nodes \(NCN\) and include the following deployments:
    * `cray-ims`, the Image Management Service \(IMS\)
* `kubectl` is installed locally and configured to point at the SMS Kubernetes cluster.
* An image root archive or a pre-built image root SquashFS archive is available.
* Optionally, additional image artifacts including a kernel, initrd, and kernel parameters file are available.
* The NCN Certificate Authority \(CA\) public key has been properly installed into the CA cache for this system.
* A token providing Simple Storage Service \(S3\) credentials has been generated.

## Limitations

* The commands in this procedure must be run as the `root` user.
* Images in the .txz compressed format need to be converted to SquashFS in order to use IMS image customization.

## Procedure

<a name="ensure_supported_format"></a>
1.  Ensure that the image root is in a supported format.

    IMS requires that an image's root filesystem is in SquashFS format. Select one of the following options based on the current state of the image root being used:

    * If the image being added is in `tgz` format, refer to [Convert TGZ Archives to SquashFS Images](Convert_TGZ_Archives_to_SquashFS_Images.md).
    * If the image being added meets the above requirements, proceed to [Create an IMS Image Record](#create_image_record).
    * If the image root is in a format other than `tgz` or SquashFS, convert the image root to `tgz`/SquashFS before continuing.

    <a name="create_image_record"></a>
1.  Choose a descriptive name for the new IMS Image Record.

    Set the `IMS_ROOTFS_FILENAME` variable to the chosen name.

    ```bash
    ncn# IMS_ROOTFS_FILENAME=sles_15_image.squashfs
    ```

1.  Create a new IMS image record for the image.

    ```bash
    ncn# cray ims images create --name $IMS_ROOTFS_FILENAME
    ```

    Example output:

    ```
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    name = "sles_15_image.squashfs"
    ```

1.  Create an environment variable for the ID of the new IMS Image Record.

    Set and export the `IMS_IMAGE_ID` variable, using the `id` field value from the returned data in the previous step.

    ```bash
    ncn# export IMS_IMAGE_ID=4e78488d-4d92-4675-9d83-97adfc17cb19
    ```

    <a name="upload_to_s3"></a>
1.  Upload the image root to S3.

    1.  Set an environment variable with the actual path and filename of the image root to be uploaded.

        > This may be the same name as your `IMS_ROOTFS_FILENAME`, but it is not required to be.

        ```bash
        ncn# ROOTFS_FILENAME=/home/rootfs.squashfs
        ```

    1. Record the `md5sum` of the image root to be uploaded.

        ```bash
        ncn# export IMS_ROOTFS_MD5SUM=`md5sum $ROOTFS_FILENAME | awk '{ print $1 }'`
        ```

    1. Upload the image root to S3.

        ```bash
        ncn# cray artifacts create boot-images $IMS_IMAGE_ID/$IMS_ROOTFS_FILENAME $ROOTFS_FILENAME
        ```

1.  Optionally, upload the kernel for the image to S3.

    > In this example, the relative path to the kernel from the working directory is
    > `image-root/boot/vmlinuz`.

    ```bash
    ncn# export IMS_KERNEL_FILENAME=vmlinuz
    ncn# cray artifacts create boot-images $IMS_IMAGE_ID/$IMS_KERNEL_FILENAME \
            image-root/boot/$IMS_KERNEL_FILENAME
    ncn# export IMS_KERNEL_MD5SUM=`md5sum image-root/boot/$IMS_KERNEL_FILENAME | awk '{ print $1 }'`
    ```

1. Optionally, upload the initrd for the image to S3.

    > In this example, the relative path to the initrd file from working directory is
    > `image-root/boot/initrd`.

    ```bash
    ncn# export IMS_INITRD_FILENAME=initrd
    ncn# cray artifacts create boot-images $IMS_IMAGE_ID/$IMS_INITRD_FILENAME \
    image-root/boot/$IMS_INITRD_FILENAME
    ncn# export IMS_INITRD_MD5SUM=`md5sum image-root/boot/$IMS_INITRD_FILENAME | awk '{ print $1 }'`
    ```

    <a name="image_manifest"></a>
1.  Create an image manifest and upload it to S3.

    HPE Cray uses a manifest file that associates multiple related boot artifacts \(kernel, initrd, rootfs, etc.\) into
    an image description that is used by IMS and other services to boot nodes. Artifacts listed within the manifest are
    identified by a `type` value:

    - `application/vnd.cray.image.rootfs.squashfs`
    - `application/vnd.cray.image.initrd`
    - `application/vnd.cray.image.kernel`
    - `application/vnd.cray.image.parameters.boot`

    1. Generate an image manifest file.

        ```bash
        ncn# cat <<EOF> manifest.json
        {
          "created": "`date '+%Y-%m-%d %H:%M:%S'`",
          "version": "1.0",
          "artifacts": [
            {
              "link": {
                  "path": "s3://boot-images/$IMS_IMAGE_ID/$IMS_ROOTFS_FILENAME",
                  "type": "s3"
              },
              "md5": "$IMS_ROOTFS_MD5SUM",
              "type": "application/vnd.cray.image.rootfs.squashfs"
            },
            {
              "link": {
                  "path": "s3://boot-images/$IMS_IMAGE_ID/$IMS_KERNEL_FILENAME",
                  "type": "s3"
              },
              "md5": "$IMS_KERNEL_MD5SUM",
              "type": "application/vnd.cray.image.kernel"
            },
            {
              "link": {
                  "path": "s3://boot-images/$IMS_IMAGE_ID/$IMS_INITRD_FILENAME",
                  "type": "s3"
              },
              "md5": "$IMS_INITRD_MD5SUM",
              "type": "application/vnd.cray.image.initrd"
            }
          ]
        }
        EOF
        ```

    1. Upload the manifest to S3.

        ```bash
        ncn# cray artifacts create boot-images $IMS_IMAGE_ID/manifest.json manifest.json
        ```

    <a name="register"></a>
1.  Register the image manifest with the IMS service.

    Update the IMS image record.

    ```bash
    ncn# cray ims images update $IMS_IMAGE_ID \
            --link-type s3 \
            --link-path s3://boot-images/$IMS_IMAGE_ID/manifest.json
    ```

    Example output:

    ```
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    name = "sles_15_image.squashfs"

    [link]
    type = "s3"
    path = "s3://boot-images/4e78488d-4d92-4675-9d83-97adfc17cb19/manifest.json"
    etag = ""
    ```
