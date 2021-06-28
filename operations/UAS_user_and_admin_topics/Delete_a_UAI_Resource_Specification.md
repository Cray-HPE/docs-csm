---
category: numbered
---

# Delete a UAI Resource Specification

Remove a UAI resource specification from UAS. UAIs will then no longer be able to use the specification.

Install and initialize the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Delete a specific UAI resource specification using the `resource_id` of that specification. Once deleted, UAIs will no longer be able to use that specification.

-   **LIMITATIONS**

    None.


To delete a particular resource specification, use a command of the form:

```screen
ncn-m001-pit# cray uas admin config resources delete RESOURCE\_ID
```

1.  Remove a UAI resource specification from UAS.

    ```screen
    ncn-m001-pit# cray uas admin config resources delete 7c78f5cf-ccf3-4d69-ae0b-a75648e5cddb
    ```


