# Retrieve Resource Specification Details

Display a specific resource specification using the `resource_id` of that specification.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the Resource ID of the resource specification to be retrieved: [List Resource Specifications](List_UAI_Resource_Specifications.md)

## Procedure

Retrieve a resource specification.

To examine a particular resource specification, use a command of the following form:

```bash
ncn-m001-pit# cray uas admin config resources describe RESOURCE_ID
```

For example:

```bash
ncn-m001-pit# cray uas admin config resources describe f26ee12c-6215-4ad1-a15e-efe4232f45e6
comment = "Resource Specification to use with Brokered End-User UAIs"
limit = "{\"cpu\": \"300m\", \"memory\": \"1Gi\"}"
request = "{\"cpu\": \"300m\", \"memory\": \"1Gi\"}"
resource_id = "f26ee12c-6215-4ad1-a15e-efe4232f45e6"
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Update a Resource Specification](Update_a_Resource_Specification.md)
