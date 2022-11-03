# Create a UAI Resource Specification

Add a resource specification to UAS. Once added, a resource specification can be used to request or limit specific resource consumption on a host node or gain access to host node features managed by Kubernetes resources.
The examples in this documentation focus on memory and CPU usage, but Kubernetes does use resources in some configurations to manage access to other kinds of resources.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)

## Procedure

Add a resource specification.

Use a command of the following form:

```bash
ncn# cray uas admin config resources create [--limit <k8s-resource-limit>] [--request <k8s-resource-request>] [--comment '<string>']
```

For example:

```bash
ncn# cray uas admin config resources create --request '{"cpu": "300m", "memory": "1Gi"}' \
            --limit '{"cpu": "300m", "memory": "1Gi"}' \
            --comment "Resource Specification to use with Brokered End-User UAIs"
```

See [Elements of a UAI](Elements_of_a_UAI.md) for an explanation of UAI resource specifications.

The example above specifies a request / limit pair that requests and is constrained to 300 milli-CPUs (0.3 CPUs) and 1 GiB of memory (`1 * 1024 * 1024 * 1024` bytes) for any UAI created with this limit specification.
By keeping the request and the limit the same, this ensures that a host node will not be oversubscribed by UAIs. It is also legitimate to request less than the limit, though that risks over-subscription and is not recommended in most cases.
If the request is greater than the limit, UAIs created with the request specification will never be scheduled because their pods will not be able to provide the requested resources.

All of the configurable parts are optional when adding a resource specification. If none are provided, an empty resource specification with only a `resource_id` will be created.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Retrieve Resource Specification Details](Retrieve_Resource_Specification_Details.md)
