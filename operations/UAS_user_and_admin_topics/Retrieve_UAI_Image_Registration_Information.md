---
category: numbered
---

# Retrieve UAI Image Registration Information

Query UAS for the registration information for a single UAI image.

Obtain a valid UAS image ID.

-   **ROLE**

    System administrator


-   **OBJECTIVE**

    Use this procedure to obtain the default and imagename values for a UAI image that has been registered with UAS. This procedure can also be used to confirm that a specific image ID is still registered with UAS.

-   **LIMITATIONS**

    None.


This procedure returns the same information as [List Registered UAI Images](List_Registered_UAI_Images.md), but only for one image.

1.  Obtain the image ID for a UAI that has been registered with UAS.

2.  Query UAS for the registration details for a specific registered UAI.

    ```screen
    ncn-m001-pit# cray uas admin config images describe 8fdf5d4a-c190-24c1-2b96-74ab98c7ec07
    [[results]]
    default = false
    image_id = "8fdf5d4a-c190-24c1-2b96-74ab98c7ec07"
    imagename = "registry.local/cray/custom-end-user-uai:latest"
    ```


