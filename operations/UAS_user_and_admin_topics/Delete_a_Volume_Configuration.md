# Delete a Volume Configuration

Delete an existing volume configuration. This procedure does not delete the underlying object referred to by the UAS volume configuration.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the Volume ID of the UAS volume to be deleted: [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md)

## Procedure

Delete the target volume configuration.

To delete a UAS Volume, use a command of the following form:

```bash
ncn-m001-pit# cray uas admin config volumes delete <volume-id>
```

For example:

```bash
ncn-m001-pit# cray uas admin config volumes delete a0066f48-9867-4155-9268-d001a4430f5c
```

If wanted, perform [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) to confirm that the UAS volume has been deleted.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Resource Specifications](Resource_Specifications.md)
