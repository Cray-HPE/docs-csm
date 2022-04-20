# Import an External Image to IMS

The Image Management Service \(IMS\) is typically used to build images from IMS recipes and customize Images that are already known to IMS.
However, it is sometimes the case that an image is built using a mechanism other than by IMS and needs to be added to IMS. In these cases, 
the following procedure can be used to add this external image to IMS and upload the image's artifact(s) to the Simple Storage Service (S3). 

## Prerequisites

* System management services \(SMS\) are running in a Kubernetes cluster on non-compute nodes \(NCN\) and include the following deployments:
  * `cray-ims`, the Image Management Service \(IMS\)
* `kubectl` is installed locally and configured to point at the SMS Kubernetes cluster.
* An image root archive or a pre-built image root SquashFS archive is available. 
* Optionally, additional image artifacts including a kernel, initrd and kernel parameters file are available. 
* The NCN Certificate Authority \(CA\) public key has been properly installed into the CA cache for this system.
* A token providing Simple Storage Service \(S3\) credentials has been generated.

## Limitations

* The commands in this procedure must be run as the `root` user.
* Images in the .txz compressed format need to be converted to SquashFS in order to use IMS image customization.

## Procedure

<a name="ensure_supported_format"></a>

**Ensure that the image root is in a supported format**

1. IMS requires that an image meet the following criteria:

    * The image's root filesystem is in SquashFS format.
    
    Select one of the following options based on the current state of the image root being used:

    * If the image being added is in tgz format, refer to [Convert TGZ Archives to SquashFS Images](Convert_TGZ_Archives_to_SquashFS_Images.md).
    * If the image being added meets the above requirements, proceed to [Create an IMS Image Record](#create_image_record).
    * If the image root is in a format other than tgz or squashfs, please convert the image root to tgz/squashfs before continuing.
    
<a name="create_image_record"></a>

**Create an IMS Image Record**

2. Create a new IMS image record for the image. Give the image a descriptive name.

    ```bash
    ncn# cray ims images create --name $IMS_ROOTFS_FILENAME
    ```

    Example output:

    ```
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    name = "sles_15_image.squashfs"
    ```

    If successful, create a variable for the id value in the returned data.

    ```bash
    ncn# export IMS_IMAGE_ID=4e78488d-4d92-4675-9d83-97adfc17cb19
    ```

<a name="upload_to_s3"></a>

**Upload Image Artifacts to S3**

3. Upload the image root to S3.

    ```bash
    ncn# cray artifacts create boot-images $IMS_IMAGE_ID/$IMS_ROOTFS_FILENAME $IMS_ROOTFS_FILENAME
    ncn# export IMS_ROOTFS_MD5SUM=`md5sum $IMS_ROOTFS_FILENAME | awk '{ print $1 }'`
    ```

4. Optionally, upload the kernel for the image to S3.

    ```bash
    ncn# export IMS_KERNEL_FILENAME=vmlinuz
    ncn# cray artifacts create boot-images $IMS_IMAGE_ID/$IMS_KERNEL_FILENAME \
    image-root/boot/$IMS_KERNEL_FILENAME
    ncn# export IMS_KERNEL_MD5SUM=`md5sum image-root/boot/$IMS_KERNEL_FILENAME | awk '{ print $1 }'`
    ```

5. Optionally, upload the initrd for the image to S3.

    ```bash
    ncn# export IMS_INITRD_FILENAME=initrd
    ncn# cray artifacts create boot-images $IMS_IMAGE_ID/$IMS_INITRD_FILENAME \
    image-root/boot/$IMS_INITRD_FILENAME
    ncn# export IMS_INITRD_MD5SUM=`md5sum image-root/boot/$IMS_INITRD_FILENAME | awk '{ print $1 }'`
    ```

<a name="image_manifest"></a>

**Create an Image Manifest and Upload it to S3**

HPE Cray uses a manifest file that associates multiple related boot artifacts \(kernel, initrd, rootfs, etc.\) into an image description that is used by IMS and other services to boot nodes. Artifacts listed within the manifest are identified by a `type` value:

- application/vnd.cray.image.rootfs.squashfs
- application/vnd.cray.image.initrd
- application/vnd.cray.image.kernel
- application/vnd.cray.image.parameters.boot

6. Generate an image manifest file. 

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

7. Upload the manifest to S3.

    ```bash
    ncn# cray artifacts create boot-images $IMS_IMAGE_ID/manifest.json manifest.json
    ```

<a name="register"></a>

**Register the Image Manifest with the IMS Service**

8. Update the IMS image record.

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
