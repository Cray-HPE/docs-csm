# Update a UAS Volume

Modify the configuration of an already-registered UAS volume. Almost any part of the configuration of a UAS volume can be modified.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know UAS volume ID of a volume; perform [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) if needed
* The administrator should be familiar with [Add a Volume to UAS](Add_a_Volume_to_UAS.md); the options and caveats for updating volumes are the same as for creating volumes

## Procedure

Modify the configuration of a UAS volume.

Once a UAS volume has been configured, any part of it except for the `volume_id` can be updated with a command of the following form:

```bash
cray uas admin config volumes update [options] <volume-id>
```

For example:

```bash
ncn-m001-pit# cray uas admin config volumes update --volumename 'my-example-volume' a0066f48-9867-4155-9268-d001a4430f5c
```

The `--volumename`, `--volume-description`, and `--mount-path` options may be used in any combination to update the configuration of a given volume.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Delete a Volume Configuration](Delete_a_Volume_Configuration.md)
