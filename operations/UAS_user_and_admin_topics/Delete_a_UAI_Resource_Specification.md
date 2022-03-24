# Delete a UAI Resource Specification

Delete a specific UAI resource specification using the `resource_id` of that specification. Once deleted, UAIs will no longer be able to use that specification.

### Prerequisites

Install and initialize the `cray` administrative CLI.

### Prerequisites

To delete a particular resource specification, use a command of the following form:

```bash
ncn-m001-pit# cray uas admin config resources delete RESOURCE_ID
```

1.  Remove a UAI resource specification from UAS.

    ```bash
    ncn-m001-pit# cray uas admin config resources delete 7c78f5cf-ccf3-4d69-ae0b-a75648e5cddb
    ```

