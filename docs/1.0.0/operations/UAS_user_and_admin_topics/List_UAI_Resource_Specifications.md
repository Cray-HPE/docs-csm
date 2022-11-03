# List UAI Resource Specifications

Obtain a list of all the UAI resource specifications registered with UAS.

### Prerequisites

The `cray` administrative CLI must be installed and initialized.

### Procedure

1.  List all the resource specifications registered in UAS.

    The resource specifications returned by the following command are available for UAIs to use:

    ```
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

    The following are the configurable parts of a resource specification:
    * `limit` - A JSON string describing a Kubernetes resource limit
    * `request` - A JSON string describing a Kubernetes resource request
    * `comment` - An optional free form string containing any information an administrator might find useful about the resource specification
    * `resource-id` - Used for examining, updating or deleting the resource specification as well as linking the resource specification into a UAI class

    Refer to [Elements of a UAI](Elements_of_a_UAI.md) for more information.

