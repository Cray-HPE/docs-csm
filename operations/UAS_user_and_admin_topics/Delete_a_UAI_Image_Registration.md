# Delete a UAI Image Registration

Unregister a UAI image from UAS.

### Prerequisites

Verify that the UAI image to be deleted is registered with UAS. See [Retrieve UAI Image Registration Information](Retrieve_UAI_Image_Registration_Information.md) for instructions.

### Procedure

Deleting a UAI image from UAS effectively unregisters the UAI image from UAS. This procedure does delete the actual UAI image artifact.

1.  Delete a UAS image registration by using a command of the following form:

    ```bash
    ncn-m001-pit# cray uas admin config images delete IMAGE_ID
    ```

    Replace IMAGE\_ID with image ID of the UAI image to unregister from UAS.

    For example:

    ```
    ncn-m001-pit# cray uas admin config images delete 8fdf5d4a-c190-24c1-2b96-74ab98c7ec07
    ```

