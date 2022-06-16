# Modify a UAI Class

Update a UAI class with a modified configuration.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the Class ID of the UAI Class to be modified: [List UAI Classes](List_Available_UAI_Classes.md)

## Limitations

The ID of the UAI class cannot be modified.

## Procedure

To update an existing UAI class, use a command of the following form:

```bash
cray uas admin config classes update OPTIONS UAI_CLASS_ID
```

`OPTIONS` are the same options supported for UAI class creation. They can be seen by using the command.
`UAI_CLASS_ID` is the Class ID of the UAI class to be modified.

```bash
cray uas admin config classes update --help
```

1. Modify a UAI class.

   The following example changes the comment on the UAI class with an ID of `bb28a35a-6cbc-4c30-84b0-6050314af76b`.

   ```bash
   ncn-m001-pit#cray uas admin config classes update \
                --replicas 3 \
                bdb4988b-c061-48fa-a005-34f8571b88b4
   ```

   Any change made using this command affects only UAIs that are both created using the modified class and are created after the modification. Existing UAIs using the class will not change.

2. **Optional:** Update currently running UAIs by deleting and recreating them, or deleting them and allowing them to be re-created through a Broker UAI. See [Delete a UAI](Delete_a_UAI.md) for more details.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Delete a UAI Class](Delete_a_UAI_Class.md)
