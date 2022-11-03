# Update a UAI Image Registration

Modify the UAS registration information of a UAI image.

### Prerequisites

Verify that the image to be updated is registered with UAS. Refer to [Retrieve UAI Image Registration Information](Retrieve_UAI_Image_Registration_Information.md).

### Procedure

Once an allowable UAI image has been created, it may be necessary to change its attributes. For example, the default image may need to change.

1.  Modify the registration information of a UAI image by using a command of the form:

    ```bash
    ncn-m001-pit# cray uas admin config images update OPTIONS IMAGE_ID
    ```

    Use the `--default` or `--imagename` options as specified when registering an image to update those specific elements of an existing image registration. For example, to make the `registry.local/cray/custom-end-user-uai:latest` image shown above the default image, use the following command:

    ```
    ncn-m001-pit# cray uas admin config images update --default yes 8fdf5d4a-c190-24c1-2b96-74ab98c7ec07
    ```

