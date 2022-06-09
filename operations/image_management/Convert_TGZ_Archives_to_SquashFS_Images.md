# Convert TGZ Archives to SquashFS Images

If customizing a pre-built image root archive compressed as a `.txz` or other non-SquashFS format, convert the image root to SquashFS and upload the SquashFS archive to S3.

The steps in this section only apply if the image root is not in SquashFS format.

## Prerequisites

There is a pre-built image that is not currently in SquashFS format.

## Procedure

1. Locate the image root to be converted to SquashFS.

    Images and recipes are uploaded to IMS and S3 via containers.

1. Uncompress the desired file to a temporary directory.

    Replace the `TXZ_COMPRESSED_IMAGE` value with the name of the image root being used that was located in the previous step.

    ```bash
    ncn# mkdir -p ~/tmp/image-root
    ncn# cd ~/tmp/
    ncn# tar xvf TXZ_COMPRESSED_IMAGE -C image-root
    ```

1. Recompress the image root with SquashFS.

    ```bash
    ncn# IMS_ROOTFS_FILENAME=IMAGE_NAME.squashfs
    ncn# mksquashfs image-root $IMS_ROOTFS_FILENAME
    ```
