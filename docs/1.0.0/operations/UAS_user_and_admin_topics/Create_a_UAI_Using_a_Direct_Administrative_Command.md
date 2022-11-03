# Create a UAI Using a Direct Administrative Command

Administrators can use this method to manually create UAIs. This method is intended more for creating broker UAIs than for creating end-user UAIs.

### Prerequisites

Install and initialize the `cray` administrative CLI.

### Procedure

This method is intended more for creating broker UAIs than for creating end-user UAIs. Administrators can, however, create end-user UAIs using this method.

1.  Create a UAI manually with a command of the form:

    ```bash
    ncn-m001-pit# cray uas admin uais create OPTIONS
    ```

    OPTIONS is one or more of the following:

    -   `--owner USERNAME`: Create the UAI as owned by the specified user.
    -   `--class-id CLASS_ID`: The class of the UAI to be created. This option must be specified unless a default UAI class exists, in which case, it can be omitted and the default will be used.
    -   `--passwd str PASSWORD_STRING`: The /etc/password format string for the user who owns the UAI. This will be used to set up credentials within the UAI for the owner when the owner logs into the UAI.
    -   `--publickey-str PUBLIC_SSH_KEY`: The SSH public key that will be used to authenticate with the UAI. The key should be, for example, the contents of an id\_rsa.pub file used by SSH.

