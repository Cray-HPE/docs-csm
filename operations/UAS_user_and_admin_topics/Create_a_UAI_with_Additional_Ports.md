---
category: numbered
---

# Create a UAI with Additional Ports

Displays when you mouse over the topic on the Cray Portal.

-   A public SSH key

-   **ROLE**

    System Adminstrator, User

-   **OBJECTIVE**

    A option is available to expose UAI ports to the customer user network in addition to the the port used for SSH access. These ports are restricted to ports 80, 443, and 8888. This procedure allows a user or administrator to create a new UAI with these additional ports.

-   **LIMITATIONS**

    Only ports 80, 443, and 8888 can be exposed. Attempting to open any other ports will result in an error.


1.  Log in to a UAN.

2.  Create a new UAI with the --ports option.

    ```screen
    ncn-w001# cray uas create --publickey PUBLIC\_SSH\_KEY\_FILE --ports PORT\_LIST
    
    ```

    **Troubleshooting:** If the Cray CLI has not been initialized, the CLI commands will not work. See [Configure the Cray Command Line Interface \(CLI\)](../configure_cray_cli.md).

    When these ports are exposed in the UAI, they will be mapped to unique ports on the UAI IP address. The mapping of these ports is displayed in the `uai_portmap` element of the return output from cray uas create, cray uas describe, and cray uas uais list. The mapping is shown as a dictionary where the key is the port requested and the value is the port that key is mapped to.

    ```screen
    ncn-w001# cray uas create --publickey /root/.ssh/id_rsa.pub --ports 80,443
    username = "user"
    uai_msg = "ContainerCreating"
    uai_host = "ncn-w001"
    uai_status = "Waiting"
    uai_age = "0m"
    uai_connect_string =  "ssh user@203.0.113.0 -i ~/.ssh/id\_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_name = "uai-user-be3a6770"
       
    [uai_portmap]
    443 = 30173
    80 = 32190
    8888 = 32469 
    ```

3.  Log in to the UAI with the connection string.

    ```screen
    $ ssh USERNAME@UAI\_IP\_ADDRESS -i ~/.ssh/id\_rsa
    ```


**Parent topic:**[User Access Service \(UAS\)](User_Access_Service_UAS.md)

