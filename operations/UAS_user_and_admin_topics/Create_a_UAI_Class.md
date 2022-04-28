[Top: User Access Service (UAS)](index.md)

[Next Topic: View a UAI Class](View_a_UAI_Class.md)

## Create a UAI Class

Add a new User Access Instance (UAI) class to the User Access Service (UAS) so that the class can be used to configure UAIs.

### Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)

### Procedure

Add a UAI class by using the command in the following example.

```
ncn-m001-pit# cray uas admin config classes create --image-id <image-id> [options]
```

The only required option is `--image-id IMAGE_ID` which sets the container image that will be used to create a UAI from this UAI Class.

Other options and arguments can be discovered using the:

```
ncn-m001-pit# cray uas admin config classes create --help
```

command. See [UAI Classes](UAI_Classes.md) for more information on what the settings in a UAI Class mean and how to use them.

[Next Topic: View a UAI Class](View_a_UAI_Class.md)
