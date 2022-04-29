# Delete a UAI Image Registration

Unregister a UAI image from UAS.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the name of the UAI Image Registration to be deleted: [List Registered UAI Images](List_Registered_UAI_Images.md)

## Procedure

Deleting a UAI image from UAS removes the UAI image registration from UAS. This procedure does not delete the actual UAI image artifact, nor does it affect UAIs currently created using the UAI Image.

Delete a UAS image registration by using a command of the following form:

```bash
ncn-m001-pit# cray uas admin config images delete IMAGE_ID
```

`IMAGE_ID` is the image ID of the UAI image registration being removed from UAS.

For example:

```bash
ncn-m001-pit# cray uas admin config images delete 8fdf5d4a-c190-24c1-2b96-74ab98c7ec07
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Volumes](Volumes.md)
