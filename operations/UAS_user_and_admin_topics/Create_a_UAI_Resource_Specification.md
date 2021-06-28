---
category: numbered
---

# Create a UAI Resource Specification

Create a specification within UAS to control resources available to UAIs. Such resources include CPU, memory, storage, and external data.

Install and initialize the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Add a resource specification to UAS. Once added, a resource specification can be used to limit UAI resource consumption on host nodes and enable UAIs to access external data.

-   **LIMITATIONS**

    None


Add a resource specification using a command of the form:

```screen
ncn-m001-pit# cray uas admin config resources create --limit K8S-RESOURCE-LIMIT \\
--request K8S-RESOURCE-REQUEST --comment COMMENT-STRING
```

See [Elements of a UAI](Elements_of_a_UAI.md) for an explanation of UAI resource specifications.

1.  Create a new UAI resource specification:

    The following example command specifies a request and limit pair that are both 0.3 CPUs and 250 MiB of memory \(250 x 250 x 1,024 bytes\) for any UAI created with this limit specification.

    All of the configurable parts are optional when adding a resource specification. If none are provided, an empty resource specification with only a resource\_id will be created.

    ```screen
    ncn-m001-pit# cray uas admin config resources create --request \\
    '\{"cpu": "300m", "memory": "250Mi"\}' --limit \\
    '\{"cpu": "300m", "memory": "250Mi"\}' --comment "my first example resource specification"
    ```

    Identical request and limits prevent host nodes from being oversubscribed by UAIs. The request can be less than the limit, but such a specification is not recommended in most cases because that risks oversubscribing the UAI host nodes. If the request is greater than the limit, UAIs created with the request specification will never be scheduled. This is because UAS will not be able to provide the requested resources.


