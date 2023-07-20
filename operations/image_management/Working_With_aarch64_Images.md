# Working With aarch64 Images

Systems may have aarch64 (arm64) compute nodes present, but the Kubernetes nodes are always going to be running
x86 hardware. This presents a challenge in creating and modifying compute images through IMS running on the
Kubernetes cluster. To solve this, aarch64 hardware is emulated using Kata VM's and QEMU emulation software.

## Kata and QEMU Emulation

### QEMU

QEMU is a generic open source emulator. We use qemu-user-static as a translator that is inserted via binfmt_misc
into the kernel as a translator. The aarch64 binaries are then recognized by the kernel and the correct emulation
applied to run them on the x86 hardware.

More information can be found on the technologies here:
[QEMU Documentation](https://www.qemu.org/docs/master/about/index.html)
[qemu-user-static](https://github.com/multiarch/qemu-user-static)

### Kata

Due to the level of kernel interaction required by QEMU and the fact that most recipe builds and image
customization jobs are running as the 'root' user, this would open a fairly significant security hole
if these Kubernetes pods were running directly on the worker nodes like normal pods.

In order to keep the system secure, the emulation pods are being run inside Kata VM's with a different
running kernel than the worker node so it isn't possible through a kernel bug to get access to the
running worker kernel. Each IMS job pod is run inside its own Kata VM so there is no possibility of
breaking out from one job into another.

More information on Kata can be found here:
[Kata](https://katacontainers.io/)

### Performance

Due to the emulation and needing to run inside of a VM, the performance of the aarch64 image building and
customization is quite a bit slower than the same operation being done for x86 images running on native
hardware. We typically see around a 10 times slowdown in this configuration. This is unfortunate, but
unavoidable given the need to work on the existing x86 management nodes.

## Specifying Architecture for Recipes and Images

For the most part, the architecture is handled automatically once a recipe is labeled with having an
architecture of aarch64. If the recipe is being installed via a package, the architecture may be set
in the manifest file. If the recipe is being installed manually, there is an option using the `cray` CLI
to set or modify the architecture.

The architecture flag in the recipe or image will be used to set up the correct environment for the IMS
job - either emulation or running on the native hardware. Once they are tagged, no further user input
is required for the IMS jobs to run correctly.

When a recipe is built into an image, the resulting image is automatically set with the correct architecture
picked up from the recipe. When an image is customized, the resulting image will have the same
architecture as the original base image used for the customization. No manual changes are required in
these workflows.

### Importing a Recipe

1. (`ncn-mw#`) Create the new recipe record

    When a new recipe is imported or created in IMS there is an architecture flag that will set that information
    into the recipe record.

    ```bash
        cray ims recipes create --name "My Recipe" \
            --recipe-type kiwi-ng --linux-distribution sles15 \
            --arch = "aarch64" --reqire-dkms False
    ```

    Expected output will look something like:

    ```toml
    created = "2022-12-04T17:25:52.482514+00:00"
    id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
    linux_distribution = "sles15"
    name = "My Recipe"
    recipe_type = "kiwi-ng"
    arch = "aarch64"
    require_dkms = false
    ```

### Updating an Existing Recipe

If a recipe record is created with the incorrect architecture, that field can be updated.

1. (`ncn-mw#`) Look at the existing recipe record

    ```bash
    cray ims recipes describe $IMS_RECIPE_ID
    ```

    Expected output will look something like this:

    ```toml
    arch = "x86_64"
    created = "2023-06-26T19:18:50.618917+00:00"
    id = "da4121c2-2681-40f9-8007-4dcccf379e24"
    linux_distribution = "sles15"
    name = "cos-2.6.71-20230622190918-sles15sp5.aarch64"
    recipe_type = "kiwi-ng"
    require_dkms = false
    [[template_dictionary]]
    key = "COS_PRODUCT_VERSION"
    value = "2.6.71-20230622190918"

    [[template_dictionary]]
    key = "SHS_VERSION"
    value = "master"

    [link]
    etag = "38dcc9d03b8bf1fcd1bb4fd660607bc0"
    path = "s3://ims/recipes/da4121c2-2681-40f9-8007-4dcccf379e24/recipe.tar.gz"
    type = "s3"
    ```

1. (`ncn-mw#`) If the architecture is wrong, update it

    ```bash
    cray ims recipes update --arch aarch64 $IMS_RECIPE_ID
    ```

    Expected output will look something like:

    ```toml
    arch = "aarch64"
    created = "2023-06-26T19:18:50.618917+00:00"
    id = "da4121c2-2681-40f9-8007-4dcccf379e24"
    linux_distribution = "sles15"
    name = "cos-2.6.71-20230622190918-sles15sp5.aarch64"
    recipe_type = "kiwi-ng"
    require_dkms = false
    [[template_dictionary]]
    key = "COS_PRODUCT_VERSION"
    value = "2.6.71-20230622190918"

    [[template_dictionary]]
    key = "SHS_VERSION"
    value = "master"

    [link]
    etag = "38dcc9d03b8bf1fcd1bb4fd660607bc0"
    path = "s3://ims/recipes/da4121c2-2681-40f9-8007-4dcccf379e24/recipe.tar.gz"
    type = "s3"
    ```

### Importing an Image

1. (`ncn-mw#`) Create the new image record.

    When a new image is imported or created in IMS there is an architecture flag that will set that information
    into the image record.

    ```bash
    cray ims images create --name "My New Image" --arch aarch64
    ```

    Example output:

    ```toml
    id = "0a6459dc-aa54-432c-9013-3963a4d0f578"
    arch = "aarch64"
    created = "2023-06-28T21:46:50.181687+00:00"
    name = "My New Image"
    ```

### Updating an Existing Image

If an image is uploaded into IMS with the incorrect architecture specified, that field can be updated.

1. (`ncn-mw#`) Look at the image record:

    ```bash
    cray ims images describe $MY_IMS_IMAGE_ID
    ```

    Expected output:

    ```json
    {
        "arch": "x86_64",
        "created": "2023-06-27T01:59:26.116060+00:00",
        "id": "5c0a8f43-462c-414d-924a-b73ae404f4e0",
        "link": {
            "etag": "90e02dc3c17a8a0d8f1b2e90f34d76ea",
            "path": "s3://boot-images/5c0a8f43-462c-414d-924a-b73ae404f4e0/manifest.json",
            "type": "s3"
        },
        "name": "sp4-aarch64-2.6.71-image"
    }
    ```

1. (`ncn-mw#`) If the architecture is incorrect, update it to the correct value

    ```bash
    cray ims images update --arch aarch64 $MY_IMS_IMAGE_ID
    ```

    Expected output:

    ```json
    {
        "arch": "aarch64",
        "created": "2023-06-27T01:59:26.116060+00:00",
        "id": "5c0a8f43-462c-414d-924a-b73ae404f4e0",
        "link": {
            "etag": "90e02dc3c17a8a0d8f1b2e90f34d76ea",
            "path": "s3://boot-images/5c0a8f43-462c-414d-924a-b73ae404f4e0/manifest.json",
            "type": "s3"
        },
        "name": "sp4-aarch64-2.6.71-image"
    }
    ```
