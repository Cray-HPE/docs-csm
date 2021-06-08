---
category: numbered
---

# Delete a UAI Using an Administrative Command

Administrators can delete one or more UAIs with a single command.

Install and initialize the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Manually delete one or more UAIs.

-   **LIMITATIONS**

    None.


1.  Delete one or more UAIs using a command of the following form:

    ```screen
    ncn-m001-pit# cray uas admin uais delete OPTIONS
    ```

    where OPTIONS is one or more of the following:

    -   --owner USERNAME: delete all UAIs owned by the named user.
    -   --class-id CLASS\_ID: delete all UAIs of the specified UAI class.
    -   --uai-list LIST\_OF\_UAI\_NAMES: delete all the listed UAIs
    The following example deletes two UAIs by name:

    ```screen
    ncn-m001-pit# cray uas admin uais delete --uai-list \\
    'uai-vers-715fa89d,uai-ctuser-0aed4970'
    results = [ "Successfully deleted uai-vers-715fa89d", "Successfully deleted uai-ctuser-0aed4970",]
    ```


