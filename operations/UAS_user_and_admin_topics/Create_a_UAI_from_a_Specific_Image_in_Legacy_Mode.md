# Create a UAI from a Specific Image in Legacy Mode

How users can choose a specific registered image for their UAIs when legacy mode UAI management is used on the HPE Cray EX system.

-   A public SSH key
-   Initialize the cray CLI for non-admin users

-   **ROLE**

    User

-   **OBJECTIVE**

    Create a UAI that uses a specific, registered image.


1.  2.  List available UAS images.

    ```screen
    # cray uas images list 
    default_image = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    image_list = [ "registry.local/cray/cray-uas-sles15sp1-slurm:latest", "registry.local/cray/cray-uas-sles15sp1:latest",]
    ```

    **Troubleshooting:** If the Cray CLI has not been initialized, the CLI commands will not work. See [Configure the Cray Command Line Interface \(CLI\)](../configure_cray_cli.md).

3.  Create a new UAI.

    ```screen
    # cray uas create --publickey PUBLIC\_SSH\_KEY\_FILE
    
    ```

    ```screen
    # cray uas create --publickey /root/.ssh/id_rsa.pub
    username = ""
    uai_msg = "ContainerCreating"
    uai_host = ""
    uai_status = "Waiting"
    uai_age = "0m"
    uai_connect_string =  ""
    uai_img = ""
    uai_name = ""
        
    ```

    To create a UAI with a non-default image, add the --imagename argument with the above command.

4.  Verify the UAI is in the "Running: Ready" state.

    ```screen
    # cray uas list
    [[results]]
    username = ""
    uai_host = ""
    uai_status = "**Running: Ready**"
    uai_connect_string = ""
    uai_img = ""
    uai_age = "0m"
    uai_name = ""
        
     
    ```

5.  Log in to the UAI with the connection string.

    ```screen
    $ ssh USERNAME@UAI\_IP\_ADDRESS -i ~/.ssh/id\_rsa
    ```


