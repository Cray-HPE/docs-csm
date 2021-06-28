---
category: numbered
---

# Retrieve Resource Specification Details

Examine a particular resource specification.

Install and initialize the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Display a specific resource specification using the `resource_id` of that specification.

-   **LIMITATIONS**

    None


To examine a particular resource specification, use a command of the form:

```screen
ncn-m001-pit# cray uas admin config resources describe RESOURCE\_ID
```

1.  Print out a resource specification.

    ```screen
    ncn-m001-pit# cray uas admin config resources describe 85645ff3-1ce0-4f49-9c23-05b8a2d31849
    comment = "my first example resource specification"
    limit = "{\"cpu\": \"300m\", \"memory\": \"250Mi\"}"
    request = "{\"cpu\": \"300m\", \"memory\": \"250Mi\"}"
    resource_id = "85645ff3-1ce0-4f49-9c23-05b8a2d31849"
    ```


