---
category: numbered
---

# List Registered UAI Images

How to list the UAI images which have been registered with UAS.

This procedure requires administrator privileges and the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Obtain a list of the UAI images that are currently registered with UAS.


Administrators can use the cray uas admin config images list command to see the list of registered images. This command also displays the UAS registration information about each image.

Registering a UAI image name is insufficient to make that image available for UAIs. UAI images must also be registered, but also created and stored in the container registry need to link to procedure on how to do that.

1.  Obtain the list of UAI images that are currently registered with UAS.

    ```screen
    ncn-m001-pit:~ # cray uas admin config images list
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

    A UAI image can appear in the output of this command and still not be available for use in a UAI.

    This example shows three image registrations. Each has an imagename indicating the image to be used to construct a UAI. If the value for the default field is true, the image will be used whenever a specific image or UAI class is not requested at UAI creation. Only one image should be the default at a time. The image\_id attribute identifies this image registration for later inspection, update, or deletion and for linking the image to a UAI class.


