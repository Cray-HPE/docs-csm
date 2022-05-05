# List Registered UAI Images

Administrators can use the `cray uas admin config images list` command to see the list of registered images. This command also displays the UAS registration information about each image.

While Registering a UAI image name with UAS is necessary for UAIs to use the image, simply registering the image is not sufficient.
The registered image must also be created and stored appropriately in its container registry.
The basic HPE supplied UAI image is both installed and registered at UAS installation or upgrade time by the `update-uas` Kubernetes job when the `update-uas` Helm chart is deployed, upgraded or downgraded.
Custom images are created, installed and registered as part of the [Customize End-User UAI Images](Customize_End-User_UAI_Images.md) procedure.

This procedure describes how to list the currently registered UAI images.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)

## Procedure

Obtain the list of UAI images that are currently registered with UAS.

```bash
ncn-m001-pit# cray uas admin config images list
```

Example output:

```bash
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

The output shown above shows three image registrations. Each has an `imagename` indicating the name of the image from the image registry to be used to construct a UAI.

**NOTE:** Simply registering a UAI image name does not make the image available. The image must also be created and stored in the container registry. See [Customize End-User UAI Images](Customize_End-User_UAI_Images.md).

There is also a `default` flag. If this flag is `true`, the image will be used, in the absence of [a default UAI Class](UAI_Classes.md), whenever a UAI is created without specifying an image or UAI Class as part of the creation.
Finally, there is an `image_id`, which identifies this image registration for later inspection, update, or deletion and for linking the image to a UAI Class.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Register a UAI Image](Register_a_UAI_Image.md)
