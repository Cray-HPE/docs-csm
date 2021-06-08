---
category: numbered
---

# Register a UAI Image

Register a UAI image with UAS. Registration tells UAS where to locate the image and whether to use the image as the default for UAIs.

-   Initialize cray administrative CLI.
-   Create a UAI image and upload it to the container registry. See [Create and Register a Custom UAI Image](Create_and_Register_a_Custom_UAI_Image.md).

-   **ROLE**

    System administrator

-   **OBJECTIVE**

    Registration enables UAS to use a UAI image for UAIs.

-   **LIMITATIONS**

    None.


1.  Register a UAI image.

    The following example registers the stock UAI image registry.local/cray/custom-end-user-uai:latest. This example also implicitly sets the default attribute to `false` since the --default option is omitted in the command.

    ```screen
    ncn-m001-pit# cray uas admin config images create --imagename registry.local/cray/custom-end-user-uai:latest
    ```

    UAS allows the image to be set as the default image during registration. There can be at most one default image defined at any given time. Setting an image as the default causes any previous default image to cease to be default. The following command registers the same example image as the default image:

    ```screen
    ncn-m001-pit# cray uas admin config images create --imagename registry.local/cray/custom-end-user-uai:latest \\
    --default yes
    ```

    Registering an image with the --default no option is usually unnecessary. Omitting the --default option causes UAS to set the default attribute as `false` internally.


