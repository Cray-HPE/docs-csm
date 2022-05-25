# List UAIs

There are two ways to list UAIs in UAS. One of these is an administrative action and provides access to all currently running UAIs.
The other is associated with the [Legacy UAI Management](Legacy_Mode_User-Driven_UAI_Management.md) mode and provides authorized users access to their own UAIs. Both of these are shown here.

View the details of every UAI that is running by using a direct UAS administrative command.

## Prerequisites

For administrative procedures:

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)

For Legacy Mode user procedures:

* The user must be logged into a host that has user access to the HPE Cray EX System API Gateway
* The user must have an installed initialized `cray` CLI and network access to the API Gateway
* The user must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The user must be logged in as to the HPE Cray EX System CLI (`cray auth login` command)

## Procedure

1. List the existing UAIs as an administrator.

    Use a command of the following form:

    ```bash
    ncn-m001-pit# cray uas admin uais list OPTIONS
    ```

    OPTIONS includes includes the following selection options:

    * `--owner '<user-name>'` show only UAIs owned by the named user
    * `--class-id '<class-id'` show only UAIs of the specified UAI class

    The following lists Broker UAIs on a system where administrators follow a convention that a Broker UAI is created with an owner called `broker`:

    ```bash
    ncn-m001-pit# cray uas admin uais list --owner broker
    ```

    Example output:

    ```bash
    [[results]]
    uai_age = "5h3m"
    uai_connect_string = "ssh broker@34.136.140.107"
    uai_host = "ncn-w003"
    uai_img = "registry.local/cray/cray-uai-broker:1.2.4"
    uai_ip = "34.136.140.107"
    uai_msg = ""
    uai_name = "uai-broker-07624d65"
    uai_status = "Running: Ready"
    username = "broker"
    ```

1. List the UAIs owned by an authorized user named `vers` in the Legacy Mode of UAI management.

    ```bash
    vers>  cray uas list
    ```

    Example output:

    ```bash
    [[results]]
    uai_age = "3m"
    uai_connect_string = "ssh vers@35.188.16.85"
    uai_host = "ncn-w003"
    uai_img = "registry.local/cray/cray-uai-sles15sp2:1.2.4"
    uai_ip = "35.188.16.85"
    uai_msg = ""
    uai_name = "uai-vers-4a38a807"
    uai_status = "Running: Ready"
    username = "vers"
    ```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Creating a UAI](Create_a_UAI.md)
