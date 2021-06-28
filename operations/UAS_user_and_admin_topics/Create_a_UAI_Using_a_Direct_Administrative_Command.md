---
category: numbered
---

# Create a UAI Using a Direct Administrative Command

Administrators can use this method to manually create UAIs. This method is intended more for creating broker UAIs than for creating end-user UAIs.

Install and initialize the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Manually create a UAI.

-   **LIMITATIONS**

    None.


This method is intended more for creating broker UAIs than for creating end-user UAIs. Administrators can, however, create end-user UAIs using this method.

1.  Create a UAI manually with a command of the form:

    ```screen
    ncn-m001-pit# cray uas admin uais create OPTIONS
    ```

    where OPTIONS is one or more of the following:

    -   --owner USERNAME: create the UAI as owned by the specified user
    -   --class-id CLASS\_ID: the class of the UAI to be created. This option must be specified unless a default UAI class exists, in which case, it can be omitted and the default will be used.
    -   --passwd str PASSWORD\_STRING: the /etc/password format string for the user who owns the UAI. This will be used to set up credentials within the UAI for the owner when the owner logs into the UAI.
    -   --publickey-str PUBLIC\_SSH\_KEY: the SSH public key that will be used to authenticate with the UAI. The key should be, for example, the contents of an id\_rsa.pub file used by SSH.

