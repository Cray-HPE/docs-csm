# Update a Resource Specification

Modify a specific UAI resource specification using the `resource_id` of that specification.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the Resource ID of the resource specification to be updated: [List UAI Resource Specifications](List_UAI_Resource_Specifications.md)

## Procedure

To modify a particular resource specification, use a command of the following form:

```bash
ncn-m001-pit# cray uas admin config resources update [OPTIONS] RESOURCE_ID
```

The `[OPTIONS]` used by this command are the same options used to create resource specifications.
See [Create a UAI Resource Specification](Create_a_UAI_Resource_Specification.md) and [Elements of a UAI](Elements_of_a_UAI.md) for a full description of those options.

Update a UAI resource specification.

The following example changes the CPU and memory limits on a UAI resource specification to 1 CPU and 1GiB, respectively.

```bash
ncn-m001-pit# cray uas admin config resources update \
--limit '{"cpu": "1", "memory": "1Gi"}' 85645ff3-1ce0-4f49-9c23-05b8a2d31849
```

The following example does the same for the CPU and memory requests:

```bash
ncn-m001-pit# cray uas admin config resources update \
--request '{"cpu": "1", "memory": "1Gi"}' 85645ff3-1ce0-4f49-9c23-05b8a2d31849
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Delete a UAI Resource Specification](Delete_a_UAI_Resource_Specification.md)
