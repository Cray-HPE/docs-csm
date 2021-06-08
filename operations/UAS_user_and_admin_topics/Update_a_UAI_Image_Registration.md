---
category: numbered
---

# Update a UAI Image Registration

Modify the UAS registration information of a UAI image.

Verify that the image to be updated is registered with UAS. Refer to [Retrieve UAI Image Registration Information](Retrieve_UAI_Image_Registration_Information.md).

-   **ROLE**

    System administrator

-   **OBJECTIVE**

    Modify the registration of a UAI image.


-   **LIMITATIONS**

    None.


Once an allowable UAI image has been created, it may be necessary to change its attributes. For example, the default image may need to change.

1.  Modify the registration information of a UAI image by using a command of the form:

    ```screen
    ncn-m001-pit# cray uas admin config images update OPTIONS IMAGE\_ID
    ```

    Replace OPTIONS and IMAGE\_ID with a list of options and the UAI image ID, respectively. Use the --default or --imagename options the same way as when the image was initially registered to update those specific elements of an existing image registration. For example, to make the image with the ID of 8fdf5d4a-c190-24c1-2b96-74ab98c7ec07 the default image, run:

    ```screen
    ncn-m001-pit# cray uas admin config images update --default yes 8fdf5d4a-c190-24c1-2b96-74ab98c7ec07
    ```


