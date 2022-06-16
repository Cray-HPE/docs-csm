# List UAI Resource Specifications

Obtain a list of all the UAI resource specifications registered with UAS.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)

## Procedure

List all the resource specifications registered in UAS.

The resource specifications returned by the following command are available for UAIs to use:

```bash
ncn-m001-pit# cray uas admin config resources list
```

Example output:

```bash
[[results]]
comment = "Resource Specification to use with Brokered End-User UAIs"
limit = "{\"cpu\": \"300m\", \"memory\": \"1Gi\"}"
request = "{\"cpu\": \"300m\", \"memory\": \"1Gi\"}"
resource_id = "f26ee12c-6215-4ad1-a15e-efe4232f45e6"
```

The following are the configurable parts of a resource specification:

* `limit` - A JSON string describing a Kubernetes resource limit
* `request` - A JSON string describing a Kubernetes resource request
* `comment` - An optional free form string containing any information an administrator might find useful about the resource specification
* `resource-id` - Used for examining, updating or deleting the resource specification as well as linking the resource specification into a UAI class

Refer to [Elements of a UAI](Elements_of_a_UAI.md) for more information.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Create a UAI Resource Specification](Create_a_UAI_Resource_Specification.md)
