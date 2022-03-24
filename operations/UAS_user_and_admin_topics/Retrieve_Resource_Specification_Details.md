# Retrieve Resource Specification Details

Display a specific resource specification using the `resource_id` of that specification.

### Prerequisites

Install and initialize the `cray` administrative CLI.

### Procedure

1.  Print out a resource specification.

    To examine a particular resource specification, use a command of the following form:

    ```bash
    ncn-m001-pit# cray uas admin config resources describe RESOURCE_ID
    ```

    For example:

    ```bash
    ncn-m001-pit# cray uas admin config resources describe 85645ff3-1ce0-4f49-9c23-05b8a2d31849
    comment = "my first example resource specification"
    limit = "{"cpu": "300m", "memory": "250Mi"}"
    request = "{"cpu": "300m", "memory": "250Mi"}"
    resource_id = "85645ff3-1ce0-4f49-9c23-05b8a2d31849"
    ```

