# Create a UAI Resource Specification

Add a resource specification to UAS. Once added, a resource specification can be used to limit UAI resource consumption on host nodes and enable UAIs to access external data.

### Prerequisites

Install and initialize the `cray` administrative CLI.

### Procedure

1. Add a resource specification.

    Use a command of the following form:

    ```
    ncn-m001-pit # cray uas admin config resources create [--limit <k8s-resource-limit>] [--request <k8s-resource-request>] [--comment '<string>']
    ```

    For example:

    ```
    ncn-m001-pit# cray uas admin config resources create --request '{"cpu": "300m", "memory": "250Mi"}' --limit '{"cpu": "300m", "memory": "250Mi"}' --comment "my first example resource specification"
    ```

    See [Elements of a UAI](Elements_of_a_UAI.md) for an explanation of UAI resource specifications.

    The example above specifies a request / limit pair that requests and is constrained to 300 milli-CPUs (0.3 CPUs) and 250 MiB of memory (`250 * 1024 * 1024` bytes) for any UAI created with this limit specification. By keeping the request and the limit the same, this ensures that a host node will not be oversubscribed by UAIs. It is also legitimate to request less than the limit, though that risks over-subscription and is not recommended in most cases. If the request is greater than the limit, UAIs created with the request specification will never be scheduled because they will not be able to provide the requested resources.

    All of the configurable parts are optional when adding a resource specification. If none are provided, an empty resource specification with only a `resource_id` will be created.

