# Build a New UAN Image Using the Default Recipe

Build or rebuild the User Access Node (UAN) image using either the default UAN image or image recipe. Both of these are supplied by the UAN
product stream installer.

* [Prerequisites](#prerequisites)
* [Overview](#overview)
* [Remove Slingshot Diagnostics RPM From Default UAN Recipe](#remove_slingshot_diags_from_uan_recipe)
* [Build the UAN Image Automatically Using IMS](#build_uan_image_automatically)
* [Build the UAN Image By Customizing It Manually](#build_uan_image_manually)

<a name="prerequisites"></a>

## Prerequisites

* Both the Cray Operation System (COS) and UAN product streams must be installed.
* The Cray administrative CLI must be initialized.

<a name="overview"></a>

## Overview

The Cray EX User Access Node \(UAN\) recipe currently requires the Slingshot Diagnostics package, which is not installed with the UAN product
itself. Therefore, the UAN recipe can only be built after either the Slingshot product is installed, or the Slingshot Diagnostics package is
removed from the recipe.

First, determine if the Slingshot product stream is installed on the HPE Cray EX system. The Slingshot Diagnostics RPM must be removed from
the default recipe if the Slingshot product is not installed.

<a name="remove_slingshot_diags_from_uan_recipe"></a>

## Remove Slingshot Diagnostics RPM From Default UAN Recipe

This procedure does not need to be followed if the Slingshot package is installed.

1. Perform [Upload and Register an Image Recipe](Upload_and_Register_an_Image_Recipe.md) procedure to download and extract the UAN image
   recipe, `cray-sles15sp1-uan-cos`, but stop before the step that modifies the recipe.

1. Edit the file `config-template.xml.j2` within the recipe by removing these lines:

    ```Jinja2
     <!-- SECTION: Slingshot Diagnostic package -->
         <package name="cray-diags-fabric"/>
    ```

1. Resume the [Upload and Register an Image Recipe](Upload_and_Register_an_Image_Recipe.md) procedure, starting with the step that locates
   the directory that contains the Kiwi-NG image description files.

   The next step requires the `id` of the new image recipe record.

1. Perform the [Build an Image Using IMS REST Service](Build_an_Image_Using_IMS_REST_Service.md) procedure in order to build the UAN image
   from the modified recipe. Use the `id` of the new image recipe.

<a name="build_uan_image_automatically"></a>

## Build the UAN Image Automatically Using IMS

This procedure does not need to be followed if choosing to build the UAN image manually.

1. Identify the UAN image recipe.

    ```bash
    ncn# cray ims recipes list --format json | jq '.[] | select(.name | contains("uan"))'
    ```

    Example output:

    ```json
    {
      "created": "2021-02-17T15:19:48.549383+00:00",
      "id": "4a5d1178-80ad-4151-af1b-bbe1480958d1",
      "link": {
        "etag": "3c3b292364f7739da966c9cdae096964",
        "path": "s3://ims/recipes/4a5d1178-80ad-4151-af1b-bbe1480958d1/recipe.tar.gz",
        "type": "s3"
      },
      "linux_distribution": "sles15",
      "name": "cray-shasta-uan-cos-sles15sp1.x86_64-@product_version@",
      "recipe_type": "kiwi-ng"
    }
    ```

1. Save the ID of the IMS recipe in an environment variable.

    ```bash
    ncn# IMS_RECIPE_ID=4a5d1178-80ad-4151-af1b-bbe1480958d1
    ```

1. Using the saved IMS recipe ID, follow the [Build an Image Using IMS REST Service](Build_an_Image_Using_IMS_REST_Service.md) procedure to
   build the UAN image.

<a name="build_uan_image_manually"></a>

## Build the UAN Image By Customizing It Manually

This procedure does not need to be followed if the previous procedure was used to build the UAN image automatically.

1. Identify the base UAN image to customize.

    ```bash
    ncn# cray ims images list --format json | jq '.[] | select(.name | contains("uan"))'
    ```

    Example output:

    ```json
    {
      "created": "2021-02-18T17:17:44.168655+00:00",
      "id": "6d46d601-c41f-444d-8b49-c9a2a55d3c21",
      "link": {
        "etag": "371b62c9f0263e4c8c70c8602ccd5158",
        "path": "s3://boot-images/6d46d601-c41f-444d-8b49-c9a2a55d3c21/manifest.json",
        "type": "s3"
      },
      "name": "uan-PRODUCT_VERSION-image"
    }
    ```

1. Save the ID of the IMS image in an environment variable.

    ```bash
    ncn# IMS_IMAGE_ID=4a5d1178-80ad-4151-af1b-bbe1480958d1
    ```

1. Using the saved IMS image ID, follow the [Customize an Image Root Using IMS](Customize_an_Image_Root_Using_IMS.md) procedure to build
   the UAN image.
