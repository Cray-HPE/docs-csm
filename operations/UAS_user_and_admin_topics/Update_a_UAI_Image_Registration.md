# Update a UAI Image Registration

Modify the UAS registration information of a UAI image.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the Image ID of the UAI Image Registration to be updated: [List UAI Registered Images](List_Registered_UAI_Images.md)

## Procedure

Once a UAI image has been registered, it may be necessary to change its attributes. For example, the default image may need to change.

Modify the registration information of a UAI image by using a command of the form:

```bash
ncn-m001-pit# cray uas admin config images update OPTIONS IMAGE_ID
```

Use the `--default` or `--imagename` options as specified when registering an image to update those specific elements of an existing image registration.
For example, to make the `registry.local/cray/custom-end-user-uai:latest` image shown in other procedures the default image, use the following command:

```bash
ncn-m001-pit# cray uas admin config images update --default yes 8fdf5d4a-c190-24c1-2b96-74ab98c7ec07
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Delete a UAI Image Registration](Delete_a_UAI_Image_Registration.md)
