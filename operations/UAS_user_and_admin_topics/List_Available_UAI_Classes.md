# List Available UAI Classes

View all the details of every available UAI class. Use this information to select a class to apply to one or more UAIs.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)

## Procedure

List all available UAI classes.

To list available UAI classes, use the following command:

```bash
ncn-m001-pit# cray uas admin config classes list
```

The `cray uas admin config classes list` command supports the same `--format` options as the `cray uas admin config volumes list` command. See [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) for details.

For example:

```bash
ncn-m001-pit# cray uas admin config classes list --format json
<output not shown>
```

See [UAI Classes](UAI_Classes.md) and [Elements of a UAI](Elements_of_a_UAI.md) for more details on the output.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Create a UAI Class](Create_a_UAI_Class.md)
