# Import an External Image to IMS

The Image Management Service \(IMS\) is typically used to build images from IMS recipes and customize Images that are already known to IMS.
However, it is sometimes the case that an image is built using a mechanism other than by IMS and needs to be added to IMS. In these cases,
the following procedure can be used to add this external image to IMS and upload the image's artifact(s) to the Simple Storage Service (S3).

## Prerequisites

* System management services \(SMS\) are running in a Kubernetes cluster on non-compute nodes \(NCN\) and include the following deployments:
  * `cray-ims`, the Image Management Service \(IMS\)
* `kubectl` is installed locally and configured to point at the SMS Kubernetes cluster.
* An image root archive or a pre-built image root SquashFS archive is available.
* Optionally, additional image artifacts including a kernel, `initrd`, and kernel parameters file are available.
* The NCN Certificate Authority \(CA\) public key has been properly installed into the CA cache for this system.
* A token providing Simple Storage Service \(S3\) credentials has been generated.

## Limitations

* The commands in this procedure must be run as the `root` user.
* Images in the `.txz` compressed format need to be converted to SquashFS in order to use IMS image customization.

## Procedure

This procedure may be run on any master or worker NCN.

### Ensure supported format

1. Ensure that the image root is in a supported format.

    IMS requires that an image's root filesystem is in SquashFS format. Select one of the following options based on the current state of the image root being used:

    * If the image being added is in `tgz` format, refer to [Convert TGZ Archives to SquashFS Images](Convert_TGZ_Archives_to_SquashFS_Images.md).
    * If the image being added meets the above requirements, proceed to [Create an IMS image record](#create-image-record).
    * If the image root is in a format other than `tgz` or SquashFS, convert the image root to `tgz`/SquashFS before continuing.

### Create image record

1. Check if `IMS_ROOTFS_FILENAME` is already set. If you are following the steps in
   [Management Node Image Customization](../configuration_management/Management_Node_Image_Customization.md), then
   this should already be set.

    ```bash
    echo $IMS_ROOTFS_FILENAME
    ```

1. If the above variable is not set, then set `IMS_ROOTFS_FILENAME` to the file name of the `rootfs` file
   to be uploaded.

    ```bash
    IMS_ROOTFS_FILENAME=sles_15_image.squashfs
    ```

1. Create a new IMS image record for the image.

    ```bash
    cray ims images create --name $IMS_ROOTFS_FILENAME --format toml
    ```

    Example output:

    ```toml
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    name = "sles_15_image.squashfs"
    ```

1. Create an environment variable for the ID of the new IMS image record.

    Set the `IMS_IMAGE_ID` variable, using the `id` field value from the returned data in the previous step.

    ```bash
    IMS_IMAGE_ID=4e78488d-4d92-4675-9d83-97adfc17cb19
    ```

### Upload image to S3

1. Upload the image root to S3.

    1. Navigate to the directory containing the `rootfs` file. Verify that it exists in your current working
       directory.

        ```bash
        ls $IMS_ROOTFS_FILENAME
        ```

    1. Record the `md5sum` of the image root to be uploaded.

        ```bash
        IMS_ROOTFS_MD5SUM=$(md5sum $IMS_ROOTFS_FILENAME | awk '{ print $1 }')
        ```

    1. Upload the image root to S3.

        ```bash
        cray artifacts create boot-images $IMS_IMAGE_ID/$IMS_ROOTFS_FILENAME $IMS_ROOTFS_FILENAME
        ```

1. Optionally, upload the kernel for the image to S3.

    1. Check if `IMS_KERNEL_FILENAME` is already set. If you are following the steps in
       [Management Node Image Customization](../configuration_management/Management_Node_Image_Customization.md), then
       this should already be set.

        ```bash
        echo $IMS_KERNEL_FILENAME
        ```

    1. If the above variable is not set, then set `IMS_KERNEL_FILENAME` to the file name of the kernel file
       to be uploaded.

        ```bash
        IMS_KERNEL_FILENAME=vmlinuz
        ```

    1. Navigate to the directory containing the kernel file. Verify that it exists in your current working
       directory.

        ```bash
        ls $IMS_KERNEL_FILENAME
        ```

    1. Record the `md5sum` of the kernel to be uploaded.

        ```bash
        IMS_KERNEL_MD5SUM=$(md5sum $IMS_KERNEL_FILENAME | awk '{ print $1 }')
        ```

    1. Upload the kernel to S3.

        ```bash
        cray artifacts create boot-images $IMS_IMAGE_ID/$IMS_KERNEL_FILENAME $IMS_KERNEL_FILENAME
        ```

1. Optionally, upload the `initrd` for the image to S3.

    1. Check if `IMS_INITRD_FILENAME` is already set. If you are following the steps in
       [Management Node Image Customization](../configuration_management/Management_Node_Image_Customization.md), then
       this should already be set.

        ```bash
        echo $IMS_INITRD_FILENAME
        ```

    1. If the above variable is not set, then set `IMS_INITRD_FILENAME` to the file name of the initrd file
       to be uploaded.

        ```bash
        IMS_INITRD_FILENAME=initrd
        ```

    1. Navigate to the directory containing the initrd file. Verify that it exists in your current working
       directory.

        ```bash
        ls $IMS_INITRD_FILENAME
        ```

    1. Record the `md5sum` of the initrd to be uploaded.

        ```bash
        IMS_INITRD_MD5SUM=$(md5sum $IMS_INITRD_FILENAME | awk '{ print $1 }')
        ```

    1. Upload the initrd to S3.

        ```bash
        cray artifacts create boot-images $IMS_IMAGE_ID/$IMS_INITRD_FILENAME $IMS_INITRD_FILENAME
        ```

### Image manifest

1. Create an image manifest and upload it to S3.

    HPE Cray uses a manifest file that associates multiple related boot artifacts \(kernel, `initrd`, `rootfs`, etc.\) into
    an image description that is used by IMS and other services to boot nodes. Artifacts listed within the manifest are
    identified by a `type` value:

    * `application/vnd.cray.image.rootfs.squashfs`
    * `application/vnd.cray.image.initrd`
    * `application/vnd.cray.image.kernel`
    * `application/vnd.cray.image.parameters.boot`

    1. Generate an image manifest file.

        ```console
        cat <<EOF> manifest.json
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
        cray artifacts create boot-images $IMS_IMAGE_ID/manifest.json manifest.json
        ```

#### Register

1. Register the image manifest with the IMS service.

    Update the IMS image record.

    ```bash
    cray ims images update $IMS_IMAGE_ID \
            --link-type s3 \
            --link-path s3://boot-images/$IMS_IMAGE_ID/manifest.json \
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
