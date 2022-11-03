# Update a Resource Specification

Modify a specific UAI resource specification using the `resource_id` of that specification.

### Prerequisites

-   Install and initialize the `cray` administrative CLI.
-   Verify that the resource specification to be updated exists within UAS. Perform either[List UAI Resource Specifications](List_UAI_Resource_Specifications.md) or [Retrieve Resource Specification Details](Retrieve_Resource_Specification_Details.md).

### Procedure

To modify a particular resource specification, use a command of the following form:

```bash
ncn-m001-pit# cray uas admin config resources update [OPTIONS] RESOURCE_ID
```

The \[OPTIONS\] used by this command are the same options used to create resource specifications. See [Create a UAI Resource Specification](Create_a_UAI_Resource_Specification.md) and [Elements of a UAI](Elements_of_a_UAI.md) for a full description of those options.

1.  Update a UAI resource specification.

    The following example changes the CPU and memory limits on a UAI resource specification to 0.1 CPU and 10MiB, respectively.

    ```bash
    ncn-m001-pit# cray uas admin config resources update \
    --limit '{"cpu": "100m", "memory": "10Mi"}' 85645ff3-1ce0-4f49-9c23-05b8a2d31849
    ```

