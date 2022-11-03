# Register a UAI Image

Register a UAI image with UAS. Registration tells UAS where to locate the image and whether to use the image as the default for UAIs.

### Prerequisites

-   Initialize `cray` administrative CLI.
-   Create a UAI image and upload it to the container registry. See [Customize End-User UAI Images](Customize_End-User_UAI_Images.md).

### Procedure

1. Register a UAI image with UAS.

    The following is the minimum required CLI command form:

    ```
    ncn-m001-pit# cray uas admin config images create --imagename <image_name>
    ```

    To register the image `registry.local/cray/custom-end-user-uai:latest`, the stock end-user UAI image, use:

    ```
    ncn-m001-pit# cray uas admin config images create --imagename registry.local/cray/custom-end-user-uai:latest
    ```

    The following example registers the stock UAI image registry.local/cray/custom-end-user-uai:latest. This example also implicitly sets the default attribute to `false` because the `--default` option is omitted in the command.

    ```
    ncn-m001-pit# cray uas admin config images create --imagename registry.local/cray/custom-end-user-uai:latest --default yes
    ```

    To register the image explicitly as non-default:

    ```
    ncn-m001-pit# cray uas admin config images create --imagename registry.local/cray/custom-end-user-uai:latest --default no
    ```

    Registering an image with the `--default no` option is usually unnecessary. Omitting the `--default` option causes UAS to set the default attribute as `false` internally.

