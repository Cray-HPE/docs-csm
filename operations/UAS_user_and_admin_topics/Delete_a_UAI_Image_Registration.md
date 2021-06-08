---
category: numbered
---

# Delete a UAI Image Registration

De-register a UAI image from UAS by deleting the registration.

Verify that the UAI image to be deleted is registered with UAS. See [Retrieve UAI Image Registration Information](Retrieve_UAI_Image_Registration_Information.md) for instructions.

-   **ROLE**

    System administrator


-   **OBJECTIVE**

    Unregister a UAI image from UAS.

-   **LIMITATIONS**

    None.


Deleting a UAI image from UAS effectively unregisters the UAI image from UAS. This procedure does delete the actual UAI image artifact.

1.  Delete a UAS image registration by using a command of the following form:

    ```screen
    ncn-m001-pit# cray uas admin config images delete IMAGE\_ID 
    ```

    Replace IMAGE\_ID with image ID of the UAI image to unregister from UAS.


