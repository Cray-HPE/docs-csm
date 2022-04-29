# Start a Broker UAI

Create a Broker UAI after a Broker UAI class has been created.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* There must be an appropriate Broker UAI Class defined: [Configure a Broker UAI Class](Configure_a_Broker_UAI_Class.md)
* The administrator must know the Class ID of the desired Broker UAI Class: [List UAI Classes](List_Available_UAI_Classes.md)

Optional: the administrator may choose a site defined name for the Broker UAI to be used in conjunction with the HPE Cray EX System External DNS mechanism.

## Procedure

Use the following command to create a Broker UAI:

```bash
ncn-m001-pit# cray uas admin uais create --class-id <class-id> [--owner <name>]
```

To make the broker obvious in the list of UAIs, giving it an owner name of `broker` is handy. The owner name on a broker is used for naming and filtering (for listing or deleting), but nothing else, so this is a convenient convention.
Alternatively, giving it a descriptive owner to make it easy to tell the differences between brokers of different kinds can be useful. Keep in mind that the owner here can only be lower-case alphanumeric or `-` (dash) characters.

The following is an example using the class created above:

```bash
ncn-m001-pit# cray uas admin uais create --class-id d764c880-41b8-41e8-bacc-f94f7c5b053d --owner broker
```

Example output:

```bash
uai_age = "0m"
uai_connect_string = "ssh broker@35.226.246.154"
uai_host = "ncn-w003"
uai_img = "registry.local/cray/cray-uai-broker:1.2.4"
uai_ip = "35.226.246.154"
uai_msg = ""
uai_name = "uai-broker-70512bbb"
uai_status = "Running: Ready"
username = "broker"

[uai_portmap]
```

When a UAI is created on an external IP address (as is always the case with Broker UAIs) the UAI name (`uai_name` field above) is given to the HPE Cray EX System External DNS mechanism to be advertised to the site DNS.
Unless a site defined name is used, a unique name like the one shown above is calculated and used.
If a site defined DNS name for the Broker UAI is desired, the UAI name may be added to the command that creates the Broker UAI as follows:

```bash
ncn-m001-pit# cray uas admin uais create --class-id d764c880-41b8-41e8-bacc-f94f7c5b053d --owner broker --uai-name my-broker-uai
```

Example output:

```bash
uai_age = "0m"
uai_connect_string = "ssh broker@35.226.246.154"
uai_host = "ncn-w003"
uai_img = "registry.local/cray/cray-uai-broker:1.2.4"
uai_ip = "35.226.246.154"
uai_msg = ""
uai_name = "my-broker-uai"
uai_status = "Running: Ready"
username = "broker"

[uai_portmap]
```

If a UAI name is specified for creation that matches that of an already created UAI, no new UAI will be created, but the creation operation will appear to succeed and will return the status of the already existing UAI.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Log in to a Broker UAI](Log_in_to_a_Broker_UAI.md)
