# Retrieve UAI Image Registration Information

Use this procedure to obtain the `default` and `imagename` values for a registered UAI image. This procedure can also be used to confirm that a specific image ID is still registered with UAS.

This procedure returns the same information as [List Registered UAI Images](List_Registered_UAI_Images.md), but only for one image.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the Image ID of the UAI Image Registration to be retrieved: [List UAI Images](List_Registered_UAI_Images.md)

## Procedure

1. Obtain the image ID for a UAI that has been registered with UAS.

2. Query UAS for the registration details for a specific registered UAI.

    ```bash
    ncn-m001-pit# cray uas admin config images describe 8fdf5d4a-c190-24c1-2b96-74ab98c7ec07
    ```

    Example output:

    ```bash
    [[results]]
    default = false
    image_id = "8fdf5d4a-c190-24c1-2b96-74ab98c7ec07"
    imagename = "registry.local/cray/custom-end-user-uai:latest"
    ```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Update a UAI Image Registration](Update_a_UAI_Image_Registration.md)
