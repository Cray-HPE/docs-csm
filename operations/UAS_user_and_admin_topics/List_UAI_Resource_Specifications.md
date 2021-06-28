---
category: numbered
---

# List UAI Resource Specifications

List the resource specifications available for UAIs to use.

The cray administrative CLI must be installed and initialized.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Obtain a list of all the UAI resource specifications registered with UAS.

-   **NEW IN THIS RELEASE**

    This procedure is new in this release.


1.  List all the resource specifications registered in UAS.

    The resource specifications returned by the following command are available for UAIs to use. Refer to [Elements of a UAI](Elements_of_a_UAI.md) for an explanation of the comment, limit, request, and resource\_id values.

    ```screen
    ncn-m001-pit# cray uas admin config resources list
    [[results]]
    comment = "my first example resource specification"
    limit = "{\"cpu\": \"300m\", \"memory\": \"250Mi\"}"
    request = "{\"cpu\": \"300m\", \"memory\": \"250Mi\"}"
    resource_id = "85645ff3-1ce0-4f49-9c23-05b8a2d31849"
    
    [[results]]
    comment = "my second example resource specification"
    limit = "{\"cpu\": \"4\", \"memory\": \"1Gi\"}"
    request = "{\"cpu\": \"4\", \"memory\": \"1Gi\"}"
    resource_id = "eff9e1f2-3560-4ece-a9ce-8093e05e032d"
    ```


