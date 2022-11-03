# List Registered UAI Images

Administrators can use the `cray uas admin config images list` command to see the list of registered images. This command also displays the UAS registration information about each image.

Registering a UAI image name is insufficient to make that image available for UAIs. UAI images must also be registered, but also created and stored in the container registry need to link to procedure on how to do that.

### Prerequisites

This procedure requires administrator privileges and the `cray` administrative CLI.

### Procedure

1.  Obtain the list of UAI images that are currently registered with UAS.

    ```bash
    ncn-m001-pit# cray uas admin config images list
    [[results]]
    default = true
    image_id = "08a04462-195a-4e66-aa31-08076072c9b3"
    imagename = "registry.local/cray/cray-uas-sles15:latest"

    [[results]]
    default = false
    image_id = "f8d5f4da-c910-421c-92b6-794ab8cc7e70"
    imagename = "registry.local/cray/cray-uai-broker:latest"

    [[results]]
    default = false
    image_id = "8fdf5d4a-c190-24c1-2b96-74ab98c7ec07"
    imagename = "registry.local/cray/custom-end-user-uai:latest"
    ```

    The output shown above shows three image registrations. Each has an imagename indicating the image to be used to construct a UAI.

    **NOTE:** Simply registering a UAI image name does not make the image available. The image must also be created and stored in the container registry. See [Customize End-User UAI Images](Customize_End-User_UAI_Images.md).

    There is also a `default` flag. If this flag is `true`, the image will be used whenever a UAI is created without specifying an image or UAI class as part of the creation. Finally, there is an `image_id`, which identifies this image registration for later inspection, update, or deletion and for linking the image to a UAI class.

