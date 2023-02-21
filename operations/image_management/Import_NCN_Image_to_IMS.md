# Import an NCN Image to IMS

This page documents an automated tool which takes a set of [Non-Compute Node (NCN)](../../glossary.md#non-compute-node-ncn)
kernel, `initrd`, and SquashFS artifact files, uploads them into the Simple Storage Service (S3), and registers them as an image in the
[Image Management Service (IMS)](../../glossary.md#image-management-service-ims).

For the more general (and more manual) procedure for how to register images in IMS, see
[Import an External Image to IMS](Import_External_Image_to_IMS.md). In addition to providing a more detailed
explanation of the various subtasks being carried out, that procedure also covers such variations as:

* Converting to SquashFS from other formats
* Importing images that are not for NCNs
* Including boot parameters as part of the image manifest file

* [Prerequisites](#prerequisites)
* [Limitations](#limitations)
* [Procedure](#procedure)
    1. [Set helper variables](#1-set-helper-variables)
    1. [Upload artifacts and create IMS image record](#2-upload-artifacts-and-create-ims-image-record)

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
* The CSM documentation RPM must be installed on the node where the procedure is being run. See
  [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).
* Image artifact files are available on the system where the procedure is being run.
  * A SquashFS image root file, a kernel file, and an `initrd` file are required.

## Limitations

* The commands in this procedure must be run as the `root` user.

## Procedure

This procedure may be run on any master or worker NCN.

### 1. Set helper variables

Set variables for all of the image artifact files: `IMS_ROOTFS_FILENAME`, `IMS_INITRD_FILENAME`, and `IMS_KERNEL_FILENAME`.

1. (`ncn-mw#`) Set the `IMS_ROOTFS_FILENAME` variable to the path and file name of the SquashFS image root file.

    For example:

    ```bash
    IMS_ROOTFS_FILENAME=my_ncn_artifacts/sles_15_image.squashfs
    ```

1. (`ncn-mw#`) Set the `IMS_INITRD_FILENAME` variable to the path and file name of the `initrd` file.

    For example:

    ```bash
    IMS_INITRD_FILENAME=my_ncn_artifacts/initrd
    ```

1. (`ncn-mw#`) Set the `IMS_KERNEL_FILENAME` variable to the file name of the kernel file.

    For example:

    ```bash
    IMS_KERNEL_FILENAME=my_ncn_artifacts/kernel
    ```

1. (`ncn-mw#`) Set the `IMS_IMAGE_NAME` variable to a name for the new image in IMS.

    > This is just a label for the image in IMS -- it does not need to correspond to an actual artifact or file.

    For example:

    ```bash
    IMS_IMAGE_NAME=rootfs-k8s-customized-version-2
    ```

### 2. Upload artifacts and create IMS image record

1. (`ncn-mw#`) Set the path to the IMS image upload script.

   ```bash
   NCN_IMS_IMAGE_UPLOAD_SCRIPT=$(rpm -ql docs-csm | grep ncn-ims-image-upload[.]sh)
   echo "${NCN_IMS_IMAGE_UPLOAD_SCRIPT}"
   ```

1. (`ncn-mw#`) Register the new NCN image in IMS.

    ```bash
    NEW_NCN_IMS_ID=$( "$NCN_IMS_IMAGE_UPLOAD_SCRIPT}" --no-cpc \
                          -i "${IMS_INITRD_FILENAME}" \
                          -k "${IMS_KERNEL_FILENAME}" \
                          -s "${IMS_ROOTFS_FILENAME}" \
                          -n "${IMS_IMAGE_NAME}" )
    echo "${NEW_NCN_IMS_ID}"
    ```

    The IMS ID (in UUID format) of the new NCN image should be shown.
