# Create a UAI

The UAS allows either administrators or authorized users using the [Legacy Mode](Legacy_Mode_User-Driven_UAI_Management.md) of UAI management to create UAIs. This section shows both methods.

It is rare that an an administrator would hand-craft an End-User UAI using this administrative procedure, but it is possible. This is, however, the procedure used to create Broker UAIs for [Broker Mode UAI Management](Broker_Mode_UAI_Management.md).

## Prerequisites

For administrative procedures:

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* For the administrative procedure,
  * the administrator must know at least the UAI Class ID to use in creating the UAI, or
  * A default UAI Class must be defined that creates the desired class of UAI

Optional: the administrator may choose a site defined name for the UAI to be used in conjunction with the HPE Cray EX System External DNS mechanism. This is only meaningful for UAIs presented on a public IP address.

For Legacy Mode user procedures:

* The user must be logged into a host that has user access to the HPE Cray EX System API Gateway
* The user must have an installed initialized `cray` CLI and network access to the API Gateway
* The user must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The user must be logged in as to the HPE Cray EX System CLI (`cray auth login` command)
* The user must have a public SSH key configured on the host from which SSH connections to the UAI will take place
* The user must have access to a file containing the above public SSH key

## Procedure

1. Create a UAI administratively.

    Use a command of the following form:

    ```bash
    ncn# cray uas admin uais create OPTIONS
    ```

    The following `OPTIONS` are available for use:

    * `--class-id <class-id>` - The class of the UAI to be created. This option must be specified unless a default UAI class exists, in which case, it can be omitted and the default will be used.
    * `--owner '<user-name>'` - Create the UAI as owned by the specified user.
    * `--passwd str '<passwd-string>'` - Specify the `/etc/password` format string for the user who owns the UAI. This will be used to set up credentials within the UAI for the owner when the owner logs into the UAI.
    * `--publickey-str '<public-ssh-key>'` - Specify the SSH public key that will be used to authenticate with the UAI. The key should be, for example, the contents of an `id_rsa.pub` file used by SSH.
    * `--uai-name TEXT` - Specify an optional name to be assigned to the UAI on creation. If this is not specified, a default name of the form `<owner>-uai-<short-uuid>` is used.
    The UAI name is used both as the name of the UAI in the UAS and as the external DNS hostname of a publicly accessible UAI.
    If the requested UAI name is the same as an already existing UAI, no new UAI is created, but the information about the existing UAI is returned.
    UAI names may contain up to 63 lower case alphanumeric or `-` characters, and must start and end with an alphanumeric character.

2. Create a UAI in the Legacy Mode of UAI Management.

    Use a command of the following form:

    ```bash
    ncn# cray uas create OPTIONS
    ```

    The following OPTIONS are available for use:
    * `--publickey <path>` - the path to a file containing the public SSH key to be used to talk to this UAI. This option is required and must specify a valid public key file name.
    * `--ports <port-list>` - a comma-separated list of TCP [port numbers to be opened on the newly created UAI](Create_a_UAI_with_Additional_Ports.md). This option is not required and will be overridden by a default UAI Class if a default UAI Class is configured.
    * `--imagename <uai-image-name>` - The name of the UAI container image to be used to create the UAI. This option is not required. If omitted the default UAI image will be used.
    Both the default UAI image and anything specified here will be overridden by a default UAI Class if a default UAI Class is configured.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Examining a UAI Using a Direct Administrative Command](Examine_a_UAI_Using_a_Direct_Administrative_Command.md)
