# Delete a UAI

There are two procedures described here. The first shows how an administrator can manually
delete arbitrary UAIs or delete UAIs belonging to a given user or created using a given [UAI Class](UAI_Classes.md).
The second shows how an authorized user on can delete UAIs created in the [legacy UIA creation mode](Legacy_Mode_User-Driven_UAI_Management.md).

When a UAI is deleted, any running WLM sessions associated with the owner of the UAI are left intact and can be interacted with through future UAIs owned by the same user or from UANs.

## Prerequisites

For administrative procedures:

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know or be able to find:
  * the name(s) of the target UAI(s) or
  * the user name of the owner of the targeted UAI(s) or
  * the class-id of the targeted UAIs

For Legacy Mode user procedures:

* The user must be logged into a host that has user access to the HPE Cray EX System API Gateway
* The user must have an installed initialized `cray` CLI and network access to the API Gateway
* The user must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The user must be logged in as to the HPE Cray EX System CLI (`cray auth login` command)
* The user must know the name(s) of the target UAI(s)

## Procedures

### Delete UAIs as an administrator

To delete a list of UAIs as an administrator use a command of the following form:

```bash
ncn-m001-pit# cray uas admin uais delete --uai-list UAI-NAMES
```

`UAI-NAMES` is a comma-separated list of UAI Names of targeted UAIs.

To deleted all UAIs owned by a given user, use a command of the form:

```bash
ncn-m001-pit# cray uas admin uais delete --owner USERNAME
```

`USERNAME` is the user name of the owner of the targeted UAIs.

To delete all UAIs of a given class, use a command of the form:

```bash
ncn-m001-pit# cray uas admin uais delete --class-id CLASS-ID
```

`CLASS-ID` is the class ID of the class used to create the targeted UAIs.

Here are some examples:

* Delete a list of UAIs by name:

  ```bash
  ncn-m001-pit# cray uas admin uais delete --uai-list uai-vers-5f46dffb,uai-vers-e530f53a
  results = [ "Successfully deleted uai-vers-5f46dffb", "Successfully deleted uai-vers-e530f53a",]
  ```

* Delete all UAIs belonging to a named user (user name here is `vers`):

  ```bash
  ncn-m001-pit# cray uas admin uais delete --owner vers
  results = [ "Successfully deleted uai-vers-5ef890be", "Successfully deleted uai-vers-da65468d",]
  ```

* Delete all UAIs belonging to a given UAI Class:

  ```bash
  ncn-m001-pit# cray uas admin uais delete --class-id a630cbda-24b4-47eb-a1f7-be1c25965ead
  results = [ "Successfully deleted uai-vers-5ef890be", "Successfully deleted uai-vers-da65468d",]
  ```

### Delete UAIs as an Authorized User in Legacy Mode

An authorized user in Legacy Mode can delete any UAI created by that user using a command of the form:

```bash
vers> cray uas delete --uai-list UAI-NAMES
```

To get a list of UAIs the user can delete:

```bash
vers> cray uas list
```

For example:

```bash
vers> cray uas list
[[results]]
uai_age = "0m"
uai_connect_string = "ssh vers@104.155.164.238"
uai_host = "ncn-w003"
uai_img = "registry.local/cray/cray-uai-sles15sp2:1.2.4"
uai_ip = "104.155.164.238"
uai_msg = ""
uai_name = "uai-vers-be3e219c"
uai_status = "Running: Ready"
username = "vers"

[[results]]
uai_age = "1m"
uai_connect_string = "ssh vers@34.70.243.171"
uai_host = "ncn-w001"
uai_img = "registry.local/cray/cray-uai-sles15sp2:1.2.4"
uai_ip = "34.70.243.171"
uai_msg = ""
uai_name = "uai-vers-ea57eb7b"
uai_status = "Running: Ready"
username = "vers"
```

To delete the UAI:

```bash
vers> cray uas delete --uai-list uai-vers-be3e219c,uai-vers-ea57eb7b
```

Output similar to the following is expected:

```bash
results = [ "Successfully deleted uai-vers-be3e219c", "Successfully deleted uai-vers-ea57eb7b",]
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Common UAI Configurations](Common_UAI_Config.md)
