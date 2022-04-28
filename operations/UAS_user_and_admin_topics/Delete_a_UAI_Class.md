# Delete a UAI Class

Delete a UAI class. After deletion, the class will no longer be available for creation of UAIs. Existing UAIs are unaffected.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the Class ID of the UAI Class to be deleted: [List UAI Classes](List_Available_UAI_Classes.md)

## Procedure

Delete a UAI Class by using a command of the following form:

```bash
cray uas admin config classes delete UAI_CLASS_ID
```

`UAI_CLASS_ID` is the UAI Class ID of the UAI class.

Delete a UAI class.

```screen
ncn-m001-pit# cray uas admin config classes delete bb28a35a-6cbc-4c30-84b0-6050314af76b
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: UAI Management](UAI_Management.md)
