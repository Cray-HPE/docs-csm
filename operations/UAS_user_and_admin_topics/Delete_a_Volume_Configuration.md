---
category: [numbered, numbered]
---

# Delete a Volume Configuration

How to delete a volume configuration and prevent its being mounted in UAIs.

-   Install and initialize the cray administrative CLI.
-   Obtain the `volume_id` of the UAS volume to delete. Perform [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) if necessary.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Delete an existing volume configuration. This procedure does not delete the underlying object referred to by the UAS volume configuration.

-   **LIMITATIONS**

    None.


1.  Delete the target volume configuration.

    In the following example, the UAS volume that will be deleted has a `volume_id` of 7f21972c-6f1d-4f67-b9ec-8cebc5b29d76.

    ```screen
    ncn-m001-pit# cray uas admin config volumes delete 7f21972c-6f1d-4f67-b9ec-8cebc5b29d76
    mount_path = "/mnt/my_data"
    volume_id = "7f21972c-6f1d-4f67-b9ec-8cebc5b29d76"
    volumename = "my-data-volume"
     
    [volume_description.host_path]
    path = "/my/shared/data"
    type = "DirectoryOrCreate"
    ```


If wanted, perform [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) to confirm that the UAS volume has been deleted.

**Parent topic:**[Create and Register a Custom UAI Image](Create_and_Register_a_Custom_UAI_Image.md)

