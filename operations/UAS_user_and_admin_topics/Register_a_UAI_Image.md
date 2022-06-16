# Register a UAI Image

Register a UAI image with UAS. Registration tells UAS where to locate the image and whether to use the image as the default for UAIs.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The UAI image must be created and uploaded to the container registry: [Customize End-User UAI Images](Customize_End-User_UAI_Images.md)

## Procedure

Register a UAI image with UAS.

The following is the minimum required CLI command form:

```bash
ncn-m001-pit# cray uas admin config images create --imagename IMAGE_NAME
```

In this example, `IMAGE_NAME` is the full name of the image, including registry host and version tag, to be registered.

The following example registers a UAI image stored in the `registry.local` registry as `registry.local/cray/custom-end-user-uai:latest`.
This example also explicitly sets the default attribute to `true` because the `--default yes` option is used in the command.

```bash
ncn-m001-pit# cray uas admin config images create --imagename registry.local/cray/custom-end-user-uai:latest --default yes
```

To register the image explicitly as non-default:

```bash
ncn-m001-pit# cray uas admin config images create --imagename registry.local/cray/custom-end-user-uai:latest --default no
```

Registering an image with the `--default no` option is usually unnecessary. Omitting the `--default` option causes UAS to set the default attribute as `false`. So, the following command would be equivalent to the previous command:

```bash
ncn-m001-pit# cray uas admin config images create --imagename registry.local/cray/custom-end-user-uai:latest
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Retrieve UAI Image Registration Information](Retrieve_UAI_Image_Registration_Information.md)
