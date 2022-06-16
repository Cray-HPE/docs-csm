# Delete a UAI Resource Specification

Delete a specific UAI resource specification using the `resource_id` of that specification. Once deleted, UAIs will no longer be able to use that specification for creation. Existing UAIs are not affected by the change.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the Resource ID of the resource specification to be deleted: [List Resource Specifications](List_UAI_Resource_Specifications.md)

## Procedure

To delete a particular resource specification, use a command of the following form:

```bash
ncn-m001-pit# cray uas admin config resources delete RESOURCE_ID
```

Remove a UAI resource specification from UAS.

```bash
ncn-m001-pit# cray uas admin config resources delete 7c78f5cf-ccf3-4d69-ae0b-a75648e5cddb
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: UAI Classes](UAI_Classes.md)
