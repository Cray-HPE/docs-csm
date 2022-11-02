# Create a UAI with Additional Ports

In legacy mode UAI creation, an option is available to expose UAI ports to the customer user network in addition to the port used for SSH access. These ports are restricted to ports 80, 443, and 8888.
This procedure allows a user or administrator to create a new UAI with these additional ports.

## Prerequisites

* The user must be logged into a host that has user access to the HPE Cray EX System API Gateway
* The user must have an installed initialized `cray` CLI and network access to the API Gateway
* The user must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The user must be logged in as to the HPE Cray EX System CLI (`cray auth login` command)
* The user must have a public SSH key configured on the host from which SSH connections to the UAI will take place
* The user must have access to a file containing the above public SSH key

## Limitations

Only ports 80, 443, and 8888 can be exposed. Attempting to open any other ports will result in an error.

## Procedure

1. Create a new UAI with the `--ports` option.

    ```bash
    vers> cray uas create --publickey PUBLIC_SSH_KEY_FILE --ports PORT_LIST
    ```

    When these ports are exposed in the UAI, they will be mapped from the port number on the externally visible IP address of the UAI to the port number used to reach the UAI pod.
    The mapping of these ports is displayed in the `uai_portmap` element of the returned output from `cray uas create`, and `cray uas list`.
    The mapping is shown as a dictionary where the key is the externally served port and the value is the internally routed port.
    Applications running on the UAI should listen on the internally routed port. Usually these will be the same value.

    ```bash
    vers> cray uas create --publickey ~/.ssh/id_rsa.pub --ports 80,443,8888
    ```

    Example output:

    ```bash
    uai_age = "0m"
    uai_connect_string = "ssh vers@34.68.41.239"
    uai_host = "ncn-w002"
    uai_img = "registry.local/cray/cray-uai-sles15sp2:1.2.4"
    uai_ip = "34.68.41.239"
    uai_msg = ""
    uai_name = "uai-vers-42de2eeb"
    uai_status = "Running: Ready"
    username = "vers"

    [uai_portmap]
    80 = 80
    443 = 443
    8888 = 8888
    ```

2. Log in to the UAI with the connection string.

    ```bash
    ssh USERNAME@UAI_IP_ADDRESS -i ~/.ssh/id_rsa
    ```

[Top: User Access Service (UAS)](README.md)
