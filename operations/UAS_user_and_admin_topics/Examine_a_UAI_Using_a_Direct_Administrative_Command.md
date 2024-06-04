# Examine a UAI Using a Direct Administrative Command

**NOTE:** UAI is deprecated in CSM 1.5.2 and will be removed in CSM 1.6.

Print out information about a UAI.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway.
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host.
* The HPE Cray EX System CLI must be configured (initialized with `cray init` command) to reach the HPE Cray EX System API Gateway.
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command).
* The administrator must know the UAI Name of the target UAI; See [List UAIs](List_UAIs.md).

## Procedure

Print out information about a UAI.

To examine an existing UAI use a command of the following form:

```console
cray uas admin uais describe <uai-name>
```

For example:

```console
ncn-m001-cray uas admin uais describe uai-broker-07624d65
```

Example output:

```text
uai_age = "5h33m"
uai_connect_string = "ssh broker@34.136.140.107"
uai_host = "ncn-w003"
uai_img = "registry.local/cray/cray-uai-broker:1.2.4"
uai_ip = "34.136.140.107"
uai_msg = ""
uai_name = "uai-broker-07624d65"
uai_status = "Running: Ready"
username = "broker"

[uai_portmap]
```

[Top: User Access Service (UAS)](README.md)

[Next Topic: Deleting a UAI](Delete_a_UAI.md)
